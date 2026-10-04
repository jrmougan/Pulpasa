
const M1_CONFIG_PATH: String = "res://data/config/round_config.tres"
const M1_CATALOG_PATH: String = "res://data/orders/order_catalog.tres"

func _setup_m1_state() -> RoundState:
	var catalog: OrderCatalog = load(M1_CATALOG_PATH) as OrderCatalog
	var config: RoundConfig = load(M1_CONFIG_PATH) as RoundConfig
	var board: OrderBoard = OrderBoard.new(catalog, _seeded_rng(), config.wrong_delivery_penalty, config.expire_penalty)
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
	rs.advance(5.0) # spawn order
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
	rs.advance(order.time_left - 1.0) # 1s remaining
	
	var base: int = order.data.recipe.base_points
	var box: BoxContents = order.data.recipe.box.duplicate()
	box.seasonings = order.data.seasonings.duplicate()
	
	rs._board.try_deliver(1, box)
	assert_eq(rs.get_revenue(), base) # bonus is 0 because 1/max_time * 5 is < 1

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
	assert_eq(rs.get_revenue(), base + 5) # full bonus

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
	
	var wrong_box: BoxContents = BoxData.new()
	
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

