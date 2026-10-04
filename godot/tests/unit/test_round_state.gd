# gdlint: disable=max-public-methods
extends GutTest
## PUL-027: RoundState (B2) y mecánicas M1 (recaudación, penalizaciones).

const M1_CONFIG_PATH: String = "res://data/config/round_config.tres"
const M1_CATALOG_PATH: String = "res://data/orders/order_catalog.tres"
const CATALOG_PATH: String = "res://tests/helpers/m0_data/orders/order_catalog.tres"
const CONFIG_PATH: String = "res://tests/helpers/m0_data/m0_round_config.tres"
const SLOTS: Array[int] = [0, 1, 2, 3]
const TICK: float = 1.0 / 60.0

var _board: OrderBoard
var _round: RoundState
var _trace: Array[String] = []


func before_each() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	_board = OrderBoard.new(load(CATALOG_PATH) as OrderCatalog, rng)
	_round = RoundState.new(load(CONFIG_PATH) as RoundConfig, _board)


func _contents_for(order: ActiveOrder) -> BoxContents:
	return BoxContents.new(
		order.data.recipe.box,
		order.data.recipe.ingredient,
		IngredientData.CookingState.COOKED,
		1.0,
		order.data.seasonings.duplicate()
	)


func _deliver(slot: int) -> ActiveOrder:
	return _board.try_deliver(slot, _contents_for(_board.get_order_for_slot(slot)))


func test_ac5_start_sequence_resets_fills_and_announces() -> void:
	watch_signals(_round)
	watch_signals(_board)
	_round.start(SLOTS)
	assert_signal_emit_count(_board, "orders_reset", 1)
	assert_signal_emit_count(_board, "order_generated", 4)
	assert_signal_emitted_with_parameters(_round, "round_time_changed", [180.0])
	assert_signal_emitted_with_parameters(_round, "round_started", [180.0])
	assert_eq(_round.get_time_left(), 180.0)
	assert_false(_round.is_finished())


func test_ac5_round_does_not_end_at_179_5() -> void:
	_round.start(SLOTS)
	watch_signals(_round)
	for i: int in range(10770):
		_round.advance(TICK)
	assert_false(_round.is_finished())
	assert_signal_not_emitted(_round, "round_finished")
	assert_almost_eq(_round.get_time_left(), 0.5, 0.0001)


func test_ac5_round_ends_exactly_at_duration() -> void:
	_round.start(SLOTS)
	watch_signals(_round)
	for i: int in range(10799):
		_round.advance(TICK)
	assert_false(_round.is_finished())
	_round.advance(TICK)
	assert_true(_round.is_finished())
	assert_signal_emit_count(_round, "round_finished", 1)
	assert_eq(_round.get_time_left(), 0.0)
	var result: RoundResult = get_signal_parameters(_round, "round_finished")[0]
	assert_eq(result.duration, 180.0)
	assert_signal_emitted_with_parameters(_round, "round_time_changed", [0.0])


func test_ac5_large_delta_clamped_to_end() -> void:
	_round.start(SLOTS)
	watch_signals(_round)
	_round.advance(500.0)
	assert_true(_round.is_finished())
	assert_eq(_round.get_time_left(), 0.0)
	assert_signal_emit_count(_round, "round_finished", 1)
	_round.advance(1.0)
	assert_signal_emit_count(_round, "round_finished", 1)


func test_ac5_time_changed_once_per_whole_second() -> void:
	_round.start(SLOTS)
	watch_signals(_round)
	for i: int in range(120):
		_round.advance(TICK)
	assert_signal_emit_count(_round, "round_time_changed", 2)


func test_ac5_try_deliver_after_finish_returns_null_without_signals() -> void:
	_round.start(SLOTS)
	_round.advance(180.0)
	var order: ActiveOrder = _board.get_order_for_slot(0)
	watch_signals(_board)
	watch_signals(_round)
	assert_null(_board.try_deliver(0, _contents_for(order)))
	assert_eq(get_signal_emit_count(_board, "order_completed"), 0)
	assert_eq(get_signal_emit_count(_board, "delivery_rejected"), 0)
	assert_eq(get_signal_emit_count(_board, "order_generated"), 0)
	assert_eq(get_signal_emit_count(_round, "score_changed"), 0)


func test_ac5_delivery_counts_and_emits_score() -> void:
	_round.start(SLOTS)
	watch_signals(_round)
	_deliver(0)
	_deliver(1)
	assert_eq(_round.get_boxes_delivered(), 2)
	assert_signal_emit_count(_round, "score_changed", 2)
	assert_signal_emitted_with_parameters(_round, "score_changed", [2, 0])


func test_ac5_result_ratio_boxes_per_minute() -> void:
	_round.start(SLOTS)
	for i: int in range(6):
		_deliver(i % 4)
	watch_signals(_round)
	_round.advance(180.0)
	var result: RoundResult = get_signal_parameters(_round, "round_finished")[0]
	assert_eq(result.boxes_delivered, 6)
	assert_almost_eq(result.boxes_per_minute, 2.0, 0.0001)
	assert_eq(result.get_performance_description(), "Pulpeiro eficiente")


func _result(boxes: int, minutes: float) -> RoundResult:
	var config: RoundConfig = load(CONFIG_PATH) as RoundConfig
	return RoundResult.new(
		minutes * 60.0, boxes, 0, config.performance_thresholds, config.performance_texts
	)


func test_ac5_performance_thresholds_match_prototype() -> void:
	assert_eq(_result(0, 3.0).get_performance_description(), "Pulpeiro ineficiente")
	assert_eq(_result(2, 3.0).get_performance_description(), "Pulpeiro ineficiente")
	assert_eq(_result(3, 3.0).get_performance_description(), "Pulpeiro aceptable")
	assert_eq(_result(5, 3.0).get_performance_description(), "Pulpeiro aceptable")
	assert_eq(_result(6, 3.0).get_performance_description(), "Pulpeiro eficiente")
	assert_eq(_result(8, 3.0).get_performance_description(), "Pulpeiro eficiente")
	assert_eq(_result(9, 3.0).get_performance_description(), "!Pulpeiro lexendario!")


func test_ac5_performance_without_tiers_is_empty() -> void:
	assert_eq(RoundResult.new(180.0, 9).get_performance_description(), "")


func test_ac5_zero_duration_ratio_is_zero() -> void:
	assert_eq(RoundResult.new(0.0, 4).boxes_per_minute, 0.0)


func test_ac5_board_stopped_after_finish() -> void:
	_round.start(SLOTS)
	_round.advance(180.0)
	assert_true(_board.is_stopped())


func test_ac5_two_round_states_do_not_share_clock() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var other_board: OrderBoard = OrderBoard.new(load(CATALOG_PATH) as OrderCatalog, rng)
	var other: RoundState = RoundState.new(load(CONFIG_PATH) as RoundConfig, other_board)
	_round.start(SLOTS)
	other.start(SLOTS)
	_round.advance(100.0)
	assert_eq(other.get_time_left(), 180.0)


func test_ac5_round_not_finished_just_below_duration() -> void:
	_round.start(SLOTS)
	watch_signals(_round)
	_round.advance(179.9999995)
	assert_false(_round.is_finished())
	assert_gt(_round.get_time_left(), 0.0)
	assert_signal_not_emitted(_round, "round_finished")
	_round.advance(1.0)
	assert_true(_round.is_finished())
	assert_signal_emit_count(_round, "round_finished", 1)


func test_ac5_round_finished_just_after_duration() -> void:
	_round.start(SLOTS)
	watch_signals(_round)
	_round.advance(180.0000005)
	assert_true(_round.is_finished())
	assert_eq(_round.get_time_left(), 0.0)
	var result: RoundResult = get_signal_parameters(_round, "round_finished")[0]
	assert_eq(result.duration, 180.0)


# --- Trazas: orden de señales entre RoundState y OrderBoard (ADR-002, signals.md §3) ---


## Catálogo de paridad con paciencia positiva en todas las comandas.
func _patience_catalog(max_time: float) -> OrderCatalog:
	var source: OrderCatalog = load(CATALOG_PATH) as OrderCatalog
	var catalog: OrderCatalog = OrderCatalog.new()
	var orders: Array[OrderData] = []
	for data: OrderData in source.orders:
		var copy: OrderData = data.duplicate() as OrderData
		copy.max_time = max_time
		orders.append(copy)
	catalog.orders = orders
	return catalog


## Crea tablero y ronda con un registro común de señales. El registro se conecta al tablero antes
## de crear la ronda, así refleja el orden real de emisión (incluido `score_changed` reentrante).
func _traced(catalog: OrderCatalog) -> void:
	_trace.clear()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	_board = OrderBoard.new(catalog, rng)
	_board.orders_reset.connect(func() -> void: _trace.append("reset"))
	_board.order_generated.connect(
		func(o: ActiveOrder) -> void: _trace.append("generated:%d" % o.slot_id)
	)
	_board.order_completed.connect(
		func(o: ActiveOrder, _p: int) -> void: _trace.append("completed:%d" % o.slot_id)
	)
	_board.order_expired.connect(
		func(o: ActiveOrder, _p: int) -> void: _trace.append("expired:%d" % o.slot_id)
	)
	_board.order_patience_changed.connect(
		func(id: int, _t: float, _m: float) -> void: _trace.append("patience:%d" % id)
	)
	_board.delivery_rejected.connect(
		func(slot: int, id: int, _p: int) -> void: _trace.append("rejected:%d:%d" % [slot, id])
	)
	_round = RoundState.new(load(CONFIG_PATH) as RoundConfig, _board)
	_round.round_started.connect(func(d: float) -> void: _trace.append("started:%.3f" % d))
	_round.round_time_changed.connect(func(t: float) -> void: _trace.append("time:%.3f" % t))
	_round.round_finished.connect(func(_r: RoundResult) -> void: _trace.append("finished"))
	_round.score_changed.connect(func(b: int, _r: int) -> void: _trace.append("score:%d" % b))


## Traza esperada del tick final: paciencia de todas (por slot) → expired/score/generated por
## slot ascendente → time_changed(0) → finished.
func _expected_final_tick() -> Array[String]:
	var expected: Array[String] = []
	var orders: Array[ActiveOrder] = _board.get_active_orders()
	for order: ActiveOrder in orders:
		expected.append("patience:%d" % order.id)
	for order: ActiveOrder in orders:
		expected.append_array(
			["expired:%d" % order.slot_id, "score:0", "generated:%d" % order.slot_id]
		)
	expected.append_array(["time:0.000", "finished"])
	return expected


func test_ac5_trace_start_sequence() -> void:
	_traced(load(CATALOG_PATH) as OrderCatalog)
	_round.start([2, 0, 3, 1] as Array[int])
	assert_eq(
		_trace,
		(
			[
				"reset",
				"generated:2",
				"generated:0",
				"generated:3",
				"generated:1",
				"time:180.000",
				"started:180.000",
			]
			as Array[String]
		)
	)


func test_ac5_trace_delivery_completed_score_generated() -> void:
	_traced(load(CATALOG_PATH) as OrderCatalog)
	_round.start(SLOTS)
	_trace.clear()
	_deliver(1)
	assert_eq(_trace, ["completed:1", "score:1", "generated:1"] as Array[String])


func test_ac5_trace_final_tick_with_patience() -> void:
	_traced(_patience_catalog(60.0))
	_round.start([2, 0, 3, 1] as Array[int])
	for i: int in range(10799):
		_round.advance(TICK)
	assert_false(_round.is_finished())
	var expected: Array[String] = _expected_final_tick()
	_trace.clear()
	_round.advance(TICK)
	assert_eq(_trace, expected)
	assert_true(_board.is_stopped())


func test_ac5_trace_final_tick_with_delta_beyond_time_left() -> void:
	_traced(_patience_catalog(60.0))
	_round.start([2, 0, 3, 1] as Array[int])
	_round.advance(120.0)
	assert_almost_eq(_round.get_time_left(), 60.0, 0.0001)
	var expected: Array[String] = _expected_final_tick()
	_trace.clear()
	_round.advance(100.0)
	assert_eq(_trace, expected)
	assert_eq(_round.get_time_left(), 0.0)


# --- M1: entrega-y-puntuacion ---


func _setup_m1_state() -> RoundState:
	var catalog: OrderCatalog = load(M1_CATALOG_PATH) as OrderCatalog
	var config: RoundConfig = load(M1_CONFIG_PATH) as RoundConfig
	var board: OrderBoard = OrderBoard.new(
		catalog, _seeded_rng(), config.wrong_delivery_penalty, config.expire_penalty
	)
	var rs: RoundState = RoundState.new(config, board)
	return rs


func test_comandas_ac1_first_order_delay() -> void:
	var rs: RoundState = _setup_m1_state()
	watch_signals(rs._board)
	rs.start([1])
	# At 0s, no order generated yet
	assert_eq(rs._board.get_active_orders().size(), 0)

	# Advance just before 5s
	rs.advance(4.9)
	assert_eq(rs._board.get_active_orders().size(), 0)

	# Advance exactly to 5s
	rs.advance(0.1)
	assert_eq(rs._board.get_active_orders().size(), 1)
	assert_signal_emitted(rs._board, "order_generated")


func test_entrega_ac4_time_bonus() -> void:
	var rs: RoundState = _setup_m1_state()
	rs.start([1])
	rs.advance(5.0)  # spawn order
	watch_signals(rs)

	var order: ActiveOrder = rs._board.get_order_for_slot(1)
	var base: int = order.data.recipe.base_points
	var bonus: int = floori((order.time_left / order.max_time) * 5)

	var box: BoxContents = order.data.recipe.box.duplicate()
	box.seasonings = order.data.seasonings.duplicate()

	rs._board.try_deliver(1, box)

	assert_eq(rs.get_revenue(), base + bonus)
	assert_signal_emitted_with_parameters(rs, "score_changed", [1, base + bonus])


func test_entrega_ac5_time_bonus_1s() -> void:
	var rs: RoundState = _setup_m1_state()
	rs.start([1])
	rs.advance(5.0)
	var order: ActiveOrder = rs._board.get_order_for_slot(1)
	rs.advance(order.time_left - 1.0)  # 1s remaining

	var base: int = order.data.recipe.base_points
	var box: BoxContents = order.data.recipe.box.duplicate()
	box.seasonings = order.data.seasonings.duplicate()

	rs._board.try_deliver(1, box)
	assert_eq(rs.get_revenue(), base)  # bonus is 0 because 1/max_time * 5 is < 1


func test_entrega_ac5b_tie_break_penalty_0() -> void:
	var rs: RoundState = _setup_m1_state()
	rs.start([1])
	rs.advance(5.0)
	var order: ActiveOrder = rs._board.get_order_for_slot(1)

	# advance until just expired
	rs.advance(order.time_left + 0.1)

	var box: BoxContents = order.data.recipe.box.duplicate()
	box.seasonings = order.data.seasonings.duplicate()

	watch_signals(rs._board)
	# delivery rejected with 0 penalty, no revenue subtracted
	rs._board.try_deliver(1, box)
	assert_signal_emitted_with_parameters(rs._board, "delivery_rejected", [1, order.id, 0])
	assert_eq(rs.get_revenue(), 0)


func test_entrega_ac5c_deliver_before_expire() -> void:
	var rs: RoundState = _setup_m1_state()
	rs.start([1])
	rs.advance(5.0)
	var order: ActiveOrder = rs._board.get_order_for_slot(1)
	var base: int = order.data.recipe.base_points

	var box: BoxContents = order.data.recipe.box.duplicate()
	box.seasonings = order.data.seasonings.duplicate()

	watch_signals(rs._board)
	rs._board.try_deliver(1, box)
	assert_signal_not_emitted(rs._board, "order_expired")
	assert_eq(rs.get_revenue(), base + 5)  # full bonus


func test_comandas_ac3_expire_replenish() -> void:
	var rs: RoundState = _setup_m1_state()
	rs.start([1])
	rs.advance(5.0)
	# make revenue 10 first
	rs._revenue = 10
	var order: ActiveOrder = rs._board.get_order_for_slot(1)

	watch_signals(rs._board)
	rs.advance(order.time_left + 0.1)

	# penalty 3 subtracted
	assert_eq(rs.get_revenue(), 7)
	assert_signal_emitted(rs._board, "order_expired")
	# new order spawned
	assert_not_null(rs._board.get_order_for_slot(1))


func test_entrega_d8_wrong_box_penalty() -> void:
	var rs: RoundState = _setup_m1_state()
	rs.start([1])
	rs.advance(5.0)
	rs._revenue = 1
	var order: ActiveOrder = rs._board.get_order_for_slot(1)

	var wrong_box: BoxContents = BoxContents.new()

	watch_signals(rs._board)
	rs._board.try_deliver(1, wrong_box)

	# penalty 2 subtracted, min 0
	assert_signal_emitted_with_parameters(rs._board, "delivery_rejected", [1, order.id, 2])
	assert_eq(rs.get_revenue(), 0)


func test_entrega_ac6_stars() -> void:
	var c: RoundConfig = load(M1_CONFIG_PATH) as RoundConfig
	assert_eq(RoundResult.new(10.0, 1, 29, [], [], c.revenue_thresholds).stars, 0)
	assert_eq(RoundResult.new(10.0, 1, 30, [], [], c.revenue_thresholds).stars, 1)
	assert_eq(RoundResult.new(10.0, 1, 59, [], [], c.revenue_thresholds).stars, 1)
	assert_eq(RoundResult.new(10.0, 1, 60, [], [], c.revenue_thresholds).stars, 2)
	assert_eq(RoundResult.new(10.0, 1, 90, [], [], c.revenue_thresholds).stars, 3)


func test_partida_5_min_ac6_duration() -> void:
	var rs: RoundState = _setup_m1_state()
	rs.start([1])
	assert_eq(rs.get_time_left(), 300.0)
