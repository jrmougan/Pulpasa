extends GutTest
## PUL-017 AC3: cada spawner de `box_shelf.tscn` da su caja S/M/L en la mano (sustituye al modo
## spawner de `Box.cs`). La estantería de botes (`spice_shelf.tscn`) se retiró en PUL-061 (D18).

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const BOX_SHELF_SCENE: PackedScene = preload("res://entities/stations/box_shelf.tscn")
const SMALL: BoxData = preload("res://data/boxes/small.tres")
const MEDIUM: BoxData = preload("res://data/boxes/medium.tres")
const LARGE: BoxData = preload("res://data/boxes/large.tres")
const INTERACTABLE_LAYER: int = 1 << 2
const SPAWNERS: Array[String] = ["SmallSpawner", "MediumSpawner", "LargeSpawner"]

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


func test_ac3_each_box_spawner_gives_its_size() -> void:
	var shelf: Node3D = _box_shelf()
	var expected: Array[BoxData] = [SMALL, MEDIUM, LARGE]
	for i: int in SPAWNERS.size():
		var spawner: ItemSpawner = shelf.get_node(SPAWNERS[i]) as ItemSpawner
		assert_not_null(spawner, SPAWNERS[i])
		assert_true(spawner.interact(_actor), SPAWNERS[i])
		var box: Box = _hold.get_held_item() as Box
		assert_not_null(box, SPAWNERS[i])
		assert_eq(box.data, expected[i], SPAWNERS[i])
		assert_eq(box.fill, 0.0)
		box.free()


func test_ac3_box_spawner_with_full_hand_does_nothing() -> void:
	var shelf: Node3D = _box_shelf()
	var small: ItemSpawner = shelf.get_node(SPAWNERS[0]) as ItemSpawner
	small.interact(_actor)
	var held: Node = _hold.get_held_item()
	(shelf.get_node(SPAWNERS[2]) as ItemSpawner).interact(_actor)
	assert_eq(_hold.get_held_item(), held)
	assert_eq((held as Box).data, SMALL)


func test_ac3_box_spawners_are_interactable() -> void:
	var shelf: Node3D = _box_shelf()
	assert_eq(InteractionContract.scan_tree(shelf), [] as Array[String])
	for spawner_name: String in SPAWNERS:
		var spawner: StaticBody3D = shelf.get_node(spawner_name) as StaticBody3D
		assert_true(spawner.is_in_group(InteractionContract.GROUP_INTERACTABLE), spawner_name)
		assert_true(spawner.collision_layer & INTERACTABLE_LAYER != 0, spawner_name)
		assert_true(spawner.get_node("Highlightable") is Highlightable, spawner_name)
