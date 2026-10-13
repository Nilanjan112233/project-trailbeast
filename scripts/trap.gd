extends Node2D
class_name Trap

# Ground-placed tool entity: Bait or Snare.

enum TrapType {
	BAIT,
	SNARE
}

signal triggered
signal consumed_signal
signal expired

@export var trap_type: TrapType = TrapType.BAIT
@export var bait_lifetime: float = 16.0
@export var snare_duration: float = 5.0
@export var trigger_radius: float = 40.0

var is_active: bool = true
var is_consumed: bool = false
var is_triggered: bool = false
var time_left: float = 16.0
var cleanup_timer: float = 0.0
var visual: TrapVisual

func _enter_tree() -> void:
	if not visual:
		visual = get_node_or_null("Visual") as TrapVisual

func _ready() -> void:
	if not visual:
		visual = get_node_or_null("Visual") as TrapVisual
	time_left = bait_lifetime
	_setup_groups()
	_update_visual()

func _setup_groups() -> void:
	if trap_type == TrapType.BAIT:
		add_to_group("bait")
	else:
		add_to_group("snare")

func _process(delta: float) -> void:
	if not is_active:
		cleanup_timer -= delta
		if cleanup_timer <= 0.0:
			queue_free()
		return

	if trap_type == TrapType.BAIT:
		_process_bait(delta)
	else:
		_process_snare(delta)

func _process_bait(delta: float) -> void:
	time_left -= delta
	if time_left <= 0.0:
		is_active = false
		is_consumed = true
		remove_from_group("bait")
		expired.emit()
		cleanup_timer = 0.4
		_update_visual()

func _process_snare(_delta: float) -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if not tree:
		return
	# Check for threats entering snare radius
	var threats := tree.get_nodes_in_group("threats")
	for t in threats:
		if is_instance_valid(t) and t is Node2D:
			if t.has_method("is_alive") and not t.is_alive():
				continue
			if "state" in t and t.state == 4: # Already SNARED
				continue
			var dist := global_position.distance_to(t.global_position)
			if dist <= trigger_radius:
				_trigger_snare_on(t)
				break

func _trigger_snare_on(target: Node2D) -> void:
	is_active = false
	is_triggered = true
	remove_from_group("snare")
	if target.has_method("apply_snare"):
		target.apply_snare(snare_duration)
	triggered.emit()
	cleanup_timer = 0.6
	_update_visual()

func consume() -> void:
	if not is_active or is_consumed:
		return
	is_active = false
	is_consumed = true
	remove_from_group("bait")
	consumed_signal.emit()
	cleanup_timer = 0.4
	_update_visual()

func _update_visual() -> void:
	if visual:
		visual.trap_type_enum = int(trap_type)
		visual.is_triggered = is_triggered
		visual.is_consumed = is_consumed
