extends GutTest
## PUL-007 AC1-AC3: RoundManager reenvía las señales de RoundState al bus, arranca la ronda en el
## orden de ADR-002 (regla 6, B10) y su reloj se detiene con la pausa.

const EventBusScript: GDScript = preload("res://autoload/event_bus.gd")
const OrderServiceScript: GDScript = preload("res://autoload/order_service.gd")
const RoundManagerScript: GDScript = preload("res://autoload/round_manager.gd")
const CATALOG_PATH: String = "res://data/orders/order_catalog.tres"
const CONFIG_PATH: String = "res://data/config/round_config.tres"
const SLOTS: Array[int] = [0, 1, 2, 3]
const TICK: float = 1.0 / 60.0

var _bus: Node
var _service: Node
var _manager: Node
var _trace: Array[String] = []


func before_each() -> void:
	_trace.clear()
	_bus = add_child_autofree(EventBusScript.new())
	_service = OrderServiceScript.new()
	_service.set_bus(_bus)
	add_child_autofree(_service)
	_service.setup(load(CATALOG_PATH) as OrderCatalog, null, _seeded_rng())
	_manager = RoundManagerScript.new()
	_manager.set_bus(_bus)
	_manager.set_order_service(_service)
	add_child_autofree(_manager)


func after_each() -> void:
	get_tree().paused = false


func _seeded_rng() -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5
	return rng


func _config(duration: float = 180.0) -> RoundConfig:
	var config: RoundConfig = (load(CONFIG_PATH) as RoundConfig).duplicate() as RoundConfig
	config.duration = duration
	return config


func _patient_catalog(max_time: float) -> OrderCatalog:
	var data: OrderData = (load(CATALOG_PATH) as OrderCatalog).orders[0].duplicate() as OrderData
	data.max_time = max_time
	var catalog: OrderCatalog = OrderCatalog.new()
	catalog.orders = [data]
	return catalog


func _contents_for(order: ActiveOrder) -> BoxContents:
	return BoxContents.new(
		order.data.recipe.box,
		order.data.recipe.ingredient,
		IngredientData.CookingState.COOKED,
		1.0,
		order.data.seasonings.duplicate()
	)


func _trace_bus() -> void:
	_bus.orders_reset.connect(func() -> void: _trace.append("orders_reset"))
	_bus.order_generated.connect(
		func(order: ActiveOrder) -> void: _trace.append("order_generated:%d" % order.slot_id)
	)
	_bus.round_started.connect(func(_d: float) -> void: _trace.append("round_started"))


func test_ac2_start_round_order_reset_generated_per_slot_then_started() -> void:
	_trace_bus()
	_manager.start_round(_config(), SLOTS)
	assert_eq(
		_trace,
		(
			[
				"orders_reset",
				"order_generated:0",
				"order_generated:1",
				"order_generated:2",
				"order_generated:3",
				"round_started",
			]
			as Array[String]
		)
	)


func test_ac1_start_round_signals_forwarded_once_with_same_args() -> void:
	watch_signals(_bus)
	_manager.start_round(_config(120.0), SLOTS)
	assert_signal_emit_count(_bus, "round_started", 1)
	assert_signal_emitted_with_parameters(_bus, "round_started", [120.0])
	assert_signal_emit_count(_bus, "round_time_changed", 1)
	assert_signal_emitted_with_parameters(_bus, "round_time_changed", [120.0])
	assert_signal_emit_count(_bus, "orders_reset", 1)
	assert_signal_emit_count(_bus, "order_generated", 4)


func test_ac1_time_and_finish_forwarded_once_with_same_args() -> void:
	_manager.start_round(_config(2.0), SLOTS)
	var state: RoundState = _manager.round_state
	watch_signals(state)
	watch_signals(_bus)
	_manager._physics_process(1.0)
	assert_signal_emit_count(_bus, "round_time_changed", 1)
	assert_signal_emitted_with_parameters(_bus, "round_time_changed", [1.0])
	assert_signal_emit_count(_bus, "round_finished", 0)
	_manager._physics_process(1.0)
	assert_signal_emit_count(_bus, "round_time_changed", 2)
	assert_signal_emit_count(_bus, "round_finished", 1)
	assert_same(
		get_signal_parameters(_bus, "round_finished")[0],
		get_signal_parameters(state, "round_finished")[0]
	)


func test_ac1_score_changed_forwarded_once_with_same_args() -> void:
	_manager.start_round(_config(), SLOTS)
	watch_signals(_bus)
	var order: ActiveOrder = _service.get_active_orders()[0]
	_service.try_deliver(order.slot_id, _contents_for(order))
	assert_signal_emit_count(_bus, "score_changed", 1)
	assert_signal_emitted_with_parameters(_bus, "score_changed", [1, 0])
	assert_signal_emit_count(_bus, "order_completed", 1)


func test_ac1_second_start_round_does_not_duplicate_forwarding() -> void:
	_manager.start_round(_config(), SLOTS)
	_manager.start_round(_config(), SLOTS)
	watch_signals(_bus)
	_manager._physics_process(1.0)
	assert_signal_emit_count(_bus, "round_time_changed", 1)


func test_ac2_physics_tick_advances_round_clock() -> void:
	_manager.start_round(_config(), SLOTS)
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_lt(_manager.round_state.get_time_left(), 180.0)


func test_ac2_physics_priority_is_minimum() -> void:
	assert_eq(_manager.process_physics_priority, RoundManagerScript.PHYSICS_PRIORITY)
	assert_lt(_manager.process_physics_priority, 0)


func test_ac3_paused_tree_does_not_advance_round_clock() -> void:
	_manager.start_round(_config(), SLOTS)
	await get_tree().physics_frame
	get_tree().paused = true
	var frozen: float = _manager.round_state.get_time_left()
	watch_signals(_bus)
	for i: int in range(5):
		await get_tree().physics_frame
	assert_eq(_manager.round_state.get_time_left(), frozen)
	assert_signal_not_emitted(_bus, "round_time_changed")
	get_tree().paused = false
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_lt(_manager.round_state.get_time_left(), frozen)


func test_ac3_paused_tree_does_not_advance_patience() -> void:
	_service.setup(_patient_catalog(30.0), null, _seeded_rng())
	_manager.start_round(_config(), [0] as Array[int])
	await get_tree().physics_frame
	get_tree().paused = true
	var frozen: float = _service.get_active_orders()[0].time_left
	watch_signals(_bus)
	for i: int in range(5):
		await get_tree().physics_frame
	assert_eq(_service.get_active_orders()[0].time_left, frozen)
	assert_signal_not_emitted(_bus, "order_patience_changed")
	get_tree().paused = false
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_lt(_service.get_active_orders()[0].time_left, frozen)


func test_ac1_physics_process_without_round_is_noop() -> void:
	watch_signals(_bus)
	_manager._physics_process(TICK)
	assert_signal_not_emitted(_bus, "round_time_changed")
	assert_null(_manager.round_state)


func test_ac1_previous_round_state_is_fully_detached_on_restart() -> void:
	_service.setup(_patient_catalog(10.0), null, _seeded_rng())
	_manager.start_round(_config(), [0] as Array[int])
	var previous: RoundState = _manager.round_state
	_manager.start_round(_config(), [0] as Array[int])
	assert_ne(_manager.round_state, previous)
	watch_signals(_bus)
	var order: ActiveOrder = _service.get_active_orders()[0]
	_service.try_deliver(0, _contents_for(order))
	assert_signal_emit_count(_bus, "score_changed", 1)
	assert_signal_emitted_with_parameters(_bus, "score_changed", [1, 0])
	assert_eq(previous.get_boxes_delivered(), 0)
	_service.board.advance(10.0)
	assert_signal_emit_count(_bus, "order_expired", 1)
	assert_signal_emit_count(_bus, "score_changed", 2)
	_manager.round_state.advance(1.0)
	assert_signal_emit_count(_bus, "round_time_changed", 1)


func test_m1_ac2_ac4_integration_with_real_data() -> void:
	var config: RoundConfig = load("res://data/config/round_config.tres") as RoundConfig
	_service.setup(load("res://data/orders/order_catalog.tres") as OrderCatalog, config)
	_manager.start_round(config, [1])
	watch_signals(_bus)

	_manager.round_state.advance(5.0)
	var order: ActiveOrder = _manager.round_state._board.get_order_for_slot(1)
	var base: int = order.data.recipe.base_points
	var bonus: int = floori((order.time_left / order.max_time) * 5)

	var box: BoxContents = order.data.recipe.box.duplicate()
	box.seasonings = order.data.seasonings.duplicate()
	_service.board.try_deliver(1, box)

	var expected_revenue: int = base + bonus
	assert_signal_emitted_with_parameters(_bus, "score_changed", [1, expected_revenue])

	var next_order: ActiveOrder = _manager.round_state._board.get_order_for_slot(1)
	_manager.round_state.advance(next_order.time_left + 0.1)
	assert_signal_emitted_with_parameters(_bus, "score_changed", [1, expected_revenue - 3])
