extends GutTest
## PUL-007 AC1: OrderService reenvía cada señal de OrderBoard al bus inyectado, una vez y con los
## mismos argumentos. Sin reglas propias, sin `_process`.

const EventBusScript: GDScript = preload("res://autoload/event_bus.gd")
const OrderServiceScript: GDScript = preload("res://autoload/order_service.gd")
const CATALOG_PATH: String = "res://data/orders/order_catalog.tres"

var _bus: Node
var _service: Node


func before_each() -> void:
	_bus = add_child_autofree(EventBusScript.new())
	_service = OrderServiceScript.new()
	_service.set_bus(_bus)
	add_child_autofree(_service)


func _setup_default() -> void:
	_service.setup(load(CATALOG_PATH) as OrderCatalog, _seeded_rng())
	watch_signals(_service.board)
	watch_signals(_bus)


func _seeded_rng() -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 11
	return rng


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


func _assert_same_args(signal_name: String, index: int = 0) -> void:
	var from_core: Array = get_signal_parameters(_service.board, signal_name, index)
	var from_bus: Array = get_signal_parameters(_bus, signal_name, index)
	assert_eq(from_bus.size(), from_core.size(), "%s: nº de argumentos" % signal_name)
	for i: int in range(from_core.size()):
		assert_same(from_bus[i], from_core[i], "%s: argumento %d" % [signal_name, i])


func test_ac1_setup_creates_board() -> void:
	assert_null(_service.board)
	_service.setup(load(CATALOG_PATH) as OrderCatalog, _seeded_rng())
	assert_not_null(_service.board)
	assert_eq(_service.get_active_orders().size(), 0)


func test_ac1_orders_reset_forwarded_once() -> void:
	_setup_default()
	_service.board.reset()
	assert_signal_emit_count(_service.board, "orders_reset", 1)
	assert_signal_emit_count(_bus, "orders_reset", 1)


func test_ac1_order_generated_forwarded_once_with_same_args() -> void:
	_setup_default()
	var order: ActiveOrder = _service.request_order(2)
	assert_not_null(order)
	assert_signal_emit_count(_bus, "order_generated", 1)
	_assert_same_args("order_generated")
	assert_eq((get_signal_parameters(_bus, "order_generated")[0] as ActiveOrder).slot_id, 2)


func test_ac1_order_completed_forwarded_once_with_same_args() -> void:
	_setup_default()
	_service.request_order(0)
	var order: ActiveOrder = _service.get_active_orders()[0]
	var done: ActiveOrder = _service.try_deliver(0, _contents_for(order))
	assert_not_null(done)
	assert_signal_emit_count(_bus, "order_completed", 1)
	_assert_same_args("order_completed")
	# La reposición también llega al bus: generated (inicial) + generated (reposición).
	assert_signal_emit_count(_bus, "order_generated", 2)


func test_ac1_delivery_rejected_forwarded_once_with_same_args() -> void:
	_setup_default()
	var done: ActiveOrder = _service.try_deliver(3, BoxContents.new())
	assert_null(done)
	assert_signal_emit_count(_bus, "delivery_rejected", 1)
	_assert_same_args("delivery_rejected")
	assert_signal_emit_count(_bus, "order_completed", 0)


func test_ac1_patience_and_expiry_forwarded_once_with_same_args() -> void:
	_service.setup(_patient_catalog(10.0), _seeded_rng())
	watch_signals(_service.board)
	watch_signals(_bus)
	_service.request_order(0)
	_service.board.advance(4.0)
	assert_signal_emit_count(_bus, "order_patience_changed", 1)
	_assert_same_args("order_patience_changed")
	_service.board.advance(6.0)
	assert_signal_emit_count(_bus, "order_patience_changed", 2)
	assert_signal_emit_count(_bus, "order_expired", 1)
	_assert_same_args("order_expired")
	assert_signal_emit_count(_bus, "order_generated", 2)


func test_ac1_get_active_orders_returns_copies() -> void:
	_setup_default()
	_service.request_order(1)
	var first: ActiveOrder = _service.get_active_orders()[0]
	first.time_left = -5.0
	assert_ne(_service.get_active_orders()[0].time_left, -5.0)


func test_ac1_previous_board_no_longer_forwards_after_new_setup() -> void:
	_setup_default()
	var previous: OrderBoard = _service.board
	_service.setup(load(CATALOG_PATH) as OrderCatalog, _seeded_rng())
	watch_signals(_bus)
	previous.request_order(0)
	assert_signal_not_emitted(_bus, "order_generated")
	_service.request_order(0)
	assert_signal_emit_count(_bus, "order_generated", 1)


func test_ac1_new_setup_does_not_duplicate_forwarding() -> void:
	_setup_default()
	_service.setup(load(CATALOG_PATH) as OrderCatalog, _seeded_rng())
	watch_signals(_bus)
	_service.request_order(0)
	assert_signal_emit_count(_bus, "order_generated", 1)


func test_ac1_service_has_no_process_callbacks() -> void:
	assert_false(_service.is_processing())
	assert_false(_service.is_physics_processing())
