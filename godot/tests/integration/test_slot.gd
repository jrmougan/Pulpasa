extends GutTest
## PUL-015 AC2: dejar un objeto en un slot lo alinea a su `%AnchorPoint`; cogerlo de nuevo
## libera el slot. Sustituye a `InteractableSlot` + `SnappingHelper`.

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const SLOT_SCENE: PackedScene = preload("res://entities/stations/slot.tscn")
const INTERACTABLE_LAYER: int = 1 << 2
const EPSILON: float = 0.0001

var _level: Node3D
var _player: Player
var _hold: HoldComponent
var _actor: InteractionComponent
var _slot: Slot


class Item:
	extends RigidBody3D
	## Cogible con `%AnchorPoint` desplazado y girado, para comprobar la alineación.

	var is_held: bool = false
	var anchor_point: Marker3D

	func _init() -> void:
		collision_layer = INTERACTABLE_LAYER
		collision_mask = 1
		add_to_group(&"interactable")
		add_to_group(&"pickable")
		var shape: CollisionShape3D = CollisionShape3D.new()
		shape.shape = BoxShape3D.new()
		add_child(shape)
		anchor_point = Marker3D.new()
		anchor_point.name = "AnchorPoint"
		anchor_point.transform = Transform3D(
			Basis(Vector3.UP, deg_to_rad(90.0)), Vector3(0.1, -0.14, 0.05)
		)
		add_child(anchor_point)
		anchor_point.owner = self
		anchor_point.unique_name_in_owner = true

	func can_interact(actor: InteractionComponent) -> bool:
		return not is_held and actor.holder.can_hold(self)

	func interact(actor: InteractionComponent) -> bool:
		return actor.holder.pick_up(self)

	func on_picked_up(_holder: Holder) -> void:
		is_held = true

	func on_dropped() -> void:
		is_held = false


func before_each() -> void:
	_level = add_child_autofree(Node3D.new())
	_player = PLAYER_SCENE.instantiate()
	_level.add_child(_player)
	_hold = _player.get_node("%HoldComponent")
	_hold.items_root = _level
	_actor = _player.get_node("%InteractionComponent")
	_slot = SLOT_SCENE.instantiate()
	_level.add_child(_slot)
	_slot.global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(30.0)), Vector3(2, 0, -1))


func _held_item() -> Item:
	var item: Item = Item.new()
	_level.add_child(item)
	assert_true(_hold.pick_up(item))
	return item


func _assert_transform_eq(a: Transform3D, b: Transform3D, msg: String) -> void:
	assert_true(a.is_equal_approx(b), "%s: %s != %s" % [msg, a, b])


func test_ac2_placing_aligns_item_anchor_point_to_slot_anchor() -> void:
	var item: Item = _held_item()
	assert_true(_slot.can_interact(_actor))
	assert_true(_slot.interact(_actor))
	var anchor: Node3D = _slot.get_node("%Anchor")
	assert_eq(item.get_parent(), anchor)
	_assert_transform_eq(item.anchor_point.global_transform, anchor.global_transform, "AnchorPoint")
	assert_eq(_slot.get_item(), item)
	assert_true(_slot.has_item())
	assert_null(_hold.get_held_item(), "la mano queda vacía")
	assert_false(item.is_held)


func test_ac2_item_without_anchor_point_aligns_its_origin() -> void:
	var item: Item = _held_item()
	item.anchor_point.free()
	_slot.interact(_actor)
	var anchor: Node3D = _slot.get_node("%Anchor")
	_assert_transform_eq(item.global_transform, anchor.global_transform, "origen")


func test_ac2_stored_item_is_frozen_and_not_detectable() -> void:
	var item: Item = _held_item()
	_slot.interact(_actor)
	assert_true(item.freeze)
	assert_eq(item.collision_layer & INTERACTABLE_LAYER, 0, "solo se detecta el slot")


func test_ac2_picking_up_again_frees_slot() -> void:
	var item: Item = _held_item()
	_slot.interact(_actor)
	assert_true(_slot.can_interact(_actor))
	assert_true(_slot.interact(_actor))
	assert_eq(_hold.get_held_item(), item)
	assert_true(item.is_held)
	assert_false(_slot.has_item())
	assert_null(_slot.get_item())


func test_ac2_item_taken_from_slot_drops_unfrozen_on_its_layer() -> void:
	var item: Item = _held_item()
	_slot.interact(_actor)
	_slot.interact(_actor)
	_hold.drop()
	assert_false(item.freeze, "no se queda congelado en el aire")
	assert_eq(item.collision_layer, INTERACTABLE_LAYER)
	assert_eq(item.collision_mask, 1)


func test_ac2_occupied_slot_rejects_full_hand() -> void:
	var stored: Item = _held_item()
	_slot.interact(_actor)
	var carried: Item = _held_item()
	assert_false(_slot.can_interact(_actor))
	assert_false(_slot.interact(_actor))
	assert_eq(_slot.get_item(), stored)
	assert_eq(_hold.get_held_item(), carried)


func test_ac2_empty_slot_with_empty_hand_does_nothing() -> void:
	assert_false(_slot.can_interact(_actor))
	assert_false(_slot.interact(_actor))
	assert_false(_slot.has_item())


func test_ac2_freed_item_frees_slot() -> void:
	var item: Item = _held_item()
	_slot.interact(_actor)
	item.free()
	assert_false(_slot.has_item())
	assert_null(_slot.get_item())


func test_ac2_interact_press_places_and_takes_via_detector() -> void:
	_slot.global_transform = Transform3D(Basis.IDENTITY, Vector3(0, 0, -1))
	var item: Item = _held_item()
	await wait_physics_frames(3)
	assert_true(_actor.interact_pressed())
	assert_eq(_slot.get_item(), item)
	await wait_physics_frames(3)
	assert_true(_actor.interact_pressed())
	assert_eq(_hold.get_held_item(), item)
	assert_false(_slot.has_item())


func test_ac2_initial_item_is_stored_on_ready() -> void:
	var scene: PackedScene = PackedScene.new()
	var proto: RigidBody3D = RigidBody3D.new()
	assert_eq(scene.pack(proto), OK)
	proto.free()
	var slot: Slot = SLOT_SCENE.instantiate()
	slot.initial_item = scene
	_level.add_child(slot)
	assert_true(slot.has_item())
	assert_eq(slot.get_item().get_parent(), slot.get_node("%Anchor"))


func test_ac2_slot_scene_fulfils_interaction_contract() -> void:
	assert_true(_slot.is_in_group(&"interactable"))
	assert_eq(InteractionContract.scan_tree(_slot), [])
	assert_eq(_slot.collision_layer, INTERACTABLE_LAYER)
