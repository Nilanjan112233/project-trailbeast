extends SceneTree

# Integrated headless scene runner for bounded frame verification.
# Instantiates main.tscn in the active SceneTree and simulates 180 frames (approx 3 seconds at 60 FPS).

var frame_count: int = 0
var max_frames: int = 180
var main_node: Main = null

func _process(_delta: float) -> bool:
	if not main_node:
		var scene := load("res://scenes/main.tscn") as PackedScene
		main_node = scene.instantiate() as Main
		root.add_child(main_node)
		print("Integrated scene instantiated and added to root window.")

	# On frame 10, dismiss initial PAN_MAP modal (simulating user dismiss tap to resume tree)
	if frame_count == 10 and is_instance_valid(main_node.hud) and main_node.hud.onboarding_overlay.visible:
		main_node.hud._on_onboarding_dismiss_pressed()
		print("Frame 10: Dismissed initial PAN_MAP modal, resuming tree.")

	# On frame 30, test confirming route to woodland
	if frame_count == 30 and main_node.map_manager.can_travel_to("woodland"):
		main_node.map_manager.select_node("woodland")
		main_node._on_route_confirmed("woodland")
		print("Frame 30: Confirmed route travel to Woodland Vale.")

	# On frame 90, test toggling halt/resume
	if frame_count == 90 and main_node.shellback.is_moving:
		main_node.shellback.toggle_movement()
		print("Frame 90: Tested Shellback halt.")

	# On frame 120, resume travel
	if frame_count == 120 and not main_node.shellback.is_moving:
		main_node.shellback.toggle_movement()
		print("Frame 120: Tested Shellback resume.")

	frame_count += 1
	if frame_count >= max_frames:
		print("==================================================")
		print(" INTEGRATED MOVING FORTRESS SCENE RUN COMPLETED")
		print(" Frames Simulated: %d" % frame_count)
		print(" Shellback Pos: (%.1f, %.1f) | HP: %.1f | State: %d | Moving: %s" % [
			main_node.shellback.global_position.x, main_node.shellback.global_position.y,
			main_node.shellback.current_health, int(main_node.shellback.state), str(main_node.shellback.is_moving)
		])
		print(" Current Node: %s | Completed: %s" % [
			main_node.map_manager.current_node_id, str(main_node.map_manager.completed_nodes)
		])
		print(" Resources: Food %d | Wood %d | Salvage %d" % [
			main_node.resources["food"], main_node.resources["wood"], main_node.resources["salvage"]
		])
		print(" Equipped Modules: %s" % str(main_node.shellback.equipped_modules))
		print(" Camera Pos: (%.1f, %.1f)" % [main_node.camera_controller.position.x, main_node.camera_controller.position.y])
		print(" Active Threats: %d" % main_node.threats_container.get_child_count())
		print(" Game Ended: %s" % str(main_node.game_ended))
		print("==================================================")
		quit(0)
		return true

	return false
