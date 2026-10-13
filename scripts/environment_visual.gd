extends Node2D
class_name EnvironmentVisual

# Procedural environment backdrop for the side-view wilderness trail.
# Draws dusky skies, distant mountain silhouettes, rolling hills, footpath, and exit waystone.

var anim_timer: float = 0.0
var exit_x: float = 1120.0
var ground_y: float = 560.0

func _process(delta: float) -> void:
	anim_timer += delta
	queue_redraw()

func _draw() -> void:
	# 1. Sky Gradient (Dusk atmosphere - Long Dusk lore)
	var sky_top: Color = Color(0.18, 0.20, 0.28) # Twilight slate
	var sky_mid: Color = Color(0.38, 0.32, 0.35) # Muted rose dusk
	var sky_bot: Color = Color(0.55, 0.42, 0.32) # Warm horizon amber

	# Sky bands
	draw_rect(Rect2(0, 0, 1280, 240), sky_top)
	draw_rect(Rect2(0, 240, 1280, 160), sky_mid)
	draw_rect(Rect2(0, 400, 1280, 160), sky_bot)

	# Distant sun/moon haze
	draw_circle(Vector2(950, 260), 60.0, Color(1.0, 0.75, 0.45, 0.15))
	draw_circle(Vector2(950, 260), 32.0, Color(1.0, 0.85, 0.60, 0.35))

	# 2. Far Mountain Range
	var mountain_color: Color = Color(0.24, 0.22, 0.28, 0.85)
	var mountain_pts: PackedVector2Array = [
		Vector2(0, 500),
		Vector2(0, 380),
		Vector2(180, 280),
		Vector2(320, 360),
		Vector2(500, 240),
		Vector2(680, 340),
		Vector2(860, 220),
		Vector2(1040, 320),
		Vector2(1200, 260),
		Vector2(1280, 300),
		Vector2(1280, 500)
	]
	draw_colored_polygon(mountain_pts, mountain_color)

	# 3. Midground Rolling Grassy Hills
	var hill_color: Color = Color(0.26, 0.34, 0.22) # Moss pine
	var hill_pts: PackedVector2Array = [
		Vector2(0, 560),
		Vector2(0, 430),
		Vector2(220, 390),
		Vector2(460, 440),
		Vector2(700, 400),
		Vector2(940, 430),
		Vector2(1150, 395),
		Vector2(1280, 420),
		Vector2(1280, 560)
	]
	draw_colored_polygon(hill_pts, hill_color)

	# 4. Foreground Trail & Ground
	var ground_color: Color = Color(0.22, 0.18, 0.14) # Rich dark soil
	var trail_color: Color = Color(0.36, 0.30, 0.22) # Trodden earth path
	var grass_edge: Color = Color(0.32, 0.42, 0.25) # Grass lip

	# Underground fill
	draw_rect(Rect2(0, ground_y, 1280, 720 - ground_y), ground_color)
	# Trail upper band
	draw_rect(Rect2(0, ground_y - 8, 1280, 28), trail_color)
	# Grass verge
	draw_line(Vector2(0, ground_y - 8), Vector2(1280, ground_y - 8), grass_edge, 4.0)

	# Little trail details: stones and grass blades
	for i in range(24):
		var stone_x: float = float(i * 54 + 20)
		draw_circle(Vector2(stone_x, ground_y + 4), 3.0, Color(0.28, 0.24, 0.20))
		draw_line(Vector2(stone_x + 12, ground_y - 8), Vector2(stone_x + 15, ground_y - 16), grass_edge, 2.0)
		draw_line(Vector2(stone_x + 15, ground_y - 8), Vector2(stone_x + 18, ground_y - 14), grass_edge, 1.5)

	# 5. Exit Waystone & Lantern Post at right edge
	_draw_exit_waypoint()

func _draw_exit_waypoint() -> void:
	var stone_color: Color = Color(0.35, 0.34, 0.36)
	var rune_glow: Color = Color(0.4, 0.85, 0.95)
	var wood_color: Color = Color(0.42, 0.30, 0.18)

	# Ancient standing monolith
	var monolith_pts: PackedVector2Array = [
		Vector2(exit_x - 16, ground_y - 4),
		Vector2(exit_x + 16, ground_y - 4),
		Vector2(exit_x + 10, ground_y - 90),
		Vector2(exit_x, ground_y - 105),
		Vector2(exit_x - 10, ground_y - 90)
	]
	draw_colored_polygon(monolith_pts, stone_color)
	draw_polyline(monolith_pts, Color(0.2, 0.2, 0.2), 2.0)

	# Glowing waystone runes
	var pulse: float = 0.7 + 0.3 * sin(anim_timer * 3.0)
	draw_line(Vector2(exit_x, ground_y - 75), Vector2(exit_x, ground_y - 35), Color(rune_glow.r, rune_glow.g, rune_glow.b, pulse), 3.0)
	draw_circle(Vector2(exit_x, ground_y - 80), 5.0 * pulse, rune_glow)

	# Lantern post beside waystone
	draw_line(Vector2(exit_x + 35, ground_y - 4), Vector2(exit_x + 35, ground_y - 110), wood_color, 4.0)
	draw_line(Vector2(exit_x + 35, ground_y - 100), Vector2(exit_x + 55, ground_y - 100), wood_color, 3.0)
	# Hanging lantern
	draw_rect(Rect2(exit_x + 50, ground_y - 98, 10, 14), Color(0.2, 0.2, 0.2))
	draw_circle(Vector2(exit_x + 55, ground_y - 91), 4.5, Color(1.0, 0.75, 0.2, 0.9))

	# Boundary marker line / beacon beam
	draw_line(Vector2(exit_x, 80), Vector2(exit_x, ground_y), Color(0.4, 0.85, 0.95, 0.18), 3.0)
