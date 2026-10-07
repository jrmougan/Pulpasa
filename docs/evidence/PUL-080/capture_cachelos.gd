extends SceneTree
## Capturas de PUL-080 desde la cámara de level_01 (registro reproducible; no es parte del juego).
## Uso, desde la raíz del repo (prefijo `before`/`after` en el nombre del fichero):
##   xvfb-run -a godot --audio-driver Dummy --path godot --resolution 1920x1080 \
##     -s "$PWD/docs/evidence/PUL-080/capture_cachelos.gd" -- <out_dir> <modo> <prefijo>
## Modos:
##   plain   la cachelera sin nadie delante.
##   hl      la cachelera resaltada con Player1 a su lado.


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
	var station := level.get_node("Stations/CachelosStorage") as Node3D
	if mode == "hl":
		# A un lado y algo por delante, para no taparla desde la cámara.
		p1.global_position = station.global_position + Vector3(0.75, 0.005, 0.55)
		var target := station.global_position
		target.y = p1.global_position.y
		p1.look_at(target, Vector3.UP)
		station.get_node("%Highlightable").call("acquire", self)
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out_dir + "/%s_level_camera_%s.png" % [prefix, mode])
	var cam := root.get_camera_3d()
	var c := cam.unproject_position(station.global_position + Vector3(0.0, 0.4, 0.0))
	var rect := Rect2i(Vector2i(c) - Vector2i(200, 150), Vector2i(400, 300))
	var crop := img.get_region(rect.intersection(Rect2i(Vector2i.ZERO, img.get_size())))
	crop.resize(crop.get_width() * 3, crop.get_height() * 3, Image.INTERPOLATE_NEAREST)
	crop.save_png(out_dir + "/%s_level_camera_%s_zoom.png" % [prefix, mode])
	quit()
