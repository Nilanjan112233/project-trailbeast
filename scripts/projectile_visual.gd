extends Node2D
class_name ProjectileVisual

# Procedural drawing for the heavy ballista bolt projectile.

var is_impacted: bool = false
var impact_timer: float = 0.0

func trigger_impact() -> void:
	is_impacted = true
	impact_timer = 0.25
	queue_redraw()

func _process(delta: float) -> void:
	if is_impacted:
		impact_timer -= delta
		queue_redraw()

func _draw() -> void:
	if is_impacted:
		# Impact spark burst
		draw_circle(Vector2.ZERO, 14.0, Color(1.0, 0.8, 0.2, 0.9))
		draw_circle(Vector2.ZERO, 7.0, Color.WHITE)
		for i in range(6):
			var a := float(i) * TAU / 6.0
			var pt := Vector2(cos(a), sin(a)) * 18.0
			draw_line(Vector2.ZERO, pt, Color(1.0, 0.4, 0.1), 2.5)
		return

	var shaft_color: Color = Color(0.48, 0.35, 0.20)
	var iron_color: Color = Color(0.80, 0.82, 0.85)
	var feather_color: Color = Color(0.9, 0.9, 0.9)

	# Fletching trail
	draw_line(Vector2(-24, 0), Vector2(-12, 0), Color(1.0, 0.9, 0.6, 0.3), 1.5)

	# Wooden shaft
	draw_line(Vector2(-14, 0), Vector2(10, 0), shaft_color, 3.5)

	# Iron arrowhead
	var tip_pts: PackedVector2Array = [
		Vector2(10, -4),
		Vector2(20, 0),
		Vector2(10, 4),
		Vector2(12, 0)
	]
	draw_colored_polygon(tip_pts, iron_color)

	# Fletching vanes
	draw_line(Vector2(-14, 0), Vector2(-10, -4), feather_color, 2.0)
	draw_line(Vector2(-14, 0), Vector2(-10, 4), feather_color, 2.0)
