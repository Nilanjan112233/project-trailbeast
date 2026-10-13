extends Node2D
class_name Warden

# Trail Warden player helper entity.
# Manages horizontal movement to tapped ground destinations within map bounds.

@export var move_speed: float = 190.0
@export var min_x: float = 40.0
@export var max_x: float = 1240.0

var target_x: float = 260.0
var is_moving: bool = false
var facing_dir: float = 1.0
var visual: WardenVisual

func _enter_tree() -> void:
	if not visual:
		visual = get_node_or_null("Visual") as WardenVisual

func _ready() -> void:
	if not visual:
		visual = get_node_or_null("Visual") as WardenVisual
	target_x = global_position.x
	_update_visual()

func _process(delta: float) -> void:
	var diff: float = target_x - global_position.x
	if abs(diff) > 3.0:
		is_moving = true
		facing_dir = 1.0 if diff > 0 else -1.0
		var step: float = sign(diff) * min(move_speed * delta, abs(diff))
		global_position.x = clamp(global_position.x + step, min_x, max_x)
	else:
		is_moving = false
		global_position.x = clamp(target_x, min_x, max_x)

	_update_visual()

func move_to(new_x: float) -> void:
	target_x = clamp(new_x, min_x, max_x)

func reset(initial_pos: Vector2) -> void:
	global_position = initial_pos
	target_x = initial_pos.x
	is_moving = false
	facing_dir = 1.0
	_update_visual()

func _update_visual() -> void:
	if visual:
		visual.is_moving = is_moving
		visual.facing_dir = facing_dir
