extends SceneTree
## Capturas de PUL-076 desde la cámara de level_01 (registro reproducible; no es parte del juego).
## Uso, desde la raíz del repo:
##   xvfb-run -a godot --path godot --audio-driver Dummy --resolution 1920x1080 \
##     -s "$PWD/docs/evidence/PUL-076/capture_food.gd" -- <out_dir> <prefijo>
## Deja en los huecos de la barra (PassSlot01..09) pulpo crudo/cocido/quemado, cachelos
## crudos/cocidos/quemados y una caja llena con cachelos; J1 sostiene un pulpo crudo. Saca la vista
## completa y un recorte ampliado ×2, sin y con resaltado (contorno) en todos los alimentos.

const OCTOPUS := "res://entities/items/octopus.tscn"
const CACHELOS := "res://entities/items/cachelos.tscn"
const BOX := "res://entities/items/box.tscn"
const RAW := "raw"
const COOKED := "cooked"
const BURNT := "burnt"

var _level: Node
var _out: String
var _prefix: String
var _highlights: Array[Node] = []


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0]
	_prefix = args[1] if args.size() > 1 else "after"
	_level = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
	root.add_child(_level)
	current_scene = _level
	for i in 10:
		await process_frame
	var layout: Array = [
		["PassSlot01", OCTOPUS, RAW],
		["PassSlot02", OCTOPUS, COOKED],
		["PassSlot03", OCTOPUS, BURNT],
		["PassSlot04", BOX, RAW],
		["PassSlot05", CACHELOS, RAW],
		["PassSlot06", CACHELOS, COOKED],
		["PassSlot07", CACHELOS, BURNT],
	]
	for entry: Array in layout:
		var item := (load(entry[1]) as PackedScene).instantiate() as Node3D
		_level.add_child(item)
		# Sin tipos globales: un script -s se analiza antes de registrar los class_name.
		if entry[1] != BOX:
			if entry[2] == COOKED:
				item.call("set_cooked")
			elif entry[2] == BURNT:
				item.call("set_burnt")
		else:
			item.call("toggle_seasoning", load("res://data/seasonings/cachelos.tres"), false)
			item.set("fill", 1.0)
			item.emit_signal("fill_changed", 1.0)
		_level.get_node("Stations/" + entry[0]).call("_store", item)
		_collect(item)
	var player := _level.get_node("Characters/Player1") as Node3D
	player.global_position = Vector3(-4.6, 0.0, 2.2)
	player.rotation.y = PI
	var held := (load(OCTOPUS) as PackedScene).instantiate() as Node3D
	_level.add_child(held)
	player.get_node("%HoldComponent").call("pick_up", held)
	_collect(held)

	await _shot("%s_plain" % _prefix)
	for h: Node in _highlights:
		h.call("show")
	await _shot("%s_highlight" % _prefix)
	quit()


func _collect(item: Node) -> void:
	var h: Node = item.get_node_or_null("%Highlightable")
	if h != null:
		_highlights.append(h)


func _shot(name: String) -> void:
	for i in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(_out + "/level_camera_%s.png" % name)
	var cam := root.get_camera_3d()
	var a := cam.unproject_position(Vector3(-5.6, 1.0, 0.0))
	var b := cam.unproject_position(Vector3(7.0, 1.0, 0.0))
	var rect := Rect2i(int(a.x) - 60, int(a.y) - 190, int(b.x - a.x) + 120, 440)
	var crop := img.get_region(rect.intersection(Rect2i(Vector2i.ZERO, img.get_size())))
	crop.resize(crop.get_width() * 2, crop.get_height() * 2, Image.INTERPOLATE_NEAREST)
	crop.save_png(_out + "/level_camera_%s_zoom.png" % name)
