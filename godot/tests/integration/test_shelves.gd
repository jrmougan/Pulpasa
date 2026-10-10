extends GutTest
## PUL-017 AC3: el único spawner de `box_shelf.tscn` da la caja única (D25, PUL-113) en la mano
## (sustituye al modo spawner de `Box.cs`).
## La estantería de botes (`spice_shelf.tscn`) se retiró en PUL-061 (D18).

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const BOX_SHELF_SCENE: PackedScene = preload("res://entities/stations/box_shelf.tscn")
const BOX: BoxData = preload("res://data/boxes/box.tres")
const INTERACTABLE_LAYER: int = 1 << 2

var _level: Node3D
var _hold: HoldComponent
var _actor: InteractionComponent


func before_each() -> void:
	_level = add_child_autofree(Node3D.new())
	var player: Player = PLAYER_SCENE.instantiate()
	_level.add_child(player)
	_hold = player.get_node("%HoldComponent")
	_hold.items_root = _level
	_actor = player.get_node("%InteractionComponent")


func _box_shelf() -> Node3D:
	var shelf: Node3D = BOX_SHELF_SCENE.instantiate()
	_level.add_child(shelf)
	shelf.position = Vector3(0, 0, -3)
	return shelf


func test_ac3_shelf_has_a_single_box_spawner() -> void:
	var shelf: Node3D = _box_shelf()
	var spawners: Array[Node] = []
	for child: Node in shelf.get_children():
		if child is ItemSpawner:
			spawners.append(child)
	assert_eq(spawners.size(), 1)
	assert_eq(spawners[0].name, &"BoxSpawner")
	assert_eq((spawners[0] as Node3D).position, Vector3(0.0, 0.31, -0.78))


func test_ac3_box_spawner_gives_the_single_box() -> void:
	var shelf: Node3D = _box_shelf()
	var spawner: ItemSpawner = shelf.get_node("BoxSpawner") as ItemSpawner
	assert_true(spawner.interact(_actor))
	var box: Box = _hold.get_held_item() as Box
	assert_not_null(box)
	assert_eq(box.data, BOX)
	assert_eq(box.fill, 0.0)
	box.free()


func test_ac3_box_spawner_with_full_hand_does_nothing() -> void:
	var shelf: Node3D = _box_shelf()
	var spawner: ItemSpawner = shelf.get_node("BoxSpawner") as ItemSpawner
	spawner.interact(_actor)
	var held: Node = _hold.get_held_item()
	spawner.interact(_actor)
	assert_eq(_hold.get_held_item(), held)
	assert_eq((held as Box).data, BOX)


func test_ac3_box_spawner_is_interactable() -> void:
	var shelf: Node3D = _box_shelf()
	assert_eq(InteractionContract.scan_tree(shelf), [] as Array[String])
	var spawner: StaticBody3D = shelf.get_node("BoxSpawner") as StaticBody3D
	assert_true(spawner.is_in_group(InteractionContract.GROUP_INTERACTABLE))
	assert_true(spawner.collision_layer & INTERACTABLE_LAYER != 0)
	var highlightable: Highlightable = spawner.get_node("Highlightable") as Highlightable
	assert_not_null(highlightable)
	assert_eq(highlightable.root, shelf.get_node("Model/box_shelf/OutlineHull"))
