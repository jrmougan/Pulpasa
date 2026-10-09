extends GutTest
## PUL-015 AC2: dejar un objeto en un slot lo alinea a su `%AnchorPoint`; cogerlo de nuevo
## libera el slot. Sustituye a `InteractableSlot` + `SnappingHelper`.

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const SLOT_SCENE: PackedScene = preload("res://entities/stations/slot.tscn")
const SALT: SeasoningData = preload("res://data/seasonings/salt.tres")
const PAPRIKA: SeasoningData = preload("res://data/seasonings/paprika.tres")
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
		return Slot.pick_up_item(actor, self)

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
	# Colocado antes de entrar al árbol: nunca existe en el origen, dentro del jugador.
	_slot.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(30.0)), Vector3(2, 0, -1))
	_level.add_child(_slot)


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


## PUL-016: el detector apunta al objeto guardado; cogerlo pasa por el slot y al soltarlo
## recupera capa, máscara y `freeze` originales.
func test_pul016_taking_stored_item_via_detector_restores_physics() -> void:
	_slot.global_transform = Transform3D(Basis.IDENTITY, Vector3(0, 0, -1))
	var item: Item = _held_item()
	assert_true(_slot.interact(_actor))
	await wait_physics_frames(3)
	var detector: InteractionDetector = _player.get_node("%InteractionDetector")
	assert_eq(detector.get_target(), item)
	assert_true(_actor.interact_pressed())
	assert_eq(_hold.get_held_item(), item)
	assert_false(_slot.has_item())
	_hold.drop()
	assert_false(item.freeze)
	assert_eq(item.collision_layer, INTERACTABLE_LAYER)
	assert_eq(item.collision_mask, 1)


func test_pul016_slot_of_and_pick_up_item() -> void:
	var loose: Item = Item.new()
	_level.add_child(loose)
	assert_null(Slot.slot_of(loose))
	var stored: Item = _held_item()
	_slot.interact(_actor)
	assert_eq(Slot.slot_of(stored), _slot)
	assert_true(Slot.pick_up_item(_actor, stored))
	assert_null(Slot.slot_of(stored))
	assert_eq(_hold.get_held_item(), stored)
	_hold.drop()
	assert_false(stored.freeze)
	assert_eq(stored.collision_layer, INTERACTABLE_LAYER)


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


## PUL-061: `initial_item_data` desaparece con los botes (scene-tree.md §7); `initial_item` se
## mantiene.
func test_pul061_initial_item_data_is_gone() -> void:
	var slot: Slot = SLOT_SCENE.instantiate()
	assert_false(&"initial_item_data" in slot)
	assert_true(&"initial_item" in slot)
	slot.free()


func test_ac2_slot_scene_fulfils_interaction_contract() -> void:
	assert_true(_slot.is_in_group(&"interactable"))
	assert_eq(InteractionContract.scan_tree(_slot), [])
	assert_eq(_slot.collision_layer, INTERACTABLE_LAYER)


func test_pul024_interactable_shape_matches_unity_slot_and_hugs_the_anchor() -> void:
	# `InteractableSlot.prefab`: collider 0,43 × 0,1 × 0,475 a la altura del ancla. Una caja de
	# 1,37 m frenaba al jugador ~0,7 m antes de la estantería (roadmap, fase 8).
	var shape_node: CollisionShape3D = _slot.get_node("CollisionShape3D")
	var box: BoxShape3D = shape_node.shape as BoxShape3D
	assert_lte(box.size.x, 0.5)
	assert_lte(box.size.z, 0.5)
	assert_lte(box.size.y, 0.2)
	var anchor: Marker3D = _slot.get_node("%Anchor")
	assert_almost_eq(shape_node.position.y, anchor.position.y - box.size.y / 2.0, 0.06)


## PUL-101 (ADR-003 §9.5): la marca `pass_mark` es parte del pasaplatos; sin mesa propia ni cuerpos
## que frenen (la barra del nivel es la mesa).
func test_pul101_slot_carries_the_visible_pass_mark_without_a_table() -> void:
	var model: Node3D = _slot.get_node("Model") as Node3D
	assert_true(model.visible)
	assert_eq(model.scene_file_path, "res://assets/models/furniture/counters/pass_mark.glb")
	assert_eq(model.find_children("*", "CollisionObject3D").size(), 0, "la marca no choca")
	assert_gt(model.find_children("*", "MeshInstance3D").size(), 0, "tiene malla visible")
	assert_almost_eq(model.position.y, 1.1, 0.001, "sobre la superficie de la barra")


## PUL-058 (ADR-003 §8.2): con `accepted_group`, lo que no está en el grupo se rechaza consumiendo
## la pulsación; ni se guarda ni se suelta.
func test_pul058_accepted_group_rejects_other_items_consuming_press() -> void:
	_slot.accepted_group = &"box"
	var item: Item = _held_item()
	assert_true(_slot.can_interact(_actor))
	assert_true(_slot.interact(_actor), "consume la pulsación")
	assert_false(_slot.has_item())
	assert_eq(_hold.get_held_item(), item, "sigue en la mano")
	assert_false(_slot.accepts(item))


func test_pul058_accepted_group_stores_items_in_group() -> void:
	_slot.accepted_group = &"box"
	var item: Item = _held_item()
	item.add_to_group(&"box")
	assert_true(_slot.accepts(item))
	assert_true(_slot.interact(_actor))
	assert_eq(_slot.get_item(), item)
	var fresh: Slot = SLOT_SCENE.instantiate()
	assert_eq(fresh.accepted_group, &"", "por defecto acepta todo")
	fresh.free()
