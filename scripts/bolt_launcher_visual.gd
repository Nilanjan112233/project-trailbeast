extends Node2D
class_name BoltLauncherVisual

# Procedural drawing node for the caravan-mounted Bolt Launcher module.

var recoil_offset: float = 0.0

func trigger_recoil() -> void:
	recoil_offset = -6.0

func _process(delta: float) -> void:
	if recoil_offset < 0.0:
		recoil_offset = min(0.0, recoil_offset + delta * 24.0)
		queue_redraw()

func _draw() -> void:
	var wood_base: Color = Color(0.38, 0.26, 0.15)
	var bow_wood: Color = Color(0.52, 0.38, 0.22)
	var iron_fittings: Color = Color(0.25, 0.26, 0.28)
	var string_color: Color = Color(0.85, 0.85, 0.80)

	# Mounting bracket
	draw_rect(Rect2(-12, -4, 24, 6), wood_base)
	draw_rect(Rect2(-8, -10, 16, 6), iron_fittings)

	# Swivel stock (shifts during recoil)
	var stock_x: float = recoil_offset
	draw_line(Vector2(-14 + stock_x, -14), Vector2(16 + stock_x, -14), iron_fittings, 5.0)

	# Twin prod / bow limbs
	var bow_center: Vector2 = Vector2(8 + stock_x, -14)
	draw_arc(bow_center, 16.0, -PI * 0.45, PI * 0.45, 10, bow_wood, 3.5)

	# Bowstring
	var top_tip: Vector2 = bow_center + Vector2(cos(-PI * 0.45), sin(-PI * 0.45)) * 16.0
	var bot_tip: Vector2 = bow_center + Vector2(cos(PI * 0.45), sin(PI * 0.45)) * 16.0
	var notch_pos: Vector2 = Vector2(-8 + stock_x, -14)
	draw_line(top_tip, notch_pos, string_color, 1.5)
	draw_line(bot_tip, notch_pos, string_color, 1.5)
