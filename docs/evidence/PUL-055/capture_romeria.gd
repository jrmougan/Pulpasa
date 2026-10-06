extends SceneTree
## Capturas de PUL-055 desde la cámara de level_01 (registro reproducible; no es parte del juego).
## Uso, desde la raíz del repo:
##   xvfb-run -a godot --path godot --resolution 1920x1080 \
##     -s "$PWD/docs/evidence/PUL-055/capture_romeria.gd" -- <out_dir> <nombre> [sin_entorno]
## Guarda <nombre>.png (vista completa) y tres recortes ampliados: carpa sobre la cocina (`_tent`),
## decoración izquierda (`_west`) y derecha (`_east`). Con `sin_entorno` oculta `Environment/Model`
## para comparar con la vista sin el arte del entorno.


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0]
	var shot: String = args[1] if args.size() > 1 else "level_camera"
	var level: Node = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	var model := level.get_node_or_null("Environment/Model") as Node3D
	if model != null and args.size() > 2 and args[2] == "sin_entorno":
		model.visible = false
	for i in 60:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out_dir + "/%s.png" % shot)
	var size := img.get_size()
	_crop(img, Rect2i(size.x / 4, 0, size.x / 2, size.y * 2 / 5), out_dir + "/%s_tent.png" % shot)
	_crop(img, Rect2i(0, size.y / 5, size.x / 5, size.y * 4 / 5), out_dir + "/%s_west.png" % shot)
	_crop(
		img,
		Rect2i(size.x * 4 / 5, size.y / 5, size.x / 5, size.y * 4 / 5),
		out_dir + "/%s_east.png" % shot
	)
	quit()


func _crop(img: Image, rect: Rect2i, path: String) -> void:
	var crop := img.get_region(rect)
	crop.resize(crop.get_width() * 2, crop.get_height() * 2, Image.INTERPOLATE_NEAREST)
	crop.save_png(path)
