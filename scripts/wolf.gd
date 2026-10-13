extends Node2D
class_name Wolf

# Wolf threat entity with explicit finite state machine.
# States: IDLE, INVESTIGATE, STALK, ATTACK, SNARED, DEAD.

enum State {
	IDLE,
	INVESTIGATE,
	STALK,
	ATTACK,
	SNARED,
	DEAD
}

signal state_changed(new_state: State)
signal health_changed(current_hp: float, max_hp: float)
signal attack_hit(damage: float)
signal died

@export var max_health: float = 60.0
@export var patrol_speed: float = 30.0
@export var investigate_speed: float = 75.0
@export var stalk_speed: float = 85.0
@export var attack_damage: float = 12.0
@export var attack_reach: float = 70.0
@export var attack_windup_time: float = 0.55
@export var attack_cycle_time: float = 1.50
@export var scent_range: float = 600.0
@export var detect_range: float = 450.0

var current_health: float = 60.0
var state: State = State.IDLE
var facing_dir: float = -1.0

# Timers and state data
var attack_timer: float = 0.0
var has_struck: bool = false
var snare_timer: float = 0.0
var feeding_timer: float = 0.0
var patrol_center_x: float = 880.0
var patrol_dir: float = -1.0
var patrol_timer: float = 0.0

var target_shellback: Node2D = null
var target_bait: Node2D = null

var visual: WolfVisual
var health_bar: WorldHealthBar

func _enter_tree() -> void:
	_setup_references()

func _setup_references() -> void:
	if not visual:
		visual = get_node_or_null("Visual") as WolfVisual
	if not health_bar:
		health_bar = get_node_or_null("HealthBar") as WorldHealthBar

func _ready() -> void:
	_setup_references()
	current_health = max_health
	patrol_center_x = global_position.x
	_update_visual()
	_update_health_bar()

func _process(delta: float) -> void:
	if state == State.DEAD:
		return

	match state:
		State.SNARED:
			_process_snared(delta)
		State.IDLE:
			_process_idle(delta)
		State.INVESTIGATE:
			_process_investigate(delta)
		State.STALK:
			_process_stalk(delta)
		State.ATTACK:
			_process_attack(delta)

	_update_visual()

func _process_snared(delta: float) -> void:
	snare_timer -= delta
	if snare_timer <= 0.0:
		# Recover from snare
		snare_timer = 0.0
		if _find_valid_bait():
			transition_to(State.INVESTIGATE)
		elif _is_target_valid_and_alive(target_shellback):
			transition_to(State.STALK)
		else:
			transition_to(State.IDLE)

func _process_idle(delta: float) -> void:
	# Priority 1: Scent bait
	if _find_valid_bait():
		transition_to(State.INVESTIGATE)
		return

	# Priority 2: Detect Shellback
	if _is_target_valid_and_alive(target_shellback):
		var dist := _distance_to_shellback()
		if dist <= detect_range:
			transition_to(State.STALK)
			return

	# Gentle territorial patrol
	patrol_timer += delta
	if patrol_timer > 3.0:
		patrol_timer = 0.0
		patrol_dir = -patrol_dir
	facing_dir = patrol_dir
	global_position.x += patrol_dir * patrol_speed * delta

func _process_investigate(delta: float) -> void:
	# If currently feeding at bait
	if feeding_timer > 0.0:
		feeding_timer -= delta
		if feeding_timer <= 0.0:
			feeding_timer = 0.0
			target_bait = null
			if _is_target_valid_and_alive(target_shellback) and _distance_to_shellback() <= detect_range:
				transition_to(State.STALK)
			else:
				transition_to(State.IDLE)
		return

	# Check if target bait is still valid
	if not _is_bait_valid(target_bait):
		# Re-check for other active bait
		if not _find_valid_bait():
			if _is_target_valid_and_alive(target_shellback) and _distance_to_shellback() <= detect_range:
				transition_to(State.STALK)
			else:
				transition_to(State.IDLE)
			return

	var diff: float = target_bait.global_position.x - global_position.x
	if abs(diff) <= 20.0:
		# Reached bait! Start feeding
		if target_bait.has_method("consume"):
			target_bait.consume()
		feeding_timer = 3.0 # Occupied feeding for 3 seconds
	else:
		facing_dir = 1.0 if diff > 0 else -1.0
		global_position.x += facing_dir * investigate_speed * delta

func _process_stalk(delta: float) -> void:
	# Bait can still distract a stalking wolf!
	if _find_valid_bait():
		transition_to(State.INVESTIGATE)
		return

	if not _is_target_valid_and_alive(target_shellback):
		transition_to(State.IDLE)
		return

	var dist := _distance_to_shellback()
	if dist <= attack_reach:
		transition_to(State.ATTACK)
		return

	# Approach contact point of Shellback in 2D
	var contact_pt: Vector2 = target_shellback.global_position
	if target_shellback.has_method("get_damage_point"):
		contact_pt = target_shellback.get_damage_point()
	var diff_vec: Vector2 = contact_pt - global_position
	facing_dir = 1.0 if diff_vec.x > 0 else -1.0
	var move_dir: Vector2 = diff_vec.normalized()
	global_position += move_dir * stalk_speed * delta

func _process_attack(delta: float) -> void:
	if not _is_target_valid_and_alive(target_shellback):
		transition_to(State.IDLE)
		return

	var dist := _distance_to_shellback()
	if dist > attack_reach * 1.5:
		# Target moved out of contact range
		transition_to(State.STALK)
		return

	# Attack sequence with telegraphed contact moment
	attack_timer += delta
	if attack_timer >= attack_windup_time and not has_struck:
		# VISIBLE CONTACT MOMENT: apply damage here, not early!
		has_struck = true
		if visual:
			visual.trigger_strike_visual()
		if _is_target_valid_and_alive(target_shellback):
			target_shellback.take_damage(attack_damage)
			attack_hit.emit(attack_damage)

	if attack_timer >= attack_cycle_time:
		# Ready for next strike cycle
		attack_timer = 0.0
		has_struck = false

func transition_to(new_state: State) -> void:
	if state == State.DEAD:
		return # Death is final!

	if state == new_state:
		return

	state = new_state
	attack_timer = 0.0
	has_struck = false
	feeding_timer = 0.0

	state_changed.emit(state)
	_update_visual()
	_update_health_bar()

func take_damage(amount: float) -> void:
	if state == State.DEAD:
		return

	current_health = clamp(current_health - amount, 0.0, max_health)
	health_changed.emit(current_health, max_health)
	_update_health_bar()

	if current_health <= 0.0:
		_die()

func _die() -> void:
	current_health = 0.0
	state = State.DEAD
	target_bait = null
	target_shellback = null
	state_changed.emit(state)
	died.emit()
	_update_visual()
	_update_health_bar()

func apply_snare(duration: float = 5.0) -> void:
	if state == State.DEAD:
		return
	snare_timer = duration
	transition_to(State.SNARED)

func is_alive() -> bool:
	return state != State.DEAD and current_health > 0.0

func get_projectile_hit_point() -> Vector2:
	# Centre mass of the procedurally drawn wolf, rather than its feet-level origin.
	return global_position + Vector2(0.0, -28.0)

func _is_target_valid_and_alive(target: Variant) -> bool:
	if not is_instance_valid(target):
		return false
	if target.is_queued_for_deletion():
		return false
	if target.has_method("is_alive") and not target.is_alive():
		return false
	return true

func _is_bait_valid(bait: Variant) -> bool:
	if not is_instance_valid(bait):
		return false
	if bait.is_queued_for_deletion():
		return false
	if "is_consumed" in bait and bait.is_consumed:
		return false
	return true

func _find_valid_bait() -> bool:
	if not is_inside_tree():
		return false
	var tree := get_tree()
	if not tree:
		return false
	var bait_nodes := tree.get_nodes_in_group("bait")
	var closest_bait: Node2D = null
	var min_dist: float = scent_range
	for b in bait_nodes:
		if b is Node2D and _is_bait_valid(b):
			var d := global_position.distance_to(b.global_position)
			if d <= min_dist:
				min_dist = d
				closest_bait = b
	if closest_bait:
		target_bait = closest_bait
		return true
	return false

func _distance_to_shellback() -> float:
	if not _is_target_valid_and_alive(target_shellback):
		return 99999.0
	var contact_pt := target_shellback.global_position
	if target_shellback.has_method("get_damage_point"):
		contact_pt = target_shellback.get_damage_point()
	return global_position.distance_to(contact_pt)

func _get_shellback_contact_x() -> float:
	if _is_target_valid_and_alive(target_shellback) and target_shellback.has_method("get_damage_point"):
		return target_shellback.get_damage_point().x
	elif _is_target_valid_and_alive(target_shellback):
		return target_shellback.global_position.x + 60.0
	return global_position.x

func reset(initial_pos: Vector2) -> void:
	global_position = initial_pos
	current_health = max_health
	state = State.IDLE
	facing_dir = -1.0
	attack_timer = 0.0
	has_struck = false
	snare_timer = 0.0
	feeding_timer = 0.0
	target_bait = null
	state_changed.emit(state)
	health_changed.emit(current_health, max_health)
	_update_visual()
	_update_health_bar()

func _update_visual() -> void:
	if visual:
		visual.set_visual_state(int(state), facing_dir)

func _update_health_bar() -> void:
	if health_bar:
		health_bar.set_health(current_health, max_health, int(state))
