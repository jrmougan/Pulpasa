extends GutTest
## PUL-006: OrderBoard sin árbol (ADR-002). AC1 (B1), AC3 (AC5b), AC4 (paridad sin paciencia), AC6.

const CATALOG_PATH: String = "res://tests/helpers/m0_data/orders/order_catalog.tres"
const ORDER_1_PATH: String = "res://data/orders/order_1.tres"
const SLOTS: Array[int] = [0, 1, 2, 3]
const SEED: int = 12345
const TICK: float = 1.0 / 60.0


func _rng(seed_value: int = SEED) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _parity_board(seed_value: int = SEED) -> OrderBoard:
	return OrderBoard.new(load(CATALOG_PATH) as OrderCatalog, _rng(seed_value))


## Catálogo con una sola receta (la de order_1) y la paciencia indicada.
func _single_recipe_board(max_time: float) -> OrderBoard:
	var order: OrderData = (load(ORDER_1_PATH) as OrderData).duplicate() as OrderData
	order.max_time = max_time
	var catalog: OrderCatalog = OrderCatalog.new()
	catalog.orders = [order]
	return OrderBoard.new(catalog, _rng())


func _contents_for(order: ActiveOrder) -> BoxContents:
	return BoxContents.new(
		order.data.recipe.box,
		order.data.recipe.ingredient,
		IngredientData.CookingState.COOKED,
		1.0,
		order.data.seasonings.duplicate()
	)


func _wrong_contents() -> BoxContents:
	return BoxContents.new(null, null, IngredientData.CookingState.RAW, 0.0, [])


func _order_ids(board: OrderBoard) -> Array[int]:
	var ids: Array[int] = []
	for order: ActiveOrder in board.get_active_orders():
		ids.append(order.id)
	return ids


# --- AC1: una entrega = una order_completed, reposición en la misma llamada (B1) ---


func test_ac1_order_completed_once_per_delivery() -> void:
	var board: OrderBoard = _parity_board()
	board.reset()
	board.fill_slots(SLOTS)
	var delivered: ActiveOrder = board.get_order_for_slot(2)
	watch_signals(board)

	var result: ActiveOrder = board.try_deliver(2, _contents_for(delivered))

	assert_not_null(result)
	assert_signal_emit_count(board, "order_completed", 1)
	var completed: ActiveOrder = get_signal_parameters(board, "order_completed")[0]
	assert_eq(completed.id, delivered.id)
	assert_eq(completed.slot_id, 2)
	assert_eq(result.id, delivered.id)
	assert_signal_emit_count(board, "order_generated", 1)
	var replacement: ActiveOrder = get_signal_parameters(board, "order_generated")[0]
	assert_eq(replacement.slot_id, 2)
	assert_ne(replacement.id, delivered.id)
	assert_eq(board.get_order_for_slot(2).id, replacement.id)
	assert_signal_not_emitted(board, "delivery_rejected")


func test_ac1_twenty_deliveries_count_twenty_and_no_empty_slot() -> void:
	var board: OrderBoard = _parity_board()
	var round_state: RoundState = RoundState.new(RoundConfig.new(), board)
	round_state.start(SLOTS)
	watch_signals(board)

	for i: int in range(20):
		var slot: int = SLOTS[i % SLOTS.size()]
		assert_not_null(board.try_deliver(slot, _contents_for(board.get_order_for_slot(slot))))

	assert_signal_emit_count(board, "order_completed", 20)
	assert_eq(round_state.get_boxes_delivered(), 20)
	assert_eq(board.get_active_orders().size(), SLOTS.size())
	for slot: int in SLOTS:
		assert_not_null(board.get_order_for_slot(slot), "puesto %d vacío" % slot)


func test_ac1_wrong_box_rejected_without_state_change() -> void:
	var board: OrderBoard = _parity_board()
	board.reset()
	board.fill_slots(SLOTS)
	var before: Array[int] = _order_ids(board)
	var live_id: int = board.get_order_for_slot(1).id
	watch_signals(board)

	assert_null(board.try_deliver(1, _wrong_contents()))

	assert_signal_not_emitted(board, "order_completed")
	assert_signal_not_emitted(board, "order_generated")
	assert_signal_emitted_with_parameters(
		board, "delivery_rejected", [1, live_id, OrderBoard.REJECT_PENALTY]
	)
	assert_eq(_order_ids(board), before)


func test_ac1_delivery_to_unknown_slot_rejected_with_minus_one() -> void:
	var board: OrderBoard = _parity_board()
	board.reset()
	board.fill_slots([0])
	watch_signals(board)
	assert_null(board.try_deliver(7, _wrong_contents()))
	assert_signal_emitted_with_parameters(board, "delivery_rejected", [7, -1, 0])


func test_ac1_max_four_active_orders() -> void:
	var board: OrderBoard = _parity_board()
	board.reset()
	board.fill_slots([0, 1, 2, 3, 4, 5])
	assert_eq(board.get_active_orders().size(), 4)
	assert_null(board.get_order_for_slot(4))
	assert_null(board.request_order(5))


func test_ac1_one_order_per_slot() -> void:
	var board: OrderBoard = _parity_board()
	board.reset()
	board.fill_slots([0])
	assert_null(board.request_order(0))
	assert_eq(board.get_active_orders().size(), 1)


func test_ac1_reset_clears_orders_and_restarts_ids() -> void:
	var board: OrderBoard = _parity_board()
	board.reset()
	board.fill_slots(SLOTS)
	watch_signals(board)
	board.reset()
	assert_signal_emit_count(board, "orders_reset", 1)
	assert_eq(board.get_active_orders().size(), 0)
	board.fill_slots([0])
	assert_eq(board.get_order_for_slot(0).id, 1)


func test_ac1_active_orders_are_copies() -> void:
	var board: OrderBoard = _parity_board()
	board.reset()
	board.fill_slots([0])
	var copy: ActiveOrder = board.get_active_orders()[0]
	copy.slot_id = 99
	copy.time_left = -5.0
	assert_eq(board.get_order_for_slot(0).slot_id, 0)
	assert_eq(board.get_order_for_slot(0).time_left, 0.0)


func test_ac1_stopped_board_rejects_silently() -> void:
	var board: OrderBoard = _parity_board()
	board.reset()
	board.fill_slots([0])
	var order: ActiveOrder = board.get_order_for_slot(0)
	board.stop()
	watch_signals(board)
	assert_null(board.try_deliver(0, _contents_for(order)))
	assert_null(board.request_order(1))
	board.advance(10.0)
	assert_eq(get_signal_emit_count(board, "order_completed"), 0)
	assert_eq(get_signal_emit_count(board, "delivery_rejected"), 0)
	assert_eq(get_signal_emit_count(board, "order_generated"), 0)


# --- AC3: empate caducar/entregar por order_id (ADR-002, feature AC5b) ---


func test_ac5b_delivery_on_expiry_tick_rejected_not_redirected() -> void:
	var board: OrderBoard = _single_recipe_board(60.0)
	var round_state: RoundState = RoundState.new(RoundConfig.new(), board)
	round_state.start([0])
	var expiring: ActiveOrder = board.get_order_for_slot(0)
	var contents: BoxContents = _contents_for(expiring)
	watch_signals(board)

	for i: int in range(3600):
		round_state.advance(TICK)

	assert_signal_emit_count(board, "order_expired", 1)
	var expired: ActiveOrder = get_signal_parameters(board, "order_expired")[0]
	assert_eq(expired.id, expiring.id)
	assert_signal_emit_count(board, "order_generated", 1)
	var replacement: ActiveOrder = get_signal_parameters(board, "order_generated")[0]
	assert_eq(replacement.slot_id, 0)
	assert_ne(replacement.id, expiring.id)

	assert_null(board.try_deliver(0, contents))
	assert_signal_emit_count(board, "delivery_rejected", 1)
	assert_signal_emitted_with_parameters(board, "delivery_rejected", [0, expiring.id, 0])
	assert_signal_emit_count(board, "order_completed", 0)
	assert_eq(round_state.get_revenue(), 0)
	assert_eq(round_state.get_boxes_delivered(), 0)
	assert_eq(board.get_order_for_slot(0).id, replacement.id)

	# Control: un tick después, la misma entrega completa la comanda repuesta.
	round_state.advance(TICK)
	var completed: ActiveOrder = board.try_deliver(0, contents)
	assert_not_null(completed)
	assert_eq(completed.id, replacement.id)
	assert_signal_emit_count(board, "order_completed", 1)


func test_ac5b_single_advance_of_sixty_expires() -> void:
	var board: OrderBoard = _single_recipe_board(60.0)
	board.reset()
	board.fill_slots([0])
	var expiring_id: int = board.get_order_for_slot(0).id
	watch_signals(board)
	board.advance(60.0)
	assert_signal_emit_count(board, "order_expired", 1)
	assert_null(board.try_deliver(0, _contents_for(board.get_order_for_slot(0))))
	assert_signal_emitted_with_parameters(board, "delivery_rejected", [0, expiring_id, 0])


func test_ac5c_delivery_before_expiry_completes() -> void:
	var board: OrderBoard = _single_recipe_board(60.0)
	board.reset()
	board.fill_slots([0])
	var order: ActiveOrder = board.get_order_for_slot(0)
	watch_signals(board)
	board.advance(59.9)
	assert_not_null(board.try_deliver(0, _contents_for(order)))
	assert_signal_emit_count(board, "order_completed", 1)
	assert_signal_not_emitted(board, "order_expired")


func test_ac3_patience_signals_and_expiry_order_by_slot() -> void:
	var board: OrderBoard = _single_recipe_board(60.0)
	board.reset()
	board.fill_slots([3, 1])
	watch_signals(board)
	board.advance(1.0)
	assert_signal_emit_count(board, "order_patience_changed", 2)
	var params: Array = get_signal_parameters(board, "order_patience_changed", 0)
	assert_almost_eq(params[1] as float, 59.0, 0.0001)
	assert_eq(params[2], 60.0)
	board.advance(59.0)
	assert_signal_emit_count(board, "order_expired", 2)
	assert_eq((get_signal_parameters(board, "order_expired", 0)[0] as ActiveOrder).slot_id, 1)
	assert_eq((get_signal_parameters(board, "order_expired", 1)[0] as ActiveOrder).slot_id, 3)
	assert_eq(board.get_active_orders().size(), 2)


func test_ac3_patience_not_expired_one_tick_before_limit() -> void:
	var board: OrderBoard = _single_recipe_board(60.0)
	board.reset()
	board.fill_slots([0])
	watch_signals(board)
	for i: int in range(3599):
		board.advance(TICK)
	assert_signal_not_emitted(board, "order_expired")
	assert_gt(board.get_order_for_slot(0).time_left, 0.0)
	board.advance(TICK)
	assert_signal_emit_count(board, "order_expired", 1)


func test_ac3_patience_not_expired_just_below_limit() -> void:
	var board: OrderBoard = _single_recipe_board(60.0)
	board.reset()
	board.fill_slots([0])
	var order: ActiveOrder = board.get_order_for_slot(0)
	watch_signals(board)
	board.advance(59.9999995)
	assert_signal_not_emitted(board, "order_expired")
	assert_gt(board.get_order_for_slot(0).time_left, 0.0)
	assert_not_null(board.try_deliver(0, _contents_for(order)))
	assert_signal_emit_count(board, "order_completed", 1)


func test_ac3_patience_expires_just_after_limit() -> void:
	var board: OrderBoard = _single_recipe_board(60.0)
	board.reset()
	board.fill_slots([0])
	watch_signals(board)
	board.advance(60.0000005)
	assert_signal_emit_count(board, "order_expired", 1)
	var params: Array = get_signal_parameters(board, "order_patience_changed", 0)
	assert_eq(params[1], 0.0)


# --- AC4: paridad M0 (max_time 0) sin caducidad ni paciencia ---


func test_ac4_zero_max_time_never_expires_nor_emits_patience() -> void:
	var board: OrderBoard = _parity_board()
	board.reset()
	board.fill_slots(SLOTS)
	var before: Array[int] = _order_ids(board)
	watch_signals(board)
	for i: int in range(600):
		board.advance(1.0)
	assert_signal_not_emitted(board, "order_patience_changed")
	assert_signal_not_emitted(board, "order_expired")
	assert_signal_not_emitted(board, "order_generated")
	assert_eq(_order_ids(board), before)


# --- AC6: determinismo con RNG sembrado y sin estado compartido ---


func _sequence(board: OrderBoard) -> Array[String]:
	var names: Array[String] = []
	board.reset()
	board.fill_slots(SLOTS)
	for order: ActiveOrder in board.get_active_orders():
		names.append("%d:%d:%s" % [order.slot_id, order.id, order.data.resource_path])
	for i: int in range(12):
		var slot: int = SLOTS[i % SLOTS.size()]
		var done: ActiveOrder = board.try_deliver(
			slot, _contents_for(board.get_order_for_slot(slot))
		)
		names.append("done:%d" % done.id)
		var next: ActiveOrder = board.get_order_for_slot(slot)
		names.append("%d:%d:%s" % [next.slot_id, next.id, next.data.resource_path])
	return names


func test_ac6_same_seed_same_sequence() -> void:
	assert_eq(_sequence(_parity_board()), _sequence(_parity_board()))


func test_ac6_boards_do_not_share_state() -> void:
	var a: OrderBoard = _parity_board()
	var b: OrderBoard = _parity_board()
	a.reset()
	a.fill_slots(SLOTS)
	b.reset()
	b.fill_slots([0])
	assert_eq(b.get_active_orders().size(), 1)
	assert_eq(b.get_order_for_slot(0).id, 1)
	a.try_deliver(0, _contents_for(a.get_order_for_slot(0)))
	a.stop()
	assert_eq(b.get_order_for_slot(0).id, 1)
	assert_false(b.is_stopped())
	b.fill_slots([1])
	assert_eq(b.get_order_for_slot(1).id, 2)
