extends SceneTree
## Capturas de PUL-081 desde la cámara de level_01 (registro reproducible; no es parte del juego).
## Uso, desde la raíz del repo (prefijo `before`/`after` en el nombre del fichero):
##   xvfb-run -a godot --audio-driver Dummy --path godot --resolution 1920x1080 \
##     -s "$PWD/docs/evidence/PUL-081/capture_box_shelf.gd" -- <out_dir> <modo> <prefijo>
## Modos:
##   plain   la estantería sin nadie delante.
##   hl      el spawner mediano resaltado con Player1 delante.
##   hl_all  los tres spawners resaltados a la vez (para ver los tres contornos).


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0]
	var mode: String = args[1] if args.size() > 1 else "plain"
	var prefix: String = args[2] if args.size() > 2 else "after"
	var level: Node = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	for i in 20:
		await process_frame
	var p1 := level.get_node("Characters/Player1") as Node3D
	var p2 := level.get_node("Characters/Player2") as Node3D
	p1.global_position = Vector3(6.5, 0.005, 3.0)
	p2.global_position = Vector3(-6.0, 0.005, -2.0)
	var station := level.get_node("Stations/BoxShelf") as Node3D
	if mode == "hl":
		# Delante del rack (su frente mira a +X del mundo) y algo hacia la cámara, para no taparlo.
		var spawner := station.get_node("MediumSpawner") as Node3D
		p1.global_position = spawner.global_position + Vector3(0.7, 0.0, 0.6)
		p1.global_position.y = 0.005
		var target := spawner.global_position
		target.y = p1.global_position.y
		p1.look_at(target, Vector3.UP)
		spawner.get_node("Highlightable").call("acquire", self)
	elif mode == "hl_all":
		for spawner_name: String in ["SmallSpawner", "MediumSpawner", "LargeSpawner"]:
			station.get_node(spawner_name + "/Highlightable").call("acquire", self)
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out_dir + "/%s_level_camera_%s.png" % [prefix, mode])
	var cam := root.get_camera_3d()
	var c := cam.unproject_position(station.global_position + Vector3(0.4, 0.6, 0.0))
	var rect := Rect2i(Vector2i(c) - Vector2i(200, 160), Vector2i(400, 320))
	var crop := img.get_region(rect.intersection(Rect2i(Vector2i.ZERO, img.get_size())))
	crop.resize(crop.get_width() * 3, crop.get_height() * 3, Image.INTERPOLATE_NEAREST)
	crop.save_png(out_dir + "/%s_level_camera_%s_zoom.png" % [prefix, mode])
	quit()
