extends SceneTree
## Capturas de PUL-054 (registro reproducible; no es parte del juego). Uso, desde la raíz del repo:
##   xvfb-run -a godot --path godot --resolution 1920x1080 \
##     -s "$PWD/docs/evidence/PUL-054/capture_counters.gd" -- <out_dir> <modo>
## Modos:
##   plain   level_01 desde su cámara, sin objetos; recortes ×2 de la barra, la esquina de la
##           nevera con la estantería de cajas y el extremo de la barra junto al hueco.
##   boxes   cajas de los tres tamaños en cuatro huecos del pasaplatos, con los personajes.
##   scale   el kit en fila en scale_check.tscn junto al cubo de 1 m (AC1).

const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const BOXES: Array[BoxData] = [
	preload("res://data/boxes/small.tres"),
	preload("res://data/boxes/medium.tres"),
	preload("res://data/boxes/large.tres"),
]
const KIT := "res://assets/models/furniture/counters/"
const PIECES: Array[String] = [
	"counter_1m",
	"counter_2m",
	"counter_3m",
	"counter_half",
	"counter_corner",
	"counter_end",
	"pass_1m",
	"pass_2m",
	"pass_3m",
	"pass_end",
	"rail_1m",
]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0]
	var mode: String = args[1] if args.size() > 1 else "plain"
	if mode == "scale":
		await _capture_scale(out_dir)
		quit()
		return
	var level: Node = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	for i in 20:
		await process_frame
	if mode == "boxes":
		var p1 := level.get_node("Characters/Player1") as Node3D
		var slots: Array[String] = ["PassSlot02", "PassSlot03", "PassSlot05", "PassSlot07"]
		for i: int in slots.size():
			var slot := level.get_node("Stations/" + slots[i]) as Slot
			var box: Box = BOX_SCENE.instantiate()
			box.data = BOXES[i % BOXES.size()]
			level.get_node("Items").add_child(box)
			box.global_position = slot.global_position + Vector3(0.0, 1.5, 1.0)
			var hold := p1.get_node("%HoldComponent")
			p1.global_position = slot.global_position + Vector3(0.0, 0.005, 1.1)
			hold.call("pick_up", box)
			slot.interact(p1.get_node("%InteractionComponent") as InteractionComponent)
		p1.global_position = Vector3(3.2, 0.005, 1.3)
		p1.rotation.y = 0.0
		(level.get_node("Characters/Player2") as Node3D).global_position = Vector3(
			-3.8, 0.005, -1.3
		)
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out_dir + "/level_camera_%s.png" % mode)
	var cam := root.get_camera_3d()
	_zoom(img, cam, Vector3(-6.9, 1.8, -0.6), Vector3(0.2, 0.0, 1.0), out_dir, mode + "_bar_left")
	_zoom(img, cam, Vector3(1.8, 1.8, -0.6), Vector3(9.3, 0.0, 1.0), out_dir, mode + "_bar_right")
	if mode == "plain":
		_zoom(
			img,
			cam,
			Vector3(-7.0, 1.6, -4.6),
			Vector3(-3.5, 0.0, 4.0),
			out_dir,
			"plain_corner_shelf"
		)
		_zoom(
			img, cam, Vector3(5.5, 1.6, -4.6), Vector3(9.3, 0.0, 6.6), out_dir, "plain_corner_right"
		)
	quit()


func _zoom(
	img: Image, cam: Camera3D, a3: Vector3, b3: Vector3, out_dir: String, tag: String
) -> void:
	var a := cam.unproject_position(a3)
	var b := cam.unproject_position(b3)
	var rect := Rect2i(Vector2i(a), Vector2i(b - a)).abs()
	var crop := img.get_region(rect.intersection(Rect2i(Vector2i.ZERO, img.get_size())))
	crop.resize(crop.get_width() * 2, crop.get_height() * 2, Image.INTERPOLATE_NEAREST)
	crop.save_png(out_dir + "/level_camera_%s_zoom.png" % tag)


func _capture_scale(out_dir: String) -> void:
	var check: Node3D = (load("res://scenes/scale_check.tscn") as PackedScene).instantiate()
	root.add_child(check)
	current_scene = check
	# Dos filas sobre la cuadrícula (encimeras delante, pasaplatos y barrera detrás), separadas
	# 0,5 m y giradas 180° para enseñar el frente (−Z del modelo) a la cámara.
	var x_by_row: Array[float] = [-6.0, -6.0]
	for piece: String in PIECES:
		var node := (load(KIT + piece + ".glb") as PackedScene).instantiate() as Node3D
		var length := 1.0
		if piece.ends_with("2m"):
			length = 2.0
		elif piece.ends_with("3m"):
			length = 3.0
		elif piece.ends_with("half"):
			length = 0.5
		var row := 0 if piece.begins_with("counter") else 1
		node.position = Vector3(x_by_row[row] + length / 2.0, 0.0, 1.5 - 2.5 * row)
		node.rotation.y = PI
		check.add_child(node)
		x_by_row[row] += length + 0.5
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir + "/scale_check.png")
