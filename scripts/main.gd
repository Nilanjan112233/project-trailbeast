extends Node2D
class_name Main

# Main gameplay coordinator for the Moving Fortress Prototype.
# Manages the 2560x1440 map, route graph navigation, Shellback caravan fortress,
# modular loadouts, encounters, river decision, camera, and victory/defeat states.

const PLAYABLE_MIN_X: float = 200.0
const PLAYABLE_MAX_X: float = 2300.0
const PLAYABLE_MIN_Y: float = 260.0
const PLAYABLE_MAX_Y: float = 1180.0

@export var snare_scene: PackedScene = preload("res://scenes/snare.tscn")
@export var bolt_launcher_scene: PackedScene = preload("res://scenes/bolt_launcher.tscn")
@export var wolf_scene: PackedScene = preload("res://scenes/wolf.tscn")
@export var raider_scene: PackedScene = preload("res://scenes/raider.tscn")

var map_manager: MapManager = null
var game_ended: bool = false
var game_won: bool = false
var hurry_chosen: bool = false
var max_frames_to_run: int = -1
var elapsed_frames: int = 0

const HOLD_DURATIONS: Dictionary = {
	"woodland": 10.0,
	"watchpost": 12.0,
	"final_pass": 20.0
}

# Hold point assault state
var is_destination_holding: bool = false
var pending_destination_id: String = ""
var hold_timer: float = 0.0
var max_hold_duration: float = 0.0

var resources: Dictionary = {
	"food": 10,
	"wood": 15,
	"salvage": 0
}

@onready var camera_controller: CameraController = $CameraController
@onready var map_visual: MapVisual = $MapVisual
@onready var shellback: Shellback = $Shellback
@onready var traps_container: Node2D = $TrapsContainer
@onready var projectiles_container: Node2D = $ProjectilesContainer
@onready var threats_container: Node2D = $ThreatsContainer
@onready var hud: HUD = $HUD

var bolt_launcher: BoltLauncher = null

func _ready() -> void:
	var all_args: PackedStringArray = OS.get_cmdline_args()
	all_args.append_array(OS.get_cmdline_user_args())
	for arg in all_args:
		if arg.begins_with("--quit-after="):
			max_frames_to_run = int(arg.trim_prefix("--quit-after="))

	map_manager = MapManager.new()
	if is_instance_valid(map_visual):
		map_visual.map_manager = map_manager
	if is_instance_valid(camera_controller) and is_instance_valid(hud):
		camera_controller.hud_ref = hud

	_setup_bolt_launcher()
	_connect_signals()
	_reset_game_state()

	# Ensure startup finishes resetting first, then open PAN_MAP as visible initial teaching modal
	_startup_onboarding()

func _startup_onboarding() -> void:
	if is_instance_valid(hud) and not hud.has_completed_onboarding:
		hud.trigger_onboarding_step(HUD.OnboardingStep.PAN_MAP)

func _setup_bolt_launcher() -> void:
	if is_instance_valid(bolt_launcher):
		return
	if bolt_launcher_scene and is_instance_valid(shellback) and is_instance_valid(shellback.launcher_mount):
		bolt_launcher = bolt_launcher_scene.instantiate() as BoltLauncher
		shellback.launcher_mount.add_child(bolt_launcher)
		bolt_launcher.position = Vector2.ZERO

func _connect_signals() -> void:
	if is_instance_valid(camera_controller):
		if not camera_controller.map_tapped.is_connected(_on_map_tapped):
			camera_controller.map_tapped.connect(_on_map_tapped)
		if not camera_controller.meaningful_pan_detected.is_connected(_on_meaningful_pan_detected):
			camera_controller.meaningful_pan_detected.connect(_on_meaningful_pan_detected)

	if is_instance_valid(shellback):
		if not shellback.health_changed.is_connected(_on_shellback_health_changed):
			shellback.health_changed.connect(_on_shellback_health_changed)
		if not shellback.state_changed.is_connected(_on_shellback_state_changed):
			shellback.state_changed.connect(_on_shellback_state_changed)
		if not shellback.movement_toggled.is_connected(_on_shellback_movement_toggled):
			shellback.movement_toggled.connect(_on_shellback_movement_toggled)
		if not shellback.destination_reached.is_connected(_on_destination_reached):
			shellback.destination_reached.connect(_on_destination_reached)
		if not shellback.died.is_connected(_on_shellback_died):
			shellback.died.connect(_on_shellback_died)

	if is_instance_valid(hud):
		if not hud.toggle_movement_pressed.is_connected(_on_toggle_movement):
			hud.toggle_movement_pressed.connect(_on_toggle_movement)
		if not hud.bolt_launcher_pressed.is_connected(_on_bolt_launcher_pressed):
			hud.bolt_launcher_pressed.connect(_on_bolt_launcher_pressed)
		if not hud.snare_selected.is_connected(_on_snare_selected):
			hud.snare_selected.connect(_on_snare_selected)
		if not hud.recenter_pressed.is_connected(_on_recenter_pressed):
			hud.recenter_pressed.connect(_on_recenter_pressed)
		if not hud.open_loadout_pressed.is_connected(_on_open_loadout):
			hud.open_loadout_pressed.connect(_on_open_loadout)
		if not hud.loadout_confirmed.is_connected(_on_loadout_confirmed):
			hud.loadout_confirmed.connect(_on_loadout_confirmed)
		if not hud.route_travel_confirmed.is_connected(_on_route_confirmed):
			hud.route_travel_confirmed.connect(_on_route_confirmed)
		if not hud.river_decision_chosen.is_connected(_on_river_decision_chosen):
			hud.river_decision_chosen.connect(_on_river_decision_chosen)
		if not hud.restart_pressed.is_connected(_on_restart_pressed):
			hud.restart_pressed.connect(_on_restart_pressed)

func _process(delta: float) -> void:
	if max_frames_to_run > 0:
		elapsed_frames += 1
		if elapsed_frames >= max_frames_to_run:
			print("INTEGRATED SCENE RUN COMPLETED: %d frames executed successfully." % elapsed_frames)
			get_tree().quit(0)
			return

	if game_ended:
		return

	# Handle hold timer during destination assault hold
	if is_destination_holding:
		hold_timer = max(0.0, hold_timer - delta)
		if is_instance_valid(hud):
			hud.show_hold_countdown(hold_timer, max_hold_duration)
		if hold_timer <= 0.0:
			_complete_destination(pending_destination_id, "Defense held! Attackers broke off assault and withdrew into the wilderness.")
			return

func _on_meaningful_pan_detected() -> void:
	if is_instance_valid(hud):
		if hud.get_next_unshown_step() == HUD.OnboardingStep.INSPECT_ROUTE:
			hud.trigger_onboarding_step(HUD.OnboardingStep.INSPECT_ROUTE)

func is_playable_trail_position(pos: Vector2) -> bool:
	return (pos.x >= PLAYABLE_MIN_X and pos.x <= PLAYABLE_MAX_X and
			pos.y >= PLAYABLE_MIN_Y and pos.y <= PLAYABLE_MAX_Y)

func is_travel_in_progress() -> bool:
	return (map_manager != null and map_manager.is_traveling) or is_destination_holding

func is_travel_encounter_active() -> bool:
	if game_ended or not map_manager:
		return false
	if map_manager.is_current_node_camp() and not is_travel_in_progress():
		return false
	return is_travel_in_progress()

func _on_map_tapped(world_pos: Vector2) -> void:
	if game_ended or (is_instance_valid(hud) and hud.is_any_modal_open()):
		return

	# If in snare placement mode, validate and handle placement attempt
	if is_instance_valid(hud) and hud.is_snare_placement_mode:
		_handle_snare_placement_attempt(world_pos)
		return

	# Check if tap was on a map node (within 65 px radius)
	if not map_manager:
		return

	var tapped_node_id: String = ""
	for n_id in map_manager.nodes.keys():
		var n_pos: Vector2 = map_manager.nodes[n_id].position
		if world_pos.distance_to(n_pos) <= 65.0:
			tapped_node_id = n_id
			break

	if not tapped_node_id.is_empty():
		var is_traveling := is_travel_in_progress()
		# Route locking: cannot travel if another travel is already active
		var can_travel := (not is_traveling) and map_manager.can_travel_to(tapped_node_id)
		var is_comp := map_manager.is_node_completed(tapped_node_id)
		if not is_traveling:
			map_manager.select_node(tapped_node_id)
		var n_data: Dictionary = map_manager.get_node(tapped_node_id)
		if is_instance_valid(hud):
			hud.show_route_inspector(n_data, can_travel, is_comp, is_traveling)

func _handle_snare_placement_attempt(pos: Vector2) -> bool:
	if not is_instance_valid(hud):
		return false

	# Reject if modal open or game ended
	if game_ended or hud.is_any_modal_open():
		return false

	# Reject if at camp or not in active travel encounter
	if not is_travel_encounter_active():
		print("Snare rejected: Can only be placed during an active travel encounter.")
		return false

	# Reject if outside playable wilderness trail region
	if not is_playable_trail_position(pos):
		print("Snare rejected: Tapped position is outside the playable wilderness trail.")
		return false

	# Reject if snare rack not equipped or no charges
	if not is_instance_valid(shellback) or not shellback.has_module("snare_rack") or shellback.snare_charges <= 0:
		print("Snare rejected: No snare charges available.")
		return false

	# Valid placement! Consume exactly 1 charge and spawn snare
	shellback.snare_charges -= 1
	var snare: Trap = snare_scene.instantiate() as Trap
	snare.global_position = pos
	traps_container.add_child(snare)

	hud.cancel_snare_placement_mode()
	hud.update_module_controls(shellback.equipped_modules, shellback.snare_charges)
	return true

func _on_route_confirmed(dest_node_id: String) -> void:
	if game_ended or not is_instance_valid(shellback):
		return
	# Strict validation in Main: reject route redirection mid-travel
	if is_travel_in_progress():
		print("Route rejected: travel is currently in progress.")
		return
	if not map_manager or not map_manager.can_travel_to(dest_node_id):
		print("Route rejected: destination is not currently valid for travel.")
		return

	var waypoints: Array[Vector2] = map_manager.confirm_route()
	shellback.start_travel(waypoints, dest_node_id)

	# Spawn travel encounter threats along this leg
	_spawn_encounter_for_destination(dest_node_id)

	if is_instance_valid(hud):
		hud.cancel_snare_placement_mode()
		hud.set_camp_status(false, true)
		hud.update_module_controls(shellback.equipped_modules, shellback.snare_charges)

func _spawn_encounter_for_destination(dest_id: String) -> void:
	_clear_threats()
	match dest_id:
		"woodland":
			# Lone wolf encounter
			_spawn_wolf(Vector2(680.0, 480.0))
		"watchpost":
			# Raider ambush
			_spawn_raider(Vector2(660.0, 940.0))
			_spawn_raider(Vector2(760.0, 1020.0))
		"final_pass":
			# Staged canyon assault: Wolf + Raiders funneling through chokepoint
			_spawn_wolf(Vector2(1650.0, 710.0))
			_spawn_raider(Vector2(1750.0, 730.0))
			_spawn_raider(Vector2(1880.0, 720.0))
			if hurry_chosen:
				_spawn_raider(Vector2(1920.0, 690.0))

func _spawn_wolf(pos: Vector2) -> Wolf:
	if not wolf_scene or not is_instance_valid(threats_container):
		return null
	var wolf: Wolf = wolf_scene.instantiate() as Wolf
	wolf.global_position = pos
	wolf.target_shellback = shellback
	if not wolf.died.is_connected(_on_threat_died):
		wolf.died.connect(_on_threat_died)
	threats_container.add_child(wolf)
	return wolf

func _spawn_raider(pos: Vector2) -> Raider:
	if not raider_scene or not is_instance_valid(threats_container):
		return null
	var raider: Raider = raider_scene.instantiate() as Raider
	raider.global_position = pos
	raider.target_shellback = shellback
	if not raider.died.is_connected(_on_threat_died):
		raider.died.connect(_on_threat_died)
	threats_container.add_child(raider)
	return raider

func _clear_threats() -> void:
	if is_instance_valid(threats_container):
		for child in threats_container.get_children():
			child.queue_free()

func _all_threats_dead() -> bool:
	if not is_instance_valid(threats_container):
		return true
	for child in threats_container.get_children():
		if is_instance_valid(child) and child is Node2D:
			if child.has_method("is_alive") and child.is_alive():
				return false
	return true

func _on_threat_died() -> void:
	# If fortress is holding at destination perimeter, check if all threats are defeated early
	if is_destination_holding and _all_threats_dead():
		_complete_destination(pending_destination_id, "Assault broken! All threats defeated.")

func _on_destination_reached(dest_id: String) -> void:
	if game_ended or not map_manager:
		return

	# If active living attackers remain, fortress holds perimeter/barricade to fight or survive
	if not _all_threats_dead():
		is_destination_holding = true
		pending_destination_id = dest_id
		var base_dur: float = HOLD_DURATIONS.get(dest_id, 15.0)
		max_hold_duration = base_dur
		hold_timer = base_dur
		if is_instance_valid(shellback):
			shellback.set_moving(false)
		if is_instance_valid(hud):
			hud.update_shellback_state(int(shellback.state), false)
			hud.show_hold_countdown(hold_timer, max_hold_duration)
		return

	_complete_destination(dest_id, "All attackers defeated!")

func _complete_destination(dest_id: String, completion_reason: String = "") -> void:
	is_destination_holding = false
	pending_destination_id = ""
	hold_timer = 0.0
	max_hold_duration = 0.0

	# Explain withdrawal / victory if enemies were still alive when timer expired
	if not _all_threats_dead():
		print("Encounter completed: %s" % completion_reason)
		if is_instance_valid(hud):
			hud.notify_attackers_withdrew(completion_reason)
	else:
		if is_instance_valid(hud):
			hud.clear_hold_display()

	# Mark node completed and collect rewards (idempotency enforced by MapManager)
	var base_rewards: Dictionary = map_manager.complete_node(dest_id)
	if not base_rewards.is_empty():
		var has_storage: bool = shellback.has_module("storage_rack") if is_instance_valid(shellback) else false
		var loot_mult: float = 1.5 if has_storage else 1.0

		var food_gain: int = int(round(float(base_rewards.get("food", 0)) * loot_mult))
		var wood_gain: int = int(round(float(base_rewards.get("wood", 0)) * loot_mult))
		var salvage_gain: int = int(round(float(base_rewards.get("salvage", 0)) * loot_mult))

		resources["food"] += food_gain
		resources["wood"] += wood_gain
		resources["salvage"] += salvage_gain

	if is_instance_valid(hud):
		hud.cancel_snare_placement_mode()
		hud.update_resources(resources["food"], resources["wood"], resources["salvage"])
		hud.set_camp_status(map_manager.is_current_node_camp(), false)

	_clear_threats()

	# Check Special Node Events
	if dest_id == "river_crossing":
		if is_instance_valid(hud):
			hud.show_river_decision(resources["wood"])
	elif dest_id == "exit_camp":
		_end_game(true)

func _on_river_decision_chosen(is_repair: bool) -> void:
	if is_repair:
		hurry_chosen = false
		if resources["wood"] >= 10 and is_instance_valid(shellback):
			resources["wood"] -= 10
			shellback.heal(60.0)
			if is_instance_valid(hud):
				hud.update_resources(resources["food"], resources["wood"], resources["salvage"])
	else:
		hurry_chosen = true

func _on_bolt_launcher_pressed() -> void:
	if game_ended or not is_instance_valid(bolt_launcher) or not bolt_launcher.can_fire():
		return

	var target := _find_nearest_alive_threat()
	if not is_instance_valid(target):
		return

	bolt_launcher.fire(projectiles_container, target)
	if is_instance_valid(hud):
		hud.trigger_bolt_cooldown(bolt_launcher.cooldown_time)

func _on_snare_selected() -> void:
	pass

func _find_nearest_alive_threat() -> Node2D:
	if not is_instance_valid(threats_container) or not is_instance_valid(shellback):
		return null
	var best_target: Node2D = null
	var min_dist: float = 999999.0
	for child in threats_container.get_children():
		if is_instance_valid(child) and child is Node2D:
			if child.has_method("is_alive") and not child.is_alive():
				continue
			var d := shellback.global_position.distance_to(child.global_position)
			if d < min_dist:
				min_dist = d
				best_target = child
	return best_target

func _on_toggle_movement() -> void:
	if is_instance_valid(shellback):
		shellback.toggle_movement()

func _on_recenter_pressed() -> void:
	if is_instance_valid(camera_controller) and is_instance_valid(shellback):
		camera_controller.recenter(shellback.global_position)

func _on_open_loadout() -> void:
	if is_instance_valid(hud) and is_instance_valid(shellback):
		hud.open_loadout(shellback.equipped_modules)

func _on_loadout_confirmed(modules: Array[String]) -> void:
	if is_instance_valid(shellback):
		shellback.set_equipped_modules(modules)
		if is_instance_valid(hud):
			hud.update_module_controls(shellback.equipped_modules, shellback.snare_charges)

func _on_shellback_health_changed(cur: float, max_val: float) -> void:
	if is_instance_valid(hud):
		hud.update_health(cur, max_val)

func _on_shellback_state_changed(new_state: Shellback.State) -> void:
	if is_instance_valid(hud) and is_instance_valid(shellback):
		hud.update_shellback_state(int(new_state), shellback.is_moving)

func _on_shellback_movement_toggled(is_moving: bool) -> void:
	if is_instance_valid(hud) and is_instance_valid(shellback):
		hud.update_shellback_state(int(shellback.state), is_moving)

func _on_shellback_died() -> void:
	if not game_ended:
		_end_game(false, "Shellback fortress collapsed under enemy assault.")

func _end_game(won: bool, reason: String = "") -> void:
	if game_ended:
		return
	game_ended = true
	game_won = won
	if is_instance_valid(hud):
		if won:
			var path_names: Array[String] = []
			for n_id in map_manager.route_history:
				path_names.append(map_manager.nodes[n_id]["name"])
			hud.show_victory(path_names, shellback.current_health, shellback.max_health, resources["food"], resources["wood"], resources["salvage"], shellback.equipped_modules)
		else:
			hud.show_defeat(reason)

func _on_restart_pressed() -> void:
	_reset_game_state()
	_startup_onboarding.call_deferred()

func _reset_game_state() -> void:
	# Ensure tree is never left paused on restart
	if get_tree():
		get_tree().paused = false

	game_ended = false
	game_won = false
	hurry_chosen = false
	is_destination_holding = false
	pending_destination_id = ""
	hold_timer = 0.0
	max_hold_duration = 0.0
	resources = {"food": 10, "wood": 15, "salvage": 0}

	# Clean containers
	if is_instance_valid(traps_container):
		for child in traps_container.get_children():
			child.queue_free()
	if is_instance_valid(projectiles_container):
		for child in projectiles_container.get_children():
			child.queue_free()
	_clear_threats()

	# Reset Map
	if map_manager:
		map_manager.reset()

	# Reset Shellback to Start Camp
	if is_instance_valid(shellback) and map_manager:
		var start_pos: Vector2 = map_manager.nodes["start_camp"].position
		shellback.reset(start_pos)
		shellback.set_equipped_modules(["bolt_launcher", "armour_screen", "snare_rack"])

	# Recenter camera & reset pan tracking
	if is_instance_valid(camera_controller) and is_instance_valid(shellback):
		camera_controller.recenter(shellback.global_position)
		camera_controller.reset_pan_tracking()

	# Reset Bolt Launcher
	if is_instance_valid(bolt_launcher):
		bolt_launcher.reset()

	# Reset HUD
	if is_instance_valid(hud):
		hud.reset_ui()
		hud.reset_onboarding()
		hud.update_resources(resources["food"], resources["wood"], resources["salvage"])
		if is_instance_valid(shellback):
			hud.update_health(shellback.current_health, shellback.max_health)
			hud.update_shellback_state(int(shellback.state), shellback.is_moving)
			hud.update_module_controls(shellback.equipped_modules, shellback.snare_charges)
			hud.set_camp_status(true, false)
