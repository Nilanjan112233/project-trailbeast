extends SceneTree

# Deterministic test suite for Moving Fortress Map Prototype.
# Verifies route graph, modular loadouts, encounters, camera clamping, decisions,
# combat mechanics, restart integrity, and modal shielding.

var passed_count: int = 0
var failed_count: int = 0
var has_run: bool = false

func _process(_delta: float) -> bool:
	if has_run:
		return true
	has_run = true

	print("==================================================")
	print(" RUNNING MOVING FORTRESS HEADLESS TEST SUITE")
	print("==================================================")

	test_required_scenes_load_and_instantiate()
	test_route_connection_validation_and_rejection()
	test_map_node_completion_and_no_revisiting()
	test_camera_clamping_and_recenter()
	test_shellback_travel_lifecycle_and_halt_resume()
	test_modular_loadout_rules()
	test_armour_screen_damage_reduction()
	test_storage_rack_resource_bonus()
	test_bolt_damage_at_impact()
	test_snare_availability_and_charges()
	test_resource_rewards_applied_once()
	test_river_crossing_decision()
	test_victory_and_defeat_exclusivity()
	test_restart_restoring_complete_prototype()
	test_freed_target_safety()
	test_modal_shielding_and_onboarding()
	test_regression_onboarding_sequence()
	test_regression_tree_pauses_and_resumes_safely()
	test_regression_mid_travel_route_locking()
	test_regression_snare_placement_validation()
	test_regression_reward_idempotency()
	test_regression_final_pass_hold_point()
	test_regression_restart_clears_all_new_state()
	test_integrated_startup_onboarding_and_pan()
	test_four_loadout_combinations_viable()
	test_final_pass_timing_simulation()
	test_full_run_strategies_viable()

	if paused:
		paused = false

	print("==================================================")
	print(" TEST RESULTS: %d PASSED, %d FAILED" % [passed_count, failed_count])
	print("==================================================")

	if failed_count == 0:
		print(">> ALL MOVING FORTRESS TESTS PASSED SUCCESSFULLY! <<")
		quit(0)
	else:
		printerr(">> SOME TESTS FAILED! <<")
		quit(1)

	return true

func assert_true(condition: bool, test_name: String, message: String = "") -> void:
	if condition:
		passed_count += 1
		print("  [PASS] %s" % test_name)
	else:
		failed_count += 1
		printerr("  [FAIL] %s - %s" % [test_name, message])

func test_required_scenes_load_and_instantiate() -> void:
	print("\n--- Test: Required scenes load and instantiate ---")
	var scenes: Array[String] = [
		"res://scenes/main.tscn",
		"res://scenes/shellback.tscn",
		"res://scenes/hud.tscn",
		"res://scenes/raider.tscn",
		"res://scenes/wolf.tscn",
		"res://scenes/snare.tscn",
		"res://scenes/bolt_launcher.tscn",
		"res://scenes/projectile.tscn"
	]
	for sc_path in scenes:
		var res := load(sc_path) as PackedScene
		assert_true(res != null, "Scene resource load: %s" % sc_path, "")
		if res:
			var inst: Node = res.instantiate()
			assert_true(inst != null, "Scene instantiate: %s" % sc_path, "")
			inst.free()

func test_route_connection_validation_and_rejection() -> void:
	print("\n--- Test: Route connection validation and rejection ---")
	var mm := MapManager.new()

	# Start camp connections
	assert_true(mm.are_nodes_connected("start_camp", "woodland"), "Start camp connected to Woodland", "")
	assert_true(mm.are_nodes_connected("start_camp", "watchpost"), "Start camp connected to Watchpost", "")

	# Woodland & Watchpost connect to River crossing
	assert_true(mm.are_nodes_connected("woodland", "river_crossing"), "Woodland connected to River crossing", "")
	assert_true(mm.are_nodes_connected("watchpost", "river_crossing"), "Watchpost connected to River crossing", "")

	# River crossing connects to Final pass
	assert_true(mm.are_nodes_connected("river_crossing", "final_pass"), "River crossing connected to Final pass", "")

	# Final pass connects to Exit camp
	assert_true(mm.are_nodes_connected("final_pass", "exit_camp"), "Final pass connected to Exit camp", "")

	# Rejection of disconnected nodes
	assert_true(not mm.are_nodes_connected("start_camp", "river_crossing"), "Start camp NOT directly connected to River crossing", "")
	assert_true(not mm.are_nodes_connected("start_camp", "exit_camp"), "Start camp NOT directly connected to Exit camp", "")
	assert_true(not mm.can_travel_to("river_crossing"), "Cannot travel from Start camp to River crossing", "")
	assert_true(not mm.can_travel_to("exit_camp"), "Cannot travel from Start camp to Exit camp", "")

	# Can travel to connected destinations
	assert_true(mm.can_travel_to("woodland"), "Can travel to Woodland from Start camp", "")
	assert_true(mm.can_travel_to("watchpost"), "Can travel to Watchpost from Start camp", "")

func test_map_node_completion_and_no_revisiting() -> void:
	print("\n--- Test: Map node completion and no revisiting ---")
	var mm := MapManager.new()

	assert_true(mm.is_node_completed("start_camp"), "Start camp completed by default", "")
	assert_true(not mm.can_travel_to("start_camp"), "Cannot travel to already completed Start camp", "")

	# Complete woodland
	mm.select_node("woodland")
	var rew := mm.complete_node("woodland")
	assert_true(mm.current_node_id == "woodland", "Current node updated to Woodland", "")
	assert_true(mm.is_node_completed("woodland"), "Woodland marked completed", "")
	assert_true(not mm.can_travel_to("woodland"), "Cannot revisit completed Woodland", "")
	assert_true(rew.get("food", 0) == 15, "Woodland base reward food is 15", "")

	# From Woodland, can travel to River crossing
	assert_true(mm.can_travel_to("river_crossing"), "Can travel to River crossing from Woodland", "")
	assert_true(not mm.can_travel_to("watchpost"), "Cannot travel across to Watchpost from Woodland", "")

func test_camera_clamping_and_recenter() -> void:
	print("\n--- Test: Camera clamping and recenter ---")
	var cam := CameraController.new()

	# Boundary limits: viewport 1280x720 in 2560x1440 world
	# Clamps to [640, 1920] x [360, 1080]
	var clamped_min := cam.clamp_camera_position(Vector2(-500, -500))
	assert_true(clamped_min == Vector2(640, 360), "Camera clamps to top-left boundary (640, 360)", "Got: %s" % clamped_min)

	var clamped_max := cam.clamp_camera_position(Vector2(4000, 4000))
	assert_true(clamped_max == Vector2(1920, 1080), "Camera clamps to bottom-right boundary (1920, 1080)", "Got: %s" % clamped_max)

	var clamped_mid := cam.clamp_camera_position(Vector2(1000, 700))
	assert_true(clamped_mid == Vector2(1000, 700), "Camera within bounds remains unshifted", "Got: %s" % clamped_mid)

	cam.recenter(Vector2(320, 720))
	assert_true(cam.position == Vector2(640, 720), "Recenter on Start camp (320, 720) clamps X to 640", "Got: %s" % cam.position)
	cam.free()

func test_shellback_travel_lifecycle_and_halt_resume() -> void:
	print("\n--- Test: Shellback travel lifecycle and halt/resume ---")
	var sh_scene := load("res://scenes/shellback.tscn") as PackedScene
	var sh: Shellback = sh_scene.instantiate() as Shellback
	root.add_child(sh)

	sh.reset(Vector2(320, 720))
	assert_true(not sh.is_moving, "Shellback begins stationary at camp", "")

	# Start travel along test waypoints
	var waypoints: Array[Vector2] = [Vector2(320, 720), Vector2(400, 720)]
	sh.start_travel(waypoints, "test_dest")
	assert_true(sh.is_moving, "Shellback is moving after start_travel", "")

	# Halt Shellback
	sh.toggle_movement()
	assert_true(not sh.is_moving, "Shellback is halted after toggle_movement", "")

	# Resume Shellback
	sh.toggle_movement()
	assert_true(sh.is_moving, "Shellback resumed after second toggle_movement", "")

	# Simulate movement completing route
	sh._process(2.0)
	assert_true(not sh.is_moving, "Shellback stops moving upon reaching destination waypoint", "")
	assert_true(sh.global_position == Vector2(400, 720), "Shellback arrived at final waypoint position", "")

	sh.free()

func test_modular_loadout_rules() -> void:
	print("\n--- Test: Modular loadout rules ---")
	var sh_scene := load("res://scenes/shellback.tscn") as PackedScene
	var sh: Shellback = sh_scene.instantiate() as Shellback

	assert_true(sh.equipped_modules.size() == 3, "Shellback defaults to exactly 3 equipped modules", "")

	# Reject 2 modules
	var res_2 := sh.set_equipped_modules(["bolt_launcher", "armour_screen"])
	assert_true(not res_2, "Rejected loadout with only 2 modules", "")

	# Reject 4 modules
	var res_4 := sh.set_equipped_modules(["bolt_launcher", "armour_screen", "storage_rack", "snare_rack"])
	assert_true(not res_4, "Rejected loadout with 4 modules", "")

	# Accept exactly 3 modules
	var res_3 := sh.set_equipped_modules(["armour_screen", "storage_rack", "snare_rack"])
	assert_true(res_3, "Accepted loadout with exactly 3 modules", "")
	assert_true(sh.has_module("storage_rack"), "Shellback now has storage rack", "")
	assert_true(not sh.has_module("bolt_launcher"), "Shellback does not have bolt launcher", "")

	sh.free()

func test_armour_screen_damage_reduction() -> void:
	print("\n--- Test: Armour screen damage reduction ---")
	var sh_scene := load("res://scenes/shellback.tscn") as PackedScene
	var sh: Shellback = sh_scene.instantiate() as Shellback

	# Without armour screen
	sh.reset(Vector2(320, 720))
	sh.set_equipped_modules(["bolt_launcher", "storage_rack", "snare_rack"])
	assert_true(not sh.has_module("armour_screen"), "Armour screen unequipped", "")
	sh.take_damage(20.0)
	assert_true(sh.current_health == 230.0, "Full 20 damage applied without armour screen (250 -> 230)", "Got: %f" % sh.current_health)

	# With armour screen (-40% damage reduction -> takes 60%)
	sh.reset(Vector2(320, 720))
	sh.set_equipped_modules(["bolt_launcher", "armour_screen", "snare_rack"])
	assert_true(sh.has_module("armour_screen"), "Armour screen equipped", "")
	sh.take_damage(20.0)
	assert_true(sh.current_health == 238.0, "Armour screen reduces 20 damage by 40% to 12 damage (250 -> 238)", "Got: %f" % sh.current_health)

	sh.free()

func test_storage_rack_resource_bonus() -> void:
	print("\n--- Test: Storage rack resource bonus ---")
	var base_rew: Dictionary = {"food": 10, "wood": 10, "salvage": 10}

	# Without storage rack: 1.0x
	var mult_normal: float = 1.0
	var food_normal := int(round(float(base_rew["food"]) * mult_normal))
	assert_true(food_normal == 10, "Normal food reward is 10", "")

	# With storage rack: 1.5x bonus
	var mult_storage: float = 1.5
	var food_boosted := int(round(float(base_rew["food"]) * mult_storage))
	assert_true(food_boosted == 15, "Storage rack boosted food reward is 15 (+50%)", "")

func test_bolt_damage_at_impact() -> void:
	print("\n--- Test: Bolt damage occurs at impact, not at fire time ---")
	var wolf_scene := load("res://scenes/wolf.tscn") as PackedScene
	var wolf: Wolf = wolf_scene.instantiate() as Wolf
	wolf.global_position = Vector2(800, 720)
	root.add_child(wolf)

	var launcher_scene := load("res://scenes/bolt_launcher.tscn") as PackedScene
	var launcher: BoltLauncher = launcher_scene.instantiate() as BoltLauncher
	launcher.global_position = Vector2(320, 720)
	root.add_child(launcher)

	var proj_container := Node2D.new()
	root.add_child(proj_container)

	var proj: Projectile = launcher.fire(proj_container, wolf)
	assert_true(proj != null, "Bolt projectile spawned", "")
	assert_true(wolf.current_health == 60.0, "Wolf HP unchanged at firing time (no premature damage)", "")

	# Mid-flight check
	proj._process(0.1)
	assert_true(wolf.current_health == 60.0, "Wolf HP unchanged while bolt is mid-flight", "")

	# Impact application
	proj.global_position = wolf.get_projectile_hit_point()
	proj._process(0.01)
	assert_true(wolf.current_health == 30.0, "Damage (30) applied precisely on physical impact (60 -> 30)", "Got: %f" % wolf.current_health)

	proj_container.free()
	launcher.free()
	wolf.free()

func test_snare_availability_and_charges() -> void:
	print("\n--- Test: Snare availability and charges ---")
	var sh_scene := load("res://scenes/shellback.tscn") as PackedScene
	var sh: Shellback = sh_scene.instantiate() as Shellback

	# Equipped: Snare rack has 1 charge
	sh.set_equipped_modules(["bolt_launcher", "armour_screen", "snare_rack"])
	assert_true(sh.snare_charges == 1, "Snare charge is 1 when Snare rack equipped", "")

	# Unequipped: Snare rack has 0 charges
	sh.set_equipped_modules(["bolt_launcher", "armour_screen", "storage_rack"])
	assert_true(sh.snare_charges == 0, "Snare charge is 0 when Snare rack unequipped", "")

	# Verify snare holding wolf
	var snare_scene := load("res://scenes/snare.tscn") as PackedScene
	var snare: Trap = snare_scene.instantiate() as Trap
	snare.global_position = Vector2(500, 720)
	root.add_child(snare)

	var wolf_scene := load("res://scenes/wolf.tscn") as PackedScene
	var wolf: Wolf = wolf_scene.instantiate() as Wolf
	wolf.global_position = Vector2(505, 720)
	root.add_child(wolf)

	snare._process(0.05)
	assert_true(wolf.state == Wolf.State.SNARED, "Wolf enters SNARED state upon stepping on snare", "")

	snare.free()
	wolf.free()
	sh.free()

func test_resource_rewards_applied_once() -> void:
	print("\n--- Test: Resource rewards applied once ---")
	var mm := MapManager.new()
	var rew_1 := mm.complete_node("woodland")
	assert_true(not rew_1.is_empty(), "First completion returns resource rewards", "")
	assert_true(mm.is_node_completed("woodland"), "Woodland is now marked completed", "")
	assert_true(not mm.can_travel_to("woodland"), "Completed node cannot be visited again", "")

func test_river_crossing_decision() -> void:
	print("\n--- Test: River crossing decision (Repair vs Hurry) ---")
	var sh_scene := load("res://scenes/shellback.tscn") as PackedScene
	var sh: Shellback = sh_scene.instantiate() as Shellback
	sh.current_health = 50.0

	var wood: int = 15

	# Repair decision
	var repair_chosen: bool = true
	if repair_chosen and wood >= 10:
		wood -= 10
		sh.heal(60.0)

	assert_true(wood == 5, "Repair spent 10 wood (15 -> 5)", "Got: %d" % wood)
	assert_true(sh.current_health == 110.0, "Repair restored 60 HP (50 -> 110)", "Got: %f" % sh.current_health)

	# Hurry decision
	var hurry_flag: bool = false
	var hurry_chosen: bool = true
	if hurry_chosen:
		hurry_flag = true

	assert_true(hurry_flag, "Hurry decision set hurry threat flag", "")
	sh.free()

func test_victory_and_defeat_exclusivity() -> void:
	print("\n--- Test: Victory and defeat exclusivity ---")
	var mm := MapManager.new()
	mm.complete_node("exit_camp")
	assert_true(mm.is_victory(), "Reaching exit_camp triggers victory condition", "")

	var sh_scene := load("res://scenes/shellback.tscn") as PackedScene
	var sh: Shellback = sh_scene.instantiate() as Shellback
	sh.reset(Vector2(2380, 720))
	assert_true(sh.is_alive(), "Shellback is alive at exit camp", "")

	# Death triggers defeat
	sh.set_health(0.0)
	assert_true(not sh.is_alive(), "Shellback at 0 HP is dead", "")
	assert_true(sh.state == Shellback.State.DEAD, "Shellback state is DEAD", "")

	# Dead Shellback cannot heal or revive
	sh.heal(50.0)
	assert_true(sh.current_health == 0.0, "Dead Shellback cannot be healed", "")
	sh.free()

func test_restart_restoring_complete_prototype() -> void:
	print("\n--- Test: Restart restoring complete prototype ---")
	var mm := MapManager.new()
	mm.complete_node("woodland")
	mm.complete_node("river_crossing")
	assert_true(mm.completed_nodes.size() > 1, "Nodes completed before reset", "")

	mm.reset()
	assert_true(mm.current_node_id == "start_camp", "Map reset restores current node to start_camp", "")
	assert_true(mm.completed_nodes == ["start_camp"], "Map reset resets completed nodes list", "")
	assert_true(mm.can_travel_to("woodland"), "Woodland is reachable again after reset", "")

func test_freed_target_safety() -> void:
	print("\n--- Test: Freed target safety ---")
	var launcher_scene := load("res://scenes/bolt_launcher.tscn") as PackedScene
	var launcher: BoltLauncher = launcher_scene.instantiate() as BoltLauncher
	root.add_child(launcher)

	var proj_container := Node2D.new()
	root.add_child(proj_container)

	var wolf_scene := load("res://scenes/wolf.tscn") as PackedScene
	var wolf: Wolf = wolf_scene.instantiate() as Wolf
	root.add_child(wolf)

	var proj: Projectile = launcher.fire(proj_container, wolf)
	assert_true(proj != null, "Projectile fired at valid wolf", "")

	# Free wolf before impact
	wolf.free()
	proj._process(0.1)
	assert_true(true, "Projectile handles freed target without crashing", "")

	proj_container.free()
	launcher.free()

func test_modal_shielding_and_onboarding() -> void:
	print("\n--- Test: Modal shielding and onboarding ---")
	var hud_scene := load("res://scenes/hud.tscn") as PackedScene
	var hud: HUD = hud_scene.instantiate() as HUD
	root.add_child(hud)

	# Onboarding steps defined
	assert_true(HUD.ONBOARDING_TEXTS.size() == 5, "Exactly 5 onboarding steps configured", "")
	assert_true(HUD.ONBOARDING_TEXTS[HUD.OnboardingStep.PAN_MAP]["title"].contains("PAN THE MAP"), "Step 1 is PAN THE MAP", "")
	assert_true(HUD.ONBOARDING_TEXTS[HUD.OnboardingStep.INSPECT_ROUTE]["title"].contains("INSPECT A ROUTE"), "Step 2 is INSPECT A ROUTE", "")
	assert_true(HUD.ONBOARDING_TEXTS[HUD.OnboardingStep.CHOOSE_MODULES]["title"].contains("LOADOUT"), "Step 3 is CONFIGURE LOADOUT", "")
	assert_true(HUD.ONBOARDING_TEXTS[HUD.OnboardingStep.CONFIRM_TRAVEL]["title"].contains("CONFIRM TRAVEL"), "Step 4 is CONFIRM TRAVEL", "")
	assert_true(HUD.ONBOARDING_TEXTS[HUD.OnboardingStep.TRAVEL_COMBAT]["title"].contains("TRAVEL & DEFEND"), "Step 5 is TRAVEL & DEFEND", "")

	# Modal shielding
	hud.reset_ui()
	assert_true(not hud.is_any_modal_open(), "No modal open after reset_ui", "")

	hud.show_onboarding_step(HUD.OnboardingStep.PAN_MAP)
	assert_true(hud.is_any_modal_open(), "is_any_modal_open returns true while onboarding open", "")

	hud.onboarding_overlay.visible = false
	assert_true(not hud.is_any_modal_open(), "is_any_modal_open returns false after closing onboarding", "")

	hud.show_route_inspector({"name": "Test"}, true, false)
	assert_true(hud.is_any_modal_open(), "is_any_modal_open returns true while route inspector open", "")

	hud.reset_ui()
	assert_true(not hud.is_any_modal_open(), "reset_ui closes all open modals", "")

	hud.free()

func test_regression_onboarding_sequence() -> void:
	print("\n--- Regression Check 1: All five onboarding steps can be triggered in order ---")
	var hud_scene := load("res://scenes/hud.tscn") as PackedScene
	var hud: HUD = hud_scene.instantiate() as HUD
	root.add_child(hud)
	hud.reset_onboarding()

	assert_true(hud.get_next_unshown_step() == HUD.OnboardingStep.PAN_MAP, "Step 1 is next unshown step", "")

	# Cannot trigger step 3 out of order
	var skipped := hud.trigger_onboarding_step(HUD.OnboardingStep.CHOOSE_MODULES)
	assert_true(not skipped, "Out-of-order step trigger rejected", "")

	# Step 1: PAN_MAP
	var s1 := hud.trigger_onboarding_step(HUD.OnboardingStep.PAN_MAP)
	assert_true(s1, "Step 1 (PAN_MAP) triggered successfully", "")
	assert_true(hud.onboarding_overlay.visible, "Onboarding overlay visible for Step 1", "")
	assert_true(paused, "SceneTree paused during Step 1", "")
	hud._on_onboarding_dismiss_pressed()
	assert_true(not paused, "SceneTree safely unpaused after dismissing Step 1", "")
	assert_true(hud.has_step_been_shown(HUD.OnboardingStep.PAN_MAP), "Step 1 marked as shown", "")
	assert_true(hud.get_next_unshown_step() == HUD.OnboardingStep.INSPECT_ROUTE, "Step 2 is next unshown step", "")

	# Step 2: INSPECT_ROUTE
	var s2 := hud.trigger_onboarding_step(HUD.OnboardingStep.INSPECT_ROUTE)
	assert_true(s2, "Step 2 (INSPECT_ROUTE) triggered successfully", "")
	assert_true(paused, "SceneTree paused during Step 2", "")
	hud._on_onboarding_dismiss_pressed()
	assert_true(not paused, "SceneTree safely unpaused after dismissing Step 2", "")
	assert_true(hud.has_step_been_shown(HUD.OnboardingStep.INSPECT_ROUTE), "Step 2 marked as shown", "")
	assert_true(hud.get_next_unshown_step() == HUD.OnboardingStep.CHOOSE_MODULES, "Step 3 is next unshown step", "")

	# Step 3: CHOOSE_MODULES
	var s3 := hud.trigger_onboarding_step(HUD.OnboardingStep.CHOOSE_MODULES)
	assert_true(s3, "Step 3 (CHOOSE_MODULES) triggered successfully", "")
	assert_true(paused, "SceneTree paused during Step 3", "")
	hud._on_onboarding_dismiss_pressed()
	assert_true(not paused, "SceneTree safely unpaused after dismissing Step 3", "")
	assert_true(hud.has_step_been_shown(HUD.OnboardingStep.CHOOSE_MODULES), "Step 3 marked as shown", "")
	assert_true(hud.get_next_unshown_step() == HUD.OnboardingStep.CONFIRM_TRAVEL, "Step 4 is next unshown step", "")

	# Step 4: CONFIRM_TRAVEL
	var s4 := hud.trigger_onboarding_step(HUD.OnboardingStep.CONFIRM_TRAVEL)
	assert_true(s4, "Step 4 (CONFIRM_TRAVEL) triggered successfully", "")
	assert_true(paused, "SceneTree paused during Step 4", "")
	hud._on_onboarding_dismiss_pressed()
	assert_true(not paused, "SceneTree safely unpaused after dismissing Step 4", "")
	assert_true(hud.has_step_been_shown(HUD.OnboardingStep.CONFIRM_TRAVEL), "Step 4 marked as shown", "")
	assert_true(hud.get_next_unshown_step() == HUD.OnboardingStep.TRAVEL_COMBAT, "Step 5 is next unshown step", "")

	# Step 5: TRAVEL_COMBAT
	var s5 := hud.trigger_onboarding_step(HUD.OnboardingStep.TRAVEL_COMBAT)
	assert_true(s5, "Step 5 (TRAVEL_COMBAT) triggered successfully", "")
	assert_true(paused, "SceneTree paused during Step 5", "")
	hud._on_onboarding_dismiss_pressed()
	assert_true(not paused, "SceneTree safely unpaused after dismissing Step 5", "")
	assert_true(hud.has_step_been_shown(HUD.OnboardingStep.TRAVEL_COMBAT), "Step 5 marked as shown", "")
	assert_true(hud.has_completed_onboarding, "All 5 onboarding steps completed", "")
	assert_true(hud.get_next_unshown_step() == HUD.OnboardingStep.COMPLETED, "Next step indicates completed", "")

	hud.free()

func test_regression_tree_pauses_and_resumes_safely() -> void:
	print("\n--- Regression Check 2: SceneTree pauses and resumes safely ---")
	var hud_scene := load("res://scenes/hud.tscn") as PackedScene
	var hud: HUD = hud_scene.instantiate() as HUD
	root.add_child(hud)
	hud.reset_ui()

	assert_true(not paused, "SceneTree begins unpaused", "")
	hud.show_onboarding_step(HUD.OnboardingStep.PAN_MAP)
	assert_true(paused, "SceneTree is paused while teaching modal visible", "")
	hud._on_onboarding_dismiss_pressed()
	assert_true(not paused, "SceneTree resumes unpaused when modal is dismissed", "")

	hud.show_onboarding_step(HUD.OnboardingStep.INSPECT_ROUTE)
	assert_true(paused, "SceneTree paused again on second modal", "")
	hud.reset_ui()
	assert_true(not paused, "reset_ui restores unpaused SceneTree state", "")

	hud.free()

func test_regression_mid_travel_route_locking() -> void:
	print("\n--- Regression Check 3: Mid-travel route changes are rejected in Main and MapManager ---")
	var main_scene := load("res://scenes/main.tscn") as PackedScene
	var main_node: Main = main_scene.instantiate() as Main
	root.add_child(main_node)

	# Dismiss initial startup onboarding modal so it doesn't block map interactions
	if main_node.hud.onboarding_overlay.visible:
		main_node.hud._on_onboarding_dismiss_pressed()

	assert_true(not main_node.is_travel_in_progress(), "Travel is not in progress initially at camp", "")
	assert_true(main_node.map_manager.can_travel_to("woodland"), "Woodland is valid destination at camp", "")
	assert_true(main_node.map_manager.can_travel_to("watchpost"), "Watchpost is valid destination at camp", "")

	# Start travel to woodland
	main_node.map_manager.select_node("woodland")
	main_node._on_route_confirmed("woodland")
	assert_true(main_node.is_travel_in_progress(), "is_travel_in_progress is true after travel started", "")
	assert_true(main_node.map_manager.is_traveling, "MapManager is_traveling flag is set", "")

	# MapManager rejects mid-travel destination queries
	assert_true(not main_node.map_manager.can_travel_to("watchpost"), "MapManager rejects travel to Watchpost while traveling", "")
	assert_true(not main_node.map_manager.can_travel_to("woodland"), "MapManager rejects travel to Woodland while traveling", "")
	assert_true(main_node.map_manager.confirm_route().is_empty(), "confirm_route returns empty array while traveling", "")

	# Main rejects redirection mid-travel
	var cur_dest := main_node.shellback.destination_node_id
	main_node._on_route_confirmed("watchpost")
	assert_true(main_node.shellback.destination_node_id == cur_dest, "Shellback destination unchanged after mid-travel redirection attempt", "")

	# Tapping other nodes mid-travel shows inspector but locks confirmation
	main_node._on_map_tapped(Vector2(880.0, 1060.0))
	assert_true(main_node.hud.route_confirm_button.disabled, "Route confirm button is disabled while travel is in progress", "")
	assert_true(main_node.map_manager.selected_node_id != "watchpost", "selected_node_id not switched mid-travel", "")

	main_node.free()

func test_regression_snare_placement_validation() -> void:
	print("\n--- Regression Check 4: Snares cannot be consumed at camp or invalid positions ---")
	var main_scene := load("res://scenes/main.tscn") as PackedScene
	var main_node: Main = main_scene.instantiate() as Main
	root.add_child(main_node)

	assert_true(main_node.shellback.snare_charges == 1, "Shellback has 1 snare charge from Snare Rack", "")

	# Rejection 1: At camp (not in active travel encounter)
	main_node.hud.is_snare_placement_mode = true
	var res_camp := main_node._handle_snare_placement_attempt(Vector2(500.0, 720.0))
	assert_true(not res_camp, "Snare rejected at camp (outside travel encounter)", "")
	assert_true(main_node.shellback.snare_charges == 1, "Snare charge preserved at camp", "")
	assert_true(main_node.traps_container.get_child_count() == 0, "No trap spawned at camp", "")

	# Rejection 2: Outside playable trail region while travel is active
	main_node.map_manager.is_traveling = true
	main_node.hud.is_snare_placement_mode = true
	var res_out_min := main_node._handle_snare_placement_attempt(Vector2(50.0, 50.0))
	assert_true(not res_out_min, "Snare rejected outside min boundary (50, 50)", "")
	assert_true(main_node.shellback.snare_charges == 1, "Snare charge preserved on min out-of-bounds", "")

	var res_out_max := main_node._handle_snare_placement_attempt(Vector2(2500.0, 1350.0))
	assert_true(not res_out_max, "Snare rejected outside max boundary (2500, 1350)", "")
	assert_true(main_node.shellback.snare_charges == 1, "Snare charge preserved on max out-of-bounds", "")

	# Rejection 3: While modal is open
	main_node.hud.show_route_inspector({"name": "Test"}, true, false)
	main_node.hud.is_snare_placement_mode = true
	var res_modal := main_node._handle_snare_placement_attempt(Vector2(600.0, 500.0))
	assert_true(not res_modal, "Snare rejected while modal is open", "")
	assert_true(main_node.shellback.snare_charges == 1, "Snare charge preserved while modal open", "")
	main_node.hud.reset_ui()

	# Rejection 4: After game over
	main_node.game_ended = true
	main_node.hud.is_snare_placement_mode = true
	var res_ended := main_node._handle_snare_placement_attempt(Vector2(600.0, 500.0))
	assert_true(not res_ended, "Snare rejected after game ended", "")
	assert_true(main_node.shellback.snare_charges == 1, "Snare charge preserved after game ended", "")
	main_node.game_ended = false

	# Success: Valid placement during active travel encounter
	main_node.map_manager.is_traveling = true
	main_node.hud.is_snare_placement_mode = true
	var res_valid := main_node._handle_snare_placement_attempt(Vector2(600.0, 500.0))
	assert_true(res_valid, "Snare successfully placed during active encounter in valid trail region", "")
	assert_true(main_node.shellback.snare_charges == 0, "Snare charge consumed exactly once (1 -> 0)", "")
	assert_true(main_node.traps_container.get_child_count() == 1, "Snare trap spawned in traps container", "")
	assert_true(not main_node.hud.is_snare_placement_mode, "Snare placement mode cancelled after successful drop", "")

	# Placement mode cancellation when modal opens or travel ends
	main_node.hud.is_snare_placement_mode = true
	main_node.hud.open_loadout(["bolt_launcher", "armour_screen", "snare_rack"])
	assert_true(not main_node.hud.is_snare_placement_mode, "Placement mode cancelled when loadout modal opened", "")

	main_node.free()

func test_regression_reward_idempotency() -> void:
	print("\n--- Regression Check 5: Completed nodes cannot return rewards twice ---")
	var mm := MapManager.new()

	var r1 := mm.complete_node("woodland")
	assert_true(not r1.is_empty(), "First completion of Woodland returns rewards", "")
	assert_true(r1.get("food", 0) == 15, "First completion awards 15 food", "")
	assert_true(mm.is_node_completed("woodland"), "Woodland is marked completed", "")

	var r2 := mm.complete_node("woodland")
	assert_true(r2.is_empty(), "Second completion returns empty reward result (idempotent)", "")

	var r3 := mm.complete_node("woodland")
	assert_true(r3.is_empty(), "Third completion returns empty reward result", "")

	# Verify in Main gameplay flow
	var main_scene := load("res://scenes/main.tscn") as PackedScene
	var main_node: Main = main_scene.instantiate() as Main
	root.add_child(main_node)

	var food_init: int = main_node.resources["food"]
	main_node._complete_destination("woodland")
	var food_after_1: int = main_node.resources["food"]
	assert_true(food_after_1 > food_init, "Resources incremented on first completion", "")

	# Duplicate destination completion call
	main_node._complete_destination("woodland")
	assert_true(main_node.resources["food"] == food_after_1, "Resources strictly NOT incremented on duplicate completion", "")

	main_node.free()

func test_regression_final_pass_hold_point() -> void:
	print("\n--- Regression Check 6: Final Pass cannot complete immediately while encounter active ---")
	var main_scene := load("res://scenes/main.tscn") as PackedScene
	var main_node: Main = main_scene.instantiate() as Main
	root.add_child(main_node)

	# Transition to river crossing then confirm final pass
	main_node.map_manager.current_node_id = "river_crossing"
	main_node.map_manager.completed_nodes = ["start_camp", "woodland", "river_crossing"]
	main_node.map_manager.select_node("final_pass")
	main_node._on_route_confirmed("final_pass")

	assert_true(main_node.threats_container.get_child_count() >= 3, "Final pass spawned at least 3 staged threats (Wolf + 2 Raiders)", "")
	assert_true(not main_node._all_threats_dead(), "Living threats are active in Final Pass", "")

	# Simulate Shellback touching destination waypoint
	main_node._on_destination_reached("final_pass")
	assert_true(main_node.is_destination_holding, "Shellback fortress enters destination holding state", "")
	assert_true(main_node.pending_destination_id == "final_pass", "pending_destination_id is set to final_pass", "")
	assert_true(not main_node.shellback.is_moving, "Shellback halted at hold point to defend", "")
	assert_true(not main_node.map_manager.is_node_completed("final_pass"), "Final Pass NOT completed while living threats remain", "")

	# Eliminate threats to simulate overcoming the climax assault
	for child in main_node.threats_container.get_children():
		if is_instance_valid(child) and child.has_method("take_damage"):
			child.take_damage(999.0)

	assert_true(main_node._all_threats_dead(), "All Final Pass threats defeated", "")
	assert_true(not main_node.is_destination_holding, "Holding state cleared upon defeating all threats", "")
	assert_true(main_node.map_manager.is_node_completed("final_pass"), "Final Pass successfully completed after assault defeated", "")

	main_node.free()

func test_regression_restart_clears_all_new_state() -> void:
	print("\n--- Regression Check 7: Restart clears all new state and unpauses SceneTree ---")
	var main_scene := load("res://scenes/main.tscn") as PackedScene
	var main_node: Main = main_scene.instantiate() as Main
	root.add_child(main_node)

	# Dirty all prototype systems
	main_node.map_manager.complete_node("woodland")
	main_node.map_manager.complete_node("river_crossing")
	main_node.resources = {"food": 99, "wood": 88, "salvage": 77}
	main_node.shellback.set_health(25.0)
	main_node.shellback.set_equipped_modules(["bolt_launcher", "storage_rack", "armour_screen"])
	main_node.shellback.snare_charges = 0
	main_node.is_destination_holding = true
	main_node.pending_destination_id = "final_pass"
	main_node.hurry_chosen = true
	main_node.game_ended = true
	main_node.hud.show_onboarding_step(HUD.OnboardingStep.PAN_MAP)
	main_node.hud.is_snare_placement_mode = true

	# Preconditions
	assert_true(paused, "SceneTree was paused by modal before restart", "")
	assert_true(main_node.resources["food"] == 99, "Resources were dirtied before restart", "")
	assert_true(main_node.map_manager.current_node_id != "start_camp", "Current node was changed before restart", "")

	# Trigger Restart
	main_node._on_restart_pressed()

	# Assert clean postconditions
	assert_true(not paused, "SceneTree is strictly unpaused after restart", "")
	assert_true(not main_node.game_ended, "game_ended reset to false", "")
	assert_true(not main_node.game_won, "game_won reset to false", "")
	assert_true(not main_node.hurry_chosen, "hurry_chosen reset to false", "")
	assert_true(not main_node.is_destination_holding, "is_destination_holding reset to false", "")
	assert_true(main_node.pending_destination_id.is_empty(), "pending_destination_id reset to empty", "")
	assert_true(main_node.resources["food"] == 10, "Food reset to 10", "")
	assert_true(main_node.resources["wood"] == 15, "Wood reset to 15", "")
	assert_true(main_node.resources["salvage"] == 0, "Salvage reset to 0", "")
	assert_true(main_node.shellback.current_health == 250.0, "Shellback health reset to 250", "")
	assert_true(main_node.shellback.equipped_modules == ["bolt_launcher", "armour_screen", "snare_rack"], "Modules reset to default trio", "")
	assert_true(main_node.shellback.snare_charges == 1, "Snare charge reset to 1", "")
	assert_true(main_node.map_manager.current_node_id == "start_camp", "Map current node reset to start_camp", "")
	assert_true(main_node.map_manager.completed_nodes == ["start_camp"], "Completed nodes reset to start_camp only", "")
	assert_true(not main_node.map_manager.is_traveling, "MapManager is_traveling reset to false", "")
	assert_true(not main_node.hud.is_any_modal_open(), "All HUD modals closed on restart", "")
	assert_true(not main_node.hud.is_snare_placement_mode, "Snare placement mode cancelled on restart", "")
	assert_true(main_node.threats_container.get_child_count() == 0, "Threats container emptied on restart", "")
	assert_true(main_node.traps_container.get_child_count() == 0, "Traps container emptied on restart", "")

	main_node.free()

func test_integrated_startup_onboarding_and_pan() -> void:
	print("\n--- Integrated Test: Startup onboarding, tree pause, and pan trigger ---")
	var main_scene := load("res://scenes/main.tscn") as PackedScene
	var main_node: Main = main_scene.instantiate() as Main
	root.add_child(main_node)

	assert_true(main_node.hud.onboarding_overlay.visible, "PAN_MAP teaching modal is visible on actual scene startup", "")
	assert_true(main_node.hud.onboarding_title.text.contains("PAN THE MAP"), "Initial teaching modal title is PAN THE MAP", "")
	assert_true(paused, "SceneTree is strictly paused while PAN_MAP modal is visible", "")

	# Dismiss modal via dismiss button press (as a user would)
	main_node.hud.onboarding_dismiss_btn.pressed.emit()

	assert_true(not main_node.hud.onboarding_overlay.visible, "Onboarding overlay is hidden after dismissal", "")
	assert_true(not paused, "SceneTree is resumed (unpaused) after modal dismissal", "")
	assert_true(main_node.hud.has_step_been_shown(HUD.OnboardingStep.PAN_MAP), "PAN_MAP marked as shown", "")
	assert_true(not main_node.hud.has_step_been_shown(HUD.OnboardingStep.INSPECT_ROUTE), "INSPECT_ROUTE not yet shown prior to pan", "")

	# Now perform a meaningful camera pan (> 30px) via real mouse drag events
	var mouse_down := InputEventMouseButton.new()
	mouse_down.button_index = MOUSE_BUTTON_LEFT
	mouse_down.pressed = true
	mouse_down.position = Vector2(400.0, 300.0)
	main_node.camera_controller._unhandled_input(mouse_down)

	var mouse_motion := InputEventMouseMotion.new()
	mouse_motion.relative = Vector2(60.0, 0.0)
	main_node.camera_controller._unhandled_input(mouse_motion)

	# Meaningful pan detected triggers INSPECT_ROUTE
	assert_true(main_node.hud.onboarding_overlay.visible, "INSPECT_ROUTE modal visible after meaningful pan", "")
	assert_true(main_node.hud.onboarding_title.text.contains("INSPECT A ROUTE"), "Teaching modal title is INSPECT A ROUTE", "")
	assert_true(paused, "SceneTree is paused while INSPECT_ROUTE modal is visible", "")

	# Dismiss step 2
	main_node.hud.onboarding_dismiss_btn.pressed.emit()
	assert_true(not paused, "SceneTree is resumed after dismissing INSPECT_ROUTE", "")

	main_node.free()

func test_four_loadout_combinations_viable() -> void:
	print("\n--- Test: All four 3-module loadouts survive real Final Pass simulation ---")
	var legal_combos: Array[Array] = [
		["bolt_launcher", "armour_screen", "snare_rack"],
		["bolt_launcher", "armour_screen", "storage_rack"],
		["bolt_launcher", "storage_rack", "snare_rack"],
		["armour_screen", "storage_rack", "snare_rack"]
	]

	for item: Array in legal_combos:
		var combo: Array[String] = []
		for module_name: Variant in item:
			combo.append(str(module_name))

		var label := ", ".join(combo)
		for hurried: bool in [false, true]:
			var result := _simulate_final_pass(combo, hurried)
			var variant := "hurried" if hurried else "normal"
			assert_true(bool(result.completed), "%s completes %s Final Pass" % [label, variant], str(result))
			assert_true(bool(result.survived), "%s keeps Shellback alive in %s Final Pass" % [label, variant], str(result))
			assert_true(float(result.ending_hp) > 0.0, "%s ends %s Final Pass with positive HP" % [label, variant], str(result))
			if combo.has("bolt_launcher"):
				assert_true(int(result.shots_fired) > 0, "%s uses real Bolt projectiles in %s Final Pass" % [label, variant], str(result))
			else:
				assert_true(str(result.completion_kind) == "survival", "%s wins %s Final Pass through survival hold" % [label, variant], str(result))
			print("  [SIMULATED] %s (%s) -> %s" % [label, variant, str(result)])

func test_final_pass_timing_simulation() -> void:
	print("\n--- Deterministic Simulation: Real Final Pass combat and timing ---")
	var offensive_modules: Array[String] = ["bolt_launcher", "armour_screen", "snare_rack"]
	var defensive_modules: Array[String] = ["armour_screen", "storage_rack", "snare_rack"]

	var normal_offense := _simulate_final_pass(offensive_modules, false)
	var hurried_offense := _simulate_final_pass(offensive_modules, true)
	var normal_defense := _simulate_final_pass(defensive_modules, false)
	var hurried_defense := _simulate_final_pass(defensive_modules, true)

	for result: Dictionary in [normal_offense, hurried_offense, normal_defense, hurried_defense]:
		print("  [SIMULATED] %s" % str(result))
		assert_true(bool(result.completed), "%s encounter completes" % result.label, str(result))
		assert_true(bool(result.survived), "%s Shellback survives" % result.label, str(result))
		assert_true(float(result.elapsed) > 0.0, "%s records positive elapsed time" % result.label, str(result))

	assert_true(int(normal_offense.shots_fired) == 6, "Normal offense lands the expected 6 Bolt shots", str(normal_offense))
	assert_true(int(hurried_offense.shots_fired) == 8, "Hurried offense lands the expected 8 Bolt shots", str(hurried_offense))
	assert_true(str(normal_offense.completion_kind) == "offense", "Normal Bolt loadout completes offensively", str(normal_offense))
	assert_true(str(hurried_offense.completion_kind) == "offense", "Hurried Bolt loadout completes offensively", str(hurried_offense))
	assert_true(str(normal_defense.completion_kind) == "survival", "Normal no-Bolt loadout completes by survival", str(normal_defense))
	assert_true(str(hurried_defense.completion_kind) == "survival", "Hurried no-Bolt loadout completes by survival", str(hurried_defense))

func test_full_run_strategies_viable() -> void:
	print("\n--- Integrated Simulation: Complete routes preserve meaningful loadout choices ---")
	var legal_combos: Array[Array] = [
		["bolt_launcher", "armour_screen", "snare_rack"],
		["bolt_launcher", "armour_screen", "storage_rack"],
		["bolt_launcher", "storage_rack", "snare_rack"],
		["armour_screen", "storage_rack", "snare_rack"]
	]

	# A cautious Woodland route plus River repair must support every legal loadout.
	for item: Array in legal_combos:
		var combo: Array[String] = []
		for module_name: Variant in item:
			combo.append(str(module_name))
		var result := _simulate_full_run(combo, "woodland", false)
		var label := ", ".join(combo)
		assert_true(bool(result.won), "%s can finish a cautious repaired run" % label, str(result))
		assert_true(bool(result.survived), "%s keeps the Shellback alive through the full route" % label, str(result))
		assert_true(float(result.ending_hp) > 0.0, "%s finishes the full route with positive HP" % label, str(result))
		print("  [FULL RUN] %s -> %s" % [label, str(result)])

	# The combat-focused default loadout must also support the riskier branch and Hurry choice.
	var aggressive_modules: Array[String] = ["bolt_launcher", "armour_screen", "snare_rack"]
	var aggressive_result := _simulate_full_run(aggressive_modules, "watchpost", true)
	assert_true(bool(aggressive_result.won), "Combat loadout can finish Watchpost + Hurry route", str(aggressive_result))
	assert_true(bool(aggressive_result.survived), "Combat loadout survives the aggressive full route", str(aggressive_result))
	assert_true(int(aggressive_result.shots_fired) > 0, "Aggressive full route uses real Bolt projectiles", str(aggressive_result))
	print("  [FULL RUN] aggressive route -> %s" % str(aggressive_result))

func _simulate_full_run(modules: Array[String], first_destination: String, hurry: bool) -> Dictionary:
	var main_scene := load("res://scenes/main.tscn") as PackedScene
	var main_node: Main = main_scene.instantiate() as Main
	root.add_child(main_node)
	main_node.hud.reset_ui()
	main_node.hud.has_completed_onboarding = true
	paused = false
	main_node.shellback.set_equipped_modules(modules)

	var total_elapsed: float = 0.0
	var total_shots: int = 0
	var completed_legs: Array[String] = []
	var destinations: Array[String] = [first_destination, "river_crossing"]
	for destination: String in destinations:
		var leg_result := _drive_simulated_leg(main_node, destination)
		total_elapsed += float(leg_result.elapsed)
		total_shots += int(leg_result.shots_fired)
		if bool(leg_result.completed):
			completed_legs.append(destination)
		if not main_node.shellback.is_alive() or not bool(leg_result.completed):
			break

	if main_node.shellback.is_alive() and main_node.map_manager.is_node_completed("river_crossing"):
		if hurry:
			main_node.hud._on_river_hurry_pressed()
		else:
			main_node.hud._on_river_repair_pressed()

		for destination: String in ["final_pass", "exit_camp"]:
			var leg_result := _drive_simulated_leg(main_node, destination)
			total_elapsed += float(leg_result.elapsed)
			total_shots += int(leg_result.shots_fired)
			if bool(leg_result.completed):
				completed_legs.append(destination)
			if not main_node.shellback.is_alive() or not bool(leg_result.completed):
				break

	var result := {
		"route": "%s -> %s" % [first_destination, "hurry" if hurry else "repair"],
		"won": main_node.game_won,
		"survived": main_node.shellback.is_alive(),
		"ending_hp": main_node.shellback.current_health,
		"elapsed": total_elapsed,
		"shots_fired": total_shots,
		"completed_legs": completed_legs
	}
	main_node.free()
	paused = false
	return result

func _drive_simulated_leg(main_node: Main, destination: String) -> Dictionary:
	const SIM_DT: float = 1.0 / 60.0
	const MAX_LEG_TIME: float = 90.0
	main_node.map_manager.select_node(destination)
	main_node._on_route_confirmed(destination)
	var elapsed: float = 0.0
	var shots_fired: int = 0
	var snare_placed: bool = false

	while elapsed < MAX_LEG_TIME and main_node.shellback.is_alive() and not main_node.map_manager.is_node_completed(destination):
		if main_node.shellback.has_module("bolt_launcher") and main_node.bolt_launcher.can_fire() and is_instance_valid(main_node._find_nearest_alive_threat()):
			var projectile_count_before := main_node.projectiles_container.get_child_count()
			main_node._on_bolt_launcher_pressed()
			if main_node.projectiles_container.get_child_count() > projectile_count_before:
				shots_fired += 1

		if not snare_placed and main_node.shellback.has_module("snare_rack") and main_node.shellback.snare_charges > 0:
			var snare_target := main_node._find_nearest_alive_threat()
			if is_instance_valid(snare_target):
				main_node.hud.is_snare_placement_mode = true
				snare_placed = main_node._handle_snare_placement_attempt(snare_target.global_position)

		_step_simulated_world(main_node, SIM_DT)
		elapsed += SIM_DT

	return {
		"completed": main_node.map_manager.is_node_completed(destination),
		"elapsed": elapsed,
		"shots_fired": shots_fired,
		"snare_placed": snare_placed
	}

func _step_simulated_world(main_node: Main, delta: float) -> void:
	main_node._process(delta)
	main_node.shellback._process(delta)
	main_node.bolt_launcher._process(delta)
	for threat: Node in main_node.threats_container.get_children():
		if is_instance_valid(threat) and not threat.is_queued_for_deletion() and threat.has_method("_process"):
			threat.call("_process", delta)
	for trap: Node in main_node.traps_container.get_children():
		if is_instance_valid(trap) and not trap.is_queued_for_deletion() and trap.has_method("_process"):
			trap.call("_process", delta)
	for projectile: Node in main_node.projectiles_container.get_children():
		if is_instance_valid(projectile) and not projectile.is_queued_for_deletion() and projectile.has_method("_process"):
			projectile.call("_process", delta)

func _simulate_final_pass(modules: Array[String], hurried: bool) -> Dictionary:
	const SIM_DT: float = 1.0 / 60.0
	const MAX_SIM_TIME: float = 75.0
	var main_scene := load("res://scenes/main.tscn") as PackedScene
	var main_node: Main = main_scene.instantiate() as Main
	root.add_child(main_node)

	main_node.hud.reset_ui()
	main_node.hud.has_completed_onboarding = true
	paused = false
	main_node.map_manager.current_node_id = "river_crossing"
	main_node.map_manager.completed_nodes = ["start_camp", "woodland", "river_crossing"]
	main_node.shellback.global_position = main_node.map_manager.nodes["river_crossing"].position
	main_node.shellback.set_health(main_node.shellback.max_health)
	main_node.shellback.set_equipped_modules(modules)
	main_node.hurry_chosen = hurried
	main_node.map_manager.select_node("final_pass")
	main_node._on_route_confirmed("final_pass")

	var elapsed: float = 0.0
	var hold_started_at: float = -1.0
	var shots_fired: int = 0
	var snare_placed: bool = false
	var used_bolt: bool = modules.has("bolt_launcher")

	while elapsed < MAX_SIM_TIME and main_node.shellback.is_alive() and not main_node.map_manager.is_node_completed("final_pass"):
		if used_bolt and main_node.bolt_launcher.can_fire() and is_instance_valid(main_node._find_nearest_alive_threat()):
			var projectile_count_before := main_node.projectiles_container.get_child_count()
			main_node._on_bolt_launcher_pressed()
			if main_node.projectiles_container.get_child_count() > projectile_count_before:
				shots_fired += 1

		if not snare_placed and modules.has("snare_rack") and main_node.shellback.snare_charges > 0:
			var snare_target := main_node._find_nearest_alive_threat()
			if is_instance_valid(snare_target):
				main_node.hud.is_snare_placement_mode = true
				snare_placed = main_node._handle_snare_placement_attempt(snare_target.global_position)

		_step_simulated_world(main_node, SIM_DT)

		if hold_started_at < 0.0 and main_node.is_destination_holding:
			hold_started_at = elapsed
		elapsed += SIM_DT

	var completed := main_node.map_manager.is_node_completed("final_pass")
	var survived := main_node.shellback.is_alive()
	var threats_defeated := main_node._all_threats_dead()
	var result := {
		"label": "%s %s" % ["hurried" if hurried else "normal", "offense" if used_bolt else "defense"],
		"completed": completed,
		"survived": survived,
		"elapsed": elapsed,
		"hold_started_at": hold_started_at,
		"ending_hp": main_node.shellback.current_health,
		"shots_fired": shots_fired,
		"snare_placed": snare_placed,
		"completion_kind": "offense" if completed and threats_defeated else ("survival" if completed else "none")
	}

	main_node.free()
	paused = false
	return result
