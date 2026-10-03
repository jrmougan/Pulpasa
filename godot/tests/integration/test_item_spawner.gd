extends GutTest
## PUL-017 AC1: la nevera (`octopus_storage.tscn`, `item_spawner.gd`) pone un pulpo crudo en la
## mano vacía (ADR-003 §6); con la mano llena consume la pulsación sin hacer nada (paridad
## `OctopusSpawner.Interact`: no suelta lo que se lleva).

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const STORAGE_SCENE: PackedScene = preload("res://entities/stations/octopus_storage.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const MEDIUM: BoxData = preload("res://data/boxes/medium.tres")
const INTERACTABLE_LAYER: int = 1 << 2

var _level: Node3D
var _hold: HoldComponent
var _actor: InteractionComponent
var _storage: ItemSpawner


func before_each() -> void:
	_level = add_child_autofree(Node3D.new())
	var player: Player = PLAYER_SCENE.instantiate()
	_level.add_child(player)
	_hold = player.get_node("%HoldComponent")
	_hold.items_root = _level
	_actor = player.get_node("%InteractionComponent")
	_storage = STORAGE_SCENE.instantiate()
	_level.add_child(_storage)
	_storage.position = Vector3(0, 0, -1.5)


func test_ac1_empty_hand_gets_raw_octopus() -> void:
	assert_true(_storage.can_interact(_actor))
	assert_true(_storage.interact(_actor))
	var held: Ingredient = _hold.get_held_item() as Ingredient
	assert_not_null(held, "un pulpo en la mano")
	assert_false(held.is_cooked(), "crudo")
	assert_true(held.is_held)
	assert_eq(held.data, preload("res://data/ingredients/octopus.tres"))


func test_ac1_each_press_with_empty_hand_spawns_a_new_octopus() -> void:
	_storage.interact(_actor)
	var first: Node = _hold.get_held_item()
	_hold.drop()
	_storage.interact(_actor)
	var second: Node = _hold.get_held_item()
	assert_not_null(second)
	assert_ne(first, second)


func test_ac1_full_hand_does_nothing() -> void:
	var box: Box = BOX_SCENE.instantiate()
	_level.add_child(box)
	assert_true(_hold.pick_up(box))
	var before: int = _level.get_child_count()
	assert_true(_storage.interact(_actor), "consume la pulsación (no suelta la caja)")
	assert_eq(_hold.get_held_item(), box, "sigue la caja en la mano")
	assert_eq(_level.get_child_count(), before, "no aparece ningún pulpo")


func test_ac1_full_hand_press_via_detector_keeps_item() -> void:
	var box: Box = BOX_SCENE.instantiate()
	_level.add_child(box)
	assert_true(_hold.pick_up(box))
	await wait_physics_frames(3)
	assert_true(_actor.interact_pressed())
	assert_eq(_hold.get_held_item(), box, "no la suelta delante de la nevera")


func test_ac1_interact_press_via_detector_spawns_in_hand() -> void:
	await wait_physics_frames(3)
	assert_true(_actor.interact_pressed())
	assert_true(_hold.get_held_item() is Ingredient)


func test_ac1_spawner_applies_data_to_spawned_item() -> void:
	var spawner: ItemSpawner = ItemSpawner.new()
	spawner.scene = BOX_SCENE
	spawner.data = MEDIUM
	_level.add_child(spawner)
	assert_true(spawner.interact(_actor))
	assert_eq((_hold.get_held_item() as Box).data, MEDIUM)


func test_ac1_spawner_without_scene_does_nothing() -> void:
	var spawner: ItemSpawner = ItemSpawner.new()
	_level.add_child(spawner)
	assert_false(spawner.can_interact(_actor))
	assert_false(spawner.interact(_actor))
	assert_null(_hold.get_held_item())


func test_ac1_storage_meets_interaction_contract() -> void:
	assert_true(_storage.is_in_group(InteractionContract.GROUP_INTERACTABLE))
	assert_eq(InteractionContract.scan_tree(_storage), [] as Array[String])
	var body: StaticBody3D = (_storage as Node) as StaticBody3D
	assert_not_null(body, "la raíz es un cuerpo")
	assert_true(body.collision_layer & INTERACTABLE_LAYER != 0)
	assert_true(_storage.get_node("%Highlightable") is Highlightable)
