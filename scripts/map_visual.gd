extends Node2D
class_name MapVisual

# Procedural rendering for the 2560x1440 wilderness map.
# Angled top-down elevated presentation with distinct terrain zones, trails, and interactive node markers.

var map_manager: MapManager = null
var pulse_time: float = 0.0

const NODE_RADIUS: float = 46.0

func _process(delta: float) -> void:
	pulse_time += delta * 3.0
	queue_redraw()

func _draw() -> void:
	# 1. Base Terrain Background (2560 x 1440)
	_draw_base_terrain()

	# 2. Distinct Terrain Features (Woodland, Ruins, River, Mountain Pass, Exit Haven)
	_draw_woodland_zone()
	_draw_watchpost_ruins_zone()
	_draw_river_crossing_zone()
	_draw_mountain_pass_zone()
	_draw_exit_haven_zone()

	# 3. Travel Route Trails
	_draw_trails()

	# 4. Route Graph Node Markers & Selection Highlighting
	_draw_nodes()

func _draw_base_terrain() -> void:
	# Main prairie ground
	draw_rect(Rect2(0, 0, 2560, 1440), Color(0.20, 0.24, 0.18))

	# Subtle elevation bands & patches
	var patch_color_1: Color = Color(0.18, 0.22, 0.16)
	var patch_color_2: Color = Color(0.23, 0.27, 0.20)
	draw_rect(Rect2(0, 0, 1300, 700), patch_color_1)
	draw_rect(Rect2(0, 740, 1300, 700), patch_color_2)
	draw_rect(Rect2(1540, 200, 1020, 1040), Color(0.24, 0.26, 0.20))

func _draw_woodland_zone() -> void:
	# Pine grove canopy (Northern branch)
	var grove_rect := Rect2(650, 160, 520, 400)
	draw_rect(grove_rect, Color(0.14, 0.20, 0.14), true)

	# Procedural pine trees
	var tree_coords: Array[Vector2] = [
		Vector2(700, 220), Vector2(780, 190), Vector2(850, 240),
		Vector2(940, 200), Vector2(1020, 230), Vector2(1080, 290),
		Vector2(720, 310), Vector2(800, 340), Vector2(980, 330),
		Vector2(750, 440), Vector2(920, 460), Vector2(1040, 420),
		Vector2(840, 490), Vector2(990, 480), Vector2(1110, 360)
	]
	for pt in tree_coords:
		_draw_pine_tree(pt)

func _draw_pine_tree(pt: Vector2) -> void:
	# Trunk
	draw_line(pt, pt + Vector2(0, 14), Color(0.30, 0.22, 0.14), 4.0)
	# 3 tiered pine needles
	var dark_green := Color(0.12, 0.26, 0.14)
	var light_green := Color(0.16, 0.32, 0.18)
	var pts_1: PackedVector2Array = [pt + Vector2(0, -18), pt + Vector2(-12, -4), pt + Vector2(12, -4)]
	var pts_2: PackedVector2Array = [pt + Vector2(0, -10), pt + Vector2(-16, 4), pt + Vector2(16, 4)]
	var pts_3: PackedVector2Array = [pt + Vector2(0, -2), pt + Vector2(-20, 12), pt + Vector2(20, 12)]
	draw_colored_polygon(pts_3, dark_green)
	draw_colored_polygon(pts_2, light_green)
	draw_colored_polygon(pts_1, light_green)

func _draw_watchpost_ruins_zone() -> void:
	# Cracked stone quarry ground (Southern branch)
	var ruins_rect := Rect2(650, 880, 520, 400)
	draw_rect(ruins_rect, Color(0.24, 0.23, 0.21), true)

	# Stone foundations & broken pillars
	var stone_color := Color(0.42, 0.40, 0.38)
	var shadow_color := Color(0.28, 0.27, 0.25)
	var ruins_positions: Array[Vector2] = [
		Vector2(720, 940), Vector2(800, 910), Vector2(960, 920),
		Vector2(1040, 950), Vector2(740, 1160), Vector2(820, 1200),
		Vector2(950, 1180), Vector2(1060, 1150)
	]
	for rpos in ruins_positions:
		draw_rect(Rect2(rpos - Vector2(16, 16), Vector2(32, 32)), shadow_color)
		draw_rect(Rect2(rpos - Vector2(14, 14), Vector2(28, 28)), stone_color)
		draw_line(rpos - Vector2(10, 0), rpos + Vector2(10, 0), Color(0.2, 0.2, 0.2), 2.0)

	# Broken arches
	draw_arc(Vector2(880, 980), 30.0, PI, 2 * PI, 16, stone_color, 6.0)
	draw_arc(Vector2(880, 1140), 28.0, 0, PI, 16, stone_color, 6.0)

func _draw_river_crossing_zone() -> void:
	# Broad winding river running north-to-south through x=1460
	var river_color := Color(0.18, 0.36, 0.52)
	var deep_water := Color(0.14, 0.28, 0.42)
	var shallow_water := Color(0.25, 0.45, 0.60)

	# River polygon (flowing top to bottom)
	var river_poly: PackedVector2Array = [
		Vector2(1410, 0), Vector2(1510, 0),
		Vector2(1520, 400), Vector2(1490, 720),
		Vector2(1520, 1050), Vector2(1500, 1440),
		Vector2(1400, 1440), Vector2(1420, 1050),
		Vector2(1390, 720), Vector2(1410, 400)
	]
	draw_colored_polygon(river_poly, deep_water)

	# Water flow ripples
	for y_ripple in range(40, 1440, 90):
		var wave_x: float = 1450.0 + sin(y_ripple * 0.05 + pulse_time) * 15.0
		draw_line(Vector2(wave_x - 30, y_ripple), Vector2(wave_x + 30, y_ripple), shallow_water, 3.0)

	# Ford crossing / wooden pylons at (1460, 720)
	draw_rect(Rect2(1380, 700, 160, 40), Color(0.28, 0.40, 0.48, 0.7)) # Ford shallows
	draw_circle(Vector2(1410, 705), 6.0, Color(0.38, 0.26, 0.16)) # Pylon
	draw_circle(Vector2(1410, 735), 6.0, Color(0.38, 0.26, 0.16))
	draw_circle(Vector2(1510, 705), 6.0, Color(0.38, 0.26, 0.16))
	draw_circle(Vector2(1510, 735), 6.0, Color(0.38, 0.26, 0.16))

func _draw_mountain_pass_zone() -> void:
	# Steep jagged canyon cliffs on upper and lower borders funneling x=1750 to 2200
	var cliff_color := Color(0.32, 0.30, 0.28)
	var dark_cliff := Color(0.22, 0.20, 0.18)

	# North canyon wall
	var north_wall: PackedVector2Array = [
		Vector2(1720, 0), Vector2(2200, 0),
		Vector2(2200, 520), Vector2(2080, 560),
		Vector2(1960, 580), Vector2(1840, 560),
		Vector2(1720, 520)
	]
	draw_colored_polygon(north_wall, dark_cliff)
	draw_polyline(north_wall, cliff_color, 4.0)

	# South canyon wall
	var south_wall: PackedVector2Array = [
		Vector2(1720, 1440), Vector2(2200, 1440),
		Vector2(2200, 920), Vector2(2080, 880),
		Vector2(1960, 860), Vector2(1840, 880),
		Vector2(1720, 920)
	]
	draw_colored_polygon(south_wall, dark_cliff)
	draw_polyline(south_wall, cliff_color, 4.0)

func _draw_exit_haven_zone() -> void:
	# Wooden palisade wall around x=2350
	var wood_fence := Color(0.44, 0.32, 0.18)
	draw_line(Vector2(2340, 540), Vector2(2340, 640), wood_fence, 8.0)
	draw_line(Vector2(2340, 800), Vector2(2340, 900), wood_fence, 8.0)
	# Sanctuary beacon / hearth glow
	var beacon_glow := Color(1.0, 0.65, 0.15, 0.35 + sin(pulse_time) * 0.1)
	draw_circle(Vector2(2440, 720), 45.0, beacon_glow)
	draw_circle(Vector2(2440, 720), 16.0, Color(1.0, 0.8, 0.2))

func _draw_trails() -> void:
	var trail_base := Color(0.40, 0.34, 0.24)
	var trail_edge := Color(0.28, 0.24, 0.16)

	var routes: Array[Array] = [
		[Vector2(320, 720), Vector2(560, 520), Vector2(880, 380)],
		[Vector2(320, 720), Vector2(560, 920), Vector2(880, 1060)],
		[Vector2(880, 380), Vector2(1180, 530), Vector2(1460, 720)],
		[Vector2(880, 1060), Vector2(1180, 910), Vector2(1460, 720)],
		[Vector2(1460, 720), Vector2(1710, 720), Vector2(1960, 720)],
		[Vector2(1960, 720), Vector2(2170, 720), Vector2(2380, 720)]
	]

	for route in routes:
		var pts: PackedVector2Array = PackedVector2Array(route)
		draw_polyline(pts, trail_edge, 32.0)
		draw_polyline(pts, trail_base, 24.0)

func _draw_nodes() -> void:
	if not map_manager:
		return

	for node_id in map_manager.nodes.keys():
		var n_data: Dictionary = map_manager.nodes[node_id]
		var pos: Vector2 = n_data.position
		var n_type: int = int(n_data.type)
		var is_completed: bool = map_manager.is_node_completed(node_id)
		var is_current: bool = (map_manager.current_node_id == node_id)
		var is_selected: bool = (map_manager.selected_node_id == node_id)
		var can_reach: bool = map_manager.can_travel_to(node_id)

		# Node fill color
		var fill_color: Color = Color(0.20, 0.22, 0.24)
		match n_type:
			MapManager.NodeType.CAMP:
				fill_color = Color(0.26, 0.38, 0.24) if is_completed else Color(0.22, 0.32, 0.20)
			MapManager.NodeType.RESOURCE:
				fill_color = Color(0.38, 0.32, 0.18) if is_completed else Color(0.32, 0.26, 0.14)
			MapManager.NodeType.HAZARD:
				fill_color = Color(0.42, 0.22, 0.20) if is_completed else Color(0.34, 0.18, 0.16)

		# Outer shadow & core circle
		draw_circle(pos, NODE_RADIUS + 4.0, Color(0.08, 0.08, 0.08, 0.6))
		draw_circle(pos, NODE_RADIUS, fill_color)

		# Border rings
		if is_current:
			# Golden fortress ring for current camp
			draw_arc(pos, NODE_RADIUS + 6.0, 0, 2 * PI, 32, Color(1.0, 0.85, 0.2), 5.0)
			draw_circle(pos + Vector2(0, -NODE_RADIUS - 16.0), 8.0, Color(1.0, 0.85, 0.2))
		elif is_selected:
			# Bright pulsing highlight for selected node
			var pulse: float = sin(pulse_time) * 4.0
			draw_arc(pos, NODE_RADIUS + 8.0 + pulse, 0, 2 * PI, 32, Color(0.2, 0.85, 1.0), 6.0)
		elif can_reach:
			# Pulsing border for valid next destinations
			var pulse: float = sin(pulse_time) * 2.0
			draw_arc(pos, NODE_RADIUS + 4.0 + pulse, 0, 2 * PI, 32, Color(1.0, 1.0, 1.0, 0.85), 3.0)
		elif is_completed:
			# Dim subtle border for completed nodes
			draw_arc(pos, NODE_RADIUS, 0, 2 * PI, 24, Color(0.4, 0.6, 0.4, 0.8), 2.5)
		else:
			# Dim grayed out for distant locked nodes
			draw_arc(pos, NODE_RADIUS, 0, 2 * PI, 24, Color(0.3, 0.3, 0.3, 0.5), 2.0)

		# Node Icon symbol
		_draw_node_icon(pos, n_type, is_completed)

func _draw_node_icon(pos: Vector2, n_type: int, is_completed: bool) -> void:
	var icon_color: Color = Color.WHITE if not is_completed else Color(0.7, 0.9, 0.7)
	match n_type:
		MapManager.NodeType.CAMP:
			# Tent / Shield icon
			var tent: PackedVector2Array = [
				pos + Vector2(0, -18),
				pos + Vector2(-16, 14),
				pos + Vector2(16, 14)
			]
			draw_colored_polygon(tent, icon_color)
			draw_line(pos + Vector2(0, -18), pos + Vector2(0, 14), Color.BLACK, 2.0)
		MapManager.NodeType.RESOURCE:
			# Diamond / Gem icon
			var diamond: PackedVector2Array = [
				pos + Vector2(0, -16),
				pos + Vector2(16, 0),
				pos + Vector2(0, 16),
				pos + Vector2(-16, 0)
			]
			draw_colored_polygon(diamond, icon_color)
		MapManager.NodeType.HAZARD:
			# Crossed swords / Danger skull emblem
			draw_line(pos + Vector2(-14, -14), pos + Vector2(14, 14), Color(1.0, 0.3, 0.3), 4.0)
			draw_line(pos + Vector2(-14, 14), pos + Vector2(14, -14), Color(1.0, 0.3, 0.3), 4.0)
			draw_circle(pos, 8.0, Color(0.9, 0.2, 0.2))
