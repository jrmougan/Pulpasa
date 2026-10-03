extends GutTest
## PUL-012 AC3/AC4: HoldComponent coge y suelta por el contrato `pickable` (B4) y valida
## antes de mutar (B5). Usa la escena real del jugador.

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const IncompletePickable: GDScript = preload("res://tests/helpers/incomplete_pickable.gd")
const HELD_LAYER: int = 1 << 3
const INTERACTABLE_LAYER: int = 1 << 2

var _player: Player
var _hold: HoldComponent
var _items_root: Node3D


class CountingPickable:
	extends RigidBody3D
	## Pickable 3D completo que cuenta las llamadas del contrato.

	var is_held: bool = false
	var picked_up_calls: int = 0
	var dropped_calls: int = 0
	var last_holder: Holder

	func on_picked_up(holder: Holder) -> void:
		picked_up_calls += 1
		last_holder = holder
		is_held = true

	func on_dropped() -> void:
		dropped_calls += 1
		is_held = false


class NoPickedUpPickable:
	extends RigidBody3D
	## Sin `on_picked_up`.

	var is_held: bool = false
	var dropped_calls: int = 0

	func on_dropped() -> void:
		dropped_calls += 1


class NoDroppedPickable:
	extends RigidBody3D
	## Sin `on_dropped`.

	var is_held: bool = false
	var picked_up_calls: int = 0

	func on_picked_up(_holder: Holder) -> void:
		picked_up_calls += 1


class NoIsHeldPickable:
	extends RigidBody3D
	## Sin `is_held`.

	var picked_up_calls: int = 0

	func on_picked_up(_holder: Holder) -> void:
		picked_up_calls += 1

	func on_dropped() -> void:
		pass


func before_each() -> void:
	var level: Node3D = add_child_autofree(Node3D.new())
	_items_root = Node3D.new()
	_items_root.name = "Items"
	level.add_child(_items_root)
	_player = PLAYER_SCENE.instantiate()
	_player.position = Vector3(1.0, 0.0, 2.0)
	level.add_child(_player)
	_hold = _player.get_node("%HoldComponent")
	_hold.items_root = _items_root


func _make_pickable() -> CountingPickable:
	var item: CountingPickable = CountingPickable.new()
	item.collision_layer = INTERACTABLE_LAYER
	item.add_to_group(&"pickable")
	_items_root.add_child(item)
	item.global_position = Vector3(3.0, 0.0, 3.0)
	return item


func test_ac3_pick_up_reparents_under_hold_point() -> void:
	var item: CountingPickable = _make_pickable()
	assert_true(_hold.pick_up(item))
	assert_eq(item.get_parent(), _player.get_node("%HoldPoint"))
	assert_eq(item.position, Vector3.ZERO)
	assert_eq(_hold.get_held_item(), item)


func test_ac3_pick_up_sets_held_layer_and_freezes() -> void:
	var item: CountingPickable = _make_pickable()
	_hold.pick_up(item)
	assert_eq(item.collision_layer, HELD_LAYER)
	assert_true(item.freeze)


func test_ac3_pick_up_calls_on_picked_up_once_and_emits() -> void:
	var item: CountingPickable = _make_pickable()
	watch_signals(_hold)
	_hold.pick_up(item)
	assert_true(item.is_held)
	assert_eq(item.picked_up_calls, 1)
	assert_eq(item.last_holder, _hold)
	assert_signal_emit_count(_hold, "item_picked_up", 1)
	assert_signal_emitted_with_parameters(_hold, "item_picked_up", [item])


func test_ac3_pick_up_works_for_item_outside_tree() -> void:
	var item: CountingPickable = CountingPickable.new()
	item.add_to_group(&"pickable")
	autofree(item)
	assert_true(_hold.pick_up(item))
	assert_eq(item.get_parent(), _player.get_node("%HoldPoint"))


func test_ac3_second_pick_up_is_rejected_while_holding() -> void:
	var first: CountingPickable = _make_pickable()
	var second: CountingPickable = _make_pickable()
	_hold.pick_up(first)
	assert_false(_hold.pick_up(second))
	assert_eq(second.get_parent(), _items_root)
	assert_eq(second.picked_up_calls, 0)


func test_ac3_drop_places_item_in_front_and_above_under_items_root() -> void:
	var item: CountingPickable = _make_pickable()
	_player.rotation.y = -PI / 2.0  # mira hacia +X
	_hold.pick_up(item)
	assert_eq(_hold.drop(), item)
	assert_eq(item.get_parent(), _items_root)
	var expected: Vector3 = _player.global_position + Vector3(0.6, 0.6, 0.0)
	assert_almost_eq(item.global_position, expected, Vector3.ONE * 0.001)
	assert_null(_hold.get_held_item())


func test_ac3_drop_calls_on_dropped_once_and_restores_physics() -> void:
	var item: CountingPickable = _make_pickable()
	_hold.pick_up(item)
	watch_signals(_hold)
	_hold.drop()
	assert_eq(item.dropped_calls, 1)
	assert_false(item.is_held)
	assert_false(item.freeze)
	assert_eq(item.collision_layer, INTERACTABLE_LAYER)
	assert_signal_emit_count(_hold, "item_dropped", 1)
	assert_signal_emitted_with_parameters(_hold, "item_dropped", [item])


func test_ac3_drop_without_item_returns_null_without_signal() -> void:
	watch_signals(_hold)
	assert_null(_hold.drop())
	assert_signal_not_emitted(_hold, "item_dropped")


func test_ac4_non_pickable_body_is_rejected_without_changes() -> void:
	var item: CountingPickable = CountingPickable.new()  # fuera del grupo `pickable`
	item.collision_layer = INTERACTABLE_LAYER
	_items_root.add_child(item)
	watch_signals(_hold)
	assert_false(_hold.can_hold(item))
	assert_false(_hold.pick_up(item))
	assert_null(_hold.get_held_item())
	assert_eq(item.get_parent(), _items_root)
	assert_eq(item.collision_layer, INTERACTABLE_LAYER)
	assert_false(item.freeze)
	assert_eq(item.picked_up_calls, 0)
	assert_signal_not_emitted(_hold, "item_picked_up")


func test_ac4_incomplete_contract_is_rejected_without_changes() -> void:
	var item: Node = IncompletePickable.new()
	item.add_to_group(&"pickable")
	_items_root.add_child(item)
	watch_signals(_hold)
	assert_false(_hold.pick_up(item))
	assert_null(_hold.get_held_item())
	assert_eq(item.get_parent(), _items_root)
	assert_false(item.get("picked_up_called"))
	assert_signal_not_emitted(_hold, "item_picked_up")


func _assert_rejected_without_changes(item: RigidBody3D) -> void:
	item.collision_layer = INTERACTABLE_LAYER
	item.add_to_group(&"pickable")
	_items_root.add_child(item)
	item.global_position = Vector3(3.0, 0.0, 3.0)
	watch_signals(_hold)
	assert_false(_hold.can_hold(item))
	assert_false(_hold.pick_up(item))
	assert_null(_hold.get_held_item())
	assert_eq(item.get_parent(), _items_root)
	assert_eq(item.global_position, Vector3(3.0, 0.0, 3.0))
	assert_eq(item.collision_layer, INTERACTABLE_LAYER)
	assert_false(item.freeze)
	assert_signal_not_emitted(_hold, "item_picked_up")


func test_ac4_body_without_on_picked_up_is_rejected_without_changes() -> void:
	var item: NoPickedUpPickable = NoPickedUpPickable.new()
	_assert_rejected_without_changes(item)
	assert_false(item.is_held)
	assert_eq(item.dropped_calls, 0)


func test_ac4_body_without_on_dropped_is_rejected_without_changes() -> void:
	var item: NoDroppedPickable = NoDroppedPickable.new()
	_assert_rejected_without_changes(item)
	assert_false(item.is_held)
	assert_eq(item.picked_up_calls, 0)


func test_ac4_body_without_is_held_is_rejected_without_changes() -> void:
	var item: NoIsHeldPickable = NoIsHeldPickable.new()
	_assert_rejected_without_changes(item)
	assert_eq(item.picked_up_calls, 0)


func test_ac3_freed_held_item_clears_hand_and_allows_new_pick_up() -> void:
	var item: CountingPickable = _make_pickable()
	_hold.pick_up(item)
	await wait_physics_frames(2)
	assert_true(_player.is_holding)
	item.queue_free()
	await wait_physics_frames(3)
	assert_false(is_instance_valid(item))
	assert_null(_hold.get_held_item())
	assert_false(_player.is_holding)
	watch_signals(_hold)
	assert_null(_hold.drop())
	assert_signal_not_emitted(_hold, "item_dropped")
	var other: CountingPickable = _make_pickable()
	assert_true(_hold.pick_up(other))
	assert_eq(_hold.get_held_item(), other)
	await wait_physics_frames(2)
	assert_true(_player.is_holding)
	assert_eq(_hold.drop(), other)
	assert_eq(other.dropped_calls, 1)


func test_ac3_item_queued_for_deletion_is_not_reported_as_held() -> void:
	var item: CountingPickable = _make_pickable()
	_hold.pick_up(item)
	item.queue_free()
	assert_null(_hold.get_held_item())
	assert_null(_hold.drop())


func test_ac4_null_is_rejected() -> void:
	watch_signals(_hold)
	assert_false(_hold.pick_up(null))
	assert_null(_hold.get_held_item())
	assert_signal_not_emitted(_hold, "item_picked_up")


func test_ac4_helper_accepts_complete_pickable_in_group() -> void:
	var item: FakePickable = autofree(FakePickable.new())
	item.add_to_group(&"pickable")
	assert_true(PickableContract.is_valid_pickable(item))


func test_ac4_helper_rejects_outside_group_incomplete_or_null() -> void:
	var outside: FakePickable = autofree(FakePickable.new())
	assert_false(PickableContract.is_valid_pickable(outside))
	var incomplete: Node = autofree(IncompletePickable.new())
	incomplete.add_to_group(&"pickable")
	assert_false(PickableContract.is_valid_pickable(incomplete))
	assert_false(PickableContract.is_valid_pickable(null))
