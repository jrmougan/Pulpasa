# gdlint: disable=max-public-methods
extends GutTest
## PUL-018: el puesto de entrega llama a `OrderService.try_deliver` al entrar el portador en
## `%DeliveryZone`; una entrega = una `order_completed` (B1). La caja entregada se libera. El label
## vive de señales (B16).
## PUL-039: la zona solo entrega una caja que coincide con la comanda viva del puesto; con otra
## no hace nada (sin rechazo ni penalización).
## PUL-131 (D26, ADR-003 §11.7): el puesto ya no es `interactable` (capa `world`), no se elige
## desde ningún punto de la zona, y entrega también a quien ya estaba dentro cuando la caja pasa
## a coincidir. `wrong_delivery_penalty` = 0 y no hay `deliver_error`.
## PUL-071: los sonidos salen de `%Feedback` (ADR-006 §4); se cuentan sus `played`.

const EventBusScript: GDScript = preload("res://autoload/event_bus.gd")
const OrderServiceScript: GDScript = preload("res://autoload/order_service.gd")
const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const STAND_SCENE: PackedScene = preload("res://entities/stations/order_stand.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const CATALOG: OrderCatalog = preload("res://data/orders/order_catalog.tres")
const SLOT_ID: int = 2
const FAR: Vector3 = Vector3(20, 0, 20)
const PALETTE: StandPalette = preload("res://data/config/stand_palette.tres")
const MAT_ON_PATH: String = "res://assets/models/stations/order_stand/delivery_zone_on.tres"
const MAT_OFF_PATH: String = "res://assets/models/stations/order_stand/delivery_zone_off.tres"
const ZONE_Z: float = 3.40
## Ticks a 60 Hz que caben en 0,1 s (R12).
const LIGHT_TICKS: int = 6
const BOX: BoxData = preload("res://data/boxes/box.tres")
const A_FEIRA: OrderData = preload("res://data/orders/a_feira.tres")

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
	watch_signals(_feedback())


func _feedback() -> FeedbackPlayer:
	return _stand.get_node("%Feedback") as FeedbackPlayer


## Veces que `%Feedback` reprodujo `cue`.
func _played(cue: StringName) -> int:
	var count: int = 0
	for i: int in get_signal_emit_count(_feedback(), "played"):
		if get_signal_parameters(_feedback(), "played", i)[0] == cue:
			count += 1
	return count


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
		box.data = BOX
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
		# Condimentos con la API de los dispensadores (apply_seasoning, ADR-003 §10.2).
		for seasoning: SeasoningData in order.data.seasonings:
			assert_eq(box.apply_seasoning(seasoning), SeasoningRules.Rejection.NONE)
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
	_bus.order_completed.emit(ActiveOrder.new(1, null, SLOT_ID + 1), 0)
	assert_signal_not_emitted(_feedback(), "played")
	_bus.order_completed.emit(ActiveOrder.new(1, null, SLOT_ID), 0)
	assert_signal_emit_count(_feedback(), "played", 1)
	assert_eq(_played(&"deliver_ok"), 1)
	assert_true(_feedback().playing)


func test_pul039_wrong_box_in_zone_does_nothing() -> void:
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	var box: Box = _box_in_hand(null)
	await _enter_zone()
	assert_signal_not_emitted(_bus, "delivery_rejected", "sin rechazo ni penalización")
	assert_signal_not_emitted(_bus, "order_completed")
	assert_eq(_played(&"deliver_ok"), 0)
	assert_eq(_hold.get_held_item(), box)


func test_pul039_box_of_another_stand_in_zone_does_nothing() -> void:
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	var own: OrderData = _order_for(SLOT_ID).data
	var other: ActiveOrder = null
	for order: ActiveOrder in _service.get_active_orders():
		if order.slot_id != SLOT_ID and order.data != own:
			other = order
	assert_not_null(other, "con la semilla 5 hay otra receta en otro puesto")
	if other == null:
		return
	var box: Box = _box_in_hand(other)
	assert_false(OrderValidator.matches(own, box.get_contents()))
	await _enter_zone()
	assert_signal_not_emitted(_bus, "delivery_rejected")
	assert_signal_not_emitted(_bus, "order_completed")
	assert_eq(_hold.get_held_item(), box)


func test_pul039_zone_ignores_box_of_expired_order() -> void:
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	var old: ActiveOrder = _order_for(SLOT_ID)
	var box: Box = _box_in_hand(old)
	_bus.order_expired.emit(old, 0)
	await _enter_zone()
	assert_signal_not_emitted(_bus, "order_completed")
	assert_signal_not_emitted(_bus, "delivery_rejected")
	assert_eq(_hold.get_held_item(), box)


## Tablero con un catálogo de una sola comanda (`first`) y penalizaciones reales; tras llenar los
## puestos, el catálogo pasa a `replacement` (la reposición del mismo tick sale de él).
func _expiring_board(first: OrderData, replacement: OrderData) -> ActiveOrder:
	var catalog: OrderCatalog = OrderCatalog.new()
	catalog.orders = [first] as Array[OrderData]
	catalog.max_active_orders = 4
	var config: RoundConfig = RoundConfig.new()
	config.wrong_delivery_penalty = 0
	config.expire_penalty = 3
	_service.setup(catalog, null, config)
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	catalog.orders = [replacement] as Array[OrderData]
	return _order_for(SLOT_ID)


## Caduca de verdad con `advance` (reposición en el mismo tick) con la caja de la caducada en la
## mano: la zona no entrega ni rechaza (AC5b; ya no hay entrega por pulsación).
func _assert_expiry_tick(first: OrderData, replacement: OrderData) -> void:
	var old: ActiveOrder = _expiring_board(first, replacement)
	var box: Box = _box_in_hand(old)
	_service.board.advance(first.max_time + 0.01)
	var fresh: ActiveOrder = _order_for(SLOT_ID)
	assert_ne(fresh.id, old.id, "repuesta en el mismo tick")
	assert_eq(fresh.data, replacement)
	assert_eq(_label(), "#%d" % fresh.id)
	_stand._on_body_entered(_player)
	assert_signal_not_emitted(_bus, "order_completed", "la zona no entrega a la repuesta")
	assert_signal_not_emitted(_bus, "delivery_rejected", "la zona no rechaza")
	assert_eq(_hold.get_held_item(), box)


func test_pul039_expiry_tick_same_recipe_zone_does_not_deliver() -> void:
	var data: OrderData = CATALOG.orders[0]
	await _assert_expiry_tick(data, data)


func test_pul039_expiry_tick_other_recipe_zone_does_not_deliver() -> void:
	var first: OrderData = CATALOG.orders[0]
	var other: OrderData = null
	for data: OrderData in CATALOG.orders:
		if data.recipe != first.recipe or data.seasonings != first.seasonings:
			other = data
	assert_not_null(other)
	await _assert_expiry_tick(first, other)


func test_pul039_zone_delivers_replacement_in_a_later_tick() -> void:
	var data: OrderData = CATALOG.orders[0]
	var old: ActiveOrder = _expiring_board(data, data)
	_box_in_hand(old)
	_service.board.advance(data.max_time + 0.01)
	# Tick siguiente: como `RoundManager`, un `advance` por tick de física.
	await wait_physics_frames(1)
	_service.board.advance(0.01)
	_stand._on_body_entered(_player)
	assert_signal_emit_count(_bus, "order_completed", 1, "misma receta: entrega a la repuesta")
	assert_signal_not_emitted(_bus, "delivery_rejected")


func test_d26_a_rejection_on_the_bus_does_not_sound_in_the_stand() -> void:
	_bus.delivery_rejected.emit(SLOT_ID, 1, 0)
	assert_signal_not_emitted(_feedback(), "played")


## D26: quien ya está dentro de la zona entrega en el primer tick en que su caja pasa a coincidir
## con la comanda viva (aquí, la comanda sale con él dentro), sin pulsar nada.
func test_d26_carrier_already_inside_delivers_when_the_order_appears() -> void:
	var catalog: OrderCatalog = OrderCatalog.new()
	catalog.orders = [A_FEIRA] as Array[OrderData]
	catalog.max_active_orders = 4
	_service.setup(catalog, null, RoundConfig.new())
	var order: ActiveOrder = ActiveOrder.new(7, catalog.orders[0], SLOT_ID)
	var box: Box = _box_in_hand(order)
	await _enter_zone()
	await wait_physics_frames(3)
	assert_signal_not_emitted(_bus, "order_completed", "sin comanda no hay entrega")
	assert_eq(_hold.get_held_item(), box)
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	await wait_physics_frames(3)
	assert_signal_emit_count(_bus, "order_completed", 1)
	assert_signal_not_emitted(_bus, "delivery_rejected")
	assert_true(_is_released(box))


## D26: completar la caja dentro de la zona entrega en el primer tick en que coincide.
func test_d26_carrier_inside_delivers_when_the_box_becomes_the_right_one() -> void:
	var catalog: OrderCatalog = OrderCatalog.new()
	catalog.orders = [A_FEIRA] as Array[OrderData]
	catalog.max_active_orders = 4
	_service.setup(catalog, null, RoundConfig.new())
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	var order: ActiveOrder = _order_for(SLOT_ID)
	var box: Box = _box_in_hand(order)
	assert_true(box.remove_seasoning(order.data.seasonings[0]))
	await _enter_zone()
	await wait_physics_frames(3)
	assert_signal_not_emitted(_bus, "order_completed", "la caja no coincide")
	assert_eq(box.apply_seasoning(order.data.seasonings[0]), SeasoningRules.Rejection.NONE)
	await wait_physics_frames(3)
	assert_signal_emit_count(_bus, "order_completed", 1)
	assert_signal_not_emitted(_bus, "delivery_rejected")
	assert_true(_is_released(box))


func test_ac4_player_without_box_or_with_other_item_does_not_deliver() -> void:
	await _enter_zone()
	assert_signal_not_emitted(_bus, "delivery_rejected")
	assert_signal_not_emitted(_bus, "order_completed")


func test_d26_stand_is_not_interactable_and_sits_on_the_world_layer() -> void:
	assert_false(_stand.is_in_group(&"interactable"))
	assert_false(_stand.has_method(&"can_interact"))
	assert_false(_stand.has_method(&"interact"))
	assert_false(_stand.has_method(&"get_action_hint"))
	assert_eq(InteractionContract.scan_tree(_stand), [] as Array[String])
	assert_eq(_stand.collision_layer, 1, "capa world: sigue siendo un mostrador que no se cruza")
	var zone: Area3D = _stand.get_node("%DeliveryZone")
	assert_eq(zone.collision_layer, 1 << 4, "capa delivery_zone")


## El detector real no lo elige desde ningún punto de la zona ni de sus alrededores, con la caja
## de la comanda en la mano.
## COOP_2P: dos jugadores dentro de la misma zona, cada uno con su caja. Una entrega por caja
## que encaja, ningun `delivery_rejected`, y el segundo solo entrega si su caja encaja con la
## comanda repuesta (aqui la misma receta, asi que entrega los dos).
func test_d26_two_players_in_the_same_zone_deliver_one_box_each() -> void:
	var catalog: OrderCatalog = OrderCatalog.new()
	catalog.orders = [A_FEIRA] as Array[OrderData]
	catalog.max_active_orders = 4
	_service.setup(catalog, null, RoundConfig.new())
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	var second: Player = PLAYER_SCENE.instantiate()
	second.position = FAR + Vector3(5, 0, 0)
	_level.add_child(second)
	var second_hold: HoldComponent = second.get_node("%HoldComponent")
	second_hold.items_root = _level
	var first_box: Box = _box_in_hand(_order_for(SLOT_ID))
	var other_box: Box = BOX_SCENE.instantiate()
	other_box.data = BOX
	_level.add_child(other_box)
	other_box.fill = 1.0
	# Caja del segundo: llena y con el aliño pedido pero sin pulpo (no encaja nunca).
	for seasoning: SeasoningData in _order_for(SLOT_ID).data.seasonings:
		other_box.apply_seasoning(seasoning)
	assert_true(second_hold.pick_up(other_box))
	var zone: Vector3 = _stand.get_node("%DeliveryZone").global_position
	_player.global_position = zone + Vector3(-0.3, 0, 0)
	second.global_position = zone + Vector3(0.3, 0, 0)
	await wait_physics_frames(6)
	assert_signal_emit_count(_bus, "order_completed", 1, "una sola entrega: la caja que encaja")
	assert_signal_not_emitted(_bus, "delivery_rejected")
	assert_true(_is_released(first_box))
	assert_eq(second_hold.get_held_item(), other_box, "la caja que no encaja se queda")
	# Ahora el segundo recibe una caja que encaja con la comanda repuesta: entrega, una vez.
	var fitting: Box = _box_for_player(second, second_hold, _order_for(SLOT_ID))
	await wait_physics_frames(6)
	assert_signal_emit_count(_bus, "order_completed", 2, "una entrega por caja que encaja")
	assert_signal_not_emitted(_bus, "delivery_rejected")
	assert_true(_is_released(fitting))


## Caja que encaja con `order`, preparada en la mano de `player` (que ya lleva otra: se suelta).
func _box_for_player(player: Player, hold: HoldComponent, order: ActiveOrder) -> Box:
	var old: Node = hold.drop()
	if old != null:
		old.free()
	var actor: InteractionComponent = player.get_node("%InteractionComponent")
	var box: Box = BOX_SCENE.instantiate()
	_level.add_child(box)
	box.data = BOX
	var guard: int = 0
	while not box.is_full() and guard < 200:
		var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
		_level.add_child(octopus)
		octopus.set_cooked()
		assert_true(hold.pick_up(octopus))
		while octopus.is_inside_tree() and not box.is_full() and guard < 200:
			assert_true(box.interact(actor))
			guard += 1
		if is_instance_valid(octopus):
			hold.drop()
			octopus.free()
	for seasoning: SeasoningData in order.data.seasonings:
		assert_eq(box.apply_seasoning(seasoning), SeasoningRules.Rejection.NONE)
	assert_true(hold.pick_up(box))
	return box


func test_d26_detector_never_picks_the_stand_from_any_point_of_the_zone() -> void:
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	_box_in_hand(_order_for(SLOT_ID))
	var detector: InteractionDetector = _player.get_node("%InteractionDetector")
	var zone_center: Vector3 = _stand.get_node("%DeliveryZone").global_position
	var checked: int = 0
	for x: float in [-0.7, -0.35, 0.0, 0.35, 0.7]:
		for z: float in [-1.5, -0.5, 0.0, 0.5, 1.0, 1.5, 2.5]:
			_player.global_position = zone_center + Vector3(x, 0.0, z)
			for yaw: float in [0.0, PI / 2.0, PI, -PI / 2.0]:
				_player.rotation.y = yaw
				await wait_physics_frames(1)
				detector.refresh()
				assert_ne(detector.get_target(), _stand, "(%s, %s) yaw %s" % [x, z, yaw])
				checked += 1
	assert_eq(checked, 140)


func test_d26_wrong_delivery_penalty_is_zero_and_no_deliver_error_cue() -> void:
	var config: RoundConfig = load("res://data/config/round_config.tres") as RoundConfig
	assert_eq(config.wrong_delivery_penalty, 0)
	var map: AudioFeedbackMap = load("res://data/audio/feedback_map.tres") as AudioFeedbackMap
	assert_null(map.get_cue(&"deliver_error"))


func test_review_same_tick_both_entry_points_valid_box_completes_once() -> void:
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	var box: Box = _box_in_hand(_order_for(SLOT_ID))
	_stand._on_body_entered(_player)
	_stand._deliver_to_carriers_inside()
	assert_signal_emit_count(_bus, "order_completed", 1)
	assert_signal_not_emitted(_bus, "delivery_rejected")
	assert_true(_is_released(box))


func test_review_box_staying_in_zone_does_not_retry_by_itself() -> void:
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	_box_in_hand(null)
	await _enter_zone()
	await wait_physics_frames(10)
	assert_signal_not_emitted(_bus, "delivery_rejected")


func test_review_late_stand_shows_current_order_id() -> void:
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	var late: OrderStand = STAND_SCENE.instantiate()
	late.slot_id = 3
	late.set_bus(_bus)
	late.set_service(_service)
	_level.add_child(late)
	assert_eq((late.get_node("%OrderLabel") as Label3D).text, "#%d" % _order_for(3).id)
	var empty: OrderStand = STAND_SCENE.instantiate()
	empty.slot_id = 9
	empty.set_bus(_bus)
	empty.set_service(_service)
	_level.add_child(empty)
	assert_eq((empty.get_node("%OrderLabel") as Label3D).text, "–")


# --- PUL-100: zona de entrega iluminada (R12, ADR-003 §9.4) ---
## Coloca al jugador a `distance` metros del centro de la zona (hacia +Z local), fuera de ella.
func _stand_at(distance: float) -> void:
	_player.global_position = _stand.get_node("%DeliveryZone").global_position
	_player.global_position += Vector3(0, 0, distance)
	await wait_physics_frames(LIGHT_TICKS)


func _frame_material(stand: OrderStand) -> StandardMaterial3D:
	var frame: MeshInstance3D = stand.find_child("DeliveryFrame", true, false) as MeshInstance3D
	assert_not_null(frame, "DeliveryFrame del .glb")
	return frame.get_active_material(0) as StandardMaterial3D


func test_pul100_ac1_matching_box_near_zone_lights_it_within_a_tenth_of_a_second() -> void:
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	assert_false(_stand.is_zone_lit())
	_box_in_hand(_order_for(SLOT_ID))
	await _stand_at(1.5)
	assert_true(_stand.is_zone_lit())
	assert_signal_not_emitted(_bus, "order_completed", "encender no entrega")


func test_pul100_ac1_wrong_box_keeps_zone_off() -> void:
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	_box_in_hand(null)
	await _stand_at(1.5)
	assert_false(_stand.is_zone_lit())


func test_pul100_ac1_box_of_another_stand_keeps_zone_off() -> void:
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	var own: OrderData = _order_for(SLOT_ID).data
	for order: ActiveOrder in _service.get_active_orders():
		if order.slot_id != SLOT_ID and order.data != own:
			_box_in_hand(order)
			await _stand_at(1.5)
			assert_false(_stand.is_zone_lit())
			return
	fail_test("con la semilla 5 hay otra receta en otro puesto")


func test_pul100_ac1_no_box_or_other_item_keeps_zone_off() -> void:
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	await _stand_at(1.5)
	assert_false(_stand.is_zone_lit(), "sin nada en la mano")
	var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
	_level.add_child(octopus)
	assert_true(_hold.pick_up(octopus))
	await wait_physics_frames(LIGHT_TICKS)
	assert_false(_stand.is_zone_lit(), "con un pulpo")


func test_pul100_ac1_beyond_two_metres_keeps_zone_off() -> void:
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	_box_in_hand(_order_for(SLOT_ID))
	await _stand_at(2.6)
	assert_false(_stand.is_zone_lit())
	_player.global_position = _stand.get_node("%DeliveryZone").global_position + Vector3(0, 0, 1.9)
	await wait_physics_frames(LIGHT_TICKS)
	assert_true(_stand.is_zone_lit(), "a 1,9 m sí")


func test_pul100_ac1_zone_turns_off_when_carrier_leaves() -> void:
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	_box_in_hand(_order_for(SLOT_ID))
	await _stand_at(1.5)
	assert_true(_stand.is_zone_lit())
	_player.global_position = FAR
	await wait_physics_frames(LIGHT_TICKS)
	assert_false(_stand.is_zone_lit())


func test_pul100_ac1_zone_turns_off_on_expired_and_reset() -> void:
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	var order: ActiveOrder = _order_for(SLOT_ID)
	_box_in_hand(order)
	await _stand_at(1.5)
	assert_true(_stand.is_zone_lit())
	_bus.order_expired.emit(order, 0)
	assert_false(_stand.is_zone_lit(), "caducada: apagada al instante")
	await wait_physics_frames(LIGHT_TICKS)
	assert_false(_stand.is_zone_lit(), "y sigue apagada sin comanda")
	_bus.order_generated.emit(order)
	await wait_physics_frames(LIGHT_TICKS)
	assert_true(_stand.is_zone_lit(), "comanda viva otra vez")
	_bus.orders_reset.emit()
	assert_false(_stand.is_zone_lit(), "reset")


func test_pul100_ac1_zone_turns_off_when_order_is_delivered() -> void:
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	_box_in_hand(_order_for(SLOT_ID))
	await _stand_at(1.5)
	assert_true(_stand.is_zone_lit())
	await _enter_zone()
	assert_signal_emit_count(_bus, "order_completed", 1)
	assert_false(_stand.is_zone_lit(), "entregada: apagada")


func test_pul100_ac1_lit_frame_uses_stand_colour_in_albedo_and_emission() -> void:
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	var shared_on: StandardMaterial3D = load(MAT_ON_PATH) as StandardMaterial3D
	var shared_before: Color = shared_on.albedo_color
	var off: StandardMaterial3D = load(MAT_OFF_PATH) as StandardMaterial3D
	assert_eq(_frame_material(_stand), off, "apagada: material apagado")
	_box_in_hand(_order_for(SLOT_ID))
	await _stand_at(1.5)
	var lit: StandardMaterial3D = _frame_material(_stand)
	var expected: Color = PALETTE.color_for(SLOT_ID)
	assert_ne(lit, shared_on, "material por instancia")
	assert_eq(lit.albedo_color, expected)
	assert_eq(lit.emission, expected)
	assert_true(lit.emission_enabled)
	assert_eq(shared_on.albedo_color, shared_before, "el .tres compartido no cambia")
	assert_eq(shared_on.emission, shared_before)
	_player.global_position = FAR
	await wait_physics_frames(LIGHT_TICKS)
	assert_eq(_frame_material(_stand), off)


func test_pul100_ac1_each_stand_lights_in_its_own_colour() -> void:
	var other: OrderStand = STAND_SCENE.instantiate()
	other.slot_id = 3
	other.set_bus(_bus)
	other.set_service(_service)
	_level.add_child(other)
	other.position = Vector3(10, 0, 0)
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	_box_in_hand(_order_for(3))
	_player.global_position = other.get_node("%DeliveryZone").global_position + Vector3(0, 0, 1.5)
	await wait_physics_frames(LIGHT_TICKS)
	assert_true(other.is_zone_lit())
	assert_false(_stand.is_zone_lit(), "la zona de otro puesto no se enciende con esta caja")
	assert_eq(_frame_material(other).albedo_color, PALETTE.color_for(3))
	assert_eq(_frame_material(other).emission, PALETTE.color_for(3))


func test_pul100_zone_geometry_matches_delivery_mark() -> void:
	var zone: Area3D = _stand.get_node("%DeliveryZone")
	assert_almost_eq(zone.position.z, ZONE_Z, 0.001, "centro en Z local 3,40")
	var shape: BoxShape3D = (zone.get_child(0) as CollisionShape3D).shape as BoxShape3D
	assert_almost_eq(shape.size.x, 1.45, 0.01)
	assert_almost_eq(shape.size.z, 1.05, 0.01)
	var frame: Node3D = _stand.find_child("DeliveryFrame", true, false) as Node3D
	assert_almost_eq(frame.global_position.z, ZONE_Z, 0.6, "la marca está sobre la zona")


func test_pul100_proximity_area_is_two_metre_cylinder_on_player_layer() -> void:
	var area: Area3D = _stand.get_node("%ProximityArea")
	var zone: Area3D = _stand.get_node("%DeliveryZone")
	assert_eq(area.collision_layer, 0)
	assert_eq(area.collision_mask, 1 << 1, "máscara player")
	assert_eq(area.global_position, zone.global_position)
	var shape: CylinderShape3D = (area.get_child(0) as CollisionShape3D).shape as CylinderShape3D
	assert_almost_eq(shape.radius, 2.0, 0.001)


func test_pul100_order_label_sits_on_anchor_order_label() -> void:
	var anchor: Node3D = _stand.find_child("Anchor_OrderLabel", true, false) as Node3D
	assert_not_null(anchor)
	var label: Label3D = _stand.get_node("%OrderLabel")
	assert_almost_eq(label.global_position.distance_to(anchor.global_position), 0.0, 0.01)


## estacion-condimentos AC20 (D25, D26): «Á feira» con aliño picante no entrega ni penaliza ni
## enciende la zona; al aplicar el dulce (sustituye) dentro de la zona entrega sola, sin cubo.
func test_ac20_a_feira_with_hot_dressing_waits_then_fixed_and_delivered() -> void:
	var catalog: OrderCatalog = OrderCatalog.new()
	catalog.orders = [A_FEIRA] as Array[OrderData]
	catalog.max_active_orders = 4
	_service.setup(catalog, null, RoundConfig.new())
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	var order: ActiveOrder = _order_for(SLOT_ID)
	var box: Box = _box_in_hand(order)
	assert_true(box.remove_seasoning(order.data.seasonings[0]))
	assert_eq(box.apply_seasoning(load("res://data/seasonings/hot_dressing.tres")), 0)
	await _enter_zone()
	await wait_physics_frames(LIGHT_TICKS)
	assert_signal_not_emitted(_bus, "delivery_rejected")
	assert_signal_not_emitted(_bus, "order_completed")
	assert_false(_stand.is_zone_lit(), "la caja no encaja: zona apagada")
	assert_eq(_hold.get_held_item(), box, "la caja sigue en la mano")
	var sweet: SeasoningData = load("res://data/seasonings/sweet_dressing.tres")
	assert_eq(box.apply_seasoning(sweet), SeasoningRules.Rejection.NONE)
	await wait_physics_frames(2)
	assert_signal_emit_count(_bus, "order_completed", 1)
	assert_signal_not_emitted(_bus, "delivery_rejected")
	assert_true(_is_released(box))
