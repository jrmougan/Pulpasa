extends GutTest
## PUL-020: tickets integrados con un servicio real y un bus aislado.

const PANEL_SCENE: PackedScene = preload("res://ui/tickets/order_tickets_panel.tscn")
const BusScript: GDScript = preload("res://autoload/event_bus.gd")
const ServiceScript: GDScript = preload("res://autoload/order_service.gd")
const ENTRY_SCENE: PackedScene = preload("res://ui/tickets/ticket_entry.tscn")
const SALT: SeasoningData = preload("res://data/seasonings/salt.tres")
const HOT: SeasoningData = preload("res://data/seasonings/hot_paprika.tres")
const OIL: SeasoningData = preload("res://data/seasonings/oil.tres")
const CACHELOS: SeasoningData = preload("res://data/seasonings/cachelos.tres")
const SWEET: SeasoningData = preload("res://data/seasonings/paprika.tres")
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


func test_ac4_ticket_shows_one_sticker_per_seasoning_in_canonical_order() -> void:
	_mount()
	_fill()
	for order: ActiveOrder in _service.get_active_orders():
		var entry: TicketEntry = _ticket(order.id).get_node("%Entry")
		var icons: Array[Node] = (entry.get_node("%SeasoningIcons") as HBoxContainer).get_children()
		var expected: Array[SeasoningData] = SeasoningRules.canonical_order(order.data.seasonings)
		assert_eq(icons.size(), expected.size(), "una pegatina por condimento")
		for i: int in range(expected.size()):
			assert_not_null(expected[i].icon, "SeasoningData.icon asignado (PUL-031)")
			assert_eq((icons[i].get_node("Icon") as TextureRect).texture, expected[i].icon)


func test_ac14_ticket_orders_stickers_canonically_whatever_the_tres_order() -> void:
	var entry: TicketEntry = ENTRY_SCENE.instantiate()
	add_child_autofree(entry)
	var data: OrderData = OrderData.new()
	data.seasonings = [CACHELOS, OIL, SALT, HOT] as Array[SeasoningData]
	entry.setup(data)
	var stickers: Array[Node] = entry.get_node("%SeasoningIcons").get_children()
	assert_eq(stickers.size(), 4)
	var want: Array[SeasoningData] = [HOT, SALT, OIL, CACHELOS]
	for i: int in range(4):
		assert_eq((stickers[i].get_node("Icon") as TextureRect).texture, want[i].icon)
	assert_not_null(stickers[0].get_node_or_null("HotMark"), "el picante lleva la llama")
	for i: int in range(1, 4):
		assert_null(stickers[i].get_node_or_null("HotMark"))
	assert_eq(data.seasonings[0], CACHELOS, "no muta la comanda")


func test_ac4_sticker_uses_box_badge_style_and_seasoning_color() -> void:
	var style: BoxBadgeStyle = load("res://data/config/box_badges.tres")
	var sticker: Control = _entry_with(SALT).get_node("%SeasoningIcons").get_child(0)
	assert_eq(sticker.custom_minimum_size, Vector2(style.badge_icon_px, style.badge_icon_px))
	var disc: Panel = sticker.get_node("Disc")
	var box: StyleBoxFlat = disc.get_theme_stylebox("panel") as StyleBoxFlat
	assert_eq(box.bg_color, SALT.color)
	assert_eq((sticker.get_node("Icon") as TextureRect).self_modulate, Color.WHITE)


func test_ac4_sweet_and_hot_paprika_tickets_are_distinguishable() -> void:
	var sweet_sticker: Control = _entry_with(SWEET).get_node("%SeasoningIcons").get_child(0)
	var hot_sticker: Control = _entry_with(HOT).get_node("%SeasoningIcons").get_child(0)
	assert_ne(_disc_color(sweet_sticker), _disc_color(hot_sticker), "tinte distinto")
	assert_null(sweet_sticker.get_node_or_null("HotMark"), "el dulce no lleva marca")
	assert_not_null(hot_sticker.get_node_or_null("HotMark"), "el picante lleva la llama")


func test_ac4_seasoning_without_icon_shows_translated_name() -> void:
	var plain: SeasoningData = SeasoningData.new()
	plain.display_name = "Sin icono"
	var entry: TicketEntry = _entry_with(plain)
	var label: Label = entry.get_node("%SeasoningIcons").get_child(0) as Label
	assert_not_null(label, "sin icono: Label con el nombre")
	assert_eq(label.text, "Sin icono")


func test_ac4_patience_bar_is_visible_and_decreases_linearly() -> void:
	_mount()
	_fill()
	var order: ActiveOrder = _service.get_active_orders()[0]
	var bar: TextureProgressBar = _ticket(order.id).get_node("%PatienceBar")
	_bus.order_patience_changed.emit(order.id, 10.0, 10.0)
	assert_true(bar.visible, "max_time > 0: la barra se muestra")
	assert_eq(bar.max_value, 10.0)
	assert_eq(bar.value, 10.0)
	_bus.order_patience_changed.emit(order.id, 7.5, 10.0)
	assert_eq(bar.value, 7.5)
	_bus.order_patience_changed.emit(order.id, 5.0, 10.0)
	assert_eq(bar.value, 5.0)
	_bus.order_patience_changed.emit(order.id, 0.0, 10.0)
	assert_eq(bar.value, 0.0)
	assert_true(bar.visible, "decrece hasta 0 sin ocultarse mientras max_time > 0")


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


func _disc_color(sticker: Control) -> Color:
	var box: StyleBoxFlat = (sticker.get_node("Disc") as Panel).get_theme_stylebox("panel")
	return box.bg_color


func _entry_with(seasoning: SeasoningData) -> TicketEntry:
	var entry: TicketEntry = ENTRY_SCENE.instantiate()
	add_child_autofree(entry)
	var data: OrderData = OrderData.new()
	data.seasonings = [seasoning] as Array[SeasoningData]
	entry.setup(data)
	return entry
