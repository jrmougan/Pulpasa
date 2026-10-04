# gdlint: disable=max-public-methods
extends GutTest
## PUL-017 AC2: la olla (`kitchen.tscn`, `cooking_station.gd`) acepta un pulpo crudo de la mano,
## lo cuece en `IngredientData.cook_time` (5 s) con barra y hervor, y lo devuelve cocido a una
## mano vacía. Sin quemado (M1). La pausa del árbol congela la cocción.
## PUL-029: varias plazas según `KitchenData.capacity` (2 en `data/config/kitchen.tres`),
## progreso independiente por plaza y devolución FIFO por orden de finalización.

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const KITCHEN_SCENE: PackedScene = preload("res://entities/stations/kitchen.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const OCTOPUS: IngredientData = preload("res://data/ingredients/octopus.tres")
const INTERACTABLE_LAYER: int = 1 << 2
const STEP: float = 0.1

var _level: Node3D
var _hold: HoldComponent
var _actor: InteractionComponent
var _kitchen: CookingStation


func before_each() -> void:
	_level = add_child_autofree(Node3D.new())
	var player: Player = PLAYER_SCENE.instantiate()
	_level.add_child(player)
	_hold = player.get_node("%HoldComponent")
	_hold.items_root = _level
	_actor = player.get_node("%InteractionComponent")
	_kitchen = KITCHEN_SCENE.instantiate()
	_level.add_child(_kitchen)
	_kitchen.position = Vector3(0, 0, -1.2)


func after_each() -> void:
	get_tree().paused = false


func _octopus_in_hand(cooked: bool = false) -> Ingredient:
	var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
	_level.add_child(octopus)
	if cooked:
		octopus.set_cooked()
	assert_true(_hold.pick_up(octopus))
	return octopus


## Avanza la cocción `seconds` de juego en pasos de física de `STEP`.
func _cook_for(seconds: float) -> void:
	simulate(_kitchen, roundi(seconds / STEP), STEP)


func _meshes_using(octopus: Ingredient, material: Material) -> int:
	var count: int = 0
	for node: Node in octopus.find_children("*", "MeshInstance3D"):
		if (node as MeshInstance3D).material_override == material:
			count += 1
	return count


func _bar() -> WorldProgressBar:
	return _kitchen.get_node("%CookBar") as WorldProgressBar


func test_ac2_cook_time_comes_from_ingredient_data() -> void:
	assert_eq(OCTOPUS.cook_time, 5.0)


func test_ac2_accepts_raw_octopus_from_hand() -> void:
	var octopus: Ingredient = _octopus_in_hand()
	watch_signals(_kitchen)
	assert_true(_kitchen.can_interact(_actor))
	assert_true(_kitchen.interact(_actor))
	assert_null(_hold.get_held_item(), "la mano queda vacía")
	assert_eq(_kitchen.get_ingredient(), octopus)
	assert_true(_kitchen.is_cooking())
	assert_false(octopus.is_held)
	assert_true(octopus.freeze, "quieto en la olla")
	assert_eq(octopus.collision_layer & INTERACTABLE_LAYER, 0, "el detector ve la olla")
	assert_signal_emitted_with_parameters(_kitchen, "cooking_started", [octopus])
	assert_true(_bar().visible, "barra visible al cocer")
	assert_true((_kitchen.get_node("%BoilAudio") as AudioStreamPlayer3D).playing, "hervor")


func test_ac2_cooked_after_five_seconds_of_game() -> void:
	var octopus: Ingredient = _octopus_in_hand()
	_kitchen.interact(_actor)
	watch_signals(_kitchen)
	_cook_for(4.9)
	assert_false(octopus.is_cooked(), "aún no a los 4,9 s")
	assert_almost_eq(_bar().get_progress(), 0.98, 0.001)
	assert_signal_not_emitted(_kitchen, "cooking_finished")
	_cook_for(0.1)
	assert_true(octopus.is_cooked(), "cocido a los 5,0 s")
	assert_false(_kitchen.is_cooking())
	assert_signal_emit_count(_kitchen, "cooking_finished", 1)
	assert_signal_emitted_with_parameters(_kitchen, "cooking_finished", [octopus])
	assert_false(_bar().visible, "barra oculta al terminar")
	assert_false((_kitchen.get_node("%BoilAudio") as AudioStreamPlayer3D).playing)
	_cook_for(2.0)
	assert_signal_emit_count(_kitchen, "cooking_finished", 1, "sin quemado ni doble aviso")


func test_ac2_cooked_octopus_uses_cooked_material() -> void:
	var octopus: Ingredient = _octopus_in_hand()
	_kitchen.interact(_actor)
	assert_false(_meshes_using(octopus, octopus.cooked_material) > 0, "crudo antes de cocer")
	_cook_for(5.0)
	assert_gt(_meshes_using(octopus, octopus.cooked_material), 0, "material cocido en datos")
	assert_eq(_meshes_using(octopus, octopus.raw_material), 0, "sin restos del crudo")


func test_ac2_octopus_anchor_point_sits_on_pot_anchor() -> void:
	var octopus: Ingredient = _octopus_in_hand()
	_kitchen.interact(_actor)
	var anchor: Node3D = _kitchen.get_node("%AnchorPoint")
	var point: Node3D = octopus.get_node("%AnchorPoint")
	assert_true(point.global_transform.is_equal_approx(anchor.global_transform))


func test_ac2_paused_tree_does_not_advance() -> void:
	var octopus: Ingredient = _octopus_in_hand()
	_kitchen.interact(_actor)
	await wait_physics_frames(2)
	var progress: float = _bar().get_progress()
	get_tree().paused = true
	for i: int in 30:
		await get_tree().physics_frame
	assert_eq(_bar().get_progress(), progress, "congelada en pausa")
	get_tree().paused = false
	await wait_physics_frames(3)
	assert_gt(_bar().get_progress(), progress, "sigue al reanudar")
	assert_false(octopus.is_cooked())


func test_ac2_empty_hand_takes_cooked_octopus() -> void:
	var octopus: Ingredient = _octopus_in_hand()
	_kitchen.interact(_actor)
	_cook_for(5.0)
	assert_true(_kitchen.can_interact(_actor))
	assert_true(_kitchen.interact(_actor))
	assert_eq(_hold.get_held_item(), octopus)
	assert_true(octopus.is_cooked())
	assert_true(octopus.is_held)
	assert_null(_kitchen.get_ingredient(), "la olla queda libre")
	_hold.drop()
	assert_false(octopus.freeze, "al soltarlo no se queda congelado")
	assert_eq(octopus.collision_layer, INTERACTABLE_LAYER)


func test_ac2_empty_hand_while_cooking_gets_nothing() -> void:
	var octopus: Ingredient = _octopus_in_hand()
	_kitchen.interact(_actor)
	_cook_for(2.0)
	_kitchen.interact(_actor)
	assert_null(_hold.get_held_item())
	assert_eq(_kitchen.get_ingredient(), octopus)
	assert_true(_kitchen.is_cooking())


func test_ac2_empty_pot_with_empty_hand_does_nothing() -> void:
	assert_false(_kitchen.can_interact(_actor))
	assert_false(_kitchen.interact(_actor))
	assert_null(_kitchen.get_ingredient())


func test_ac2_rejects_cooked_octopus() -> void:
	var octopus: Ingredient = _octopus_in_hand(true)
	_kitchen.interact(_actor)
	assert_eq(_hold.get_held_item(), octopus, "sigue en la mano")
	assert_null(_kitchen.get_ingredient())
	assert_false(_kitchen.is_cooking())


func test_ac2_rejects_box() -> void:
	var box: Box = BOX_SCENE.instantiate()
	_level.add_child(box)
	assert_true(_hold.pick_up(box))
	_kitchen.interact(_actor)
	assert_eq(_hold.get_held_item(), box, "sigue en la mano")
	assert_null(_kitchen.get_ingredient())


func test_ac1_capacity_two_staggered_start() -> void:
	var first: Ingredient = _octopus_in_hand()
	_kitchen.interact(_actor)
	_cook_for(2.5)
	var second: Ingredient = _octopus_in_hand()
	_kitchen.interact(_actor)
	_cook_for(2.5)

	assert_true(first.is_cooked(), "el primero se cuece tras 5s")
	assert_false(second.is_cooked(), "el segundo no se cuece en 2.5s")

	_cook_for(2.5)
	assert_true(second.is_cooked(), "el segundo se cuece tras otros 2.5s")


func test_ac1_pause_freezes_two_slots() -> void:
	var first: Ingredient = _octopus_in_hand()
	_kitchen.interact(_actor)
	var second: Ingredient = _octopus_in_hand()
	_kitchen.interact(_actor)

	await wait_physics_frames(2)
	var prog1: float = _kitchen._slots[0].bar.get_progress()
	var prog2: float = _kitchen._slots[1].bar.get_progress()

	get_tree().paused = true
	for i: int in 30:
		await get_tree().physics_frame
	assert_eq(_kitchen._slots[0].bar.get_progress(), prog1, "pausa congela barra 1")
	assert_eq(_kitchen._slots[1].bar.get_progress(), prog2, "pausa congela barra 2")
	get_tree().paused = false

	await wait_physics_frames(3)
	assert_gt(_kitchen._slots[0].bar.get_progress(), prog1, "sigue la barra 1 al reanudar")
	assert_gt(_kitchen._slots[1].bar.get_progress(), prog2, "sigue la barra 2 al reanudar")


func test_ac1_mix_octopus_and_cachelos_compete_for_slots() -> void:
	var octopus: Ingredient = _octopus_in_hand()
	_kitchen.interact(_actor)

	var cachelo: Ingredient = load("res://entities/items/cachelos.tscn").instantiate()
	_level.add_child(cachelo)
	_hold.pick_up(cachelo)
	_kitchen.interact(_actor)

	var third: Ingredient = _octopus_in_hand()
	_kitchen.interact(_actor)
	assert_eq(_hold.get_held_item(), third, "capacidad respetada con mezcla")

	_cook_for(5.0)
	assert_true(octopus.is_cooked())
	assert_true(cachelo.is_cooked())


func test_ac2_full_hand_cannot_take_cooked_item() -> void:
	var octopus: Ingredient = _octopus_in_hand()
	_kitchen.interact(_actor)
	_cook_for(5.0)
	assert_true(octopus.is_cooked())

	var box: Box = BOX_SCENE.instantiate() as Box
	_level.add_child(box)
	_hold.pick_up(box)

	_kitchen.interact(_actor)
	assert_eq(_hold.get_held_item(), box, "con mano llena no se recoge el cocido")
	assert_not_null(_kitchen._slots[0].get_ingredient(), "el cocido sigue en la olla")


func test_ac2_rejected_item_is_not_dropped_on_press() -> void:
	var octopus: Ingredient = _octopus_in_hand(true)
	await wait_physics_frames(3)
	assert_true(_actor.interact_pressed(), "la olla consume la pulsación (paridad Unity)")
	assert_eq(_hold.get_held_item(), octopus)


func test_ac2_full_cycle_via_detector() -> void:
	var octopus: Ingredient = _octopus_in_hand()
	await wait_physics_frames(3)
	assert_true(_actor.interact_pressed())
	assert_eq(_kitchen.get_ingredient(), octopus)
	_cook_for(5.0)
	await wait_physics_frames(3)
	assert_true(_actor.interact_pressed())
	assert_eq(_hold.get_held_item(), octopus)
	assert_true(octopus.is_cooked())


func test_ac2_freed_ingredient_frees_pot() -> void:
	var octopus: Ingredient = _octopus_in_hand()
	_kitchen.interact(_actor)
	octopus.free()
	_cook_for(5.0)
	assert_null(_kitchen.get_ingredient())
	assert_false(_kitchen.is_cooking())
	assert_false(_bar().visible)


func test_ac2_kitchen_scene_contract() -> void:
	assert_true(_kitchen.is_in_group(InteractionContract.GROUP_INTERACTABLE))
	assert_true(_kitchen.is_in_group(&"kitchen"))
	assert_eq(InteractionContract.scan_tree(_kitchen), [] as Array[String])
	assert_true(_kitchen.collision_layer & INTERACTABLE_LAYER != 0)
	assert_true(_kitchen.get_node("%Highlightable") is Highlightable)
	assert_true(_kitchen.get_node("%AnchorPoint") is Marker3D)
	assert_false(_bar().visible, "barra oculta en reposo")
	var audio: AudioStreamPlayer3D = _kitchen.get_node("%BoilAudio")
	assert_eq(audio.stream, preload("res://assets/audio/boiling_water_loop.ogg"))


func test_ac1_fifo_by_finish_order() -> void:
	var first: Ingredient = _octopus_in_hand()
	_kitchen.interact(_actor)
	_cook_for(2.5)
	var second: Ingredient = _octopus_in_hand()
	_kitchen.interact(_actor)
	_cook_for(2.5)

	# Wait enough for both to finish (second takes another 2.5s)
	_cook_for(3.0)
	assert_true(first.is_cooked())
	assert_true(second.is_cooked())

	_kitchen.interact(_actor)
	assert_eq(_hold.get_held_item(), first, "devuelve primero el que terminó antes")
	_hold.drop()
	_kitchen.interact(_actor)
	assert_eq(_hold.get_held_item(), second, "devuelve el segundo")
