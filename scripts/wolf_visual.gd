extends Node2D
class_name WolfVisual

# Procedural drawing node for the wilderness Wolf threat.
# Displays distinct poses, eye colors, intent icons, and attack strike effects for each state.

var state_enum: int = 0
var facing_dir: float = -1.0 # Typically faces left toward caravan
var anim_timer: float = 0.0
var strike_timer: float = 0.0
var struggle_timer: float = 0.0

func _process(delta: float) -> void:
	anim_timer += delta
	if strike_timer > 0.0:
		strike_timer -= delta
	if state_enum == 4: # SNARED
		struggle_timer += delta * 15.0
	queue_redraw()

func set_visual_state(new_state_enum: int, facing: float) -> void:
	state_enum = new_state_enum
	facing_dir = facing

func trigger_strike_visual() -> void:
	strike_timer = 0.35

func _draw() -> void:
	var dir: float = 1.0 if facing_dir >= 0.0 else -1.0
	var is_dead: bool = (state_enum == 5)
	var is_snared: bool = (state_enum == 4)
	var is_attacking: bool = (state_enum == 3)
	var is_stalking: bool = (state_enum == 2)
	var is_investigating: bool = (state_enum == 1)

	# Body colors
	var coat_main: Color = Color(0.35, 0.36, 0.38) # Timber grey
	var coat_belly: Color = Color(0.50, 0.51, 0.53) # Light grey underbelly
	var coat_dark: Color = Color(0.24, 0.25, 0.27) # Mane / back ridge
	var eye_color: Color = Color(0.9, 0.8, 0.2) # Default yellow

	if is_dead:
		coat_main = Color(0.25, 0.25, 0.26)
		coat_belly = Color(0.32, 0.32, 0.33)
		coat_dark = Color(0.18, 0.18, 0.19)
	elif is_snared:
		coat_main = Color(0.32, 0.34, 0.36)
	elif is_stalking or is_attacking:
		coat_dark = Color(0.30, 0.18, 0.18) # Reddish aggressive bristles
		eye_color = Color(1.0, 0.2, 0.15) # Fierce red eye
	elif is_investigating:
		eye_color = Color(1.0, 0.9, 0.1) # Bright curious gold

	var shake_x: float = sin(struggle_timer) * 3.0 if is_snared else 0.0
	var stalk_drop_y: float = 8.0 if is_stalking else (12.0 if is_dead else 0.0)
	var lunge_x: float = dir * 14.0 if (is_attacking and strike_timer > 0.1) else 0.0

	# --- 1. Tail ---
	var tail_wag: float = sin(anim_timer * 4.0) * 8.0 if (not is_dead and not is_snared) else 0.0
	var tail_pts: PackedVector2Array = [
		Vector2(dir * (-26 + lunge_x) + shake_x, -24 + stalk_drop_y),
		Vector2(dir * (-46 + lunge_x) + shake_x, -36 + stalk_drop_y + tail_wag),
		Vector2(dir * (-40 + lunge_x) + shake_x, -22 + stalk_drop_y + tail_wag),
		Vector2(dir * (-24 + lunge_x) + shake_x, -16 + stalk_drop_y)
	]
	draw_colored_polygon(tail_pts, coat_dark)

	# --- 2. Back Legs ---
	_draw_wolf_leg(dir, -18 + lunge_x + shake_x, -16 + stalk_drop_y, is_dead, coat_dark)
	_draw_wolf_leg(dir, 14 + lunge_x + shake_x, -16 + stalk_drop_y, is_dead, coat_dark)

	# --- 3. Body Torso & Mane ---
	var body_pts: PackedVector2Array = [
		Vector2(dir * (-25 + lunge_x) + shake_x, -26 + stalk_drop_y),
		Vector2(dir * (-5 + lunge_x) + shake_x, -30 + stalk_drop_y),
		Vector2(dir * (18 + lunge_x) + shake_x, -32 + stalk_drop_y), # Shoulders
		Vector2(dir * (22 + lunge_x) + shake_x, -20 + stalk_drop_y),
		Vector2(dir * (12 + lunge_x) + shake_x, -12 + stalk_drop_y),
		Vector2(dir * (-20 + lunge_x) + shake_x, -12 + stalk_drop_y)
	]
	draw_colored_polygon(body_pts, coat_main)

	# Muscular shoulders / mane
	var mane_pts: PackedVector2Array = [
		Vector2(dir * (-5 + lunge_x) + shake_x, -30 + stalk_drop_y),
		Vector2(dir * (18 + lunge_x) + shake_x, -33 + stalk_drop_y),
		Vector2(dir * (26 + lunge_x) + shake_x, -24 + stalk_drop_y),
		Vector2(dir * (10 + lunge_x) + shake_x, -20 + stalk_drop_y)
	]
	draw_colored_polygon(mane_pts, coat_dark)

	# --- 4. Fore Legs ---
	_draw_wolf_leg(dir, -12 + lunge_x + shake_x, -14 + stalk_drop_y, is_dead, coat_main)
	_draw_wolf_leg(dir, 18 + lunge_x + shake_x, -14 + stalk_drop_y, is_dead, coat_main)

	# --- 5. Wolf Head & Muzzle ---
	var head_center: Vector2 = Vector2(dir * (28 + lunge_x) + shake_x, -30 + stalk_drop_y)
	if is_investigating:
		head_center.y += 10.0 # Sniffing low
	elif is_stalking:
		head_center.y += 6.0
	elif is_dead:
		head_center.y += 18.0

	var snout_pts: PackedVector2Array = [
		head_center + Vector2(dir * -4, -8),
		head_center + Vector2(dir * 18, -2), # Snout tip
		head_center + Vector2(dir * 16, 6),
		head_center + Vector2(dir * -4, 8)
	]
	draw_colored_polygon(snout_pts, coat_main)

	# Nose
	draw_circle(head_center + Vector2(dir * 18, -2), 2.5, Color(0.1, 0.1, 0.1))

	# Ears
	var ear_pts: PackedVector2Array = [
		head_center + Vector2(dir * -6, -8),
		head_center + Vector2(dir * -12, -22),
		head_center + Vector2(dir * 0, -12)
	]
	draw_colored_polygon(ear_pts, coat_dark)

	# Eyes
	var eye_pos: Vector2 = head_center + Vector2(dir * 6, -4)
	if is_dead:
		draw_line(eye_pos + Vector2(-3, -3), eye_pos + Vector2(3, 3), Color.BLACK, 2.0)
		draw_line(eye_pos + Vector2(-3, 3), eye_pos + Vector2(3, -3), Color.BLACK, 2.0)
	else:
		draw_circle(eye_pos, 3.2, eye_color)
		draw_circle(eye_pos + Vector2(dir * 1, 0), 1.6, Color.BLACK)

	# --- 6. Snare Overlay (Vines / Chains when snared) ---
	if is_snared:
		var vine_color: Color = Color(0.75, 0.65, 0.35)
		draw_arc(Vector2(shake_x, -16), 18.0, 0, TAU, 16, vine_color, 3.0)
		draw_line(Vector2(-15 + shake_x, -28), Vector2(15 + shake_x, -8), vine_color, 2.5)
		draw_line(Vector2(15 + shake_x, -28), Vector2(-15 + shake_x, -8), vine_color, 2.5)
		draw_line(Vector2(shake_x, -5), Vector2(shake_x, 2), Color(0.4, 0.3, 0.1), 4.0) # Stake in ground

	# --- 7. Visible Attack Slash Moment ---
	if strike_timer > 0.0:
		var strike_pos: Vector2 = head_center + Vector2(dir * 28, 0)
		draw_arc(strike_pos, 22.0, -PI * 0.4, PI * 0.4, 8, Color(1.0, 0.2, 0.1, 0.9), 5.0)
		draw_circle(strike_pos, 8.0, Color(1.0, 0.9, 0.2, 0.8))

	# --- 8. State Intent Badge ---
	_draw_state_badge(Vector2(0, -65 + stalk_drop_y))

func _draw_wolf_leg(dir: float, x: float, y: float, dead: bool, color: Color) -> void:
	var foot_y: float = 0.0 if not dead else 10.0
	draw_line(Vector2(dir * x, y), Vector2(dir * x, foot_y - 3), color, 4.0)
	draw_line(Vector2(dir * x, foot_y - 3), Vector2(dir * (x + 5), foot_y), color, 4.0)

func _draw_state_badge(pos: Vector2) -> void:
	var label: String = ""
	var tag_color: Color = Color.WHITE
	var bg_color: Color = Color(0.1, 0.1, 0.1, 0.85)

	match state_enum:
		0:
			label = "IDLE"
			tag_color = Color(0.7, 0.7, 0.7)
		1:
			label = "? INVESTIGATE"
			tag_color = Color(1.0, 0.85, 0.2)
		2:
			label = "! STALKING"
			tag_color = Color(1.0, 0.5, 0.2)
		3:
			label = "⚔ ATTACK"
			tag_color = Color(1.0, 0.2, 0.2)
		4:
			label = "⛓ SNARED"
			tag_color = Color(0.4, 0.8, 1.0)
		5:
			label = "💀 DEAD"
			tag_color = Color(0.5, 0.5, 0.5)

	var w: float = 100.0
	var h: float = 20.0
	var rect: Rect2 = Rect2(pos.x - w * 0.5, pos.y - h * 0.5, w, h)
	draw_rect(rect, bg_color)
	draw_rect(rect, tag_color, false, 1.5)
	# State tag symbol mark
	draw_circle(Vector2(rect.position.x + 10, pos.y), 4.0, tag_color)
