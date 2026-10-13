extends Node2D
class_name Raider

# Raider threat entity with explicit finite state machine.
# States: IDLE, APPROACH, TELEGRAPH, ATTACK, SNARED, DEAD.

enum State {
	IDLE,
	APPROACH,
	TELEGRAPH,
	ATTACK,
	SNARED,
	DEAD
}

signal state_changed(new_state: State)
signal health_changed(current_hp: float, max_hp: float)
signal attack_hit(damage: float)
signal died

@export var max_health: float = 40.0
@export var move_speed: float = 70.0
@export var attack_damage: float = 9.0
@export var attack_reach: float = 65.0
@export var telegraph_duration: float = 0.6
@export var attack_cycle: float = 1.4

var current_health: float = 40.0
var state: State = State.IDLE
var facing_dir: float = -1.0

var telegraph_timer: float = 0.0
var attack_cooldown_timer: float = 0.0
var snare_timer: float = 0.0
var has_struck: bool = false

var target_shellback: Node2D = null

var visual: RaiderVisual
var health_bar: WorldHealthBar

func _enter_tree() -> void:
	_setup_references()

func _setup_references() -> void:
	if not visual:
		visual = get_node_or_null("Visual") as RaiderVisual
	if not health_bar:
		health_bar = get_node_or_null("HealthBar") as WorldHealthBar

func _ready() -> void:
	_setup_references()
	current_health = max_health
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
		State.APPROACH:
			_process_approach(delta)
		State.TELEGRAPH:
			_process_telegraph(delta)
		State.ATTACK:
			_process_attack(delta)

	_update_visual()

func _process_snared(delta: float) -> void:
	snare_timer -= delta
	if snare_timer <= 0.0:
		snare_timer = 0.0
		if _is_target_valid_and_alive(target_shellback):
			transition_to(State.APPROACH)
		else:
			transition_to(State.IDLE)

func _process_idle(_delta: float) -> void:
	if _is_target_valid_and_alive(target_shellback):
		transition_to(State.APPROACH)

func _process_approach(delta: float) -> void:
	if not _is_target_valid_and_alive(target_shellback):
		transition_to(State.IDLE)
		return

	var target_pos: Vector2 = target_shellback.global_position
	var diff := target_pos - global_position
	var dist := diff.length()

	facing_dir = -1.0 if diff.x < 0 else 1.0

	if dist <= attack_reach:
		transition_to(State.TELEGRAPH)
		return

	var dir := diff.normalized()
	global_position += dir * move_speed * delta

func _process_telegraph(delta: float) -> void:
	if not _is_target_valid_and_alive(target_shellback):
		transition_to(State.IDLE)
		return

	telegraph_timer -= delta
	if telegraph_timer <= 0.0:
		transition_to(State.ATTACK)

func _process_attack(delta: float) -> void:
	if not _is_target_valid_and_alive(target_shellback):
		transition_to(State.IDLE)
		return

	if not has_struck:
		has_struck = true
		_apply_attack_damage()

	attack_cooldown_timer -= delta
	if attack_cooldown_timer <= 0.0:
		var dist := global_position.distance_to(target_shellback.global_position)
		if dist <= attack_reach + 15.0:
			transition_to(State.TELEGRAPH)
		else:
			transition_to(State.APPROACH)

func _apply_attack_damage() -> void:
	if not _is_target_valid_and_alive(target_shellback):
		return
	if target_shellback.has_method("take_damage"):
		target_shellback.call("take_damage", attack_damage)
	attack_hit.emit(attack_damage)

func transition_to(new_state: State) -> void:
	if state == State.DEAD:
		return
	state = new_state
	match state:
		State.TELEGRAPH:
			telegraph_timer = telegraph_duration
		State.ATTACK:
			has_struck = false
			attack_cooldown_timer = attack_cycle
	state_changed.emit(state)
	_update_visual()

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

func _is_target_valid_and_alive(t: Node) -> bool:
	if not is_instance_valid(t):
		return false
	if t.has_method("is_alive"):
		return t.call("is_alive")
	return true

func _update_visual() -> void:
	if not visual:
		return
	visual.facing_dir = facing_dir
	visual.is_moving = (state == State.APPROACH)
	visual.is_telegraphing = (state == State.TELEGRAPH)
	visual.is_attacking = (state == State.ATTACK)
	visual.is_snared = (state == State.SNARED)
	visual.is_dead = (state == State.DEAD)

func _update_health_bar() -> void:
	if health_bar:
		health_bar.set_health(current_health, max_health)
		health_bar.visible = (state != State.DEAD)

func reset(pos: Vector2) -> void:
	global_position = pos
	current_health = max_health
	state = State.IDLE
	telegraph_timer = 0.0
	attack_cooldown_timer = 0.0
	snare_timer = 0.0
	has_struck = false
	health_changed.emit(current_health, max_health)
	state_changed.emit(state)
	_update_visual()
	_update_health_bar()
