extends SceneTree
## Capturas de PUL-052 desde la cámara de level_01 (registro reproducible; no es parte del juego).
## Uso, desde la raíz del repo:
##   xvfb-run -a godot --path godot --resolution 1920x1080 \
##     -s "$PWD/docs/evidence/PUL-052/capture_station.gd" -- <out_dir> <modo>
## Modos:
##   plain              estación vacía, sin nadie alrededor.
##   box                caja llena con picante, sal, aceite y cachelos en la bandeja (pegatinas);
##                      Player1 en el lado de pase y Player2 en el de condimentar.
##   hl_<Nombre>        resalta el dispensador `Dispensers/<Nombre>` o, con `hl_CachelosBowl`,
##                      el cuenco (con 2 raciones); Player2 al lado, con la mano vacía.

const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const MEDIUM: BoxData = preload("res://data/boxes/medium.tres")
const HOT: SeasoningData = preload("res://data/seasonings/hot_paprika.tres")
const SALT: SeasoningData = preload("res://data/seasonings/salt.tres")
const OIL: SeasoningData = preload("res://data/seasonings/oil.tres")


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0]
	var mode: String = args[1] if args.size() > 1 else "plain"
	var level: Node = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	for i in 20:
		await process_frame
	var station := level.get_node("Stations/SeasoningStation") as SeasoningStation
	var p1 := level.get_node("Characters/Player1") as Node3D
	var p2 := level.get_node("Characters/Player2") as Node3D
	p1.global_position = Vector3(6.5, 0.005, 3.0)
	p2.global_position = Vector3(-6.0, 0.005, -2.0)
	var bowl := station.get_node("CachelosBowl") as CachelosBowl
	if mode == "box":
		var box: Box = BOX_SCENE.instantiate()
		box.data = MEDIUM
		level.get_node("Items").add_child(box)
		box.global_position = p1.global_position + Vector3(0.0, 0.5, 0.0)
		box.fill = 1.0
		var hold := p1.get_node("%HoldComponent")
		hold.call("pick_up", box)
		station.get_tray().interact(p1.get_node("%InteractionComponent") as InteractionComponent)
		for s: SeasoningData in [HOT, SALT, OIL]:
			box.toggle_seasoning(s, true)
		box.toggle_seasoning(bowl.seasoning, true)
		p1.global_position = station.global_position + Vector3(0.6, 0.005, -1.2)
		p2.global_position = station.global_position + Vector3(-0.8, 0.005, 1.25)
		p1.rotation.y = 0.0
		p2.rotation.y = PI
	elif mode.begins_with("hl_"):
		var target_name := mode.substr(3)
		var target: Node3D
		if target_name == "CachelosBowl":
			target = bowl
			bowl.stock = 2
			bowl.call("_set_stock", 2)
		else:
			target = station.get_node("Dispensers/" + target_name) as Node3D
		# A un lado del objetivo: delante lo taparía desde esta cámara.
		var side: float = 0.7 if target == bowl else -0.7
		var at_x: float = target.global_position.x + side
		p2.global_position = Vector3(at_x, 0.005, station.global_position.z + 1.25)
		p2.rotation.y = PI
		(target.get_node("%Highlightable") as Highlightable).acquire(self)
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out_dir + "/level_camera_%s.png" % mode)
	var cam := root.get_camera_3d()
	var a := cam.unproject_position(station.to_global(Vector3(-2.3, 2.2, -0.6)))
	var b := cam.unproject_position(station.to_global(Vector3(2.3, 0.0, 1.8)))
	var rect := Rect2i(Vector2i(a), Vector2i(b - a))
	var crop := img.get_region(rect.intersection(Rect2i(Vector2i.ZERO, img.get_size())))
	crop.resize(crop.get_width() * 2, crop.get_height() * 2, Image.INTERPOLATE_NEAREST)
	crop.save_png(out_dir + "/level_camera_%s_zoom.png" % mode)
	quit()
