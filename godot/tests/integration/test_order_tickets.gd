extends GutTest
## PUL-020: tickets integrados con un servicio real y un bus aislado.

const PANEL_SCENE: PackedScene = preload("res://ui/tickets/order_tickets_panel.tscn")
const BusScript: GDScript = preload("res://autoload/event_bus.gd")
const ServiceScript: GDScript = preload("res://autoload/order_service.gd")
const CATALOG: OrderCatalog = preload("res://data/orders/order_catalog.tres")

var _bus: Node
var _service: Node
var _panel: OrderTicketsPanel


func before_each() -> void:
	_bus = add_child_autofree(BusScript.new())
	_service = ServiceScript.new()
	_service.set_bus(_bus)
	add_child_autofree(_service)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20
	_service.setup(CATALOG, rng)


func after_each() -> void:
	await wait_process_frames(2)


func _mount() -> void:
	_panel = PANEL_SCENE.instantiate()
	_panel.set_bus(_bus)
	_panel.set_service(_service)
	add_child_autofree(_panel)


func _tickets() -> Array[Node]:
	return _panel.get_node("%Tickets").get_children()


func _ticket(id: int) -> OrderTicket:
	for ticket: OrderTicket in _tickets():
		if ticket.order_id == id:
			return ticket
	return null


func _fill() -> void:
	_service.board.fill_slots([1, 2, 3, 4] as Array[int])


func test_ac2_one_ticket_per_active_order_and_duplicate_event_is_idempotent() -> void:
	_mount()
	_fill()
	assert_eq(_tickets().size(), 4)
	for order: ActiveOrder in _service.get_active_orders():
		assert_not_null(_ticket(order.id))
		_bus.order_generated.emit(order)
	assert_eq(_tickets().size(), 4)


func test_ac2_completion_replaces_only_its_ticket_then_reset_clears() -> void:
	_mount()
	_fill()
	var orders: Array[ActiveOrder] = _service.get_active_orders()
	var order: ActiveOrder = orders[0]
	var untouched: OrderTicket = _ticket(orders[1].id)
	var contents: BoxContents = BoxContents.new(
		order.data.recipe.box,
		order.data.recipe.ingredient,
		IngredientData.CookingState.COOKED,
		1.0,
		order.data.seasonings
	)
	assert_not_null(_service.try_deliver(order.slot_id, contents))
	assert_null(_ticket(order.id))
	assert_eq(_tickets().size(), 4)
	assert_same(_ticket(orders[1].id), untouched)
	for active: ActiveOrder in _service.get_active_orders():
		assert_not_null(_ticket(active.id))
	_service.board.reset()
	assert_eq(_tickets().size(), 0)


func test_ac2_expired_ticket_disappears() -> void:
	_mount()
	_fill()
	var order: ActiveOrder = _service.get_active_orders()[0]
	_bus.order_expired.emit(order, 0)
	assert_null(_ticket(order.id))
	assert_eq(_tickets().size(), 3)


func test_ac3_late_panel_reconstructs_active_orders_and_text() -> void:
	_fill()
	_mount()
	assert_eq(_tickets().size(), 4)
	for order: ActiveOrder in _service.get_active_orders():
		var ticket: OrderTicket = _ticket(order.id)
		assert_eq((ticket.get_node("%OrderId") as Label).text, "#%d" % order.id)
		var entry: TicketEntry = ticket.get_node("%Entry")
		assert_eq((entry.get_node("%Recipe") as Label).text, order.data.recipe.display_name)
		for seasoning: SeasoningData in order.data.seasonings:
			assert_string_contains(
				(entry.get_node("%Seasonings") as Label).text, seasoning.display_name
			)


func test_ac2_patience_is_hidden_in_m0_and_updates_only_own_id() -> void:
	_mount()
	_fill()
	var order: ActiveOrder = _service.get_active_orders()[0]
	var bar: TextureProgressBar = _ticket(order.id).get_node("%PatienceBar")
	assert_false(bar.visible)
	_bus.order_patience_changed.emit(order.id + 999, 5.0, 10.0)
	assert_false(bar.visible)
	_bus.order_patience_changed.emit(order.id, 5.0, 10.0)
	assert_true(bar.visible)
	assert_eq(bar.value, 5.0)
	_bus.order_patience_changed.emit(order.id + 999, 1.0, 10.0)
	assert_eq(bar.value, 5.0)
	_bus.order_patience_changed.emit(order.id, 0.0, 0.0)
	assert_false(bar.visible)
