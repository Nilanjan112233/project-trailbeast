extends RefCounted
class_name MapManager

# Route graph, node definitions, and path navigation for Moving Fortress prototype.
# Map dimensions: 2560 x 1440 world units.

const MAP_SIZE: Vector2 = Vector2(2560.0, 1440.0)

enum NodeType {
	CAMP,
	RESOURCE,
	HAZARD
}

var nodes: Dictionary = {
	"start_camp": {
		"id": "start_camp",
		"name": "Starting Camp",
		"type": NodeType.CAMP,
		"position": Vector2(320.0, 720.0),
		"connections": ["woodland", "watchpost"],
		"rewards": {"food": 0, "wood": 0, "salvage": 0},
		"threat": "Safe Haven",
		"terrain_effect": "Fortified perimeter. Workshop facilities for module configuration."
	},
	"woodland": {
		"id": "woodland",
		"name": "Woodland Vale",
		"type": NodeType.RESOURCE,
		"position": Vector2(880.0, 380.0),
		"connections": ["river_crossing"],
		"rewards": {"food": 15, "wood": 10, "salvage": 0},
		"threat": "Low (Lone Wolf)",
		"terrain_effect": "Dense pine canopy. Soft loam trails favour defensive movement."
	},
	"watchpost": {
		"id": "watchpost",
		"name": "Ruined Watchpost",
		"type": NodeType.RESOURCE,
		"position": Vector2(880.0, 1060.0),
		"connections": ["river_crossing"],
		"rewards": {"food": 0, "wood": 10, "salvage": 25},
		"threat": "High (Raider Ambush)",
		"terrain_effect": "Crumbling stone masonry. High salvage value with ambush danger."
	},
	"river_crossing": {
		"id": "river_crossing",
		"name": "River Crossing",
		"type": NodeType.CAMP,
		"position": Vector2(1460.0, 720.0),
		"connections": ["final_pass"],
		"rewards": {"food": 5, "wood": 5, "salvage": 5},
		"threat": "Moderate (River Ford)",
		"terrain_effect": "Shallow water crossing. Brief respite to repair shell or hurry."
	},
	"final_pass": {
		"id": "final_pass",
		"name": "The Narrow Pass",
		"type": NodeType.HAZARD,
		"position": Vector2(1960.0, 720.0),
		"connections": ["exit_camp"],
		"rewards": {"food": 10, "wood": 0, "salvage": 15},
		"threat": "Extreme (Combined Assault)",
		"terrain_effect": "Steep rocky chokepoint funneling predators and raiders."
	},
	"exit_camp": {
		"id": "exit_camp",
		"name": "Exit Haven",
		"type": NodeType.CAMP,
		"position": Vector2(2380.0, 720.0),
		"connections": [],
		"rewards": {"food": 20, "wood": 20, "salvage": 20},
		"threat": "Safe Sanctuary",
		"terrain_effect": "Eastern valley haven. Journey complete upon arrival."
	}
}

var current_node_id: String = "start_camp"
var selected_node_id: String = ""
var completed_nodes: Array[String] = ["start_camp"]
var route_history: Array[String] = ["start_camp"]
var is_traveling: bool = false

func _init() -> void:
	reset()

func reset() -> void:
	current_node_id = "start_camp"
	selected_node_id = ""
	completed_nodes = ["start_camp"]
	route_history = ["start_camp"]
	is_traveling = false

func get_node(node_id: String) -> Dictionary:
	return nodes.get(node_id, {})

func are_nodes_connected(from_id: String, to_id: String) -> bool:
	var from_node: Dictionary = nodes.get(from_id, {})
	if from_node.is_empty():
		return false
	var connections: Array = from_node.get("connections", [])
	return connections.has(to_id)

func is_node_completed(node_id: String) -> bool:
	return completed_nodes.has(node_id)

func can_travel_to(node_id: String) -> bool:
	if is_traveling:
		return false
	if not nodes.has(node_id):
		return false
	if is_node_completed(node_id):
		return false
	return are_nodes_connected(current_node_id, node_id)

func select_node(node_id: String) -> bool:
	if not nodes.has(node_id):
		selected_node_id = ""
		return false
	selected_node_id = node_id
	return true

func is_selected_reachable() -> bool:
	if selected_node_id.is_empty():
		return false
	return can_travel_to(selected_node_id)

func confirm_route() -> Array[Vector2]:
	if is_traveling or not is_selected_reachable():
		return []
	is_traveling = true
	var dest_id: String = selected_node_id
	var waypoints: Array[Vector2] = get_waypoints(current_node_id, dest_id)
	return waypoints

func complete_node(node_id: String) -> Dictionary:
	is_traveling = false
	if not nodes.has(node_id):
		return {}
	if is_node_completed(node_id):
		return {}
	completed_nodes.append(node_id)
	route_history.append(node_id)
	current_node_id = node_id
	selected_node_id = ""
	return nodes[node_id].get("rewards", {}).duplicate()

func is_current_node_camp() -> bool:
	var node: Dictionary = get_node(current_node_id)
	return int(node.get("type", -1)) == NodeType.CAMP

func is_victory() -> bool:
	return current_node_id == "exit_camp"

func get_waypoints(from_id: String, to_id: String) -> Array[Vector2]:
	var from_pos: Vector2 = nodes[from_id].position
	var to_pos: Vector2 = nodes[to_id].position

	# Natural curved paths with intermediate control points
	if from_id == "start_camp" and to_id == "woodland":
		return [from_pos, Vector2(560.0, 520.0), to_pos]
	elif from_id == "start_camp" and to_id == "watchpost":
		return [from_pos, Vector2(560.0, 920.0), to_pos]
	elif from_id == "woodland" and to_id == "river_crossing":
		return [from_pos, Vector2(1180.0, 530.0), to_pos]
	elif from_id == "watchpost" and to_id == "river_crossing":
		return [from_pos, Vector2(1180.0, 910.0), to_pos]
	elif from_id == "river_crossing" and to_id == "final_pass":
		return [from_pos, Vector2(1710.0, 720.0), to_pos]
	elif from_id == "final_pass" and to_id == "exit_camp":
		return [from_pos, Vector2(2170.0, 720.0), to_pos]

	# Default direct line if not explicitly mapped
	return [from_pos, to_pos]
