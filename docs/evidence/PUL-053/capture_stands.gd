extends SceneTree
## Capturas de PUL-053 desde la cámara de level_01 (registro reproducible; no es parte del juego).
## Uso, desde la raíz del repo:
##   xvfb-run -a godot --path godot --resolution 1920x1080 \
##     -s "$PWD/docs/evidence/PUL-053/capture_stands.gd" -- <out_dir> <plain|highlight>
## Los cuatro puestos con su número y con comandas vivas (`#id`). En `highlight`, Player1 se pone
## detrás del puesto 2 con una caja en la mano (entregando) y ese puesto se resalta.


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0]
	var mode: String = args[1] if args.size() > 1 else "plain"
	var level: Node = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	for i in 20:
		await process_frame
	var stand := level.get_node("Stations/OrderStand2") as Node3D
	var player := level.get_node("Characters/Player1") as Node3D
	var p2 := level.get_node("Characters/Player2") as Node3D
	p2.global_position = (
		level.get_node("Stations/OrderStand1").global_position + Vector3(0.9, 0.005, -1.4)
	)
	if mode == "highlight":
		player.global_position = stand.global_position + Vector3(0.2, 0.005, -1.5)
		var box := (load("res://entities/items/box.tscn") as PackedScene).instantiate()
		level.get_node("Items").add_child(box)
		var hold := player.get_node("%HoldComponent")
		hold.call("pick_up", box)
		(stand.get_node("%Highlightable") as Highlightable).acquire(self)
	else:
		player.global_position = Vector3(6.0, 0.005, 3.0)
	# Si aún no hay comandas vivas, se rellena el `#id` a mano para ver cómo se lee sobre el cartel.
	for i in range(1, 5):
		var label := level.get_node("Stations/OrderStand%d/OrderLabel" % i) as Label3D
		if label.text == "–" and i != 4:
			label.text = "#%d" % (i * 6 + 1)
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out_dir + "/level_camera_%s.png" % mode)
	var cam := root.get_camera_3d()
	var a := cam.unproject_position(level.get_node("Stations/OrderStand1").global_position)
	var b := cam.unproject_position(level.get_node("Stations/OrderStand4").global_position)
	var rect := Rect2i(int(a.x) - 160, int(a.y) - 260, int(b.x - a.x) + 320, 340)
	var crop := img.get_region(rect.intersection(Rect2i(Vector2i.ZERO, img.get_size())))
	crop.resize(crop.get_width() * 2, crop.get_height() * 2, Image.INTERPOLATE_NEAREST)
	crop.save_png(out_dir + "/level_camera_%s_zoom.png" % mode)
	quit()
