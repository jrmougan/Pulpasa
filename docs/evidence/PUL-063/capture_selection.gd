extends SceneTree
## PUL-063 AC4: captura el resaltado del detector real en `level_01.tscn` para cada caso de
## `test_m2b_station_selection.gd` (posición frontal a 1,0 m del centro del mostrador).
## Uso (desde la raíz del repo, con pantalla virtual):
##   xvfb-run -a godot --path godot -s "$PWD/docs/evidence/PUL-063/capture_selection.gd"

## Se cargan en `_run()`: con `preload` se compilarían antes de que existan los autoloads.
const LEVEL: String = "res://scenes/levels/level_01.tscn"
const BOX_SCENE: String = "res://entities/items/box.tscn"
const RECIPE: String = "res://data/recipes/individual.tres"
const OUT_DIR: String = "../docs/evidence/PUL-063/"
const DEPTH: float = 1.0
## Recorte alrededor de la estación (px de la ventana) y factor de ampliación.
const CROP: Vector2i = Vector2i(440, 300)
const ZOOM: int = 2

var _level: Node
var _station: Node3D
var _player: Node3D
var _hold: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	_run.call_deferred()


func _run() -> void:
	_level = (load(LEVEL) as PackedScene).instantiate()
	root.add_child(_level)
	_station = _level.get_node("Stations/SeasoningStation")
	_player = _level.get_node("Characters/Player1")
	_hold = _player.get_node("%HoldComponent")
	await _frames(10)
	var box: Node3D = _new_box()
	_hold.call(&"pick_up", box)
	_station.call(&"get_tray").call(&"interact", _player.get_node("%InteractionComponent"))
	var parts: Array[Node3D] = []
	for child: Node in _station.get_node("Dispensers").get_children():
		parts.append(child as Node3D)
	parts.append(_station.get_node("CachelosBowl") as Node3D)
	var index: int = 1
	for part: Node3D in parts:
		await _shot(
			part, 1.0, "%02d-condimentar-%s-caja-en-bandeja" % [index, part.name.to_lower()]
		)
		index += 1
	var tray: Node3D = _station.call(&"get_tray")
	await _shot(tray, 1.0, "%02d-condimentar-mano-vacia-caja" % index)
	await _shot(tray, -1.0, "%02d-pase-mano-vacia-caja" % (index + 1))
	# Coge la caja de la bandeja (como `Slot.interact` con la mano vacía).
	tray.call(&"interact", _player.get_node("%InteractionComponent"))
	await _shot(tray, 1.0, "%02d-condimentar-caja-en-mano-bandeja" % (index + 2))
	await _shot(tray, -1.0, "%02d-pase-caja-en-mano-bandeja" % (index + 3))
	quit()


func _new_box() -> Node3D:
	var box: Node3D = (load(BOX_SCENE) as PackedScene).instantiate()
	box.set(&"data", (load(RECIPE) as Resource).get(&"box"))
	_level.get_node("Items").add_child(box)
	box.global_position = _player.global_position + Vector3(0.0, 0.5, 0.0)
	return box


func _shot(part: Node3D, side: float, file: String) -> void:
	var spot: Vector3 = part.global_position
	spot.z = _station.global_position.z + side * DEPTH
	spot.y = _player.global_position.y
	_player.global_position = spot
	_player.rotation.y = 0.0 if side > 0.0 else PI
	await _frames(6)
	var target: Node = (
		(_player.get_node("%InteractionDetector") as InteractionDetector).get_target()
	)
	print("%s -> %s" % [file, target.name if target != null else "null"])
	var camera: Camera3D = root.get_viewport().get_camera_3d()
	var center: Vector2 = camera.unproject_position(_station.global_position + Vector3.UP)
	var image: Image = root.get_texture().get_image()
	var origin: Vector2i = Vector2i(center) - CROP / 2
	origin = origin.clamp(Vector2i.ZERO, image.get_size() - CROP)
	var crop: Image = image.get_region(Rect2i(origin, CROP))
	crop.resize(CROP.x * ZOOM, CROP.y * ZOOM, Image.INTERPOLATE_NEAREST)
	crop.save_png(OUT_DIR + file + ".png")


func _frames(count: int) -> void:
	for _i: int in count:
		await process_frame
