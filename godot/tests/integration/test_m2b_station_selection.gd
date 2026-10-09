extends GutTest
## PUL-063/097: en `level_01.tscn` real, el detector del jugador elige lo que tiene delante en la
## estación de condimentos al paso (D23). El personaje se coloca de frente a cada pieza (a 0,8–1,2 m
## del centro del mostrador y desplazado ±0,1 m) y se lee el objetivo del `InteractionDetector`
## real,
## sin llamar a `interact()` ni publicar `target_changed`.
## AC1 (R1): con una caja llena en la mano, cada dispensador y el cuenco desde el lado de
## condimentar.
## AC2 (R4): con la mano vacía, ni dispensadores ni cuenco son objetivo, desde los dos lados.
## AC2b (R5): con una caja en la mano desde el pase, ni dispensadores ni cuenco.
## AC8 (R5): con cachelos cocidos en la mano, solo el cuenco, desde los dos lados.

const LEVEL: PackedScene = preload("res://scenes/levels/level_01.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const CACHELOS_SCENE: PackedScene = preload("res://entities/items/cachelos.tscn")
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


## Pone una caja llena en la mano del personaje.
func _box_in_hand() -> Box:
	var box: Box = _new_box()
	box.fill = 1.0
	assert_true(_hold.pick_up(box))
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


# --- AC1 ----------------------------------------------------------------------------------------


func test_ac1_front_of_each_dispenser_and_bowl_selects_it_with_full_box_in_hand() -> void:
	var box: Box = _box_in_hand()
	assert_eq(_parts().size(), 5, "4 dispensadores y el cuenco")
	for part: Node3D in _parts():
		for depth: float in DEPTHS:
			for offset: float in OFFSETS:
				var got: Node = await _target_from(part, 1.0, depth, offset)
				var where: String = "%s a %.1f m, %+.1f" % [part.name, depth, offset]
				assert_eq(got, part, where)
				assert_true(_is_lit(part), "%s resaltado" % where)
				assert_false(_is_lit(box), "%s: la caja de la mano no se resalta" % where)


# --- AC2 -----------------------------------------------------------------------------------------


func _is_station_part(node: Node) -> bool:
	return node is SeasoningDispenser or node is CachelosBowl


func test_ac2_empty_hand_no_dispenser_or_bowl_is_target_from_both_sides() -> void:
	for part: Node3D in _parts():
		for side: float in [1.0, -1.0]:
			for depth: float in DEPTHS:
				for offset: float in OFFSETS:
					var got: Node = await _target_from(part, side, depth, offset)
					var where: String = (
						"%s lado %+d a %.1f m, %+.1f" % [part.name, int(side), depth, offset]
					)
					assert_false(_is_station_part(got), where)
					assert_false(_is_lit(part), "%s: sin resaltar" % where)


func test_ac2_box_in_hand_from_pass_side_no_dispenser_or_bowl_is_target() -> void:
	_box_in_hand()
	for part: Node3D in _parts():
		for depth: float in DEPTHS:
			for offset: float in OFFSETS:
				var got: Node = await _target_from(part, -1.0, depth, offset)
				var where: String = "%s desde el pase a %.1f m, %+.1f" % [part.name, depth, offset]
				assert_false(_is_station_part(got), where)
				assert_false(_is_lit(part), "%s: sin resaltar" % where)


# --- AC8 -----------------------------------------------------------------------------------------


func test_ac8_cooked_cachelos_in_hand_only_the_bowl_is_target_from_both_sides() -> void:
	var cachelos: Ingredient = CACHELOS_SCENE.instantiate()
	_level.get_node("Items").add_child(cachelos)
	cachelos.set_cooked()
	assert_true(_hold.pick_up(cachelos))
	var bowl: Node3D = _station.get_node("CachelosBowl")
	for part: Node3D in _parts():
		for side: float in [1.0, -1.0]:
			for depth: float in DEPTHS:
				for offset: float in OFFSETS:
					var got: Node = await _target_from(part, side, depth, offset)
					var where: String = (
						"%s lado %+d a %.1f m, %+.1f" % [part.name, int(side), depth, offset]
					)
					assert_false(got is SeasoningDispenser, "%s: ningún dispensador" % where)
					if part == bowl:
						assert_eq(got, bowl, where)
						assert_true(_is_lit(bowl), "%s: cuenco resaltado" % where)
