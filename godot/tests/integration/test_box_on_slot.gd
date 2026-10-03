extends GutTest
## PUL-016 (revisión): caja sobre la mesa con escenas reales (Player + Slot + Box) y la ruta de
## input completa (`InteractionDetector` → `InteractionComponent.interact_pressed`). El detector
## sustituye el slot ocupado por la caja (InteractionDetector.cs:57) y la caja decide.

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const SLOT_SCENE: PackedScene = preload("res://entities/stations/slot.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const SEASONING_SCENE: PackedScene = preload("res://entities/items/seasoning.tscn")
const SMALL: BoxData = preload("res://data/boxes/small.tres")
const MEDIUM: BoxData = preload("res://data/boxes/medium.tres")
const LARGE: BoxData = preload("res://data/boxes/large.tres")
const SALT: SeasoningData = preload("res://data/seasonings/salt.tres")
const INTERACTABLE_LAYER: int = 1 << 2
## Donde nacen los objetos antes de cogerlos: sin solapar la cápsula del jugador.
const AWAY: Vector3 = Vector3(5.0, 0.5, 5.0)

var _level: Node3D
var _hold: HoldComponent
var _actor: InteractionComponent
var _detector: InteractionDetector
var _slot: Slot


func before_each() -> void:
	_level = add_child_autofree(Node3D.new())
	var player: Player = PLAYER_SCENE.instantiate()
	_level.add_child(player)
	_hold = player.get_node("%HoldComponent")
	_hold.items_root = _level
	_actor = player.get_node("%InteractionComponent")
	_detector = player.get_node("%InteractionDetector")
	_slot = SLOT_SCENE.instantiate()
	_slot.position = Vector3(0.0, 0.0, -1.0)
	_level.add_child(_slot)


func _settle() -> void:
	await wait_physics_frames(2)


func _in_hand(item: Node3D) -> Node3D:
	_level.add_child(item)
	item.global_position = AWAY
	assert_true(_hold.pick_up(item))
	return item


## Deja la caja en la mesa con una pulsación.
func _box_on_table(data: BoxData) -> Box:
	var box: Box = BOX_SCENE.instantiate()
	box.data = data
	_in_hand(box)
	await _settle()
	assert_eq(_detector.get_target(), _slot, "mesa vacía con la caja en la mano")
	assert_true(_actor.interact_pressed())
	assert_eq(_slot.get_item(), box)
	return box


func _cooked_octopus() -> Ingredient:
	var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
	_in_hand(octopus)
	octopus.set_cooked()
	return octopus


## Suelta y retira lo que lleve la mano.
func _discard_held() -> void:
	var item: Node = _hold.drop()
	if item != null:
		item.free()


func _assert_fills_on_table(data: BoxData, presses: int) -> void:
	var box: Box = await _box_on_table(data)
	var octopus: Ingredient = _cooked_octopus()
	await _settle()
	assert_eq(_detector.get_target(), box, "el objetivo es la caja, no la mesa")
	for i: int in presses:
		assert_false(box.is_full(), "%s llena antes de %d" % [data.display_name, i])
		assert_true(_actor.interact_pressed(), "corte %d" % [i + 1])
		await _settle()
	assert_true(box.is_full(), "%s llena en %d pulsaciones" % [data.display_name, presses])
	assert_almost_eq(octopus.remaining, 50.0, 0.001)
	assert_eq(_slot.get_item(), box, "sigue en la mesa")
	assert_eq(_hold.get_held_item(), octopus)


func test_review_small_box_on_table_fills_in_5_presses() -> void:
	await _assert_fills_on_table(SMALL, 5)


func test_review_medium_box_on_table_fills_in_10_presses() -> void:
	await _assert_fills_on_table(MEDIUM, 10)


func test_review_large_box_on_table_fills_in_20_presses() -> void:
	await _assert_fills_on_table(LARGE, 20)


func test_review_raw_octopus_does_not_target_box_on_table() -> void:
	var box: Box = await _box_on_table(SMALL)
	_in_hand(OCTOPUS_SCENE.instantiate())
	await _settle()
	assert_null(_detector.get_target(), "pulpo crudo: la caja no lo acepta y se descarta")
	assert_eq(box.fill, 0.0)


func test_review_season_box_on_table_then_pick_up_and_drop() -> void:
	var box: Box = await _box_on_table(SMALL)
	_cooked_octopus()
	await _settle()
	for i: int in 5:
		_actor.interact_pressed()
		await _settle()
	assert_true(box.is_full())
	_discard_held()
	var salt: SeasoningItem = SEASONING_SCENE.instantiate()
	salt.data = SALT
	_in_hand(salt)
	await _settle()
	assert_eq(_detector.get_target(), box)
	watch_signals(box)
	assert_true(_actor.interact_pressed())
	await _settle()
	assert_true(_actor.interact_pressed(), "repetir consume la pulsación")
	assert_signal_emit_count(box, "seasoned", 1)
	assert_eq(box.get_contents().seasonings, [SALT] as Array[SeasoningData])
	assert_eq(_hold.get_held_item(), salt, "el bote no se consume")
	_discard_held()
	await _settle()
	assert_eq(_detector.get_target(), box, "mano vacía: el objetivo es la caja, para cogerla")
	assert_true(_actor.interact_pressed())
	assert_eq(_hold.get_held_item(), box)
	assert_false(_slot.has_item(), "la mesa queda libre")
	_hold.drop()
	assert_false(box.freeze, "suelta, no congelada")
	assert_eq(box.collision_layer, INTERACTABLE_LAYER)
	assert_eq(box.collision_mask, 5)
	assert_eq(box.fill, 1.0, "conserva el contenido")
	assert_eq(box.get_contents().seasonings.size(), 1)
