extends SceneTree
## Captura del sandbox de la estación al paso (PUL-097, AC4): modelos de PUL-094, jugador con la
## caja llena en la mano y el cuenco a 0, 2 y 4 raciones. Uso, desde godot/:
## godot --audio-driver Dummy --resolution 1920x1080 -s <ruta>/capture_station.gd -- <carpeta salida>

var sandbox: Node3D
var out: String


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	out = OS.get_cmdline_user_args()[0]
	var scene: PackedScene = load("res://entities/stations/sandbox/seasoning_station_sandbox.tscn")
	sandbox = scene.instantiate() as Node3D
	sandbox.set("staged_cachelos", 0)
	root.add_child(sandbox)
	current_scene = sandbox
	for i: int in 20:
		await process_frame
	var station: Node3D = sandbox.get_node("SeasoningStation")
	var bowl: Node = station.get_node("CachelosBowl")
	var player: Node3D = sandbox.get_node("Player") as Node3D
	player.global_position = Vector3(-0.2, 0.0, 1.5)
	await _shot("bowl_0", bowl)
	for stock: int in [2, 4]:
		var cachelos: Node = (load("res://entities/items/cachelos.tscn") as PackedScene).instantiate()
		sandbox.get_node("Items").add_child(cachelos)
		cachelos.call("set_cooked")
		var held: Node = player.get_node("%HoldComponent").call("get_held_item")
		# El jugador lleva la caja: se deja un momento para echar el cachelo y se vuelve a coger.
		player.get_node("%HoldComponent").call("drop")
		player.get_node("%HoldComponent").call("pick_up", cachelos)
		bowl.call("interact", player.get_node("%InteractionComponent"))
		player.get_node("%HoldComponent").call("pick_up", held)
		await _shot("bowl_%d" % stock, bowl)
	print("CAPTURE STATION OK: ", out)
	quit()


func _shot(label: String, bowl: Node) -> void:
	for i: int in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	var shot: Image = root.get_texture().get_image()
	shot.save_png(out + "/sandbox_%s_1080.png" % label)
	var cam: Camera3D = root.get_camera_3d()
	var top_left: Vector2 = cam.unproject_position(Vector3(-3.0, 2.4, -0.9))
	var bottom_right: Vector2 = cam.unproject_position(Vector3(3.0, 0.0, 2.2))
	var rect: Rect2 = Rect2(top_left, Vector2.ZERO).expand(bottom_right)
	rect = rect.intersection(Rect2(Vector2.ZERO, Vector2(shot.get_size())))
	var crop: Image = shot.get_region(Rect2i(rect))
	crop.resize(crop.get_width() * 2, crop.get_height() * 2, Image.INTERPOLATE_NEAREST)
	crop.save_png(out + "/sandbox_%s_zoom.png" % label)
	var near: Rect2 = Rect2(cam.unproject_position(Vector3(1.0, 1.9, -0.5)), Vector2.ZERO)
	near = near.expand(cam.unproject_position(Vector3(3.0, 0.9, 0.9)))
	near = near.intersection(Rect2(Vector2.ZERO, Vector2(shot.get_size())))
	var bowl_crop: Image = shot.get_region(Rect2i(near))
	bowl_crop.resize(bowl_crop.get_width() * 5, bowl_crop.get_height() * 5, Image.INTERPOLATE_NEAREST)
	bowl_crop.save_png(out + "/sandbox_%s_bowl.png" % label)
	print("stock=", bowl.get("stock"), " ", label)
