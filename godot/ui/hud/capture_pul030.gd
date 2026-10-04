extends Control
## PUL-030: capturas de evidencia (AC2) de HUD, ticket con iconos y game over con estrellas.
## Uso: xvfb-run -a godot --path godot res://ui/hud/capture_pul030.tscn

const CATALOG: OrderCatalog = preload("res://data/orders/order_catalog.tres")
const CONFIG: RoundConfig = preload("res://data/config/round_config.tres")
const HUD_SCENE: PackedScene = preload("res://ui/hud/hud.tscn")
const PANEL_SCENE: PackedScene = preload("res://ui/tickets/order_tickets_panel.tscn")
const GAME_OVER_SCENE: PackedScene = preload("res://ui/menus/game_over.tscn")

var _out_dir: String = ProjectSettings.globalize_path("res://../docs/evidence/PUL-030")


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var hud: RoundHUD = HUD_SCENE.instantiate()
	add_child(hud)
	var panel: OrderTicketsPanel = PANEL_SCENE.instantiate()
	add_child(panel)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20
	OrderService.setup(CATALOG, rng)
	RoundManager.start_round(CONFIG, [1, 2, 3, 4] as Array[int])
	# Las comandas iniciales llegan tras first_order_delay (5 s de reloj de ronda).
	var waited: int = 0
	while OrderService.get_active_orders().is_empty() and waited < 600:
		await get_tree().process_frame
		waited += 1
	if OrderService.get_active_orders().is_empty():
		push_error("no se generaron comandas")
		get_tree().quit(1)
		return
	await _frames(5)

	# Paciencia consumida y una entrega correcta: barra decreciente y recaudación > 0.
	OrderService.board.advance(15.0)
	var order: ActiveOrder = OrderService.get_active_orders()[0]
	var contents: BoxContents = BoxContents.new(
		order.data.recipe.box,
		order.data.recipe.ingredient,
		IngredientData.CookingState.COOKED,
		1.0,
		order.data.seasonings
	)
	OrderService.try_deliver(order.slot_id, contents)
	await _frames(10)

	_shot(Rect2i(), "partida_hud_y_tickets.png")
	_shot(Rect2i(hud.get_global_rect()).grow(6), "hud_recaudacion.png")
	var ticket: OrderTicket = panel.get_node("%Tickets").get_child(0)
	_shot(Rect2i(ticket.get_global_rect()).grow(6), "ticket_iconos_y_paciencia.png")

	var over: GameOver = GAME_OVER_SCENE.instantiate()
	add_child(over)
	EventBus.round_finished.emit(
		RoundResult.new(
			CONFIG.duration,
			8,
			65,
			CONFIG.performance_thresholds,
			CONFIG.performance_texts,
			CONFIG.revenue_thresholds
		)
	)
	await _frames(10)
	_shot(Rect2i(), "game_over_estrellas.png")
	print("capturas en %s" % _out_dir)
	get_tree().quit()


func _frames(count: int) -> void:
	for i: int in range(count):
		await get_tree().process_frame


func _shot(region: Rect2i, file_name: String) -> void:
	var image: Image = get_viewport().get_texture().get_image()
	if region.has_area():
		region = region.intersection(Rect2i(Vector2i(), image.get_size()))
		image = image.get_region(region)
	var err: Error = image.save_png(_out_dir.path_join(file_name))
	if err != OK:
		push_error("save_png %s: %s" % [file_name, error_string(err)])
		get_tree().quit(1)
