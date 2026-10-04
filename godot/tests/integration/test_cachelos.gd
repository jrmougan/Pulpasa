extends GutTest

const KITCHEN_SCENE: PackedScene = preload("res://entities/stations/kitchen.tscn")
const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const CACHELOS_SCENE: PackedScene = preload("res://entities/items/cachelos.tscn")
const SMALL_BOX: Resource = preload("res://data/boxes/small.tres")
const SEASONING_SCENE: PackedScene = preload("res://entities/items/seasoning.tscn")

const STEP: float = 0.1
const INTERACTABLE_LAYER: int = 1 << 2

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


func after_each() -> void:
	get_tree().paused = false


func _cook_for(seconds: float) -> void:
	simulate(_kitchen, roundi(seconds / STEP), STEP)


func test_ac2_cachelo_raw_to_pot_to_cooked() -> void:
	var cachelo: Ingredient = CACHELOS_SCENE.instantiate()
	_level.add_child(cachelo)
	_hold.pick_up(cachelo)

	_kitchen.interact(_actor)
	assert_true(_kitchen.is_cooking())
	assert_null(_hold.get_held_item())

	_cook_for(5.0)
	assert_true(cachelo.is_cooked())


func test_ac2_cachelo_cooked_applied_to_full_box() -> void:
	var cachelo: Ingredient = CACHELOS_SCENE.instantiate()
	_level.add_child(cachelo)
	cachelo.set_cooked()
	_hold.pick_up(cachelo)

	var box: Box = BOX_SCENE.instantiate()
	_level.add_child(box)
	box.data = SMALL_BOX
	box.fill = 1.0  # full

	box.interact(_actor)

	var contents := box.get_contents()
	assert_eq(contents.seasonings.size(), 1)
	assert_eq(contents.seasonings[0].type, SeasoningData.SeasoningType.CACHELOS)

	# cachelo is consumed, not in hand
	assert_null(_hold.get_held_item())
	assert_true(not is_instance_valid(cachelo) or cachelo.is_queued_for_deletion())


func test_ac2_cachelo_raw_rejected_by_box() -> void:
	var cachelo: Ingredient = CACHELOS_SCENE.instantiate()
	_level.add_child(cachelo)
	_hold.pick_up(cachelo)

	var box: Box = BOX_SCENE.instantiate()
	_level.add_child(box)
	box.data = SMALL_BOX
	box.fill = 1.0  # full

	box.interact(_actor)

	var contents := box.get_contents()
	assert_eq(contents.seasonings.size(), 0)
	assert_eq(_hold.get_held_item(), cachelo)


func test_ac3_four_seasonings() -> void:
	var box: Box = BOX_SCENE.instantiate()
	_level.add_child(box)
	box.data = SMALL_BOX
	box.fill = 1.0  # full

	var salt: SeasoningItem = SEASONING_SCENE.instantiate()
	salt.data = load("res://data/seasonings/salt.tres")
	_level.add_child(salt)
	_hold.pick_up(salt)
	box.interact(_actor)
	_hold.drop()

	var paprika: SeasoningItem = SEASONING_SCENE.instantiate()
	paprika.data = load("res://data/seasonings/paprika.tres")
	_level.add_child(paprika)
	_hold.pick_up(paprika)
	box.interact(_actor)
	_hold.drop()

	var oil: SeasoningItem = SEASONING_SCENE.instantiate()
	oil.data = load("res://data/seasonings/oil.tres")
	_level.add_child(oil)
	_hold.pick_up(oil)
	box.interact(_actor)
	_hold.drop()

	var cachelo: Ingredient = CACHELOS_SCENE.instantiate()
	_level.add_child(cachelo)
	cachelo.set_cooked()
	_hold.pick_up(cachelo)
	box.interact(_actor)

	var contents := box.get_contents()
	assert_eq(contents.seasonings.size(), 4)


func test_pul033_cachelo_material_changes_and_colors_differ() -> void:
	var cachelo: Ingredient = CACHELOS_SCENE.instantiate()
	_level.add_child(cachelo)
	var mesh: MeshInstance3D = cachelo.get_node("Model").find_children("*", "MeshInstance3D")[0]
	assert_eq(mesh.material_override, cachelo.raw_material, "crudo")
	cachelo.set_cooked()
	assert_eq(mesh.material_override, cachelo.cooked_material, "cocido")
	var raw: Color = (cachelo.raw_material as StandardMaterial3D).albedo_color
	var cooked: Color = (cachelo.cooked_material as StandardMaterial3D).albedo_color
	assert_gt(absf(raw.v - cooked.v), 0.3, "crudo y cocido se distinguen por luminosidad")
