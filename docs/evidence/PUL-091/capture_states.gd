extends SceneTree
## Visual fixture only: staged state, not evidence of interaction or completed orders.
var level: Node
func _initialize() -> void:
	level = load("res://scenes/levels/level_01.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	for i: int in 30:
		await process_frame
	var camera: Camera3D = root.get_camera_3d()
	print("AUDIT camera=", camera.global_transform, " size=", camera.size, " viewport=", root.size)
	for row: int in 3:
		for col: int in 3:
			var box: Box = load("res://entities/items/box.tscn").instantiate() as Box
			box.data = load("res://data/boxes/" + ["small", "medium", "large"][col] + ".tres")
			level.add_child(box)
			box.freeze = true
			box.global_position = Vector3(-2.0 + col * 1.1, 1.3, 1.5 + row * 1.25)
			box.fill = [0.0, 0.5, 1.0][row]
			box.fill_changed.emit(box.fill)
			if row == 1:
				var bar: WorldProgressBar = box.get_node("FillBar") as WorldProgressBar
				bar.visible = true
				bar.set_progress(box.fill)
			if row == 2:
				for condiment: String in ["hot_paprika", "salt", "oil", "cachelos"]:
					box.toggle_seasoning(load("res://data/seasonings/" + condiment + ".tres"), true)
	for i: int in 40:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0] + "/06_estados_controlados.png")
	quit()
