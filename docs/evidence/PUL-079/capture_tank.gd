extends SceneTree
## Capturas de PUL-079 desde la cámara de level_01 (registro reproducible; no es parte del juego).
## Uso, desde la raíz del repo (o de un worktree con el estado «antes»):
##   xvfb-run -a godot --audio-driver Dummy --path godot --resolution 1920x1080 \
##     -s "$PWD/docs/evidence/PUL-079/capture_tank.gd" -- <out_dir> <prefijo> <plain|highlight>
## `highlight`: OctopusStorage resaltado (contorno de interacción); `plain`: sin resaltar (se apaga
## aunque el jugador 2 empiece apuntándolo). En las dos, un pulpo crudo
## recién sacado en la encimera de al lado (PassSlot01) para comparar con los del tanque.

const OCTOPUS_SCENE := "res://entities/items/octopus.tscn"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0]
	var prefix: String = args[1]
	var mode: String = args[2] if args.size() > 2 else "plain"
	var level: Node = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	for i in 10:
		await process_frame
	var storage: Node3D = level.get_node("Stations/OctopusStorage")
	var slot: Node = level.get_node_or_null("Stations/PassSlot01")
	if slot != null:
		var ing: Node = (load(OCTOPUS_SCENE) as PackedScene).instantiate()
		level.add_child(ing)
		slot.call("_store", ing)
	if mode == "highlight":
		(storage.get_node("%Highlightable") as Highlightable).show()
	for i in 60:
		await process_frame
	if mode == "plain":
		(storage.get_node("%Highlightable") as Highlightable).hide()
		for i in 3:
			await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var tag := "%s_%s" % [prefix, mode]
	img.save_png(out_dir + "/level_camera_%s.png" % tag)
	var cam := root.get_camera_3d()
	var c := cam.unproject_position(storage.global_position + Vector3(0, 0.8, 0))
	var rect := Rect2i(int(c.x) - 260, int(c.y) - 190, 520, 330)
	rect = rect.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	var crop := img.get_region(rect)
	crop.resize(crop.get_width() * 2, crop.get_height() * 2, Image.INTERPOLATE_NEAREST)
	crop.save_png(out_dir + "/level_camera_%s_zoom.png" % tag)
	quit()
