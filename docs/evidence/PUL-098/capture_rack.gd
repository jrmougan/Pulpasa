extends SceneTree
## Rack y bandejas S/M/L (vacías, a medias y llenas) con la cámara real de level_01.
## Uso: godot --audio-driver Dummy --resolution 1920x1080 -s capture_rack.gd -- <dir absoluto>

var level: Node3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	level = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(level)
	current_scene = level
	for i: int in 10:
		await process_frame
	level.process_mode = Node.PROCESS_MODE_DISABLED
	var zs: Array[float] = [1.75, 2.5, 3.3]
	var sizes: Array[String] = ["small", "medium", "large"]
	var fills: Array[float] = [0.0, 0.5, 1.0]
	for row: int in 3:
		for col: int in 3:
			var item: Node3D = (load("res://entities/items/box.tscn") as PackedScene).instantiate() as Node3D
			item.set("data", load("res://data/boxes/%s.tres" % sizes[col]))
			level.add_child(item)
			item.global_position = Vector3(-4.7 + 0.8 * row, 0.7, zs[col])
			item.set("fill", fills[row])
			item.emit_signal("fill_changed", fills[row])
			(item as RigidBody3D).freeze = true
	for i: int in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	var shot: Image = root.get_texture().get_image()
	shot.save_png(out + "/rack_and_trays_1080.png")
	var cam: Camera3D = root.get_camera_3d()
	var a: Vector2 = cam.unproject_position(Vector3(-6.4, 1.2, 1.4))
	var b: Vector2 = cam.unproject_position(Vector3(-3.0, 0.0, 3.8))
	var rect: Rect2 = Rect2(a, Vector2.ZERO).expand(b).grow(40.0)
	rect = rect.intersection(Rect2(Vector2.ZERO, Vector2(shot.get_size())))
	var crop: Image = shot.get_region(Rect2i(rect))
	crop.resize(crop.get_width() * 2, crop.get_height() * 2, Image.INTERPOLATE_BILINEAR)
	crop.save_png(out + "/rack_and_trays_zoom.png")
	print("CAPTURE RACK OK: ", out, " size_icons=", sizes.map(func(s: String) -> bool: return (load("res://data/boxes/%s.tres" % s) as BoxData).icon != null))
	quit()
