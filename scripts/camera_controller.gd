extends Camera2D
class_name CameraController

# Touch-drag panning and bounded camera controller for 2560x1440 world in 1280x720 viewport.

signal map_tapped(world_pos: Vector2)
signal meaningful_pan_detected

const VIEWPORT_SIZE: Vector2 = Vector2(1280.0, 720.0)
const MAP_SIZE: Vector2 = Vector2(2560.0, 1440.0)

var min_bounds: Vector2 = Vector2(VIEWPORT_SIZE.x * 0.5, VIEWPORT_SIZE.y * 0.5)
var max_bounds: Vector2 = Vector2(MAP_SIZE.x - VIEWPORT_SIZE.x * 0.5, MAP_SIZE.y - VIEWPORT_SIZE.y * 0.5)

var is_dragging: bool = false
var drag_start_pos: Vector2 = Vector2.ZERO
var drag_distance_accum: float = 0.0
var has_emitted_meaningful_pan: bool = false
var is_input_locked: bool = false
var hud_ref: Node = null

func is_locked() -> bool:
	if is_input_locked:
		return true
	if is_instance_valid(hud_ref) and hud_ref.has_method("is_any_modal_open") and hud_ref.is_any_modal_open():
		return true
	return false

func _ready() -> void:
	position = clamp_camera_position(position)

func clamp_camera_position(target: Vector2) -> Vector2:
	return Vector2(
		clamp(target.x, min_bounds.x, max_bounds.x),
		clamp(target.y, min_bounds.y, max_bounds.y)
	)

func recenter(target_pos: Vector2) -> void:
	position = clamp_camera_position(target_pos)

func _unhandled_input(event: InputEvent) -> void:
	if is_locked():
		is_dragging = false
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed:
			is_dragging = true
			drag_start_pos = mouse_event.position
			drag_distance_accum = 0.0
		else:
			if is_dragging:
				is_dragging = false
				# Check if this was a tap rather than a drag
				if drag_distance_accum < 12.0:
					var world_pos := get_screen_center_position() + (mouse_event.position - (VIEWPORT_SIZE * 0.5))
					map_tapped.emit(world_pos)

	elif event is InputEventMouseMotion and is_dragging:
		var motion_event := event as InputEventMouseMotion
		drag_distance_accum += motion_event.relative.length()
		position = clamp_camera_position(position - motion_event.relative)
		if drag_distance_accum > 30.0 and not has_emitted_meaningful_pan:
			has_emitted_meaningful_pan = true
			meaningful_pan_detected.emit()

	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			is_dragging = true
			drag_start_pos = touch_event.position
			drag_distance_accum = 0.0
		else:
			if is_dragging:
				is_dragging = false
				if drag_distance_accum < 12.0:
					var world_pos := get_screen_center_position() + (touch_event.position - (VIEWPORT_SIZE * 0.5))
					map_tapped.emit(world_pos)

	elif event is InputEventScreenDrag and is_dragging:
		var sdrag_event := event as InputEventScreenDrag
		drag_distance_accum += sdrag_event.relative.length()
		position = clamp_camera_position(position - sdrag_event.relative)
		if drag_distance_accum > 30.0 and not has_emitted_meaningful_pan:
			has_emitted_meaningful_pan = true
			meaningful_pan_detected.emit()

func reset_pan_tracking() -> void:
	has_emitted_meaningful_pan = false
	drag_distance_accum = 0.0
	is_dragging = false
	is_input_locked = false
