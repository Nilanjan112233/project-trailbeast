extends Area2D
class_name Shellback

# Shellback moving fortress caravan entity.
# Manages waypoint path navigation, modules, health, damage mitigation, panic, and halt/resume.

enum State {
	ALIVE,
	PANICKED,
	DEAD
}

signal health_changed(current_hp: float, max_hp: float)
signal state_changed(new_state: State)
signal movement_toggled(moving: bool)
signal destination_reached(dest_node_id: String)
signal died

@export var max_health: float = 250.0
@export var travel_speed: float = 75.0
@export var panic_speed_multiplier: float = 1.6
@export var panic_duration: float = 3.0

var current_health: float = 250.0
var state: State = State.ALIVE
var is_moving: bool = false
var panic_timer: float = 0.0

# Waypoint route navigation
var travel_waypoints: Array[Vector2] = []
var waypoint_index: int = 0
var destination_node_id: String = ""

# Equipped modules (Exactly 3 out of 4)
var equipped_modules: Array[String] = ["bolt_launcher", "armour_screen", "snare_rack"]
var snare_charges: int = 1 # 1 snare placement per travel encounter if Snare Rack equipped

var visual: ShellbackVisual
var launcher_mount: Marker2D
var damage_point: Marker2D
var health_bar_container: Node2D

func _enter_tree() -> void:
	_setup_references()

func _setup_references() -> void:
	if not visual:
		visual = get_node_or_null("Visual") as ShellbackVisual
	if not launcher_mount:
		launcher_mount = get_node_or_null("LauncherMount") as Marker2D
	if not damage_point:
		damage_point = get_node_or_null("DamagePoint") as Marker2D
	if not health_bar_container:
		health_bar_container = get_node_or_null("HealthBar") as Node2D

func _ready() -> void:
	_setup_references()
	current_health = max_health
	input_event.connect(_on_input_event)
	_update_visual_state()
	_update_health_bar()

func _process(delta: float) -> void:
	if state == State.DEAD:
		return

	if state == State.PANICKED:
		panic_timer -= delta
		if panic_timer <= 0.0:
			state = State.ALIVE
			state_changed.emit(state)
			_update_visual_state()

	if is_moving and waypoint_index < travel_waypoints.size():
		var remaining_step: float = travel_speed * (panic_speed_multiplier if state == State.PANICKED else 1.0) * delta
		while remaining_step > 0.0 and waypoint_index < travel_waypoints.size():
			var target_pt: Vector2 = travel_waypoints[waypoint_index]
			var diff := target_pt - global_position
			var dist := diff.length()
			if dist <= remaining_step:
				global_position = target_pt
				remaining_step -= dist
				waypoint_index += 1
				if waypoint_index >= travel_waypoints.size():
					is_moving = false
					movement_toggled.emit(false)
					destination_reached.emit(destination_node_id)
					break
			else:
				var dir := diff.normalized()
				global_position += dir * remaining_step
				remaining_step = 0.0
				if visual:
					visual.facing_dir = dir

	# Map boundary safety clamping [100, 2460] x [100, 1340]
	global_position.x = clamp(global_position.x, 100.0, 2460.0)
	global_position.y = clamp(global_position.y, 100.0, 1340.0)

	_update_visual_state()

func start_travel(waypoints: Array[Vector2], dest_id: String) -> void:
	if state == State.DEAD:
		return
	travel_waypoints = waypoints
	destination_node_id = dest_id
	waypoint_index = 0
	if waypoints.size() > 1 and global_position.distance_to(waypoints[0]) < 10.0:
		waypoint_index = 1
	snare_charges = 1 if has_module("snare_rack") else 0
	is_moving = true
	movement_toggled.emit(true)
	_update_visual_state()

func toggle_movement() -> void:
	if state == State.DEAD or state == State.PANICKED:
		return
	if travel_waypoints.is_empty() or waypoint_index >= travel_waypoints.size():
		return
	is_moving = not is_moving
	movement_toggled.emit(is_moving)
	_update_visual_state()

func set_moving(moving: bool) -> void:
	if state == State.DEAD:
		is_moving = false
		return
	if state == State.PANICKED:
		is_moving = true
		return
	is_moving = moving
	movement_toggled.emit(is_moving)
	_update_visual_state()

func has_module(module_id: String) -> bool:
	return equipped_modules.has(module_id)

func set_equipped_modules(modules: Array[String]) -> bool:
	if modules.size() != 3:
		return false
	equipped_modules = modules.duplicate()
	snare_charges = 1 if has_module("snare_rack") else 0
	if visual:
		visual.equipped_modules = equipped_modules
	return true

func take_damage(amount: float) -> void:
	if state == State.DEAD:
		return

	# Armour Screen passive damage reduction (40% reduction -> takes 60%)
	var effective_damage: float = amount
	if has_module("armour_screen"):
		effective_damage = amount * 0.60

	current_health = clamp(current_health - effective_damage, 0.0, max_health)
	health_changed.emit(current_health, max_health)
	_update_health_bar()

	if current_health <= 0.0:
		_die()
	else:
		trigger_panic(panic_duration)

func set_health(amount: float) -> void:
	if state == State.DEAD:
		return
	current_health = clamp(amount, 0.0, max_health)
	health_changed.emit(current_health, max_health)
	_update_health_bar()
	if current_health <= 0.0:
		_die()

func heal(amount: float) -> void:
	if state == State.DEAD:
		return
	current_health = clamp(current_health + amount, 0.0, max_health)
	health_changed.emit(current_health, max_health)
	_update_health_bar()

func _die() -> void:
	current_health = 0.0
	state = State.DEAD
	is_moving = false
	panic_timer = 0.0
	state_changed.emit(state)
	died.emit()
	_update_visual_state()
	_update_health_bar()

func trigger_panic(duration: float = -1.0) -> void:
	if state == State.DEAD:
		return
	var dur: float = panic_duration if duration < 0.0 else duration
	state = State.PANICKED
	panic_timer = dur
	is_moving = true
	state_changed.emit(state)
	_update_visual_state()

func is_alive() -> bool:
	return state != State.DEAD and current_health > 0.0

func get_damage_point() -> Vector2:
	if is_instance_valid(damage_point):
		return damage_point.global_position
	return global_position + Vector2(40, -35)

func get_launcher_mount_position() -> Vector2:
	if is_instance_valid(launcher_mount):
		return launcher_mount.global_position
	return global_position + Vector2(30, -95)

func reset(initial_pos: Vector2) -> void:
	global_position = initial_pos
	current_health = max_health
	state = State.ALIVE
	is_moving = false
	panic_timer = 0.0
	travel_waypoints.clear()
	waypoint_index = 0
	destination_node_id = ""
	snare_charges = 1 if has_module("snare_rack") else 0
	health_changed.emit(current_health, max_health)
	state_changed.emit(state)
	movement_toggled.emit(is_moving)
	_update_visual_state()
	_update_health_bar()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		toggle_movement()

func _update_visual_state() -> void:
	if visual:
		visual.is_moving = is_moving
		visual.is_panicked = (state == State.PANICKED)
		visual.is_dead = (state == State.DEAD)
		visual.equipped_modules = equipped_modules

func _update_health_bar() -> void:
	if health_bar_container and health_bar_container.has_method("set_health"):
		health_bar_container.call("set_health", current_health, max_health, state)
