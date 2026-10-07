extends SceneTree
## Staged ART fixture: switches materials, not evidence of delivery gameplay.
const MATERIAL_DIR: String = "res://assets/models/stations/order_stand/"


func _initialize() -> void:
	var output: String = OS.get_cmdline_user_args()[0]
	var level: Node = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	for frame: int in range(30):
		await process_frame
	(level.get_node("Characters/Player1") as Node3D).global_position = Vector3(6.5, 0.005, 3)
	(level.get_node("Characters/Player2") as Node3D).global_position = Vector3(-6, 0.005, -2)
	var camera: Camera3D = root.get_camera_3d()
	print("CAMERA ", camera.global_transform, " size=", camera.size, " viewport=", root.size)
	for mode: String in ["off", "on", "empty_highlight"]:
		for i: int in range(1, 5):
			var stand: Node3D = level.get_node("Stations/OrderStand%d" % i) as Node3D
			var label: Label3D = stand.get_node("OrderLabel") as Label3D
			label.text = "–" if mode == "empty_highlight" else "#%d" % (16 + i)
			var zone: MeshInstance3D = stand.get_node("Model").find_child("delivery_zone", true, false) as MeshInstance3D
			var material_name: String = "delivery_zone_off" if mode != "on" else "delivery_zone_on_%d" % i
			zone.material_override = load(MATERIAL_DIR + material_name + ".tres") as StandardMaterial3D
			if mode == "empty_highlight" and i == 2:
				stand.get_node("Highlightable").call("acquire", self)
		for frame: int in range(10):
			await process_frame
		await RenderingServer.frame_post_draw
		var shot: Image = root.get_texture().get_image()
		shot.save_png(output + "/level_1080_" + mode + ".png")
		# Native pixel crop, never resized.
		shot.get_region(Rect2i(530, 650, 860, 400)).save_png(output + "/kiosks_1x_" + mode + ".png")
	level.queue_free()
	await process_frame
	await process_frame
	quit()
