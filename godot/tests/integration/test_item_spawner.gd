extends GutTest
## PUL-017 AC1: la nevera (`octopus_storage.tscn`, `item_spawner.gd`) pone un pulpo crudo en la
## mano vacía (ADR-003 §6). D26 (PUL-125): con la mano llena no es objetivo y ya no se traga la
## pulsación (`can_interact` honesto): la pulsación cae al suelo, como con cualquier otra cosa.

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const STORAGE_SCENE: PackedScene = preload("res://entities/stations/octopus_storage.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const MEDIUM: BoxData = preload("res://data/boxes/box.tres")
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
	assert_false(_storage.can_interact(_actor), "con la mano llena no es objetivo")
	assert_eq(_storage.get_action_hint(_actor).state, ActionHint.State.NONE)
	assert_false(_storage.interact(_actor), "no consume la pulsación")
	assert_eq(_hold.get_held_item(), box, "sigue la caja en la mano")
	assert_eq(_level.get_child_count(), before, "no aparece ningún pulpo")


## D26: la nevera no es objetivo con la mano llena y la pulsación cae al suelo (A8).
func test_ac1_full_hand_press_via_detector_never_spawns() -> void:
	var box: Box = BOX_SCENE.instantiate()
	_level.add_child(box)
	assert_true(_hold.pick_up(box))
	await wait_physics_frames(3)
	assert_ne(_actor.detector.get_target(), _storage, "la nevera no es objetivo")
	var before: int = get_tree().get_nodes_in_group(&"pickable").size()
	assert_true(_actor.interact_pressed(), "responde: suelta al suelo")
	assert_null(_hold.get_held_item(), "la caja cae al suelo")
	assert_eq(get_tree().get_nodes_in_group(&"pickable").size(), before, "no aparece ningún pulpo")


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
