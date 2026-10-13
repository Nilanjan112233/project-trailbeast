extends Node2D
class_name RaiderVisual

# Procedural rendering for the Raider threat.
# Scavenged armor, spiked iron club, animated windup telegraph, attack swing, and death collapse.

var walk_cycle: float = 0.0
var is_moving: bool = false
var is_telegraphing: bool = false
var is_attacking: bool = false
var is_snared: bool = false
var is_dead: bool = false
var facing_dir: float = -1.0 # Facing left towards Shellback by default

func _process(delta: float) -> void:
	if is_moving and not is_dead and not is_snared:
		walk_cycle += delta * 7.0
	queue_redraw()

func _draw() -> void:
	scale.x = -1.0 if facing_dir > 0 else 1.0

	if is_dead:
		_draw_dead()
		return

	var bob: float = sin(walk_cycle) * 2.0 if is_moving else 0.0
	var leg_swing: float = sin(walk_cycle) * 8.0 if is_moving else 0.0

	var skin_color := Color(0.65, 0.52, 0.42)
	var armor_color := Color(0.28, 0.24, 0.20) # Rough leather
	var iron_color := Color(0.45, 0.45, 0.48) # Scavenged scrap metal
	var cloth_color := Color(0.55, 0.22, 0.18) # Weathered crimson rags

	# Legs
	draw_line(Vector2(-8, 6), Vector2(-8 + leg_swing, 28), armor_color, 5.0)
	draw_line(Vector2(8, 6), Vector2(8 - leg_swing, 28), armor_color, 5.0)

	# Torso & Tunic
	draw_rect(Rect2(-12, -14 + bob, 24, 22), cloth_color)
	draw_rect(Rect2(-10, -12 + bob, 20, 16), armor_color)

	# Head & Spiked Helmet
	draw_circle(Vector2(0, -22 + bob), 9.0, skin_color)
	# Iron helmet
	draw_arc(Vector2(0, -24 + bob), 10.0, PI, 2 * PI, 12, iron_color, 4.0)
	# Spikes / Horns
	draw_line(Vector2(-6, -26 + bob), Vector2(-12, -34 + bob), iron_color, 3.0)
	draw_line(Vector2(6, -26 + bob), Vector2(12, -34 + bob), iron_color, 3.0)

	# Red glow eye slit
	draw_line(Vector2(-4, -22 + bob), Vector2(2, -22 + bob), Color(0.9, 0.1, 0.1), 2.0)

	# Left Hand (Shield)
	var shield_pts: PackedVector2Array = [
		Vector2(10, -18 + bob), Vector2(18, -12 + bob),
		Vector2(18, 4 + bob), Vector2(10, 10 + bob), Vector2(6, -4 + bob)
	]
	draw_colored_polygon(shield_pts, iron_color)

	# Right Hand (Spiked Club / Cleaver)
	if is_telegraphing:
		# Weapon raised high with warning glow
		var glow_color := Color(1.0, 0.4, 0.1, 0.7)
		draw_circle(Vector2(-18, -36 + bob), 12.0, glow_color)
		draw_line(Vector2(-8, -10 + bob), Vector2(-18, -34 + bob), iron_color, 5.0)
		draw_circle(Vector2(-18, -34 + bob), 7.0, iron_color)
	elif is_attacking:
		# Forward cleave swing
		draw_line(Vector2(-6, -6 + bob), Vector2(-28, 4 + bob), iron_color, 6.0)
		draw_circle(Vector2(-28, 4 + bob), 7.0, iron_color)
	else:
		# Resting weapon at side
		draw_line(Vector2(-8, -6 + bob), Vector2(-16, 12 + bob), iron_color, 4.0)
		draw_circle(Vector2(-16, 12 + bob), 6.0, iron_color)

	if is_snared:
		# Snare chains wrapped around legs
		draw_arc(Vector2(0, 20), 14.0, 0, 2 * PI, 16, Color(0.85, 0.7, 0.2), 3.0)

func _draw_dead() -> void:
	var dark := Color(0.25, 0.22, 0.20)
	draw_line(Vector2(-20, 24), Vector2(20, 24), dark, 6.0)
	draw_circle(Vector2(-12, 18), 7.0, dark)
