# gdlint: disable=max-public-methods
extends GutTest
## PUL-070: dificultad por fases (features/dificultad-progresiva.md AC1–AC6, ADR-006 §6).
## Núcleos `RoundState` + `OrderBoard` con los datos reales, `RoundManager`/`OrderService` (bus y
## semilla) y `level_01` con las fases reales de `round_config.tres`.

const EventBusScript: GDScript = preload("res://autoload/event_bus.gd")
const OrderServiceScript: GDScript = preload("res://autoload/order_service.gd")
const RoundManagerScript: GDScript = preload("res://autoload/round_manager.gd")
const LEVEL: PackedScene = preload("res://scenes/levels/level_01.tscn")
const CONFIG_PATH: String = "res://data/config/round_config.tres"
const CATALOG_PATH: String = "res://data/orders/order_catalog.tres"
const SLOTS: Array[int] = [1, 2, 3, 4]
const TICK: float = 1.0 / 60.0

var _config: RoundConfig
var _catalog: OrderCatalog
var _board: OrderBoard
var _round: RoundState
var _trace: Array[String] = []
var _level: Node


func before_each() -> void:
	_trace.clear()
	_config = load(CONFIG_PATH) as RoundConfig
	_catalog = load(CATALOG_PATH) as OrderCatalog
	_board = OrderBoard.new(_catalog, _seeded_rng(11))
	_round = RoundState.new(_config, _board)


func after_each() -> void:
	GameState.set_paused(false)
	GameState.reset_input()
	if is_instance_valid(_level):
		_level.free()
	_level = null


func _seeded_rng(seed_value: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


## Copia del config real con otra duración, retardo inicial o fases.
func _config_copy(duration: float = 300.0, first_order_delay: float = 5.0) -> RoundConfig:
	var config: RoundConfig = _config.duplicate() as RoundConfig
	config.duration = duration
	config.first_order_delay = first_order_delay
	return config


func _phase(start_fraction: float, active_slots: int, multiplier: float) -> PhaseData:
	var phase: PhaseData = PhaseData.new()
	phase.start_fraction = start_fraction
	phase.active_slots = active_slots
	phase.patience_multiplier = multiplier
	return phase


func _contents_for(order: ActiveOrder) -> BoxContents:
	return BoxContents.new(
		order.data.recipe.box,
		order.data.recipe.ingredient,
		IngredientData.CookingState.COOKED,
		1.0,
		order.data.seasonings.duplicate()
	)


func _active_slots(board: OrderBoard = _board) -> Array[int]:
	var ids: Array[int] = []
	for order: ActiveOrder in board.get_active_orders():
		ids.append(order.slot_id)
	return ids


## Avanza `seconds` en ticks de 1/60 s (el redondeo del reloj como en el juego).
func _ticks(seconds: float, state: RoundState = _round) -> void:
	for _i: int in roundi(seconds / TICK):
		state.advance(TICK)


## Avanza hasta `elapsed` segundos de ronda en un solo paso.
func _advance_to(elapsed: float, state: RoundState = _round, config: RoundConfig = _config) -> void:
	state.advance(elapsed - (config.duration - state.get_time_left()))


func _on_trace(label: String) -> void:
	_trace.append(label)


# --- Datos ---


func test_data_three_phases_at_thirds_with_2_3_4_slots_and_multipliers() -> void:
	assert_eq(_config.phases.size(), 3)
	var expected: Array = [[0.0, 2, 1.0], [1.0 / 3.0, 3, 0.85], [2.0 / 3.0, 4, 0.7]]
	for i: int in expected.size():
		var phase: PhaseData = _config.phases[i]
		assert_almost_eq(phase.start_fraction, expected[i][0] as float, 1e-9, "fase %d" % (i + 1))
		assert_eq(phase.active_slots, expected[i][1] as int, "fase %d" % (i + 1))
		assert_almost_eq(phase.patience_multiplier, expected[i][2] as float, 1e-9)
	assert_eq(_config.rng_seed, 0, "partida real: semilla aleatoria")
	assert_true(_config.phases.back().active_slots <= _catalog.max_active_orders)


# --- AC1 ---


func test_ac1_start_is_phase_1_with_two_stands_and_recipe_patience() -> void:
	watch_signals(_round)
	_round.start(SLOTS)
	assert_eq(_round.get_phase(), 1)
	assert_signal_emit_count(_round, "phase_changed", 1)
	assert_signal_emitted_with_parameters(_round, "phase_changed", [1])
	_round.advance(_config.first_order_delay)
	assert_eq(_active_slots(), [1, 2] as Array[int], "los 2 primeros puestos de level.stands")
	for order: ActiveOrder in _board.get_active_orders():
		assert_eq(order.max_time, order.data.max_time, "×1,0 del max_time de la receta")
	assert_signal_emit_count(_round, "phase_changed", 1)


func test_ac1_start_sequence_reset_phase_orders_time_started() -> void:
	var config: RoundConfig = _config_copy(300.0, 0.0)
	var round_state: RoundState = RoundState.new(config, _board)
	_board.orders_reset.connect(_on_trace.bind("orders_reset"))
	_board.order_generated.connect(
		func(o: ActiveOrder) -> void: _trace.append("gen:%d" % o.slot_id)
	)
	round_state.phase_changed.connect(func(p: int) -> void: _trace.append("phase:%d" % p))
	round_state.round_time_changed.connect(func(_t: float) -> void: _trace.append("time"))
	round_state.round_started.connect(func(_d: float) -> void: _trace.append("started"))
	round_state.start(SLOTS)
	assert_eq(
		_trace, ["orders_reset", "phase:1", "gen:1", "gen:2", "time", "started"] as Array[String]
	)


func test_ac1_inactive_stands_stay_empty_through_phase_1() -> void:
	_round.start(SLOTS)
	var opened: bool = false
	for _i: int in roundi(99.0 / TICK):
		_round.advance(TICK)
		var slots: Array[int] = _active_slots()
		opened = opened or slots.has(3) or slots.has(4)
	assert_false(opened, "puestos 3 y 4 cerrados en fase 1")
	assert_eq(_round.get_phase(), 1)


# --- AC2 ---


func test_ac2_phase_2_exactly_at_100_s_with_one_signal_and_third_stand_same_tick() -> void:
	_round.start(SLOTS)
	_ticks(99.9)
	assert_eq(_round.get_phase(), 1, "a 99,9 s sigue la fase 1")
	assert_eq(_active_slots().size(), 2)
	watch_signals(_round)
	_round.advance(TICK)
	assert_eq(_round.get_phase(), 1, "a 99,9 + 1/60 s sigue la fase 1")
	for _i: int in 4:
		_round.advance(TICK)
	assert_eq(_round.get_phase(), 1, "tick 5999")
	_round.advance(TICK)
	assert_eq(_round.get_phase(), 2, "tick 6000 = 100,0 s")
	assert_signal_emit_count(_round, "phase_changed", 1)
	assert_signal_emitted_with_parameters(_round, "phase_changed", [2])
	assert_eq(_active_slots(), [1, 2, 3] as Array[int], "3 puestos con comanda en el mismo tick")
	_ticks(10.0)
	assert_signal_emit_count(_round, "phase_changed", 1, "una sola vez")


func test_ac2_clock_step_from_99_9_to_100_0() -> void:
	_round.start(SLOTS)
	_advance_to(99.9)
	assert_eq(_round.get_phase(), 1)
	watch_signals(_round)
	_round.advance(0.1)
	assert_eq(_round.get_phase(), 2)
	assert_signal_emit_count(_round, "phase_changed", 1)
	assert_eq(_active_slots(), [1, 2, 3] as Array[int])


func test_ac2_phase_signal_before_new_stand_order_and_time_change() -> void:
	_round.start(SLOTS)
	_advance_to(99.5)
	_round.phase_changed.connect(func(p: int) -> void: _trace.append("phase:%d" % p))
	_board.order_generated.connect(
		func(o: ActiveOrder) -> void: _trace.append("gen:%d" % o.slot_id)
	)
	_round.round_time_changed.connect(func(_t: float) -> void: _trace.append("time"))
	_round.advance(0.5)
	assert_eq(_trace, ["phase:2", "gen:3", "time"] as Array[String])


func test_ac2_new_orders_in_phase_2_use_0_85_of_recipe_patience() -> void:
	_round.start(SLOTS)
	_advance_to(100.0)
	var order: ActiveOrder = _board.get_order_for_slot(3)
	assert_almost_eq(order.max_time, order.data.max_time * 0.85, 1e-6)
	assert_almost_eq(order.time_left, order.max_time, 1e-6)


# --- AC3 ---


func test_ac3_phase_3_at_200_s_four_stands_never_above_max_active_orders() -> void:
	_round.start(SLOTS)
	var max_seen: int = 0
	for _i: int in roundi(199.0 / TICK):
		_round.advance(TICK)
		max_seen = maxi(max_seen, _board.get_active_orders().size())
	assert_eq(_round.get_phase(), 2)
	_ticks(1.0)
	assert_eq(_round.get_phase(), 3)
	assert_eq(_active_slots(), SLOTS, "4 puestos activos")
	for _i: int in roundi(99.0 / TICK):
		_round.advance(TICK)
		max_seen = maxi(max_seen, _board.get_active_orders().size())
	assert_true(max_seen <= _catalog.max_active_orders, "nunca más de max_active_orders")
	assert_eq(max_seen, 4)


func test_ac3_cap_holds_when_catalog_allows_fewer_than_active_stands() -> void:
	var catalog: OrderCatalog = _catalog.duplicate() as OrderCatalog
	catalog.max_active_orders = 3
	var board: OrderBoard = OrderBoard.new(catalog, _seeded_rng(3))
	var round_state: RoundState = RoundState.new(_config, board)
	round_state.start(SLOTS)
	_advance_to(250.0, round_state)
	assert_eq(round_state.get_phase(), 3)
	assert_eq(board.get_active_orders().size(), 3)


func test_ac3_deliveries_in_phase_3_restock_all_four_stands() -> void:
	_round.start(SLOTS)
	_advance_to(200.0)
	for slot_id: int in SLOTS:
		var order: ActiveOrder = _board.get_order_for_slot(slot_id)
		assert_not_null(_board.try_deliver(slot_id, _contents_for(order)))
	assert_eq(_active_slots(), SLOTS)


# --- AC4 ---


func test_ac4_live_orders_keep_their_max_time_across_phase_changes() -> void:
	_round.start(SLOTS)
	_advance_to(99.0)
	var before: Dictionary[int, float] = {}
	for order: ActiveOrder in _board.get_active_orders():
		before[order.id] = order.max_time
	assert_eq(before.size(), 2)
	_round.advance(1.0)
	assert_eq(_round.get_phase(), 2)
	for order: ActiveOrder in _board.get_active_orders():
		if before.has(order.id):
			assert_eq(order.max_time, before[order.id], "comanda #%d conserva max_time" % order.id)
		else:
			assert_almost_eq(order.max_time, order.data.max_time * 0.85, 1e-6)


func test_ac4_phase_3_orders_use_0_7_and_patience_changed_reports_own_max_time() -> void:
	_round.start(SLOTS)
	_advance_to(199.0)
	var live: Array[ActiveOrder] = _board.get_active_orders()
	watch_signals(_board)
	_round.advance(1.0)
	assert_eq(_round.get_phase(), 3)
	var newest: ActiveOrder = _board.get_order_for_slot(4)
	assert_almost_eq(newest.max_time, newest.data.max_time * 0.7, 1e-6)
	_round.advance(TICK)
	for order: ActiveOrder in live:
		var now: ActiveOrder = _board.get_order_for_slot(order.slot_id)
		if now != null and now.id == order.id:
			assert_eq(now.max_time, order.max_time)


# --- AC5 ---


## Recetas generadas en una ronda completa por un `OrderService` montado con `config`, con una
## entrega cada 7 s en el puesto de menor `slot_id` (mezcla reposición por entrega y caducidad).
func _sequence_for(config: RoundConfig) -> Array[String]:
	var bus: Node = add_child_autofree(EventBusScript.new())
	var service: Node = OrderServiceScript.new()
	service.set_bus(bus)
	add_child_autofree(service)
	service.setup(_catalog, null, config)
	var board: OrderBoard = service.board
	var sequence: Array[String] = []
	board.order_generated.connect(
		func(o: ActiveOrder) -> void: sequence.append("%d:%s" % [o.slot_id, o.data.display_name])
	)
	var round_state: RoundState = RoundState.new(config, board)
	round_state.start(SLOTS)
	var step: float = 0.0
	while not round_state.is_finished():
		round_state.advance(0.5)
		step += 0.5
		if step >= 7.0:
			step = 0.0
			var active: Array[ActiveOrder] = board.get_active_orders()
			if not active.is_empty():
				board.try_deliver(active[0].slot_id, _contents_for(active[0]))
	return sequence


func test_ac5_same_seed_same_order_sequence() -> void:
	var config: RoundConfig = _config_copy()
	config.rng_seed = 1234
	var first: Array[String] = _sequence_for(config)
	var second: Array[String] = _sequence_for(config)
	assert_gt(first.size(), 20)
	assert_eq(first, second)


func test_ac5_different_seed_changes_the_sequence() -> void:
	var config_a: RoundConfig = _config_copy()
	config_a.rng_seed = 1234
	var config_b: RoundConfig = _config_copy()
	config_b.rng_seed = 98765
	assert_ne(_sequence_for(config_a), _sequence_for(config_b))


func test_ac5_injected_rng_wins_over_config_seed() -> void:
	var config: RoundConfig = _config_copy()
	config.rng_seed = 1234
	var service: Node = OrderServiceScript.new()
	service.set_bus(add_child_autofree(EventBusScript.new()))
	add_child_autofree(service)
	var rng: RandomNumberGenerator = _seeded_rng(5)
	service.setup(_catalog, rng, config)
	var expected: RandomNumberGenerator = _seeded_rng(5)
	var order: ActiveOrder = service.request_order(1)
	assert_eq(order.data, _catalog.orders[expected.randi_range(0, _catalog.orders.size() - 1)])


# --- AC6 ---


func test_ac6_phase_bounds_scale_with_match_duration() -> void:
	var config: RoundConfig = _config_copy(150.0)
	var round_state: RoundState = RoundState.new(config, _board)
	round_state.start(SLOTS)
	_advance_to(49.9, round_state, config)
	assert_eq(round_state.get_phase(), 1)
	_advance_to(50.0, round_state, config)
	assert_eq(round_state.get_phase(), 2, "fase 2 al tercio de 150 s")
	_advance_to(99.9, round_state, config)
	assert_eq(round_state.get_phase(), 2)
	_advance_to(100.0, round_state, config)
	assert_eq(round_state.get_phase(), 3, "fase 3 a los dos tercios")
	assert_eq(_active_slots(), SLOTS)


func test_ac6_ticks_hit_scaled_bound_exactly() -> void:
	var config: RoundConfig = _config_copy(600.0)
	var round_state: RoundState = RoundState.new(config, _board)
	round_state.start(SLOTS)
	_ticks(199.0, round_state)
	for _i: int in 59:
		round_state.advance(TICK)
	assert_eq(round_state.get_phase(), 1, "tick 11999")
	round_state.advance(TICK)
	assert_eq(round_state.get_phase(), 2, "tick 12000 = 200 s")


# --- Bordes ---


func test_large_delta_crossing_two_phases_emits_each_once_in_order() -> void:
	_round.start(SLOTS)
	_round.phase_changed.connect(func(p: int) -> void: _trace.append("phase:%d" % p))
	_round.advance(250.0)
	assert_eq(_trace, ["phase:2", "phase:3"] as Array[String])
	assert_eq(_active_slots(), SLOTS)


func test_no_phase_changed_after_round_end_and_phase_at_duration_never_starts() -> void:
	var config: RoundConfig = _config_copy(300.0, 0.0)
	var phases: Array[PhaseData] = [_phase(0.0, 2, 1.0), _phase(1.0, 4, 0.5)]
	config.phases = phases
	var round_state: RoundState = RoundState.new(config, _board)
	round_state.start(SLOTS)
	watch_signals(round_state)
	round_state.advance(400.0)
	assert_true(round_state.is_finished())
	assert_signal_not_emitted(round_state, "phase_changed")
	assert_eq(round_state.get_phase(), 1)


func test_no_phases_behaves_as_before() -> void:
	var config: RoundConfig = _config_copy(300.0, 0.0)
	config.phases = [] as Array[PhaseData]
	var round_state: RoundState = RoundState.new(config, _board)
	watch_signals(round_state)
	round_state.start(SLOTS)
	assert_eq(round_state.get_phase(), 0)
	assert_eq(_active_slots(), SLOTS, "todos los puestos")
	for order: ActiveOrder in _board.get_active_orders():
		assert_eq(order.max_time, order.data.max_time)
	round_state.advance(250.0)
	assert_signal_not_emitted(round_state, "phase_changed")


func test_restart_returns_to_phase_1() -> void:
	_round.start(SLOTS)
	_advance_to(250.0)
	assert_eq(_round.get_phase(), 3)
	watch_signals(_round)
	_round.start(SLOTS)
	assert_eq(_round.get_phase(), 1)
	assert_signal_emitted_with_parameters(_round, "phase_changed", [1])
	_round.advance(_config.first_order_delay)
	assert_eq(_active_slots(), [1, 2] as Array[int])


func test_config_change_mid_round_does_not_alter_running_phases() -> void:
	var config: RoundConfig = _config_copy()
	var round_state: RoundState = RoundState.new(config, _board)
	round_state.start(SLOTS)
	config.phases = [] as Array[PhaseData]
	_advance_to(150.0, round_state, config)
	assert_eq(round_state.get_phase(), 2)


# --- OrderBoard ---


func test_board_set_active_slots_blocks_other_stands() -> void:
	_board.reset()
	_board.set_active_slots([2] as Array[int])
	assert_null(_board.request_order(1))
	assert_not_null(_board.request_order(2))


func test_board_deactivated_stand_keeps_live_order_but_is_not_restocked() -> void:
	_board.reset()
	_board.fill_slots(SLOTS)
	_board.set_active_slots([1, 2] as Array[int])
	var order: ActiveOrder = _board.get_order_for_slot(4)
	assert_not_null(order, "la comanda viva sigue")
	assert_not_null(_board.try_deliver(4, _contents_for(order)))
	assert_null(_board.get_order_for_slot(4), "no se repone")
	var slot_3: ActiveOrder = _board.get_order_for_slot(3)
	_board.advance(slot_3.max_time)
	assert_null(_board.get_order_for_slot(3), "caduca y no se repone")


func test_board_patience_multiplier_only_affects_new_orders_and_reset_restores() -> void:
	_board.reset()
	var old: ActiveOrder = _board.request_order(1)
	_board.set_new_order_patience_multiplier(0.5)
	var new_order: ActiveOrder = _board.request_order(2)
	assert_eq(_board.get_order_for_slot(1).max_time, old.data.max_time)
	assert_almost_eq(new_order.max_time, new_order.data.max_time * 0.5, 1e-6)
	_board.set_active_slots([] as Array[int])
	_board.reset()
	var fresh: ActiveOrder = _board.request_order(3)
	assert_not_null(fresh, "reset: todos los puestos activos")
	assert_eq(fresh.max_time, fresh.data.max_time, "reset: multiplicador 1,0")


# --- RoundManager / bus ---


func test_round_manager_forwards_phase_changed_to_bus() -> void:
	var bus: Node = add_child_autofree(EventBusScript.new())
	var service: Node = OrderServiceScript.new()
	service.set_bus(bus)
	add_child_autofree(service)
	service.setup(_catalog, _seeded_rng(2), _config)
	var manager: Node = RoundManagerScript.new()
	manager.set_bus(bus)
	manager.set_order_service(service)
	manager.set_physics_process(false)
	add_child_autofree(manager)
	watch_signals(bus)
	manager.start_round(_config, SLOTS)
	assert_signal_emit_count(bus, "phase_changed", 1)
	assert_signal_emitted_with_parameters(bus, "phase_changed", [1])
	manager.round_state.advance(250.0)
	assert_signal_emit_count(bus, "phase_changed", 3)
	assert_signal_emitted_with_parameters(bus, "phase_changed", [3])
	manager.start_round(_config, SLOTS)
	manager.round_state.advance(250.0)
	assert_signal_emit_count(bus, "phase_changed", 6, "el núcleo anterior ya no reenvía")


# --- level_01 con las fases reales ---


func test_level_01_real_phases_open_2_then_3_then_4_stands() -> void:
	watch_signals(EventBus)
	_level = LEVEL.instantiate()
	add_child(_level)
	await wait_physics_frames(2)
	var state: RoundState = RoundManager.round_state
	assert_signal_emitted_with_parameters(EventBus, "phase_changed", [1])
	state.advance(_config.first_order_delay)
	assert_eq(_slots_of(OrderService.get_active_orders()), [1, 2] as Array[int])
	_advance_to(100.0, state)
	assert_eq(state.get_phase(), 2)
	assert_eq(_slots_of(OrderService.get_active_orders()), [1, 2, 3] as Array[int])
	_advance_to(200.0, state)
	assert_eq(state.get_phase(), 3)
	assert_eq(_slots_of(OrderService.get_active_orders()), [1, 2, 3, 4] as Array[int])
	assert_signal_emit_count(EventBus, "phase_changed", 3)
	var stand_4: Node = _level.get_node("Stations/OrderStand4")
	var label: String = (stand_4.get_node("%OrderLabel") as Label3D).text
	assert_ne(label, "–", "el puesto 4 muestra su comanda")
	# Volver a un frame de proceso: la suite siguiente no debe arrancar dentro de un tick de física.
	await wait_process_frames(1)


func _slots_of(orders: Array[ActiveOrder]) -> Array[int]:
	var ids: Array[int] = []
	for order: ActiveOrder in orders:
		ids.append(order.slot_id)
	return ids
