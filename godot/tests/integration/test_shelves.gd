extends GutTest
## PUL-017 AC3: cada spawner de `box_shelf.tscn` da su caja S/M/L en la mano (sustituye al modo
## spawner de `Box.cs`); `spice_shelf.tscn` tiene tres slots precargados con sal, pimentón y
## pimentón picante, que se cogen y se devuelven a su slot.

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const BOX_SHELF_SCENE: PackedScene = preload("res://entities/stations/box_shelf.tscn")
const SPICE_SHELF_SCENE: PackedScene = preload("res://entities/stations/spice_shelf.tscn")
const SMALL: BoxData = preload("res://data/boxes/small.tres")
const MEDIUM: BoxData = preload("res://data/boxes/medium.tres")
const LARGE: BoxData = preload("res://data/boxes/large.tres")
const SALT: SeasoningData = preload("res://data/seasonings/salt.tres")
const PAPRIKA: SeasoningData = preload("res://data/seasonings/paprika.tres")
const HOT_PAPRIKA: SeasoningData = preload("res://data/seasonings/hot_paprika.tres")
const OIL: SeasoningData = preload("res://data/seasonings/oil.tres")
const INTERACTABLE_LAYER: int = 1 << 2
const SPAWNERS: Array[String] = ["SmallSpawner", "MediumSpawner", "LargeSpawner"]
const SPICE_SLOTS: Array[String] = ["SaltSlot", "PaprikaSlot", "HotPaprikaSlot", "OilSlot"]

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


func _spice_shelf() -> Node3D:
	var shelf: Node3D = SPICE_SHELF_SCENE.instantiate()
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


func test_ac3_spice_slots_are_preloaded() -> void:
	var shelf: Node3D = _spice_shelf()
	var expected: Array[SeasoningData] = [SALT, PAPRIKA, HOT_PAPRIKA, OIL]
	for i: int in SPICE_SLOTS.size():
		var slot: Slot = shelf.get_node(SPICE_SLOTS[i]) as Slot
		assert_not_null(slot, SPICE_SLOTS[i])
		var item: SeasoningItem = slot.get_item() as SeasoningItem
		assert_not_null(item, SPICE_SLOTS[i])
		assert_eq(item.data, expected[i], SPICE_SLOTS[i])


func test_ac3_spice_can_be_taken_and_returned_to_its_slot() -> void:
	var shelf: Node3D = _spice_shelf()
	for slot_name: String in SPICE_SLOTS:
		var slot: Slot = shelf.get_node(slot_name) as Slot
		var item: SeasoningItem = slot.get_item() as SeasoningItem
		assert_true(Slot.pick_up_item(_actor, item), slot_name)
		assert_eq(_hold.get_held_item(), item, slot_name)
		assert_false(slot.has_item(), slot_name)
		assert_true(slot.interact(_actor), slot_name)
		assert_eq(slot.get_item(), item, "vuelve a su slot")
		assert_null(_hold.get_held_item())


func test_ac3_spice_taken_from_shelf_drops_unfrozen() -> void:
	var shelf: Node3D = _spice_shelf()
	var slot: Slot = shelf.get_node(SPICE_SLOTS[1]) as Slot
	var item: SeasoningItem = slot.get_item() as SeasoningItem
	assert_true(slot.interact(_actor))
	_hold.drop()
	assert_false(item.freeze)
	assert_eq(item.collision_layer, INTERACTABLE_LAYER)


func test_ac3_spice_shelf_uses_box_furniture_model() -> void:
	var shelf: Node3D = _spice_shelf()
	var model: Node3D = shelf.get_node("Model") as Node3D
	assert_eq(model.scene_file_path, "res://assets/models/furniture/Mueblecajas.tscn")
	assert_true(shelf.get_node("CollisionShape3D") is CollisionShape3D, "colisión del mueble")


func test_ac3_spice_slots_hide_and_disable_their_tables() -> void:
	var shelf: Node3D = _spice_shelf()
	for slot_name: String in SPICE_SLOTS:
		var table: Node3D = shelf.get_node(slot_name).get_node("Model") as Node3D
		assert_false(table.visible, slot_name)
		assert_eq(table.process_mode, Node.PROCESS_MODE_DISABLED, "%s: sin colisión" % slot_name)


func test_ac3_spices_sit_on_the_shelf_in_order() -> void:
	var shelf: Node3D = _spice_shelf()
	var previous_x: float = -INF
	for slot_name: String in SPICE_SLOTS:
		var item: Node3D = (shelf.get_node(slot_name) as Slot).get_item()
		var local: Vector3 = shelf.to_local(item.get_node("%AnchorPoint").global_position)
		assert_almost_eq(local.y, 0.15, 0.001, "%s: sobre el estante" % slot_name)
		assert_almost_eq(local.z, -0.78, 0.001, slot_name)
		assert_gt(
			local.x,
			previous_x,
			"%s: sal, pimentón, picante, aceite de izquierda a derecha" % slot_name
		)
		previous_x = local.x


func test_ac3_spice_shelf_contract() -> void:
	var shelf: Node3D = _spice_shelf()
	assert_eq(InteractionContract.scan_tree(shelf), [] as Array[String])
