extends GutTest
## PUL-018: el puesto de entrega llama a `OrderService.try_deliver` al entrar el portador en
## `%DeliveryZone` y al interactuar (B12); una entrega = una `order_completed` (B1). La caja
## entregada se libera; la rechazada se queda en la mano. El label vive de señales (B16).

const EventBusScript: GDScript = preload("res://autoload/event_bus.gd")
const OrderServiceScript: GDScript = preload("res://autoload/order_service.gd")
const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const STAND_SCENE: PackedScene = preload("res://entities/stations/order_stand.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const SEASONING_SCENE: PackedScene = preload("res://entities/items/seasoning.tscn")
const CATALOG: OrderCatalog = preload("res://data/orders/order_catalog.tres")
const SLOT_ID: int = 2
const FAR: Vector3 = Vector3(20, 0, 20)

var _bus: Node
var _service: Node
var _level: Node3D
var _stand: OrderStand
var _player: Player
var _hold: HoldComponent
var _actor: InteractionComponent


func before_each() -> void:
	_bus = add_child_autofree(EventBusScript.new())
	_service = OrderServiceScript.new()
	_service.set_bus(_bus)
	add_child_autofree(_service)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5
	_service.setup(CATALOG, rng)
	_level = add_child_autofree(Node3D.new())
	_stand = STAND_SCENE.instantiate()
	_stand.slot_id = SLOT_ID
	_stand.set_bus(_bus)
	_stand.set_service(_service)
	_level.add_child(_stand)
	_player = PLAYER_SCENE.instantiate()
	_player.position = FAR
	_level.add_child(_player)
	_hold = _player.get_node("%HoldComponent")
	_hold.items_root = _level
	_actor = _player.get_node("%InteractionComponent")
	watch_signals(_bus)


func _label() -> String:
	return (_stand.get_node("%OrderLabel") as Label3D).text


func _order_for(slot_id: int) -> ActiveOrder:
	for order: ActiveOrder in _service.get_active_orders():
		if order.slot_id == slot_id:
			return order
	return null


## Caja en la mano con lo que pide `order` (o una caja pequeña vacía si es `null`).
func _box_in_hand(order: ActiveOrder) -> Box:
	var box: Box = BOX_SCENE.instantiate()
	_level.add_child(box)
	if order != null:
		box.data = order.data.recipe.box
		var guard: int = 0
		while not box.is_full() and guard < 200:
			var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
			_level.add_child(octopus)
			octopus.set_cooked()
			assert_true(_hold.pick_up(octopus))
			while octopus.is_inside_tree() and not box.is_full() and guard < 200:
				assert_true(box.interact(_actor))
				guard += 1
			if is_instance_valid(octopus):
				_hold.drop()
				octopus.free()
		for seasoning: SeasoningData in order.data.seasonings:
			var item: SeasoningItem = SEASONING_SCENE.instantiate()
			item.data = seasoning
			_level.add_child(item)
			assert_true(_hold.pick_up(item))
			assert_true(box.interact(_actor))
			_hold.drop()
			item.free()
	assert_true(_hold.pick_up(box))
	return box


func _is_released(node: Variant) -> bool:
	return not is_instance_valid(node) or (node as Node).is_queued_for_deletion()


func _enter_zone() -> void:
	_player.global_position = _stand.get_node("%DeliveryZone").global_position
	await wait_physics_frames(3)


func test_ac1_valid_box_in_zone_completes_exactly_one_order() -> void:
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	var order: ActiveOrder = _order_for(SLOT_ID)
	var box: Variant = _box_in_hand(order)
	await _enter_zone()
	assert_signal_emit_count(_bus, "order_completed", 1)
	var args: Array = get_signal_parameters(_bus, "order_completed", 0)
	assert_eq((args[0] as ActiveOrder).id, order.id)
	assert_eq((args[0] as ActiveOrder).slot_id, SLOT_ID)
	assert_signal_not_emitted(_bus, "delivery_rejected")
	assert_true(_is_released(box), "la caja entregada se libera")
	assert_null(_hold.get_held_item())


func test_ac1_label_moves_to_replacement_order() -> void:
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	var order: ActiveOrder = _order_for(SLOT_ID)
	assert_eq(_label(), "#%d" % order.id)
	_box_in_hand(order)
	await _enter_zone()
	var replacement: ActiveOrder = _order_for(SLOT_ID)
	assert_ne(replacement.id, order.id)
	assert_eq(_label(), "#%d" % replacement.id)


func test_ac1_other_slot_orders_do_not_touch_label() -> void:
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	var mine: String = _label()
	_bus.order_generated.emit(ActiveOrder.new(99, null, 3))
	_bus.order_completed.emit(ActiveOrder.new(98, null, 3), 0)
	_bus.order_expired.emit(ActiveOrder.new(97, null, 4), 0)
	assert_eq(_label(), mine)


func test_ac1_label_clears_on_reset_completed_and_expired() -> void:
	assert_eq(_label(), "–")
	_bus.order_generated.emit(ActiveOrder.new(7, null, SLOT_ID))
	assert_eq(_label(), "#7")
	_bus.orders_reset.emit()
	assert_eq(_label(), "–")
	_bus.order_generated.emit(ActiveOrder.new(8, null, SLOT_ID))
	_bus.order_completed.emit(ActiveOrder.new(8, null, SLOT_ID), 0)
	assert_eq(_label(), "–")
	_bus.order_generated.emit(ActiveOrder.new(9, null, SLOT_ID))
	_bus.order_expired.emit(ActiveOrder.new(9, null, SLOT_ID), 0)
	assert_eq(_label(), "–")


func test_ac1_ok_sound_only_for_own_slot() -> void:
	var ok: AudioStreamPlayer3D = _stand.get_node("%OkAudio")
	_bus.order_completed.emit(ActiveOrder.new(1, null, SLOT_ID + 1), 0)
	assert_false(ok.playing)
	_bus.order_completed.emit(ActiveOrder.new(1, null, SLOT_ID), 0)
	assert_true(ok.playing)


func test_ac2_wrong_box_is_rejected_error_sounds_and_box_stays_in_hand() -> void:
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	var box: Box = _box_in_hand(null)
	await _enter_zone()
	assert_signal_emit_count(_bus, "delivery_rejected", 1)
	assert_eq(get_signal_parameters(_bus, "delivery_rejected", 0)[0], SLOT_ID)
	assert_signal_not_emitted(_bus, "order_completed")
	assert_true((_stand.get_node("%ErrorAudio") as AudioStreamPlayer3D).playing)
	assert_false((_stand.get_node("%OkAudio") as AudioStreamPlayer3D).playing)
	assert_eq(_hold.get_held_item(), box)
	assert_false(_is_released(box))


func test_ac2_error_sound_only_for_own_slot() -> void:
	var error: AudioStreamPlayer3D = _stand.get_node("%ErrorAudio")
	_bus.delivery_rejected.emit(SLOT_ID + 1, 1, 0)
	assert_false(error.playing)
	_bus.delivery_rejected.emit(SLOT_ID, 1, 0)
	assert_true(error.playing)


func test_ac3_already_inside_zone_interact_delivers() -> void:
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	await _enter_zone()
	assert_signal_not_emitted(_bus, "order_completed")
	var box: Box = _box_in_hand(_order_for(SLOT_ID))
	await wait_physics_frames(2)
	assert_signal_not_emitted(_bus, "order_completed", "coger la caja dentro no entrega solo")
	assert_true(_stand.can_interact(_actor))
	assert_true(_stand.interact(_actor))
	assert_signal_emit_count(_bus, "order_completed", 1)
	assert_true(_is_released(box))
	assert_null(_hold.get_held_item())


func test_ac3_interact_with_wrong_box_consumes_press_and_keeps_box() -> void:
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	var box: Box = _box_in_hand(null)
	assert_true(_stand.can_interact(_actor))
	assert_true(_stand.interact(_actor), "consume la pulsación: no suelta la caja")
	assert_signal_emit_count(_bus, "delivery_rejected", 1)
	assert_eq(_hold.get_held_item(), box)


func test_ac3_interact_without_box_does_nothing() -> void:
	assert_false(_stand.can_interact(_actor))
	assert_false(_stand.interact(_actor))
	var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
	_level.add_child(octopus)
	assert_true(_hold.pick_up(octopus))
	assert_false(_stand.can_interact(_actor))
	assert_false(_stand.interact(_actor))
	assert_signal_not_emitted(_bus, "delivery_rejected")
	assert_eq(_hold.get_held_item(), octopus)


func test_ac4_player_without_box_or_with_other_item_does_not_deliver() -> void:
	await _enter_zone()
	assert_signal_not_emitted(_bus, "delivery_rejected")
	assert_signal_not_emitted(_bus, "order_completed")


func test_ac4_stand_fulfils_interaction_contract() -> void:
	assert_true(_stand.is_in_group(&"interactable"))
	assert_eq(InteractionContract.scan_tree(_stand), [])
	var zone: Area3D = _stand.get_node("%DeliveryZone")
	assert_eq(zone.collision_layer, 1 << 4, "capa delivery_zone")
