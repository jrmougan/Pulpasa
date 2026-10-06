extends SceneTree
## PUL-073: copia de docs/art/style-refs/capture_style_refs.gd (mismo plano) con tilt-shift opcional.
## Uso: xvfb-run -a godot --audio-driver Dummy --path godot --resolution 1920x1080 -s <este>.gd -- <out_dir> [tiltshift]

const OCTOPUS := "res://entities/items/octopus.tscn"
const BOX := "res://entities/items/box.tscn"
const LARGE := "res://data/boxes/large.tres"
const MEDIUM := "res://data/boxes/medium.tres"
const SEASONINGS := [
	"res://data/seasonings/hot_paprika.tres",
	"res://data/seasonings/salt.tres",
	"res://data/seasonings/oil.tres",
]

var _level: Node


func _initialize() -> void:
	var out_dir: String = OS.get_cmdline_user_args()[0]
	_level = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
	root.add_child(_level)
	if OS.get_cmdline_user_args().has("tiltshift"):
		var env: LevelEnvironment = _level.get_node("Environment") as LevelEnvironment
		var config: RenderConfig = env.config.duplicate() as RenderConfig
		config.tilt_shift_enabled = true
		env.apply(config)
	current_scene = _level
	for i in 30:
		await process_frame
	_stage()
	# Deja que salgan las comandas (retardo de la primera) y se asiente la física.
	for i in 420:
		await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.save_png(out_dir + "/01_nivel_completo.png")
	var ui: CanvasItem = _level.get_node_or_null("UI") as CanvasItem
	if ui == null:
		var layer: Node = _level.get_node_or_null("UI")
		if layer != null:
			layer.set("visible", false)
	else:
		ui.visible = false
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	img = root.get_texture().get_image()
	img.save_png(out_dir + "/00_nivel_sin_hud.png")
	var s: Vector2i = img.get_size()
	_crop(
		img,
		Rect2i(s.x * 22 / 100, s.y * 28 / 100, s.x * 56 / 100, s.y * 30 / 100),
		out_dir + "/02_cocina.png"
	)
	_crop(
		img,
		Rect2i(s.x * 35 / 100, s.y * 52 / 100, s.x * 30 / 100, s.y * 22 / 100),
		out_dir + "/03_estacion_condimentos.png"
	)
	_crop(
		img,
		Rect2i(s.x * 25 / 100, s.y * 72 / 100, s.x * 50 / 100, s.y * 28 / 100),
		out_dir + "/04_puestos_entrega.png"
	)
	_crop(img, Rect2i(0, 0, s.x, s.y * 45 / 100), out_dir + "/05_carpa_y_entorno.png")
	quit()


func _stage() -> void:
	var p1: Node = _level.get_node_or_null("Characters/Player1")
	var p2: Node = _level.get_node_or_null("Characters/Player2")
	var items: Node = _level.get_node_or_null("Items")
	var kitchen: Node = _level.find_child("Kitchen", true, false)
	# J1: mete un pulpo crudo en la olla y se queda con uno cocido en la mano.
	if p1 != null and kitchen != null:
		var actor: Node = p1.get_node_or_null("%InteractionComponent")
		var hold: Node = p1.get_node_or_null("%HoldComponent")
		var raw: Node = (load(OCTOPUS) as PackedScene).instantiate()
		items.add_child(raw)
		if hold.call("pick_up", raw):
			kitchen.call("interact", actor)
		var cooked: Node = (load(OCTOPUS) as PackedScene).instantiate()
		items.add_child(cooked)
		cooked.call("set_cooked")
		hold.call("pick_up", cooked)
	# J2: plato grande lleno y condimentado en la mano.
	if p2 != null:
		var hold2: Node = p2.get_node_or_null("%HoldComponent")
		var box: Node = _make_box(LARGE, items)
		hold2.call("pick_up", box)
	# Plato mediano condimentado en la bandeja de la estación.
	var station: Node = _level.find_child("SeasoningStation", true, false)
	if station != null and station.has_method("get_tray"):
		var tray: Node = station.call("get_tray")
		var box2: Node = _make_box(MEDIUM, items)
		if tray != null and tray.has_method("_store"):
			tray.call("_store", box2)


func _make_box(data_path: String, parent: Node) -> Node:
	var box: Node = (load(BOX) as PackedScene).instantiate()
	box.set("data", load(data_path))
	parent.add_child(box)
	box.set("fill", 1.0)
	box.emit_signal("fill_changed", 1.0)
	for path: String in SEASONINGS:
		box.call("toggle_seasoning", load(path), true)
	return box


func _crop(img: Image, rect: Rect2i, path: String) -> void:
	img.get_region(rect).save_png(path)
