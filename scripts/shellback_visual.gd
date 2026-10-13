extends Node2D
class_name ShellbackVisual

# Procedural drawing for the giant Shellback caravan creature.
# Visibly renders the 3 equipped fortress modules (Bolt Launcher, Armour Screen, Storage Rack, Snare Rack).

var walk_cycle: float = 0.0
var is_moving: bool = false
var is_panicked: bool = false
var is_dead: bool = false
var blink_timer: float = 0.0
var equipped_modules: Array[String] = ["bolt_launcher", "armour_screen", "snare_rack"]
var facing_dir: Vector2 = Vector2.RIGHT

func _process(delta: float) -> void:
	if is_moving and not is_dead:
		walk_cycle += delta * (8.0 if is_panicked else 4.0)
	blink_timer += delta
	queue_redraw()

func _draw() -> void:
	# Reference coordinate: (0, 0) is bottom-center ground contact.
	# Shellback faces along facing_dir.
	var flip_h: bool = facing_dir.x < -0.1
	scale.x = -1.0 if flip_h else 1.0

	var bob: float = sin(walk_cycle) * 2.5 if (is_moving and not is_dead) else 0.0
	var leg_swing_1: float = sin(walk_cycle) * 12.0 if (is_moving and not is_dead) else 0.0
	var leg_swing_2: float = cos(walk_cycle) * 12.0 if (is_moving and not is_dead) else 0.0

	var body_color: Color = Color(0.38, 0.32, 0.25)
	var shell_main: Color = Color(0.24, 0.35, 0.22)
	var shell_plate: Color = Color(0.18, 0.27, 0.17)
	var wood_color: Color = Color(0.48, 0.34, 0.20)
	var cloth_color: Color = Color(0.72, 0.65, 0.50)
	var hearth_glow: Color = Color(1.0, 0.6, 0.1, 0.8)

	if is_dead:
		body_color = Color(0.28, 0.28, 0.28)
		shell_main = Color(0.22, 0.22, 0.22)
		shell_plate = Color(0.16, 0.16, 0.16)
		wood_color = Color(0.30, 0.28, 0.26)
		cloth_color = Color(0.40, 0.40, 0.40)
		hearth_glow = Color(0.3, 0.2, 0.1, 0.3)
	elif is_panicked:
		shell_main = Color(0.36, 0.32, 0.20)

	# --- 1. Far Legs (Back layer) ---
	_draw_leg(Vector2(-55, -20), leg_swing_2, body_color * 0.8)
	_draw_leg(Vector2(45, -20), -leg_swing_1, body_color * 0.8)

	# --- 2. Low Tail ---
	var tail_pts: PackedVector2Array = [
		Vector2(-80, -45 + bob),
		Vector2(-105, -35 + bob),
		Vector2(-95, -20 + bob),
		Vector2(-75, -35 + bob)
	]
	draw_colored_polygon(tail_pts, body_color)

	# --- 3. Massive Underbelly & Neck ---
	var neck_pts: PackedVector2Array = [
		Vector2(60, -50 + bob),
		Vector2(95, -60 + bob),
		Vector2(115, -45 + bob),
		Vector2(85, -25 + bob),
		Vector2(55, -25 + bob)
	]
	draw_colored_polygon(neck_pts, body_color)

	# --- 4. Head ---
	var head_center: Vector2 = Vector2(115, -50 + bob)
	draw_circle(head_center, 18.0, body_color)
	var snout_pts: PackedVector2Array = [
		head_center + Vector2(10, -8),
		head_center + Vector2(24, 0),
		head_center + Vector2(15, 12),
		head_center + Vector2(-2, 10)
	]
	draw_colored_polygon(snout_pts, body_color)

	# Eye
	var eye_pos: Vector2 = head_center + Vector2(8, -5)
	if is_dead:
		draw_line(eye_pos + Vector2(-3, -3), eye_pos + Vector2(3, 3), Color.BLACK, 2.0)
		draw_line(eye_pos + Vector2(-3, 3), eye_pos + Vector2(3, -3), Color.BLACK, 2.0)
	elif is_panicked:
		draw_circle(eye_pos, 4.0, Color.WHITE)
		draw_circle(eye_pos + Vector2(1, 0), 2.0, Color.CRIMSON)
	else:
		var blink: bool = fmod(blink_timer, 4.0) < 0.15
		if blink:
			draw_line(eye_pos + Vector2(-3, 0), eye_pos + Vector2(3, 0), Color(0.1, 0.1, 0.1), 2.0)
		else:
			draw_circle(eye_pos, 3.5, Color(0.15, 0.12, 0.10))
			draw_circle(eye_pos + Vector2(1, -1), 1.0, Color.WHITE)

	# --- 5. Great Shell / Carapace ---
	var shell_points: PackedVector2Array = []
	var shell_center: Vector2 = Vector2(-5, -55 + bob)
	var rx: float = 85.0
	var ry: float = 55.0
	for i in range(17):
		var angle: float = PI + (PI * float(i) / 16.0)
		shell_points.append(shell_center + Vector2(cos(angle) * rx, sin(angle) * ry))
	shell_points.append(shell_center + Vector2(rx * 0.9, 10))
	shell_points.append(shell_center + Vector2(-rx * 0.9, 10))
	draw_colored_polygon(shell_points, shell_main)

	# Carapace Plates
	for plate_x in [-50, -20, 15, 45]:
		draw_arc(shell_center + Vector2(plate_x, -10), 28.0, PI + 0.3, TAU - 0.3, 8, shell_plate, 2.5)

	# Outer shell rim
	draw_polyline(shell_points, shell_plate, 3.0)

	# --- MODULE: Armour Screen ---
	if equipped_modules.has("armour_screen") and not is_dead:
		_draw_armour_screen(shell_center)

	# --- 6. Near Legs (Front layer) ---
	_draw_leg(Vector2(-35, -15), leg_swing_1, body_color)
	_draw_leg(Vector2(65, -15), leg_swing_2, body_color)

	# --- 7. Caravan Platform, Cargo & Hearthseed ---
	var plat_y: float = -105 + bob
	draw_line(Vector2(-65, plat_y), Vector2(45, plat_y), wood_color, 6.0)
	draw_line(Vector2(-50, plat_y + 4), Vector2(-50, plat_y + 16), wood_color, 4.0)
	draw_line(Vector2(35, plat_y + 4), Vector2(35, plat_y + 16), wood_color, 4.0)

	# Living Hearthseed brazier
	var brazier_pos: Vector2 = Vector2(-5, plat_y - 12)
	draw_circle(brazier_pos, 7.0, Color(0.2, 0.2, 0.2))
	var glow_pulse: float = 0.8 + 0.2 * sin(blink_timer * 4.0)
	draw_circle(brazier_pos, 5.0 * glow_pulse, hearth_glow)
	draw_circle(brazier_pos, 2.5, Color.WHITE)

	# --- MODULE: Storage Rack ---
	if equipped_modules.has("storage_rack") and not is_dead:
		_draw_storage_rack(plat_y)
	else:
		# Standard canvas pack if no storage rack
		var pack_pts: PackedVector2Array = [
			Vector2(-35, plat_y - 2),
			Vector2(-20, plat_y - 14),
			Vector2(10, plat_y - 14),
			Vector2(20, plat_y - 2)
		]
		draw_colored_polygon(pack_pts, cloth_color)

	# --- MODULE: Bolt Launcher ---
	if equipped_modules.has("bolt_launcher") and not is_dead:
		_draw_bolt_launcher_turret(plat_y)

	# --- MODULE: Snare Rack ---
	if equipped_modules.has("snare_rack") and not is_dead:
		_draw_snare_rack(plat_y)

func _draw_armour_screen(shell_center: Vector2) -> void:
	var bronze := Color(0.65, 0.50, 0.25)
	var rivet := Color(0.25, 0.20, 0.12)
	# Bolted metal screen over carapace flank
	for off_x in [-42.0, -8.0, 26.0]:
		var plate_rect := Rect2(shell_center.x + off_x, shell_center.y - 18, 24, 30)
		draw_rect(plate_rect, bronze)
		draw_rect(plate_rect, rivet, false, 2.0)
		draw_circle(plate_rect.position + Vector2(4, 4), 1.5, rivet)
		draw_circle(plate_rect.position + Vector2(20, 4), 1.5, rivet)
		draw_circle(plate_rect.position + Vector2(4, 26), 1.5, rivet)
		draw_circle(plate_rect.position + Vector2(20, 26), 1.5, rivet)

func _draw_storage_rack(plat_y: float) -> void:
	# Wooden crates and cargo barrels on deck
	var crate_wood := Color(0.55, 0.38, 0.22)
	var crate_rim := Color(0.32, 0.22, 0.14)
	# Crates stack
	draw_rect(Rect2(-40, plat_y - 22, 18, 20), crate_wood)
	draw_rect(Rect2(-40, plat_y - 22, 18, 20), crate_rim, false, 2.0)
	draw_rect(Rect2(-20, plat_y - 18, 14, 16), crate_wood)
	draw_rect(Rect2(-20, plat_y - 18, 14, 16), crate_rim, false, 2.0)
	# Barrel
	draw_circle(Vector2(14, plat_y - 12), 10.0, Color(0.48, 0.32, 0.18))
	draw_circle(Vector2(14, plat_y - 12), 8.0, Color(0.35, 0.25, 0.15))

func _draw_bolt_launcher_turret(plat_y: float) -> void:
	var iron := Color(0.35, 0.38, 0.42)
	var bow_wood := Color(0.40, 0.25, 0.12)
	var turret_pos := Vector2(32, plat_y - 6)
	# Turret swivel mount
	draw_circle(turret_pos, 7.0, iron)
	# Heavy bolt launch rail pointing forward
	draw_line(turret_pos, turret_pos + Vector2(24, -4), iron, 4.0)
	# Crossbow limbs
	draw_line(turret_pos + Vector2(12, -14), turret_pos + Vector2(16, 6), bow_wood, 3.5)

func _draw_snare_rack(plat_y: float) -> void:
	var rope := Color(0.70, 0.62, 0.42)
	var trap_iron := Color(0.25, 0.25, 0.28)
	var rack_pos := Vector2(-58, plat_y - 8)
	# Coiled rope ring
	draw_arc(rack_pos, 8.0, 0, 2 * PI, 12, rope, 3.0)
	# Clamped bear trap jaws
	draw_arc(rack_pos + Vector2(0, -10), 9.0, PI * 0.8, PI * 1.8, 8, trap_iron, 3.5)
	draw_line(rack_pos + Vector2(-6, -10), rack_pos + Vector2(-6, -14), trap_iron, 2.0)
	draw_line(rack_pos + Vector2(6, -10), rack_pos + Vector2(6, -14), trap_iron, 2.0)

func _draw_leg(base_pos: Vector2, swing: float, color: Color) -> void:
	var foot_pos: Vector2 = base_pos + Vector2(swing, 20)
	var leg_pts: PackedVector2Array = [
		base_pos + Vector2(-12, 0),
		base_pos + Vector2(12, 0),
		foot_pos + Vector2(14, 0),
		foot_pos + Vector2(-14, 0)
	]
	draw_colored_polygon(leg_pts, color)
	draw_rect(Rect2(foot_pos.x - 14, foot_pos.y - 4, 28, 6), color * 0.9)
