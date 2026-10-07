extends SceneTree
## Controlled visual fixture; actual level/camera/holders, not a played round.
var level: Node
var out: String

func _initialize() -> void:
	out = OS.get_cmdline_user_args()[0]
	level = load("res://scenes/levels/level_01.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	for i: int in 30:
		await process_frame
	level.get_node("UI").set("visible", false)
	var cam: Camera3D = root.get_camera_3d()
	print("CAMERA ", cam.global_transform, " size=", cam.size, " viewport=", root.size)
	var threshold: Node3D = load("res://assets/models/furniture/counters/pass_threshold.glb").instantiate()
	level.add_child(threshold)
	threshold.position = Vector3(7.7, 0.0, 0.0)
	for col: int in 3:
		for row: int in 3:
			var box: Box = make_box(col)
			box.freeze = true
			box.global_position = Vector3(-1.8 + col * 1.1, 1.3, 2.0 + row * 1.0)
			box.fill = [0.0, 0.5, 1.0][row]
			box.fill_changed.emit(box.fill)
			if row == 1:
				var bar: WorldProgressBar = box.get_node("FillBar")
				bar.visible = true
				bar.set_progress(box.fill)
			if row == 2:
				box.toggle_seasoning(load("res://data/seasonings/cachelos.tres"), true)
	await shot("01_level_states")
	var rack: Node3D = level.get_node("Stations/BoxShelf")
	var pos: Vector2 = cam.unproject_position(rack.global_position)
	var img: Image = root.get_texture().get_image()
	img.get_region(Rect2i(Vector2i(pos) - Vector2i(100, 180), Vector2i(210, 260))).save_png(out + "/rack_1x.png")
	for size: int in 3:
		for player_index: int in 2:
			var player: Node3D = level.get_node("Characters/Player%d" % (player_index + 1))
			player.global_position = Vector3(-3.8 + player_index * 7.5, 0.05, 2.0)
			player.rotation.y = 0.0 if player_index == 0 else PI
			var holder: Node = player.get_node("%HoldComponent")
			var old: Node = holder.call("get_held_item")
			if old != null:
				holder.call("drop")
				old.queue_free()
			holder.call("pick_up", make_box(size))
		await shot("02_held_" + ["small", "medium", "large"][size])
	print("MONITORS tris=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), " draws=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	quit()

func make_box(size: int) -> Box:
	var box: Box = load("res://entities/items/box.tscn").instantiate()
	box.data = load("res://data/boxes/" + ["small", "medium", "large"][size] + ".tres")
	level.get_node("Items").add_child(box)
	return box

func shot(name: String) -> void:
	for i: int in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out + "/" + name + ".png")
