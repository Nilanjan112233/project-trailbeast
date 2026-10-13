extends Node2D
class_name WardenVisual

# Procedural drawing for the Trail Warden scout figure.
# Clean, readable shapes representing a hooded ranger with a traveler staff and satchel.

var walk_cycle: float = 0.0
var is_moving: bool = false
var facing_dir: float = 1.0 # 1.0 = right, -1.0 = left

func _process(delta: float) -> void:
	if is_moving:
		walk_cycle += delta * 10.0
	else:
		walk_cycle = 0.0
	queue_redraw()

func _draw() -> void:
	# Reference coordinate: (0, 0) is ground contact point.
	# Scale horizontally by facing_dir so drawing flips naturally.
	var dir: float = 1.0 if facing_dir >= 0.0 else -1.0
	var bob: float = abs(sin(walk_cycle)) * 4.0 if is_moving else 0.0
	var leg_swing: float = sin(walk_cycle) * 8.0 if is_moving else 0.0

	var cloak_color: Color = Color(0.24, 0.42, 0.32) # Forest cloak
	var cloak_dark: Color = Color(0.18, 0.32, 0.24)
	var tunic_color: Color = Color(0.55, 0.40, 0.25) # Leather tunic
	var boot_color: Color = Color(0.22, 0.16, 0.12)
	var staff_wood: Color = Color(0.45, 0.32, 0.18)
	var charm_glow: Color = Color(0.4, 0.85, 0.95, 0.9) # Wayfinder beacon charm

	# --- 1. Boots & Legs ---
	# Back leg
	draw_line(Vector2(dir * (-4 - leg_swing), -12 + bob), Vector2(dir * (-4 - leg_swing), -2), boot_color, 4.0)
	draw_rect(Rect2(dir * (-7 - leg_swing), -3, 6 * dir, 3), boot_color)
	# Front leg
	draw_line(Vector2(dir * (4 + leg_swing), -12 + bob), Vector2(dir * (4 + leg_swing), -2), boot_color, 4.0)
	draw_rect(Rect2(dir * (1 + leg_swing), -3, 6 * dir, 3), boot_color)

	# --- 2. Tunic / Body ---
	var body_pts: PackedVector2Array = [
		Vector2(dir * -7, -30 + bob),
		Vector2(dir * 7, -30 + bob),
		Vector2(dir * 9, -14 + bob),
		Vector2(dir * -9, -14 + bob)
	]
	draw_colored_polygon(body_pts, tunic_color)
	# Satchel strap
	draw_line(Vector2(dir * -6, -30 + bob), Vector2(dir * 6, -16 + bob), Color(0.3, 0.2, 0.1), 2.0)
	# Satchel bag
	draw_rect(Rect2(dir * 5, -20 + bob, 5 * dir, 7), Color(0.38, 0.25, 0.15))

	# --- 3. Cloak & Cowl ---
	var cloak_pts: PackedVector2Array = [
		Vector2(dir * -8, -32 + bob),
		Vector2(dir * 4, -32 + bob),
		Vector2(dir * -4, -10 + bob),
		Vector2(dir * -12, -10 + bob)
	]
	draw_colored_polygon(cloak_pts, cloak_dark)

	# --- 4. Hooded Head ---
	var hood_pts: PackedVector2Array = [
		Vector2(dir * -8, -32 + bob),
		Vector2(dir * 6, -32 + bob),
		Vector2(dir * 9, -42 + bob),
		Vector2(dir * 0, -48 + bob),
		Vector2(dir * -10, -44 + bob)
	]
	draw_colored_polygon(hood_pts, cloak_color)

	# Shadow inside hood & keen scout eye
	draw_circle(Vector2(dir * 2, -38 + bob), 5.0, Color(0.12, 0.12, 0.12))
	draw_circle(Vector2(dir * 4, -38 + bob), 1.8, Color(0.95, 0.90, 0.75))

	# Hood rim / scarf fold
	draw_line(Vector2(dir * -9, -32 + bob), Vector2(dir * 8, -32 + bob), cloak_dark, 3.0)

	# --- 5. Walking Staff & Beacon ---
	var staff_x: float = dir * 12
	draw_line(Vector2(staff_x, -52 + bob), Vector2(staff_x, 0), staff_wood, 3.0)
	# Carved ring
	draw_arc(Vector2(staff_x, -52 + bob), 5.0, 0, TAU, 12, staff_wood, 2.0)
	# Glowing talisman charm
	draw_circle(Vector2(staff_x, -52 + bob), 3.0, charm_glow)
