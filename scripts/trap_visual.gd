extends Node2D
class_name TrapVisual

# Procedural drawing node for Bait and Snare ground tools.

var trap_type_enum: int = 0 # 0 = BAIT, 1 = SNARE
var anim_timer: float = 0.0
var is_triggered: bool = false
var is_consumed: bool = false

func _process(delta: float) -> void:
	anim_timer += delta
	queue_redraw()

func _draw() -> void:
	if trap_type_enum == 0:
		_draw_bait()
	else:
		_draw_snare()

func _draw_bait() -> void:
	# Wooden forage bowl
	var bowl_color: Color = Color(0.42, 0.28, 0.16)
	var meat_color: Color = Color(0.72, 0.22, 0.20)
	var berry_color: Color = Color(0.85, 0.15, 0.45)

	if is_consumed:
		bowl_color.a = 0.4
		meat_color.a = 0.4
		berry_color.a = 0.4

	# Bowl ellipse
	draw_rect(Rect2(-14, -8, 28, 8), bowl_color)
	draw_arc(Vector2(0, -4), 14.0, 0, PI, 12, bowl_color, 3.0)

	# Meat chunks & berries
	draw_circle(Vector2(-5, -9), 5.0, meat_color)
	draw_circle(Vector2(4, -8), 4.5, meat_color * 0.9)
	draw_circle(Vector2(0, -12), 3.0, berry_color)
	draw_circle(Vector2(7, -10), 2.5, berry_color)

	# Rising aromatic scent rings (attraction beacon)
	if not is_consumed:
		for i in range(3):
			var wave_t: float = fmod(anim_timer * 1.5 + float(i) * 0.6, 2.0)
			var wave_alpha: float = clamp(1.0 - (wave_t / 2.0), 0.0, 0.7)
			var wave_y: float = -14.0 - (wave_t * 22.0)
			var wave_spread: float = 10.0 + (wave_t * 12.0)
			draw_arc(Vector2(0, wave_y), wave_spread, -PI * 0.8, -PI * 0.2, 8, Color(1.0, 0.85, 0.3, wave_alpha), 2.0)

func _draw_snare() -> void:
	var wire_color: Color = Color(0.75, 0.72, 0.68)
	var stake_color: Color = Color(0.38, 0.26, 0.15)

	if is_triggered:
		wire_color = Color(0.9, 0.4, 0.2)

	# Wooden ground stakes
	draw_line(Vector2(-18, 0), Vector2(-18, -12), stake_color, 4.0)
	draw_line(Vector2(18, 0), Vector2(18, -12), stake_color, 4.0)

	# Coiled loop wire
	if is_triggered:
		# Snapped shut
		draw_line(Vector2(-18, -10), Vector2(0, -18), wire_color, 3.0)
		draw_line(Vector2(18, -10), Vector2(0, -18), wire_color, 3.0)
		draw_circle(Vector2(0, -18), 4.0, wire_color)
	else:
		# Open spring loop
		draw_arc(Vector2(0, -6), 18.0, PI * 0.1, PI * 0.9, 12, wire_color, 2.5)
		draw_line(Vector2(-18, -8), Vector2(-12, -4), wire_color, 2.0)
		draw_line(Vector2(18, -8), Vector2(12, -4), wire_color, 2.0)
		# Subtle trigger glint
		var glint: float = 0.5 + 0.5 * sin(anim_timer * 3.0)
		draw_circle(Vector2(0, -3), 2.5, Color(1.0, 1.0, 1.0, glint))
