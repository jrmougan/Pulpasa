extends GutTest
## PUL-016: el bote de condimento solo se coge y se suelta; condimentar es cosa de la caja y el
## bote no se consume (B6).

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const SEASONING_SCENE: PackedScene = preload("res://entities/items/seasoning.tscn")
const SMALL: BoxData = preload("res://data/boxes/small.tres")
const SALT: SeasoningData = preload("res://data/seasonings/salt.tres")

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


func _salt() -> SeasoningItem:
	var item: SeasoningItem = SEASONING_SCENE.instantiate()
	item.data = SALT
	_level.add_child(item)
	return item


func test_b6_jar_is_not_consumed_when_seasoning() -> void:
	var box: Box = BOX_SCENE.instantiate()
	box.data = SMALL
	_level.add_child(box)
	var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
	_level.add_child(octopus)
	octopus.set_cooked()
	_hold.pick_up(octopus)
	while not box.is_full():
		box.interact(_actor)
	_hold.drop()
	var salt: SeasoningItem = _salt()
	_hold.pick_up(salt)
	assert_true(box.interact(_actor))
	assert_true(is_instance_valid(salt) and not salt.is_queued_for_deletion())
	assert_eq(_hold.get_held_item(), salt, "el bote sigue en la mano")


func test_empty_hand_picks_up_and_drops_jar() -> void:
	var salt: SeasoningItem = _salt()
	assert_true(salt.can_interact(_actor))
	assert_true(salt.interact(_actor))
	assert_true(salt.is_held)
	assert_false(salt.can_interact(_actor), "en la mano no se vuelve a coger")
	_hold.drop()
	assert_false(salt.is_held)


func test_jar_tinted_with_seasoning_color() -> void:
	var salt: SeasoningItem = _salt()
	var cap: MeshInstance3D = salt.get_node("Model/Cap")
	var material: StandardMaterial3D = cap.material_override as StandardMaterial3D
	assert_not_null(material)
	assert_eq(material.albedo_color, SALT.color)
