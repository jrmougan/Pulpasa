extends GutTest
## PUL-129 (controles-tactiles AC14-AC17, ADR-005 E4): HUD y 4 tickets en la banda superior del
## perfil MOBILE, con texto >= 36 px a 1080, nombres sin recortar, fuera de las zonas del stick y
## de los botones y dentro de la safe area. Todo medido en px de pantalla (unidades por la
## escala de estiramiento de la ventana).

const HUD_SCENE: PackedScene = preload("res://ui/hud/hud.tscn")
const PANEL_SCENE: PackedScene = preload("res://ui/tickets/order_tickets_panel.tscn")
const BusScript: GDScript = preload("res://autoload/event_bus.gd")
const RECIPES: Array[OrderData] = [
	preload("res://data/orders/bravo_cachelos.tres"),
	preload("res://data/orders/picante.tres"),
	preload("res://data/orders/con_cachelos.tres"),
	preload("res://data/orders/a_feira.tres"),
]
const SAFE_LEFT: float = 132.0
const SAFE_BOTTOM: float = 63.0
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(2340, 1080), Vector2i(1920, 1080), Vector2i(1600, 720)
]

var _original_size: Vector2i
var _bus: Node
var _service: StubService
var _hud: RoundHUD
var _panel: OrderTicketsPanel


class StubService:
	extends Node

	func get_active_orders() -> Array[ActiveOrder]:
		return []


func before_each() -> void:
	_original_size = get_window().size
	GameState.set_platform(PlatformProfile.Kind.MOBILE)
	_bus = add_child_autofree(BusScript.new())
	_service = add_child_autofree(StubService.new())


func after_each() -> void:
	get_window().size = _original_size
	GameState.set_platform(PlatformProfile.Kind.DESKTOP)


## Monta HUD y panel con la safe area del diseño (o ninguna) y 4 comandas vivas.
func _mount(resolution: Vector2i, with_safe_area: bool) -> float:
	get_window().size = resolution
	await wait_process_frames(2)
	_hud = HUD_SCENE.instantiate()
	_hud.set_bus(_bus)
	_panel = PANEL_SCENE.instantiate()
	_panel.set_bus(_bus)
	_panel.set_service(_service)
	var window: Vector2 = Vector2(resolution)
	var safe: Rect2 = Rect2(Vector2.ZERO, window)
	if with_safe_area:
		safe = Rect2(SAFE_LEFT, 0.0, window.x - 2.0 * SAFE_LEFT, window.y - SAFE_BOTTOM)
	_hud.set_safe_rect(safe, window)
	_panel.set_safe_rect(safe, window)
	add_child_autofree(_hud)
	add_child_autofree(_panel)
	for i: int in RECIPES.size():
		var order: ActiveOrder = ActiveOrder.new(i + 1, RECIPES[i], i + 1, 60.0)
		_bus.order_generated.emit(order)
		_bus.order_patience_changed.emit(order.id, 45.0, 60.0)
	_bus.round_started.emit(180.0)
	_bus.score_changed.emit(2, 1234)
	await wait_process_frames(3)
	return get_viewport().get_final_transform().get_scale().y


func _unmount() -> void:
	_hud.queue_free()
	_panel.queue_free()
	await wait_process_frames(2)


func _tickets() -> Array[OrderTicket]:
	var tickets: Array[OrderTicket] = []
	for node: Node in _panel.get_node("%Tickets").get_children():
		tickets.append(node as OrderTicket)
	return tickets


func _blocks() -> Array[Control]:
	var blocks: Array[Control] = [_hud.get_node("%Background")]
	for ticket: OrderTicket in _tickets():
		blocks.append(ticket)
	return blocks


## Rectángulo en px de pantalla de un control (unidades de lienzo por el estiramiento).
func _px(control: Control, stretch: float) -> Rect2:
	var rect: Rect2 = control.get_global_rect()
	return Rect2(rect.position * stretch, rect.size * stretch)


func _visible_texts(root: Node) -> Array[Control]:
	var found: Array[Control] = []
	for node: Node in root.find_children("*", "Control", true, false):
		var control: Control = node as Control
		if control.is_visible_in_tree() and TextFloor.font_size_of(control) > 0:
			found.append(control)
	return found


func _text_width(label: Label) -> float:
	var font: Font = label.get_theme_font(&"font")
	var size: int = label.get_theme_font_size(&"font_size")
	return font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


func _assert_text_floor(stretch: float, minimum_px: float) -> void:
	var checked: int = 0
	for node: Control in _visible_texts(_hud) + _visible_texts(_panel):
		var size_px: float = TextFloor.font_size_of(node) * stretch
		assert_gte(size_px, minimum_px - 0.01, "%s: %.1f px" % [node.get_path(), size_px])
		checked += 1
	assert_gt(checked, 10, "se comprobaron los textos de HUD y tickets")


func test_ac15_four_tickets_fit_the_band_at_2340x1080() -> void:
	var stretch: float = await _mount(Vector2i(2340, 1080), true)
	var tickets: Array[OrderTicket] = _tickets()
	assert_eq(tickets.size(), 4)
	var previous: Rect2 = Rect2()
	for i: int in tickets.size():
		var rect: Rect2 = _px(tickets[i], stretch)
		assert_between(rect.size.x, 329.5, 380.5, "ancho del ticket %d: %s" % [i, rect.size.x])
		assert_lte(rect.size.y, 150.5, "alto del ticket %d" % i)
		if i > 0:
			assert_almost_eq(rect.position.x - previous.end.x, 16.0, 1.0, "separación %d" % i)
		previous = rect


func test_ac15_ticket_width_is_342_at_1920x1080_without_safe_area() -> void:
	var stretch: float = await _mount(Vector2i(1920, 1080), false)
	for ticket: OrderTicket in _tickets():
		assert_almost_eq(_px(ticket, stretch).size.x, 342.0, 1.5)


func test_ac15_recipe_names_are_not_clipped_including_bravo_cachelos() -> void:
	for resolution: Vector2i in RESOLUTIONS:
		var stretch: float = await _mount(resolution, resolution.x == 2340)
		for ticket: OrderTicket in _tickets():
			var recipe: Label = ticket.get_node("%Entry/%Recipe")
			var where: String = "%s a %s" % [recipe.text, resolution]
			assert_false(recipe.text.contains("…"), where)
			assert_lte(_text_width(recipe), recipe.size.x + 0.5, where)
			var content: Control = ticket.get_node("Content")
			assert_lte(content.get_combined_minimum_size().x, content.size.x + 0.5, where)
			assert_lte(_px(ticket, stretch).size.y, 150.0 * resolution.y / 1080.0 + 0.5, where)
		await _unmount()


func test_ac15_hud_tickets_and_pause_do_not_overlap_and_band_is_at_most_200_px() -> void:
	var stretch: float = await _mount(Vector2i(2340, 1080), true)
	var hud: Rect2 = _px(_hud.get_node("%Background"), stretch)
	assert_almost_eq(hud.position.x, 180.0, 2.0, "HUD en (180, 24)")
	assert_almost_eq(hud.position.y, 24.0, 2.0)
	assert_lte(hud.size.x, 240.5, "bloque de 240 px")
	assert_lte(hud.size.y, 150.5, "bloque de 150 px")
	var tickets: Array[OrderTicket] = _tickets()
	var first: Rect2 = _px(tickets[0], stretch)
	var last: Rect2 = _px(tickets[3], stretch)
	assert_gte(first.position.x - hud.end.x, 23.0, "hueco HUD-tickets")
	var side: float = TouchHudLayout.pause_button_px()
	var edge: float = TouchHudLayout.edge_margin_px()
	var pause: Rect2 = Rect2(2340.0 - SAFE_LEFT - edge - side, edge, side, side)
	assert_eq(pause, Rect2(2040.0, 48.0, 120.0, 120.0), "pausa del diseño")
	assert_gte(pause.position.x - last.end.x, 23.0, "hueco tickets-pausa")
	assert_lte(maxf(hud.end.y, last.end.y), 200.0, "banda superior")


func test_ac16_hud_and_tickets_stay_out_of_the_reserved_zones() -> void:
	for resolution: Vector2i in RESOLUTIONS:
		var stretch: float = await _mount(resolution, resolution.x == 2340)
		var profile: UiProfile = GameState.ui_profile
		var factor: float = resolution.y / 1080.0
		var size: Vector2 = Vector2(resolution)
		var stick: Rect2 = Rect2(
			0.0, profile.stick_zone_top_px * factor, size.x * profile.stick_zone_fraction, size.y
		)
		var buttons: Rect2 = Rect2(
			size.x - profile.button_zone_width_px * factor,
			profile.button_zone_top_px * factor,
			size.x,
			size.y
		)
		for control: Control in _blocks():
			var rect: Rect2 = _px(control, stretch)
			var where: String = "%s a %s" % [control.name, resolution]
			assert_false(rect.intersects(stick), "%s toca el stick" % where)
			assert_false(rect.intersects(buttons), "%s toca los botones" % where)
		await _unmount()


func test_ac17_everything_stays_inside_the_safe_area() -> void:
	var stretch: float = await _mount(Vector2i(2340, 1080), true)
	var safe: Rect2 = Rect2(SAFE_LEFT, 0.0, 2340.0 - 2.0 * SAFE_LEFT, 1080.0 - SAFE_BOTTOM)
	for control: Control in _blocks():
		assert_true(safe.encloses(_px(control, stretch)), "%s fuera" % control.name)
	for node: Control in _visible_texts(_hud) + _visible_texts(_panel):
		assert_true(safe.encloses(_px(node, stretch).grow(-0.5)), "%s fuera" % node.get_path())


func test_ac17_without_safe_area_the_layout_anchors_to_the_edges_with_48_px() -> void:
	var stretch: float = await _mount(Vector2i(1920, 1080), false)
	var hud: Rect2 = _px(_hud.get_node("%Background"), stretch)
	assert_almost_eq(hud.position.x, 48.0, 2.0)
	assert_almost_eq(hud.position.y, 24.0, 2.0)
	assert_almost_eq(_px(_tickets()[0], stretch).position.x, 312.0, 2.0)


func test_ac14_every_visible_text_is_at_least_36_px_at_2340x1080() -> void:
	var stretch: float = await _mount(Vector2i(2340, 1080), true)
	_assert_text_floor(stretch, 36.0)


func test_ac14_every_visible_text_is_at_least_24_px_at_1600x720() -> void:
	var stretch: float = await _mount(Vector2i(1600, 720), false)
	_assert_text_floor(stretch, 24.0)


func test_hud_shows_only_revenue_then_time_without_boxes_per_minute() -> void:
	var stretch: float = await _mount(Vector2i(2340, 1080), true)
	var texts: PackedStringArray = []
	for node: Control in _visible_texts(_hud):
		texts.append((node as Label).text)
	assert_eq(texts, PackedStringArray(["1234 €", "180.0s"]))
	assert_lte(_px(_hud.get_node("%Background"), stretch).size.y, 150.5)
	var revenue: Control = _hud.get_node("%Revenue")
	var time: Control = _hud.get_node("%TimeLeft")
	assert_lt(revenue.global_position.y, time.global_position.y, "recaudación arriba, tiempo abajo")


func test_ticket_icons_use_the_seasoning_icon_at_48_px() -> void:
	var stretch: float = await _mount(Vector2i(2340, 1080), true)
	var checked: int = 0
	var tickets: Array[OrderTicket] = _tickets()
	for i: int in tickets.size():
		var entry: TicketEntry = tickets[i].get_node("%Entry")
		var stickers: Array[Node] = entry.get_node("%SeasoningIcons").get_children()
		var seasonings: Array[SeasoningData] = SeasoningRules.canonical_order(RECIPES[i].seasonings)
		assert_eq(stickers.size(), seasonings.size(), "una pegatina por aliño")
		for k: int in stickers.size():
			var icon: TextureRect = stickers[k].get_node("Icon")
			assert_eq(icon.texture, seasonings[k].icon, "icono de %s" % seasonings[k].display_name)
			assert_almost_eq(_px(stickers[k] as Control, stretch).size.x, 48.0, 1.0)
			checked += 1
	assert_gt(checked, 0)


func test_ticket_clock_id_and_patience_bar_are_visible_and_12_px_thick() -> void:
	var stretch: float = await _mount(Vector2i(2340, 1080), true)
	for ticket: OrderTicket in _tickets():
		var bar: Control = ticket.get_node("%PatienceBar")
		assert_true(bar.is_visible_in_tree())
		assert_gte(_px(bar, stretch).size.y, 11.5, "barra de 12 px")
		assert_true((ticket.get_node("%Clock") as Label).is_visible_in_tree())
		assert_true((ticket.get_node("%OrderId") as Label).is_visible_in_tree())


func test_layout_follows_a_window_resize() -> void:
	var stretch: float = await _mount(Vector2i(2340, 1080), true)
	assert_almost_eq(_px(_tickets()[0], stretch).size.x, 380.0, 1.5)
	get_window().size = Vector2i(1920, 1080)
	await wait_process_frames(3)
	var flat: Rect2 = Rect2(0, 0, 1920, 1080)
	_panel.set_safe_rect(flat, Vector2(1920, 1080))
	_hud.set_safe_rect(flat, Vector2(1920, 1080))
	await wait_process_frames(3)
	var after: float = get_viewport().get_final_transform().get_scale().y
	assert_almost_eq(_px(_tickets()[0], after).size.x, 342.0, 1.5)
