extends SceneTree
## Capturas de PUL-083 desde la cámara de level_01 (registro reproducible; no es parte del juego).
## Uso, desde la raíz del repo (prefijo `before`/`after` en el nombre del fichero):
##   xvfb-run -a godot --audio-driver Dummy --path godot --resolution 1920x1080 \
##     -s "$PWD/docs/evidence/PUL-083/capture_stands.gd" -- <out_dir> <modo> <prefijo>
## Modos:
##   plain   los cuatro puestos vacíos, sin nadie delante.
##   hl      resalta el puesto 2 con Player1 en su zona de entrega (lado de la cocina) y una
##           comanda en el cartel (`%OrderLabel` con `#id`).


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
	var stand := level.get_node("Stations/OrderStand2") as Node3D
	if mode == "hl":
		p1.global_position = stand.global_position + Vector3(0.0, 0.045, -1.2)
		p1.rotation.y = 0.0
		(stand.get_node("%OrderLabel") as Label3D).text = "#7"
		stand.get_node("%Highlightable").call("acquire", self)
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out_dir + "/%s_level_camera_%s.png" % [prefix, mode])
	var cam := root.get_camera_3d()
	var s1 := level.get_node("Stations/OrderStand1") as Node3D
	var s4 := level.get_node("Stations/OrderStand4") as Node3D
	var a := cam.unproject_position(s1.global_position + Vector3(-1.0, 2.3, -1.6))
	var b := cam.unproject_position(s4.global_position + Vector3(1.0, 0.0, 0.6))
	var rect := Rect2i(Vector2i(a), Vector2i(b - a))
	var crop := img.get_region(rect.intersection(Rect2i(Vector2i.ZERO, img.get_size())))
	crop.resize(crop.get_width() * 2, crop.get_height() * 2, Image.INTERPOLATE_NEAREST)
	crop.save_png(out_dir + "/%s_level_camera_%s_zoom.png" % [prefix, mode])
	quit()
