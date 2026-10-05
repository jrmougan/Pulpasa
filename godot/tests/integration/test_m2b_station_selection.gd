extends GutTest
## PUL-063: en `level_01.tscn` real, el detector del jugador elige lo que tiene delante en la
## estación de condimentos. El personaje se coloca de frente a cada pieza (a 0,8–1,2 m del centro
## del mostrador y desplazado ±0,1 m) y se lee el objetivo del `InteractionDetector` real, sin
## llamar a `interact()` ni publicar `target_changed`.
## AC1: con una caja en la bandeja, cada dispensador y el cuenco desde el lado de condimentar.
## AC2: de frente a la bandeja, por los dos lados: mano vacía → la caja; caja en la mano → bandeja.

const LEVEL: PackedScene = preload("res://scenes/levels/level_01.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const RECIPE: RecipeData = preload("res://data/recipes/individual.tres")
## Distancias al centro del mostrador (eje z de la estación) desde las que se prueba (m).
const DEPTHS: Array[float] = [0.8, 1.0, 1.2]
## Desplazamientos laterales respecto a la pieza (m).
const OFFSETS: Array[float] = [-0.1, 0.0, 0.1]
const SETTLE_FRAMES: int = 3

var _level: Node
var _station: SeasoningStation
var _player: Player
var _detector: InteractionDetector
var _hold: Holder


func before_each() -> void:
	GameState.set_paused(false)
	_level = LEVEL.instantiate()
	add_child_autofree(_level)
	_station = _level.get_node("Stations/SeasoningStation")
	_player = _level.get_node("Characters/Player1")
	_detector = _player.get_node("%InteractionDetector")
	_hold = _player.get_node("%HoldComponent")
	await wait_physics_frames(2)


func after_each() -> void:
	GameState.set_paused(false)
	GameState.reset_input()


func _new_box() -> Box:
	var box: Box = BOX_SCENE.instantiate()
	box.data = RECIPE.box
	_level.get_node("Items").add_child(box)
	box.global_position = _player.global_position + Vector3(0.0, 0.5, 0.0)
	return box


## Deja una caja en la bandeja como lo haría el jugador (por `Slot.interact`).
func _box_on_tray() -> Box:
	var box: Box = _new_box()
	assert_true(_hold.pick_up(box))
	assert_true(_station.get_tray().interact(_player.get_node("%InteractionComponent")))
	assert_eq(_station.get_box(), box, "caja en la bandeja")
	return box


## Coloca al personaje en `part.x + offset`, a `depth` m del centro del mostrador por el lado
## `side` (+1 condimentar, −1 pase), mirando al mostrador, y devuelve el objetivo del detector.
func _target_from(part: Node3D, side: float, depth: float, offset: float) -> Node:
	var spot: Vector3 = Vector3(part.global_position.x + offset, 0.0, 0.0)
	spot.z = _station.global_position.z + side * depth
	spot.y = _player.global_position.y
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	# Mira hacia −z desde el servicio (+z) y hacia +z desde la cocina.
	_player.rotation.y = 0.0 if side > 0.0 else PI
	await wait_physics_frames(SETTLE_FRAMES)
	return _detector.get_target()


func _parts() -> Array[Node3D]:
	var parts: Array[Node3D] = []
	for child: Node in _station.get_node("Dispensers").get_children():
		parts.append(child as Node3D)
	parts.append(_station.get_node("CachelosBowl") as Node3D)
	return parts


func _is_lit(node: Node) -> bool:
	for child: Node in node.get_children():
		if child is Highlightable:
			return (child as Highlightable).is_highlighted()
	return false


# --- AC1 -----------------------------------------------------------------------------------------


func test_ac1_front_of_each_dispenser_and_bowl_selects_it_with_box_on_tray() -> void:
	var box: Box = _box_on_tray()
	assert_eq(_parts().size(), 5, "4 dispensadores y el cuenco")
	for part: Node3D in _parts():
		for depth: float in DEPTHS:
			for offset: float in OFFSETS:
				var got: Node = await _target_from(part, 1.0, depth, offset)
				var where: String = "%s a %.1f m, %+.1f" % [part.name, depth, offset]
				assert_eq(got, part, where)
				assert_true(_is_lit(part), "%s resaltado" % where)
				assert_false(_is_lit(box), "%s: la caja no se resalta" % where)


# --- AC2 -----------------------------------------------------------------------------------------


func test_ac2_front_of_tray_with_empty_hand_selects_the_box_from_both_sides() -> void:
	var box: Box = _box_on_tray()
	var tray: Slot = _station.get_tray()
	for side: float in [1.0, -1.0]:
		for depth: float in DEPTHS:
			for offset: float in OFFSETS:
				var got: Node = await _target_from(tray, side, depth, offset)
				var where: String = "lado %+d a %.1f m, %+.1f" % [int(side), depth, offset]
				assert_eq(got, box, where)
				assert_true(_is_lit(box), "%s: caja resaltada" % where)


func test_ac2_front_of_tray_with_box_in_hand_selects_the_tray_from_both_sides() -> void:
	var box: Box = _new_box()
	assert_true(_hold.pick_up(box))
	var tray: Slot = _station.get_tray()
	for side: float in [1.0, -1.0]:
		for depth: float in DEPTHS:
			for offset: float in OFFSETS:
				var got: Node = await _target_from(tray, side, depth, offset)
				var where: String = "lado %+d a %.1f m, %+.1f" % [int(side), depth, offset]
				assert_eq(got, tray, where)
				assert_true(_is_lit(tray), "%s: bandeja resaltada" % where)
