class_name OrderTicketsPanel
extends SafeAreaMargin
## Se suscribe antes de reconstruir; los ids evitan tickets duplicados. En MOBILE (PUL-129) es la
## fila de 4 tickets de la banda superior, entre el bloque del HUD y el botón de pausa.

const TICKET_SCENE: PackedScene = preload("res://ui/tickets/order_ticket.tscn")

var _bus: Node
var _service: Node
var _tickets: Dictionary[int, OrderTicket] = {}


func _ready() -> void:
	super._ready()
	if _bus == null:
		_bus = EventBus
	if _service == null:
		_service = OrderService
	_bus.orders_reset.connect(_on_reset)
	_bus.order_generated.connect(_on_generated)
	_bus.order_completed.connect(_on_removed)
	_bus.order_expired.connect(_on_removed)
	_apply_layout()
	for order: ActiveOrder in _service.get_active_orders():
		_on_generated(order)


## SafeAreaMargin llama aquí al cambiar la ventana o la safe area: se recalcula el ancho.
func refresh() -> void:
	super.refresh()
	if is_node_ready():
		_apply_layout()


func set_bus(bus: Node) -> void:
	_bus = bus


func set_service(service: Node) -> void:
	_service = service


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
	if _mobile():
		ticket.apply_mobile_layout(GameState.ui_profile, _ticket_width_units())
	_tickets[order.id] = ticket


func _on_removed(order: ActiveOrder, _points: int) -> void:
	if not _tickets.has(order.id):
		return
	var ticket: OrderTicket = _tickets[order.id]
	_tickets.erase(order.id)
	%Tickets.remove_child(ticket)
	ticket.queue_free()


func _mobile() -> bool:
	return GameState.platform == PlatformProfile.Kind.MOBILE


## Ancho de cada ticket en unidades de lienzo: lo que queda entre el HUD y el botón de pausa,
## sin los márgenes de la safe area, repartido en 4 y acotado por el perfil.
func _ticket_width_units() -> float:
	var canvas: Vector2 = get_viewport().get_visible_rect().size
	var inner: float = canvas.x - offset_left + offset_right
	inner -= get_theme_constant(&"margin_left") + get_theme_constant(&"margin_right")
	var available_px: float = inner * UiScale.REFERENCE_HEIGHT_PX / canvas.y
	var width_px: float = TouchHudLayout.ticket_width_px(available_px, GameState.ui_profile)
	return UiScale.px_to_units(width_px, canvas.y)


## Disposición del perfil (ADR-005 E4). En DESKTOP no cambia nada de la escena.
func _apply_layout() -> void:
	if not _mobile():
		return
	var profile: UiProfile = GameState.ui_profile
	var canvas_height: float = get_viewport().get_visible_rect().size.y
	add_theme_constant_override(&"margin_bottom", 0)
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = UiScale.px_to_units(TouchHudLayout.tickets_left_px(profile), canvas_height)
	offset_right = -UiScale.px_to_units(TouchHudLayout.tickets_right_px(), canvas_height)
	offset_top = UiScale.px_to_units(TouchHudLayout.TOP_PX, canvas_height)
	offset_bottom = offset_top + UiScale.px_to_units(profile.ticket_height, canvas_height)
	%Tickets.add_theme_constant_override(
		&"separation", floori(UiScale.px_to_units(profile.ticket_gap, canvas_height))
	)
	var width: float = _ticket_width_units()
	for ticket: OrderTicket in _tickets.values():
		ticket.apply_mobile_layout(profile, width)
