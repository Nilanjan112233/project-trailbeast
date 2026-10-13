extends Node2D
class_name WorldHealthBar

# Code-drawn overhead health and state display for game entities.

@export var bar_width: float = 120.0
@export var bar_height: float = 12.0
@export var show_label: bool = true

var current_hp: float = 100.0
var max_hp: float = 100.0
var status_text: String = "ALIVE"
var bar_color: Color = Color(0.2, 0.8, 0.3)

func set_health(hp: float, maximum: float, state_enum_val: int = 0) -> void:
	current_hp = hp
	max_hp = maximum

	if current_hp <= 0.0:
		status_text = "DEAD"
		bar_color = Color(0.4, 0.4, 0.4)
	elif state_enum_val == 1: # Panicked or Investigate depending on entity
		status_text = "ALERT"
		bar_color = Color(0.9, 0.6, 0.1)
	else:
		var ratio: float = current_hp / max(max_hp, 1.0)
		if ratio > 0.5:
			bar_color = Color(0.25, 0.82, 0.35)
			status_text = "HEALTHY"
		elif ratio > 0.25:
			bar_color = Color(0.95, 0.75, 0.15)
			status_text = "INJURED"
		else:
			bar_color = Color(0.9, 0.25, 0.2)
			status_text = "CRITICAL"

	queue_redraw()

func _draw() -> void:
	var left: float = -bar_width * 0.5
	var top: float = -bar_height * 0.5

	# Background drop
	draw_rect(Rect2(left - 2, top - 2, bar_width + 4, bar_height + 4), Color(0.08, 0.08, 0.08, 0.8))
	draw_rect(Rect2(left, top, bar_width, bar_height), Color(0.2, 0.2, 0.2, 0.9))

	# Fill
	var fill_ratio: float = clamp(current_hp / max(max_hp, 1.0), 0.0, 1.0)
	if fill_ratio > 0.0:
		draw_rect(Rect2(left, top, bar_width * fill_ratio, bar_height), bar_color)

	# Border
	draw_rect(Rect2(left - 1, top - 1, bar_width + 2, bar_height + 2), Color(0.85, 0.85, 0.85, 0.6), false, 1.5)
