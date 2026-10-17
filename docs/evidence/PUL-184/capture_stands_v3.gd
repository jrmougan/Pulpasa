extends SceneTree
## PUL-184: capturas de los 4 puestos de entrega con la paleta v3 y los números macizos
## (`#1..#4` en `%OrderLabel`, `1..4` en `StandNumber`) desde la cámara de `level_01`.
## Uso (desde la raíz), una vez por resolución:
##   xvfb-run -a godot --path godot --audio-driver Dummy --resolution 1920x1080 \
##     -s "$PWD/docs/evidence/PUL-184/capture_stands_v3.gd" -- "$PWD/docs/evidence/PUL-184"
##   (ídem con --resolution 800x370)
## Guarda `stands_<WxH>.png` (pantalla completa) y `stands_<WxH>_zoom.png` (recorte ×2 sin
## filtrado de la fila de puestos).


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var out_dir: String = OS.get_cmdline_user_args()[0]
	var level: Node = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	for i: int in 20:
		await process_frame
	# Jugadores fuera del encuadre de los puestos.
	(level.get_node("Characters/Player1") as Node3D).global_position = Vector3(6.0, 0.005, 3.0)
	(level.get_node("Characters/Player2") as Node3D).global_position = Vector3(-6.0, 0.005, 3.0)
	for i: int in range(1, 5):
		var label: Label3D = level.get_node("Stations/OrderStand%d/OrderLabel" % i) as Label3D
		label.text = "#%d" % i
	for i: int in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	var tag: String = "%dx%d" % [img.get_width(), img.get_height()]
	img.save_png(out_dir.path_join("stands_%s.png" % tag))
	# `unproject_position` da coordenadas del viewport lógico (stretch); se pasan a la imagen.
	var to_img: Vector2 = Vector2(img.get_size()) / root.get_visible_rect().size
	var cam: Camera3D = root.get_camera_3d()
	var a: Vector2 = (
		cam.unproject_position((level.get_node("Stations/OrderStand1") as Node3D).global_position)
		* to_img
	)
	var b: Vector2 = (
		cam.unproject_position((level.get_node("Stations/OrderStand4") as Node3D).global_position)
		* to_img
	)
	var scale: float = img.get_height() / 1080.0
	var rect: Rect2i = Rect2i(
		int(minf(a.x, b.x) - 160.0 * scale),
		int(minf(a.y, b.y) - 230.0 * scale),
		int(absf(b.x - a.x) + 320.0 * scale),
		int(260.0 * scale)
	)
	var crop: Image = img.get_region(rect.intersection(Rect2i(Vector2i.ZERO, img.get_size())))
	var factor: int = 2 if scale > 0.5 else 4
	crop.resize(crop.get_width() * factor, crop.get_height() * factor, Image.INTERPOLATE_NEAREST)
	crop.save_png(out_dir.path_join("stands_%s_zoom.png" % tag))
	quit()
