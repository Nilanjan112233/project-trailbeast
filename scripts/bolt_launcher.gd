extends Node2D
class_name BoltLauncher

# Shellback-mounted bolt launcher module.
# Fires heavy physical bolts toward a selected threat.

signal fired(projectile: Node2D)
signal cooldown_changed(current: float, max_cd: float)

@export var cooldown_time: float = 3.0
@export var projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")

var current_cooldown: float = 0.0
var visual: BoltLauncherVisual
var muzzle: Marker2D

func _enter_tree() -> void:
	if not visual:
		visual = get_node_or_null("Visual") as BoltLauncherVisual
	if not muzzle:
		muzzle = get_node_or_null("Muzzle") as Marker2D

func _ready() -> void:
	if not visual:
		visual = get_node_or_null("Visual") as BoltLauncherVisual
	if not muzzle:
		muzzle = get_node_or_null("Muzzle") as Marker2D

func _process(delta: float) -> void:
	if current_cooldown > 0.0:
		current_cooldown = max(0.0, current_cooldown - delta)
		cooldown_changed.emit(current_cooldown, cooldown_time)

func can_fire() -> bool:
	return current_cooldown <= 0.0

func fire(container_node: Node = null, target_node: Node2D = null) -> Projectile:
	if not can_fire():
		return null

	current_cooldown = cooldown_time
	cooldown_changed.emit(current_cooldown, cooldown_time)

	if visual:
		visual.trigger_recoil()

	if not projectile_scene:
		return null

	var proj: Projectile = projectile_scene.instantiate() as Projectile
	var spawn_pos: Vector2 = muzzle.global_position if is_instance_valid(muzzle) else global_position + Vector2(20, -14)
	proj.global_position = spawn_pos
	if is_instance_valid(target_node):
		proj.set_target(target_node)
		proj.direction = spawn_pos.direction_to(proj.get_target_point())
	else:
		proj.direction = Vector2.RIGHT

	if is_instance_valid(container_node):
		container_node.add_child(proj)
	else:
		get_tree().root.add_child(proj)

	fired.emit(proj)
	return proj

func reset() -> void:
	current_cooldown = 0.0
	cooldown_changed.emit(current_cooldown, cooldown_time)
