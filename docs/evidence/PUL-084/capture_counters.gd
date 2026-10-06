extends SceneTree
## Capturas de PUL-084 desde la cámara de level_01 (registro reproducible; no es parte del juego).
## Uso, desde la raíz del repo (o de un worktree con el estado «antes»):
##   xvfb-run -a godot --audio-driver Dummy --path godot --resolution 1920x1080 \
##     -s "$PWD/docs/evidence/PUL-084/capture_counters.gd" -- <out_dir> <prefijo> <plain|boxes|highlight>
## `plain`: nivel completo en reposo. `boxes`: cajas de las tres tallas en cuatro huecos del pase.
## `highlight`: PassSlot03 resaltado (retícula) con Player1 delante.
## Además del fichero completo guarda recortes ×2: `_bar` (barra y encimeras del fondo izquierdas),
## `_right` (fondo y pared derecha) y `_front` (pared izquierda, paso inferior y rejillas).
## Luz: la del nivel (PUL-073); el acero metálico se ve oscuro hasta PUL-089 (reflejos).

const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const SIZES: Array[String] = ["small", "medium", "large", "medium"]
const BOX_SLOTS: Array[String] = ["PassSlot01", "PassSlot03", "PassSlot06", "PassSlot08"]
const CROPS := {
	"bar": [Vector3(-7.0, 2.0, -5.0), Vector3(0.5, 0.0, 1.0)],
	"right": [Vector3(0.5, 2.0, -5.0), Vector3(9.5, 0.0, 1.5)],
	"front": [Vector3(-7.0, 2.0, 0.5), Vector3(9.5, 0.0, 6.5)],
}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0]
	var prefix: String = args[1]
	var mode: String = args[2] if args.size() > 2 else "plain"
	var level: Node = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	for i in 20:
		await process_frame
	var p1 := level.get_node("Characters/Player1") as Node3D
	if mode == "boxes":
		for i in BOX_SLOTS.size():
			var slot := level.get_node("Stations/" + BOX_SLOTS[i]) as Node3D
			var box: Node3D = BOX_SCENE.instantiate()
			box.set("data", load("res://data/boxes/%s.tres" % SIZES[i]))
			level.get_node("Items").add_child(box)
			box.global_position = (slot.get_node("%Anchor") as Node3D).global_position
	elif mode == "highlight":
		var slot := level.get_node("Stations/PassSlot03") as Node3D
		p1.global_position = slot.global_position + Vector3(0.0, 0.045, 1.0)
		p1.rotation.y = 0.0
		(slot.get_node("%Highlightable") as Highlightable).acquire(self)
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out_dir + "/%s_level_camera_%s.png" % [prefix, mode])
	var cam := root.get_camera_3d()
	for key: String in CROPS:
		var a := cam.unproject_position(CROPS[key][0])
		var b := cam.unproject_position(CROPS[key][1])
		var rect := Rect2i(Vector2i(a), Vector2i(b - a)).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
		var crop := img.get_region(rect)
		crop.resize(crop.get_width() * 2, crop.get_height() * 2, Image.INTERPOLATE_NEAREST)
		crop.save_png(out_dir + "/%s_level_camera_%s_%s.png" % [prefix, mode, key])
	quit()
