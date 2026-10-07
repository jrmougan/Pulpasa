class_name OrderTicketsPanel
extends Control
## Se suscribe antes de reconstruir; los ids evitan tickets duplicados.

const TICKET_SCENE: PackedScene = preload("res://ui/tickets/order_ticket.tscn")

var _bus: Node
var _service: Node
var _tickets: Dictionary[int, OrderTicket] = {}


func _ready() -> void:
	if _bus == null:
		_bus = EventBus
	if _service == null:
		_service = OrderService
	_bus.orders_reset.connect(_on_reset)
	_bus.order_generated.connect(_on_generated)
	_bus.order_completed.connect(_on_removed)
	_bus.order_expired.connect(_on_removed)
	for order: ActiveOrder in _service.get_active_orders():
		_on_generated(order)
	get_viewport().size_changed.connect(_apply_ui_scale)
	_apply_ui_scale()


func set_bus(bus: Node) -> void:
	_bus = bus


func set_service(service: Node) -> void:
	_service = service


func _apply_ui_scale() -> void:
	(%Tickets as Control).scale = Vector2.ONE * UiScale.factor(get_viewport_rect().size.y)


func _on_reset() -> void:
	for ticket: OrderTicket in _tickets.values():
		%Tickets.remove_child(ticket)
		ticket.queue_free()
	_tickets.clear()


func _on_generated(order: ActiveOrder) -> void:
	if _tickets.has(order.id):
		return
	var ticket: OrderTicket = TICKET_SCENE.instantiate()
	ticket.set_bus(_bus)
	%Tickets.add_child(ticket)
	ticket.setup(order)
	_tickets[order.id] = ticket


func _on_removed(order: ActiveOrder, _points: int) -> void:
	if not _tickets.has(order.id):
		return
	var ticket: OrderTicket = _tickets[order.id]
	_tickets.erase(order.id)
	%Tickets.remove_child(ticket)
	ticket.queue_free()
