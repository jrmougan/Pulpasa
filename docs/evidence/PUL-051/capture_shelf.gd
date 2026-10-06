extends SceneTree
## Capturas de PUL-051 desde la cámara de level_01 (registro reproducible; no es parte del juego).
## Uso, desde la raíz del repo:
##   xvfb-run -a godot --path godot --resolution 1920x1080 \
##     -s "$PWD/docs/evidence/PUL-051/capture_shelf.gd" -- <out_dir> <plain|small|medium|large>
## Un personaje (Player2) se coloca junto a la estantería para comprobar la escala; `small|medium|large`
## resalta ese spawner.


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0]
	var mode: String = args[1] if args.size() > 1 else "plain"
	var level: Node = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	for i in 10:
		await process_frame
	var shelf := level.get_node("Stations/BoxShelf") as Node3D
	var player := level.get_node("Characters/Player2") as Node3D
	player.global_position = shelf.global_position + Vector3(1.6, 0.005, 1.2)
	if mode != "plain":
		var spawner: Node = shelf.get_node("%sSpawner" % mode.capitalize())
		(spawner.get_node("Highlightable") as Highlightable).acquire(self)
	for i in 30:
		await process_frame
	if mode == "plain":
		# El detector de Player1 puede resaltar un spawner cercano: sin resaltar en esta captura.
		for child in shelf.get_children():
			var h := child.get_node_or_null("Highlightable") as Highlightable
			if h != null:
				h.release(self)
				h.hide()
		for i in 3:
			await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out_dir + "/level_camera_%s.png" % mode)
	var a := root.get_camera_3d().unproject_position(shelf.global_position + Vector3(0, 0.6, 0))
	var rect := Rect2i(int(a.x) - 330, int(a.y) - 330, 660, 560).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	var crop := img.get_region(rect)
	crop.resize(crop.get_width() * 2, crop.get_height() * 2, Image.INTERPOLATE_NEAREST)
	crop.save_png(out_dir + "/level_camera_%s_zoom.png" % mode)
	quit()
