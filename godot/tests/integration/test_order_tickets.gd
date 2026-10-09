# gdlint: disable=max-public-methods
extends GutTest
## PUL-020: tickets integrados con un servicio real y un bus aislado.
## PUL-086: estética de referencia (reloj de 7 segmentos, aviso de paciencia, sal clara).

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
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const MEDIUM_BOX: BoxData = preload("res://data/boxes/medium.tres")
const SMALL_BOX: BoxData = preload("res://data/boxes/small.tres")
const PALETTE: StandPalette = preload("res://data/config/stand_palette.tres")
const THEME: Theme = preload("res://ui/theme/default_theme.tres")

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
	var hot: Control = _entry_with(HOT).get_node("%SeasoningIcons").get_child(0)
	assert_eq((hot.get_node("Icon") as TextureRect).self_modulate, Color.WHITE)


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


func test_pul086_salt_sticker_is_light_with_ink_icon_and_ring() -> void:
	assert_true(StickerInk.is_light(SALT.color), "sal #F7F4EC (biblia §2.5)")
	var sticker: Control = _entry_with(SALT).get_node("%SeasoningIcons").get_child(0)
	var box: StyleBoxFlat = (sticker.get_node("Disc") as Panel).get_theme_stylebox("panel")
	assert_eq(box.border_color, StickerInk.INK)
	assert_gt(box.border_width_left, 0, "anillo marrón")
	assert_eq((sticker.get_node("Icon") as TextureRect).self_modulate, StickerInk.INK)
	for other: SeasoningData in [SWEET, HOT, OIL, CACHELOS]:
		var plain: Control = _entry_with(other).get_node("%SeasoningIcons").get_child(0)
		var style: StyleBoxFlat = (plain.get_node("Disc") as Panel).get_theme_stylebox("panel")
		assert_eq(style.border_width_left, 0, "%s sin anillo" % other.display_name)
		assert_eq((plain.get_node("Icon") as TextureRect).self_modulate, Color.WHITE)


func test_pul086_box_badge_salt_uses_ink_icon_and_ringed_disc() -> void:
	var box: Box = BOX_SCENE.instantiate()
	box.data = SMALL_BOX
	add_child_autofree(box)
	box.fill = 1.0
	box.toggle_seasoning(SALT, true)
	box.toggle_seasoning(HOT, true)
	var row: BadgeRow = box.get_node("%BadgeRow") as BadgeRow
	var hot_badge: Node = row.get_child(0)
	var salt_badge: Node = row.get_child(1)
	assert_eq((salt_badge.get_child(0) as Sprite3D).modulate, SALT.color)
	assert_eq((salt_badge.get_child(1) as Sprite3D).modulate, StickerInk.INK)
	assert_eq((hot_badge.get_child(1) as Sprite3D).modulate, Color.WHITE)
	var ringed: Image = (salt_badge.get_child(0) as Sprite3D).texture.get_image()
	var plain: Image = (hot_badge.get_child(0) as Sprite3D).texture.get_image()
	var edge: Vector2i = Vector2i(ringed.get_width() / 2, 2)
	assert_lt(ringed.get_pixelv(edge).get_luminance(), 0.5, "anillo oscuro en el borde")
	assert_eq(plain.get_pixelv(edge).get_luminance(), 1.0, "disco liso sin anillo")
	var centre: Vector2i = Vector2i(ringed.get_width() / 2, ringed.get_height() / 2)
	assert_eq(ringed.get_pixelv(centre), Color.WHITE, "el centro toma el color de la sal")


func test_pul086_clock_shows_remaining_time_in_display_format() -> void:
	assert_eq(OrderTicket.format_clock(5.0), "00:05")
	assert_eq(OrderTicket.format_clock(4.2), "00:05", "redondea hacia arriba")
	assert_eq(OrderTicket.format_clock(75.0), "01:15")
	assert_eq(OrderTicket.format_clock(0.0), "00:00")
	assert_eq(OrderTicket.format_clock(-3.0), "00:00")
	_mount()
	_fill()
	var order: ActiveOrder = _service.get_active_orders()[0]
	var ticket: OrderTicket = _ticket(order.id)
	var clock: Label = ticket.get_node("%Clock")
	assert_false((ticket.get_node("%ClockWell") as Control).visible, "sin paciencia, sin reloj")
	_bus.order_patience_changed.emit(order.id, 30.0, 40.0)
	assert_true((ticket.get_node("%ClockWell") as Control).visible)
	assert_eq(clock.text, "00:30")
	assert_eq(clock.get_theme_font(&"font"), THEME.get_font(&"font", &"DisplayLabel"))
	_bus.order_patience_changed.emit(order.id, 0.0, 0.0)
	assert_false((ticket.get_node("%ClockWell") as Control).visible)


func test_pul086_low_patience_switches_to_alert_and_blinks() -> void:
	_mount()
	_fill()
	var order: ActiveOrder = _service.get_active_orders()[0]
	var ticket: OrderTicket = _ticket(order.id)
	var bar: TextureProgressBar = ticket.get_node("%PatienceBar")
	var alert: Color = ticket.get_theme_color(&"alert_color", &"OrderTicket")
	var normal: Color = ticket.get_theme_color(&"bar_color", &"OrderTicket")
	assert_ne(alert, normal)
	_bus.order_patience_changed.emit(order.id, 20.0, 40.0)
	assert_false(ticket.is_low_patience())
	assert_eq(bar.tint_progress, normal)
	assert_false(ticket.is_processing(), "sin parpadeo")
	_bus.order_patience_changed.emit(order.id, 8.0, 40.0)
	assert_true(ticket.is_low_patience(), "≤ 25 %")
	assert_eq(bar.tint_progress, alert)
	assert_eq((ticket.get_node("%Clock") as Label).get_theme_color(&"font_color"), alert)
	assert_true(ticket.is_processing(), "parpadea: el aviso no es solo color")
	_bus.order_patience_changed.emit(order.id, 0.0, 0.0)
	assert_false(ticket.is_low_patience())
	assert_eq(bar.self_modulate.a, 1.0)


func test_pul086_ticket_uses_brand_panel_and_title() -> void:
	_mount()
	_fill()
	var ticket: OrderTicket = _ticket(_service.get_active_orders()[0].id)
	assert_eq(ticket.theme_type_variation, &"UiPanel")
	var panel: StyleBoxFlat = ticket.get_theme_stylebox(&"panel", &"UiPanel") as StyleBoxFlat
	assert_eq(Color(panel.bg_color, 1.0), Color("13202f"), "ui_panel = brand_night")
	assert_eq(panel.border_color, Color("8e9494"), "ui_border")
	assert_eq((ticket.get_node("%Title") as Label).text, "Comanda")


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


func test_pul099_palette_has_the_four_awning_colors_and_fallback() -> void:
	var palette: StandPalette = PALETTE
	assert_eq(palette.color_for(1).to_html(false), "d2473f")
	assert_eq(palette.color_for(2).to_html(false), "3f7cc8")
	assert_eq(palette.color_for(3).to_html(false), "e8c23a")
	assert_eq(palette.color_for(4).to_html(false), "4fa05a")
	assert_eq(palette.color_for(0), palette.fallback)
	assert_eq(palette.color_for(5), palette.fallback)


func test_pul099_ac1_r10_medium_box_ticket_shows_icon_and_letter_before_recipe() -> void:
	var medium: BoxData = MEDIUM_BOX
	var entry: TicketEntry = ENTRY_SCENE.instantiate()
	add_child_autofree(entry)
	var data: OrderData = OrderData.new()
	data.recipe = RecipeData.new()
	data.recipe.display_name = "Pulpo"
	data.recipe.box = medium
	entry.setup(data)
	assert_eq((entry.get_node("%SizeLabel") as Label).text, "M")
	assert_eq((entry.get_node("%SizeIcon") as TextureRect).texture, medium.icon)
	assert_not_null(medium.icon)
	var badge: Node = entry.get_node("%SizeBadge")
	assert_eq(badge.get_parent(), entry.get_node("%Recipe").get_parent())
	assert_lt(badge.get_index(), entry.get_node("%Recipe").get_index(), "talla antes del nombre")
	assert_lt(entry.get_node("%SizeIcon").get_index(), entry.get_node("%SizeLabel").get_index())


func test_pul099_ticket_without_box_hides_size_but_keeps_recipe() -> void:
	var entry: TicketEntry = ENTRY_SCENE.instantiate()
	add_child_autofree(entry)
	var with_box: OrderData = OrderData.new()
	with_box.recipe = RecipeData.new()
	with_box.recipe.display_name = "Pulpo"
	with_box.recipe.box = MEDIUM_BOX
	entry.setup(with_box)
	assert_true((entry.get_node("%SizeBadge") as Control).visible)
	var without: OrderData = OrderData.new()
	without.recipe = RecipeData.new()
	without.recipe.display_name = "Sin caja"
	without.recipe.box = null
	entry.setup(without)
	assert_false((entry.get_node("%SizeBadge") as Control).visible)
	assert_eq((entry.get_node("%Recipe") as Label).text, "Sin caja")


func test_pul099_icon_carries_the_letter_text_only_as_fallback() -> void:
	var entry: TicketEntry = ENTRY_SCENE.instantiate()
	add_child_autofree(entry)
	var data: OrderData = OrderData.new()
	data.recipe = RecipeData.new()
	data.recipe.box = MEDIUM_BOX
	entry.setup(data)
	assert_false((entry.get_node("%SizeLabel") as Label).visible, "icono con letra")
	var plain: BoxData = BoxData.new()
	plain.short_label = "M"
	data.recipe.box = plain
	entry.setup(data)
	assert_true((entry.get_node("%SizeLabel") as Label).visible, "sin icono: letra")


func test_pul099_ticket_width_stays_212_for_longest_recipe_and_every_size() -> void:
	var names: Array[String] = ["Pulpo Individual", "Pulpo Familiar", "Combo Duo"]
	for recipe: RecipeData in _catalog_recipes():
		names.append(recipe.display_name)
	names.append("Pulpo á feira gigante de la romería de San Froilán")
	for size_name: String in ["small", "medium", "large"]:
		for display: String in names:
			var ticket: OrderTicket = load("res://ui/tickets/order_ticket.tscn").instantiate()
			ticket.set_bus(_bus)
			add_child_autofree(ticket)
			var data: OrderData = OrderData.new()
			data.recipe = RecipeData.new()
			data.recipe.display_name = display
			data.recipe.box = load("res://data/boxes/%s.tres" % size_name)
			data.seasonings = [HOT, SALT] as Array[SeasoningData]
			var order: ActiveOrder = ActiveOrder.new(1, data, 1, 0.0)
			ticket.setup(order)
			await wait_process_frames(1)
			assert_eq(ticket.size.x, 212.0, "%s / %s" % [size_name, display])


func _catalog_recipes() -> Array[RecipeData]:
	var out: Array[RecipeData] = []
	for order: OrderData in CATALOG.orders:
		if order.recipe != null and not out.has(order.recipe):
			out.append(order.recipe)
	return out


func test_pul099_every_live_ticket_size_matches_its_recipe_box() -> void:
	_mount()
	_fill()
	for order: ActiveOrder in _service.get_active_orders():
		var entry: TicketEntry = _ticket(order.id).get_node("%Entry")
		assert_eq((entry.get_node("%SizeLabel") as Label).text, order.data.recipe.box.short_label)
		assert_eq((entry.get_node("%SizeIcon") as TextureRect).texture, order.data.recipe.box.icon)


func test_pul099_ac2_r13_four_live_orders_stripe_is_stand_color() -> void:
	_mount()
	_fill()
	var palette: StandPalette = PALETTE
	var seen: Dictionary[int, bool] = {}
	for order: ActiveOrder in _service.get_active_orders():
		var stripe: ColorRect = _ticket(order.id).get_node("%Stripe")
		assert_eq(stripe.color, palette.color_for(order.slot_id), "slot %d" % order.slot_id)
		seen[order.slot_id] = true
	assert_eq(seen.size(), 4, "cuatro puestos distintos")
