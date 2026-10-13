extends CanvasLayer
class_name HUD

# User interface for Moving Fortress prototype.
# Touch-friendly controls (>= 52px height), route inspector, loadout configuration,
# river crossing decision, contextual onboarding with SceneTree pause safety, and victory/defeat screens.

signal toggle_movement_pressed
signal bolt_launcher_pressed
signal snare_selected
signal restart_pressed
signal recenter_pressed
signal open_loadout_pressed
signal loadout_confirmed(modules: Array[String])
signal route_travel_confirmed(node_id: String)
signal river_decision_chosen(is_repair: bool)

# Contextual Onboarding steps
enum OnboardingStep {
	PAN_MAP = 0,
	INSPECT_ROUTE = 1,
	CHOOSE_MODULES = 2,
	CONFIRM_TRAVEL = 3,
	TRAVEL_COMBAT = 4,
	COMPLETED = 5
}

const ONBOARDING_TEXTS: Dictionary = {
	OnboardingStep.PAN_MAP: {
		"title": "1. PAN THE MAP",
		"body": "Drag anywhere across the wilderness to scout ahead along the trail.\nTap RE-CENTER anytime to focus back on the Shellback."
	},
	OnboardingStep.INSPECT_ROUTE: {
		"title": "2. INSPECT A ROUTE",
		"body": "Tap a connected destination node (Woodland Vale or Ruined Watchpost) to inspect its resource rewards, threat level, and terrain."
	},
	OnboardingStep.CHOOSE_MODULES: {
		"title": "3. CONFIGURE LOADOUT",
		"body": "The Shellback can equip exactly 3 modules from 4 choices at camp. Tap LOADOUT to adjust your weapons, armour, or racks."
	},
	OnboardingStep.CONFIRM_TRAVEL: {
		"title": "4. CONFIRM TRAVEL",
		"body": "When satisfied with your chosen route, tap CONFIRM TRAVEL on the route card to move the moving fortress."
	},
	OnboardingStep.TRAVEL_COMBAT: {
		"title": "5. TRAVEL & DEFEND",
		"body": "The fortress moves along the trail. Tap HALT to stop and defend, fire the Bolt Launcher, or drop Snares to trap attackers!"
	}
}

var has_completed_onboarding: bool = false
var shown_onboarding_steps: Dictionary = {}
var current_onboarding_step: OnboardingStep = OnboardingStep.PAN_MAP

# Pending actions deferred by onboarding
var pending_loadout_open_after_onboarding: bool = false
var pending_travel_node_after_onboarding: String = ""

# Resources
var food_count: int = 10
var wood_count: int = 15
var salvage_count: int = 0

# Cooldowns and states
var bolt_cd: float = 0.0
var max_bolt_cd: float = 4.0
var inspected_node_id: String = ""

# Loadout selection buffer
var selected_loadout: Array[String] = ["bolt_launcher", "armour_screen", "snare_rack"]

# Node references
@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
@onready var state_badge: Label = %StateBadge
@onready var resource_label: Label = %ResourceLabel
@onready var recenter_button: Button = %RecenterButton
@onready var loadout_button: Button = %LoadoutButton
@onready var restart_button: Button = %RestartButton

# Bottom bar
@onready var bottom_bar: PanelContainer = $BottomBar
@onready var halt_button: Button = %HaltButton
@onready var bolt_container: VBoxContainer = %BoltContainer
@onready var bolt_button: Button = %BoltButton
@onready var bolt_cd_bar: ProgressBar = %BoltCDBar
@onready var snare_container: VBoxContainer = %SnareContainer
@onready var snare_button: Button = %SnareButton

# Route Inspector Modal
@onready var route_inspector_panel: PanelContainer = %RouteInspectorPanel
@onready var route_title_label: Label = %RouteTitleLabel
@onready var route_threat_label: Label = %RouteThreatLabel
@onready var route_reward_label: Label = %RouteRewardLabel
@onready var route_terrain_label: Label = %RouteTerrainLabel
@onready var route_status_label: Label = %RouteStatusLabel
@onready var route_confirm_button: Button = %RouteConfirmButton
@onready var route_close_button: Button = %RouteCloseButton

# Loadout Modal
@onready var loadout_panel: PanelContainer = %LoadoutPanel
@onready var mod_bolt_btn: Button = %ModBoltBtn
@onready var mod_armour_btn: Button = %ModArmourBtn
@onready var mod_storage_btn: Button = %ModStorageBtn
@onready var mod_snare_btn: Button = %ModSnareBtn
@onready var loadout_status_label: Label = %LoadoutStatusLabel
@onready var loadout_confirm_btn: Button = %LoadoutConfirmBtn
@onready var loadout_close_btn: Button = %LoadoutCloseBtn

# River Decision Modal
@onready var river_decision_panel: PanelContainer = %RiverDecisionPanel
@onready var river_repair_btn: Button = %RiverRepairBtn
@onready var river_hurry_btn: Button = %RiverHurryBtn

# Onboarding Modal
@onready var onboarding_overlay: Control = %OnboardingOverlay
@onready var onboarding_title: Label = %OnboardingTitle
@onready var onboarding_body: Label = %OnboardingBody
@onready var onboarding_dismiss_btn: Button = %OnboardingDismissBtn

# Victory / Defeat Modal
@onready var game_over_panel: PanelContainer = %GameOverPanel
@onready var game_over_title: Label = %GameOverTitle
@onready var game_over_subtitle: Label = %GameOverSubtitle
@onready var victory_stats_label: Label = %VictoryStatsLabel
@onready var game_over_restart_btn: Button = %GameOverRestartButton

var is_game_over: bool = false
var is_snare_placement_mode: bool = false

func _ready() -> void:
	_connect_ui_signals()
	update_resources(food_count, wood_count, salvage_count)
	_sync_loadout_buttons()

func _connect_ui_signals() -> void:
	if halt_button and not halt_button.pressed.is_connected(_on_halt_pressed):
		halt_button.pressed.connect(_on_halt_pressed)
	if bolt_button and not bolt_button.pressed.is_connected(_on_bolt_pressed):
		bolt_button.pressed.connect(_on_bolt_pressed)
	if snare_button and not snare_button.pressed.is_connected(_on_snare_pressed):
		snare_button.pressed.connect(_on_snare_pressed)
	if recenter_button and not recenter_button.pressed.is_connected(_on_recenter_pressed):
		recenter_button.pressed.connect(_on_recenter_pressed)
	if loadout_button and not loadout_button.pressed.is_connected(_on_loadout_pressed):
		loadout_button.pressed.connect(_on_loadout_pressed)
	if restart_button and not restart_button.pressed.is_connected(_on_restart_pressed):
		restart_button.pressed.connect(_on_restart_pressed)
	if game_over_restart_btn and not game_over_restart_btn.pressed.is_connected(_on_restart_pressed):
		game_over_restart_btn.pressed.connect(_on_restart_pressed)

	# Route inspector
	if route_confirm_button and not route_confirm_button.pressed.is_connected(_on_route_confirm_pressed):
		route_confirm_button.pressed.connect(_on_route_confirm_pressed)
	if route_close_button and not route_close_button.pressed.is_connected(_on_route_close_pressed):
		route_close_button.pressed.connect(_on_route_close_pressed)

	# Loadout buttons
	if mod_bolt_btn and not mod_bolt_btn.pressed.is_connected(_toggle_bolt_module):
		mod_bolt_btn.pressed.connect(_toggle_bolt_module)
	if mod_armour_btn and not mod_armour_btn.pressed.is_connected(_toggle_armour_module):
		mod_armour_btn.pressed.connect(_toggle_armour_module)
	if mod_storage_btn and not mod_storage_btn.pressed.is_connected(_toggle_storage_module):
		mod_storage_btn.pressed.connect(_toggle_storage_module)
	if mod_snare_btn and not mod_snare_btn.pressed.is_connected(_toggle_snare_module):
		mod_snare_btn.pressed.connect(_toggle_snare_module)
	if loadout_confirm_btn and not loadout_confirm_btn.pressed.is_connected(_on_loadout_confirm_pressed):
		loadout_confirm_btn.pressed.connect(_on_loadout_confirm_pressed)
	if loadout_close_btn and not loadout_close_btn.pressed.is_connected(_on_loadout_close_pressed):
		loadout_close_btn.pressed.connect(_on_loadout_close_pressed)

	# River decisions
	if river_repair_btn and not river_repair_btn.pressed.is_connected(_on_river_repair_pressed):
		river_repair_btn.pressed.connect(_on_river_repair_pressed)
	if river_hurry_btn and not river_hurry_btn.pressed.is_connected(_on_river_hurry_pressed):
		river_hurry_btn.pressed.connect(_on_river_hurry_pressed)

	# Onboarding dismiss
	if onboarding_dismiss_btn and not onboarding_dismiss_btn.pressed.is_connected(_on_onboarding_dismiss_pressed):
		onboarding_dismiss_btn.pressed.connect(_on_onboarding_dismiss_pressed)

func _process(delta: float) -> void:
	if is_any_modal_open():
		return

	if bolt_cd > 0.0:
		bolt_cd = max(0.0, bolt_cd - delta)
		if bolt_cd_bar:
			bolt_cd_bar.value = (bolt_cd / max_bolt_cd) * 100.0
			bolt_cd_bar.visible = (bolt_cd > 0.0)
		if bolt_button:
			bolt_button.disabled = (bolt_cd > 0.0)

# --- Modal Check ---
func is_any_modal_open() -> bool:
	return (
		(onboarding_overlay != null and onboarding_overlay.visible) or
		(route_inspector_panel != null and route_inspector_panel.visible) or
		(loadout_panel != null and loadout_panel.visible) or
		(river_decision_panel != null and river_decision_panel.visible) or
		(game_over_panel != null and game_over_panel.visible)
	)

func cancel_snare_placement_mode() -> void:
	is_snare_placement_mode = false

# --- Onboarding Methods ---
func has_step_been_shown(step: OnboardingStep) -> bool:
	return shown_onboarding_steps.has(step)

func get_next_unshown_step() -> int:
	for step in [OnboardingStep.PAN_MAP, OnboardingStep.INSPECT_ROUTE, OnboardingStep.CHOOSE_MODULES, OnboardingStep.CONFIRM_TRAVEL, OnboardingStep.TRAVEL_COMBAT]:
		if not has_step_been_shown(step):
			return step
	return OnboardingStep.COMPLETED

func trigger_onboarding_step(step: OnboardingStep) -> bool:
	if has_step_been_shown(step):
		return false
	var next_step := get_next_unshown_step()
	if step != next_step:
		return false
	show_onboarding_step(step)
	return true

func show_onboarding_step(step: OnboardingStep) -> void:
	current_onboarding_step = step
	if not ONBOARDING_TEXTS.has(step):
		if onboarding_overlay:
			onboarding_overlay.visible = false
		return
	var data: Dictionary = ONBOARDING_TEXTS[step]
	if onboarding_title:
		onboarding_title.text = data["title"]
	if onboarding_body:
		onboarding_body.text = data["body"]
	if onboarding_overlay:
		onboarding_overlay.visible = true
	cancel_snare_placement_mode()
	# Gameplay must pause while teaching modal is visible
	if get_tree():
		get_tree().paused = true

func _on_onboarding_dismiss_pressed() -> void:
	if onboarding_overlay:
		onboarding_overlay.visible = false
	# Safely resume gameplay
	if get_tree():
		get_tree().paused = false
	shown_onboarding_steps[current_onboarding_step] = true
	if shown_onboarding_steps.size() >= 5:
		has_completed_onboarding = true

	# Check deferred actions triggered by onboarding dismissal
	if pending_loadout_open_after_onboarding:
		pending_loadout_open_after_onboarding = false
		open_loadout_pressed.emit()
	elif not pending_travel_node_after_onboarding.is_empty():
		var dest_id := pending_travel_node_after_onboarding
		pending_travel_node_after_onboarding = ""
		route_travel_confirmed.emit(dest_id)
	elif not inspected_node_id.is_empty() and route_inspector_panel and route_inspector_panel.visible:
		if get_next_unshown_step() == OnboardingStep.CONFIRM_TRAVEL:
			trigger_onboarding_step(OnboardingStep.CONFIRM_TRAVEL)

func reset_onboarding() -> void:
	shown_onboarding_steps.clear()
	has_completed_onboarding = false
	pending_loadout_open_after_onboarding = false
	pending_travel_node_after_onboarding = ""
	if get_tree():
		get_tree().paused = false

# --- Top Bar Updates ---
func update_health(cur: float, max_hp: float) -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = cur
	if health_label:
		health_label.text = "Shellback HP: %.0f / %.0f" % [cur, max_hp]

func update_shellback_state(state_idx: int, is_moving: bool) -> void:
	if not state_badge:
		return
	match state_idx:
		1: # PANICKED
			state_badge.text = "⚠ PANICKED"
			state_badge.modulate = Color(1.0, 0.35, 0.35)
		2: # DEAD
			state_badge.text = "☠ FALLEN"
			state_badge.modulate = Color(0.6, 0.6, 0.6)
		_:
			if is_moving:
				state_badge.text = "▶ ADVANCING"
				state_badge.modulate = Color(0.4, 0.9, 0.4)
			else:
				state_badge.text = "■ HALTED"
				state_badge.modulate = Color(1.0, 0.85, 0.3)
	if halt_button:
		halt_button.text = "▶ RESUME" if not is_moving else "⏸ HALT"

func update_resources(food: int, wood: int, salvage: int) -> void:
	food_count = food
	wood_count = wood
	salvage_count = salvage
	if resource_label:
		resource_label.text = "🥩 %d  |  🪵 %d  |  ⚙ %d" % [food_count, wood_count, salvage_count]

func set_camp_status(is_camp: bool, is_traveling: bool) -> void:
	if loadout_button:
		loadout_button.disabled = (not is_camp or is_traveling)

func show_hold_countdown(remaining: float, _max_time: float) -> void:
	if state_badge:
		state_badge.text = "🛡 HOLD: %.1fs" % remaining
		state_badge.modulate = Color(1.0, 0.75, 0.2)

func notify_attackers_withdrew(_reason: String = "") -> void:
	if state_badge:
		state_badge.text = "✔ WITHDREW"
		state_badge.modulate = Color(0.4, 0.9, 0.5)

func clear_hold_display() -> void:
	if state_badge:
		state_badge.modulate = Color(1.0, 1.0, 1.0)

# --- Route Inspector ---
func show_route_inspector(node_data: Dictionary, can_travel: bool, is_completed: bool, is_traveling: bool = false) -> void:
	cancel_snare_placement_mode()
	inspected_node_id = node_data.get("id", "")
	if route_title_label:
		route_title_label.text = node_data.get("name", "Unknown Node")
	if route_threat_label:
		route_threat_label.text = "Threat: %s" % node_data.get("threat", "Unknown")
	if route_reward_label:
		var rew: Dictionary = node_data.get("rewards", {})
		route_reward_label.text = "Rewards: +%d Food, +%d Wood, +%d Salvage" % [
			rew.get("food", 0), rew.get("wood", 0), rew.get("salvage", 0)
		]
	if route_terrain_label:
		route_terrain_label.text = node_data.get("terrain_effect", "")
	if route_status_label:
		if is_traveling:
			route_status_label.text = "Status: Travel in progress. Reach destination first."
		elif is_completed:
			route_status_label.text = "Status: Completed / Visited"
		elif can_travel:
			route_status_label.text = "Status: Connected — Ready to Travel"
		else:
			route_status_label.text = "Status: Disconnected from Current Camp"
	if route_confirm_button:
		route_confirm_button.disabled = (not can_travel or is_traveling)
	if route_inspector_panel:
		route_inspector_panel.visible = true

	# Onboarding check when inspecting a route
	if get_next_unshown_step() == OnboardingStep.INSPECT_ROUTE:
		trigger_onboarding_step(OnboardingStep.INSPECT_ROUTE)
	elif can_travel and not is_traveling:
		if get_next_unshown_step() == OnboardingStep.CHOOSE_MODULES:
			trigger_onboarding_step(OnboardingStep.CHOOSE_MODULES)
		elif get_next_unshown_step() == OnboardingStep.CONFIRM_TRAVEL:
			trigger_onboarding_step(OnboardingStep.CONFIRM_TRAVEL)

func _on_route_confirm_pressed() -> void:
	if route_inspector_panel:
		route_inspector_panel.visible = false
	if not inspected_node_id.is_empty():
		var target_id := inspected_node_id
		inspected_node_id = ""
		# Step 5 Onboarding check: immediately before active travel/combat
		if get_next_unshown_step() == OnboardingStep.TRAVEL_COMBAT:
			pending_travel_node_after_onboarding = target_id
			trigger_onboarding_step(OnboardingStep.TRAVEL_COMBAT)
		else:
			route_travel_confirmed.emit(target_id)

func _on_route_close_pressed() -> void:
	if route_inspector_panel:
		route_inspector_panel.visible = false
	inspected_node_id = ""

# --- Loadout Configuration ---
func open_loadout(current_modules: Array[String]) -> void:
	cancel_snare_placement_mode()
	selected_loadout = current_modules.duplicate()
	_sync_loadout_buttons()
	if loadout_panel:
		loadout_panel.visible = true

func _sync_loadout_buttons() -> void:
	if mod_bolt_btn:
		mod_bolt_btn.text = "✔ Bolt Launcher (Active)" if selected_loadout.has("bolt_launcher") else "+ Bolt Launcher"
	if mod_armour_btn:
		mod_armour_btn.text = "✔ Armour Screen (-40% Dmg)" if selected_loadout.has("armour_screen") else "+ Armour Screen"
	if mod_storage_btn:
		mod_storage_btn.text = "✔ Storage Rack (+50% Loot)" if selected_loadout.has("storage_rack") else "+ Storage Rack"
	if mod_snare_btn:
		mod_snare_btn.text = "✔ Snare Rack (1 Trap/Leg)" if selected_loadout.has("snare_rack") else "+ Snare Rack"

	var count := selected_loadout.size()
	if loadout_status_label:
		loadout_status_label.text = "Equipped: %d / 3" % count
		loadout_status_label.modulate = Color.GREEN if count == 3 else Color.ORANGE
	if loadout_confirm_btn:
		loadout_confirm_btn.disabled = (count != 3)

func _toggle_module(id: String) -> void:
	if selected_loadout.has(id):
		selected_loadout.erase(id)
	else:
		if selected_loadout.size() < 3:
			selected_loadout.append(id)
	_sync_loadout_buttons()

func _toggle_bolt_module() -> void: _toggle_module("bolt_launcher")
func _toggle_armour_module() -> void: _toggle_module("armour_screen")
func _toggle_storage_module() -> void: _toggle_module("storage_rack")
func _toggle_snare_module() -> void: _toggle_module("snare_rack")

func _on_loadout_confirm_pressed() -> void:
	if selected_loadout.size() == 3:
		loadout_confirmed.emit(selected_loadout.duplicate())
		if loadout_panel:
			loadout_panel.visible = false
		_update_action_bar_modules(selected_loadout)

func _on_loadout_close_pressed() -> void:
	if loadout_panel:
		loadout_panel.visible = false

func _update_action_bar_modules(modules: Array[String]) -> void:
	if bolt_container:
		bolt_container.visible = modules.has("bolt_launcher")
	if snare_container:
		snare_container.visible = modules.has("snare_rack")

# --- River Crossing Decision ---
func show_river_decision(wood_available: int) -> void:
	cancel_snare_placement_mode()
	if river_repair_btn:
		var can_repair := wood_available >= 10
		river_repair_btn.text = "REPAIR FORTRESS (-10 Wood -> +60 HP)" if can_repair else "REPAIR FORTRESS (Need 10 Wood, have %d)" % wood_available
		river_repair_btn.disabled = not can_repair
	if river_decision_panel:
		river_decision_panel.visible = true

func _on_river_repair_pressed() -> void:
	if river_decision_panel:
		river_decision_panel.visible = false
	river_decision_chosen.emit(true)

func _on_river_hurry_pressed() -> void:
	if river_decision_panel:
		river_decision_panel.visible = false
	river_decision_chosen.emit(false)

# --- Travel Combat Controls ---
func update_module_controls(modules: Array[String], snare_avail: int) -> void:
	if bolt_container:
		bolt_container.visible = modules.has("bolt_launcher")
	if snare_container:
		snare_container.visible = modules.has("snare_rack")
	if snare_button:
		snare_button.text = "🪤 PLACE SNARE (%d/1)" % snare_avail
		snare_button.disabled = (snare_avail <= 0)

func trigger_bolt_cooldown(cd: float) -> void:
	bolt_cd = cd
	max_bolt_cd = cd
	if bolt_cd_bar:
		bolt_cd_bar.visible = true
		bolt_cd_bar.value = 100.0
	if bolt_button:
		bolt_button.disabled = true

func _on_halt_pressed() -> void:
	toggle_movement_pressed.emit()

func _on_bolt_pressed() -> void:
	if bolt_cd <= 0.0:
		bolt_launcher_pressed.emit()

func _on_snare_pressed() -> void:
	is_snare_placement_mode = true
	snare_selected.emit()

func _on_recenter_pressed() -> void:
	recenter_pressed.emit()

func _on_loadout_pressed() -> void:
	# Step 3 Onboarding check
	if not has_step_been_shown(OnboardingStep.CHOOSE_MODULES):
		pending_loadout_open_after_onboarding = true
		trigger_onboarding_step(OnboardingStep.CHOOSE_MODULES)
	else:
		open_loadout_pressed.emit()

func _on_restart_pressed() -> void:
	restart_pressed.emit()

# --- Game Over / Victory ---
func show_victory(route_path: Array[String], hp: float, max_hp: float, food: int, wood: int, salvage: int, modules: Array[String]) -> void:
	cancel_snare_placement_mode()
	is_game_over = true
	if game_over_title:
		game_over_title.text = "★ EXPEDITION SUCCESSFUL ★"
		game_over_title.modulate = Color(1.0, 0.85, 0.2)
	if game_over_subtitle:
		game_over_subtitle.text = "The Shellback safely reached Exit Haven!"
	if victory_stats_label:
		var route_str := " -> ".join(route_path)
		var mod_str := ", ".join(modules)
		victory_stats_label.text = "Route Taken: %s\nRemaining Health: %.0f / %.0f HP\nResources: Food %d | Wood %d | Salvage %d\nModules: %s\nRun Reward: Relic of the Hearthseed (Display Only)" % [
			route_str, hp, max_hp, food, wood, salvage, mod_str
		]
		victory_stats_label.visible = true
	if game_over_panel:
		game_over_panel.visible = true

func show_defeat(reason: String) -> void:
	cancel_snare_placement_mode()
	is_game_over = true
	if game_over_title:
		game_over_title.text = "☠ FORTRESS FALLEN ☠"
		game_over_title.modulate = Color(1.0, 0.3, 0.3)
	if game_over_subtitle:
		game_over_subtitle.text = "The Shellback was defeated.\n%s" % reason
	if victory_stats_label:
		victory_stats_label.visible = false
	if game_over_panel:
		game_over_panel.visible = true

func reset_ui() -> void:
	# Restart must NEVER leave SceneTree paused
	if get_tree():
		get_tree().paused = false
	is_game_over = false
	cancel_snare_placement_mode()
	bolt_cd = 0.0
	if bolt_cd_bar:
		bolt_cd_bar.visible = false
	if bolt_button:
		bolt_button.disabled = false
	if route_inspector_panel:
		route_inspector_panel.visible = false
	if loadout_panel:
		loadout_panel.visible = false
	if river_decision_panel:
		river_decision_panel.visible = false
	if game_over_panel:
		game_over_panel.visible = false
	if onboarding_overlay:
		onboarding_overlay.visible = false
	clear_hold_display()
