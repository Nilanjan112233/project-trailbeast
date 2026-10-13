extends Node2D
class_name Projectile

# Ballista bolt projectile.
# Applies damage strictly upon physical impact, not at fire time.

signal impacted(target: Node2D)

@export var speed: float = 460.0
@export var damage: float = 30.0
@export var hit_radius: float = 24.0
@export var max_range: float = 1300.0

var direction: Vector2 = Vector2.RIGHT
var distance_traveled: float = 0.0
var has_hit: bool = false
var hit_timer: float = 0.0
var visual: ProjectileVisual
var target: Node2D = null
var has_locked_target: bool = false

func _enter_tree() -> void:
	if not visual:
		visual = get_node_or_null("Visual") as ProjectileVisual

func _ready() -> void:
	if not visual:
		visual = get_node_or_null("Visual") as ProjectileVisual
	rotation = direction.angle()

func _process(delta: float) -> void:
	if has_hit:
		hit_timer -= delta
		if hit_timer <= 0.0:
			queue_free()
		return

	if has_locked_target:
		if not _is_valid_living_target(target):
			queue_free()
			return
		direction = global_position.direction_to(get_target_point())
		rotation = direction.angle()

	var step: float = speed * delta
	global_position += direction * step
	distance_traveled += step

	if distance_traveled >= max_range or global_position.x > 2650.0 or global_position.x < -100.0 or global_position.y > 1550.0 or global_position.y < -100.0:
		queue_free()
		return

	_check_impact()

func _check_impact() -> void:
	if has_locked_target:
		if _is_valid_living_target(target) and global_position.distance_to(get_target_point()) <= hit_radius:
			_apply_impact(target)
		return

	if not is_inside_tree():
		return
	var tree := get_tree()
	if not tree:
		return
	var threats := tree.get_nodes_in_group("threats")
	for t in threats:
		if is_instance_valid(t) and t is Node2D:
			if t.has_method("is_alive") and not t.is_alive():
				continue
			var dist := global_position.distance_to(t.global_position)
			if dist <= hit_radius:
				_apply_impact(t)
				break

func _apply_impact(target: Node2D) -> void:
	has_hit = true
	hit_timer = 0.25
	if target.has_method("take_damage"):
		target.take_damage(damage)
	impacted.emit(target)
	if visual:
		visual.trigger_impact()

func set_target(target_node: Node2D) -> void:
	target = target_node
	has_locked_target = is_instance_valid(target_node)

func get_target_point() -> Vector2:
	if not is_instance_valid(target):
		return global_position + direction * 100.0
	if target.has_method("get_projectile_hit_point"):
		var point: Variant = target.call("get_projectile_hit_point")
		if point is Vector2:
			return point
	return target.global_position

func _is_valid_living_target(candidate: Variant) -> bool:
	if not is_instance_valid(candidate):
		return false
	if candidate is Node and candidate.is_queued_for_deletion():
		return false
	if candidate.has_method("is_alive") and not candidate.is_alive():
		return false
	return true
