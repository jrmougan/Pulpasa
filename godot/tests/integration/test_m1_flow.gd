extends GutTest
## PUL-032: partida M1 completa sobre `level_01.tscn` con los datos reales y los autoloads reales.
## Una comanda con aceite y cachelos (D10): pulpo y cachelos cuecen juntos en la olla (D9), la caja
## se llena sobre la bandeja de la estación, los cachelos cocidos van al cuenco y la caja se
## condimenta en el dispensador de aceite y el cuenco (PUL-061), y se entrega con bonus por tiempo
## (D2). Después una caducidad (−expire_penalty), una caja errónea
## (−wrong_delivery_penalty, D8) y el fin de ronda: recaudación y estrellas en el game over.
##
## Usa la comanda del catálogo real con aceite y cachelos (PUL-033) y `max_active_orders = 1`.
## Como en `test_kitchen_flow.gd`, cada pulsación pasa por `InteractionComponent.interact_pressed()`
## con el objetivo que publicaría el detector (`target_changed`).

const LEVEL: PackedScene = preload("res://scenes/levels/level_01.tscn")
const RECIPE: RecipeData = preload("res://data/recipes/individual.tres")
const OIL: SeasoningData = preload("res://data/seasonings/oil.tres")
const CACHELOS_SEASONING: SeasoningData = preload("res://data/seasonings/cachelos.tres")
const STAR_FULL: Texture2D = preload("res://assets/textures/icons/star_full.svg")
const STAR_EMPTY: Texture2D = preload("res://assets/textures/icons/star_empty.svg")
const COOK_STEP: float = 0.1
## Margen sobre `cook_time` al avanzar la olla a mano.
const COOK_MARGIN: float = 0.5

var _level: Node
var _player: Player
var _actor: InteractionComponent
var _detector: Node
var _hold: Holder
var _config: RoundConfig
var _order_data: OrderData
## Recaudación que debe llevar `RoundState` según los datos.
var _expected_revenue: int = 0


func before_each() -> void:
	PhaselessConfig.disable()
	watch_signals(EventBus)
	_order_data = _real_cachelos_order()
	var catalog: OrderCatalog = OrderCatalog.new()
	catalog.orders = [_order_data] as Array[OrderData]
	catalog.max_active_orders = 1
	_level = LEVEL.instantiate()
	_level.set("order_catalog", catalog)
	add_child_autofree(_level)
	_config = _level.get("round_config")
	_player = _level.get_node("Characters/Player1")
	_actor = _player.get_node("%InteractionComponent")
	_detector = _player.get_node("%InteractionDetector")
	_hold = _player.get_node("%HoldComponent")
	await wait_physics_frames(2)
	_expected_revenue = 0
	# first_order_delay (dato): hasta entonces no hay comandas.
	RoundManager.round_state.advance(_config.first_order_delay)


func after_each() -> void:
	GameState.set_paused(false)
	PhaselessConfig.restore()


func _real_cachelos_order() -> OrderData:
	var real: OrderCatalog = load("res://data/orders/order_catalog.tres") as OrderCatalog
	for order: OrderData in real.orders:
		if order.seasonings.has(OIL) and order.seasonings.has(CACHELOS_SEASONING):
			return order
	return null


func _press(target: Node) -> bool:
	_detector.emit_signal(&"target_changed", null, target)
	return _actor.interact_pressed()


func _station(path: String) -> Node:
	return _level.get_node("Stations/%s" % path)


func _small_box_spawner() -> ItemSpawner:
	for child: Node in _station("BoxShelf").get_children():
		if child is ItemSpawner and (child as ItemSpawner).data == RECIPE.box:
			return child
	return null


func _seasoning_station() -> SeasoningStation:
	return _station("SeasoningStation") as SeasoningStation


func _dispenser(seasoning: SeasoningData) -> SeasoningDispenser:
	for child: Node in _seasoning_station().get_node("Dispensers").get_children():
		if (child as SeasoningDispenser).seasoning == seasoning:
			return child as SeasoningDispenser
	return null


func _is_released(node: Variant) -> bool:
	return not is_instance_valid(node) or (node as Node).is_queued_for_deletion()


func _bonus(order: ActiveOrder) -> int:
	return floori((order.time_left / order.max_time) * _config.time_bonus_max)


## Nevera y cachelera → olla (dos plazas), la caja de la comanda a la bandeja, cocción, FIFO,
## cortes sobre la bandeja hasta llenar, cachelos cocidos al cuenco y, en la estación, cachelos y
## aceite. Devuelve la caja lista para entregar.
func _prepare_box() -> Box:
	var kitchen: CookingStation = _station("Kitchen")
	assert_true(_press(_station("OctopusStorage")), "nevera: da un pulpo")
	var octopus: Ingredient = _hold.get_held_item() as Ingredient
	assert_true(_press(kitchen), "olla: pulpo crudo")
	assert_true(_press(_station("CachelosStorage")), "cachelera: da cachelos")
	var cachelos: Ingredient = _hold.get_held_item() as Ingredient
	assert_not_null(cachelos)
	assert_eq(cachelos.data.type, IngredientData.IngredientType.CACHELOS)
	assert_true(_press(kitchen), "olla: cachelos crudos junto al pulpo")
	assert_null(_hold.get_held_item())

	# Mientras cuecen: la caja de la comanda, a la bandeja de la estación.
	var spawner: ItemSpawner = _small_box_spawner()
	assert_not_null(spawner)
	assert_true(_press(spawner), "estantería: da la caja")
	var box: Box = _hold.get_held_item() as Box
	assert_eq(box.data, RECIPE.box)
	var station: SeasoningStation = _seasoning_station()
	assert_true(_press(station.get_tray()), "bandeja: guarda la caja")
	assert_eq(station.get_box(), box)

	simulate(kitchen, roundi((octopus.data.cook_time + COOK_MARGIN) / COOK_STEP), COOK_STEP)
	assert_true(octopus.is_cooked(), "pulpo cocido")
	assert_true(cachelos.is_cooked(), "cachelos cocidos")
	assert_true(_press(kitchen), "olla: devuelve primero lo que terminó antes")
	assert_eq(_hold.get_held_item(), octopus, "FIFO: el pulpo (plaza 0) terminó primero")
	var presses: int = 0
	while not box.is_full() and presses < 100:
		assert_true(_press(box))
		presses += 1
	assert_true(box.is_full(), "caja llena tras %d cortes" % presses)
	if not _is_released(octopus):
		_press(null)
	assert_null(_hold.get_held_item())

	assert_true(_press(kitchen), "olla: devuelve los cachelos cocidos")
	assert_eq(_hold.get_held_item(), cachelos)
	var bowl: CachelosBowl = station.get_node("CachelosBowl")
	assert_true(_press(bowl), "cachelos cocidos al cuenco")
	assert_true(_is_released(cachelos), "los cachelos se consumen")
	assert_eq(bowl.stock, 1)
	assert_true(_press(bowl), "cuenco: cachelos a la caja")
	assert_true(box.has_seasoning(CACHELOS_SEASONING), "cachelos aplicados como condimento")
	assert_eq(bowl.stock, 0)
	assert_true(_press(_dispenser(OIL)), "dispensador de aceite")
	assert_true(box.has_seasoning(OIL))
	assert_null(_hold.get_held_item())
	assert_eq(box.get_contents().seasonings.size(), 2)
	return box


## Entrega directa de una caja correcta por `OrderService` (sin recorrer la cocina).
func _deliver_directly() -> void:
	var order: ActiveOrder = OrderService.get_active_orders()[0]
	var contents: BoxContents = BoxContents.new(
		RECIPE.box,
		RECIPE.ingredient,
		IngredientData.CookingState.COOKED,
		1.0,
		_order_data.seasonings.duplicate()
	)
	_expected_revenue += RECIPE.base_points + _bonus(order)
	assert_not_null(OrderService.try_deliver(order.slot_id, contents))
	assert_eq(RoundManager.round_state.get_revenue(), _expected_revenue)


func test_m1_full_round_oil_cachelos_bonus_expiry_wrong_box_and_stars() -> void:
	var order: ActiveOrder = OrderService.get_active_orders()[0]
	assert_eq(order.slot_id, 1)
	assert_eq(order.data.seasonings.size(), 2, "comanda con aceite y cachelos")

	# --- Entrega con bonus por tiempo -------------------------------------------------------
	var box: Box = await _prepare_box()
	assert_true(_press(box), "coge la caja")
	assert_eq(_hold.get_held_item(), box)
	RoundManager.round_state.advance(6.0)
	var live: ActiveOrder = OrderService.get_active_orders()[0]
	assert_eq(live.id, order.id)
	var bonus: int = _bonus(live)
	assert_gt(bonus, 0, "entrega rápida: bonus por tiempo")
	assert_lt(bonus, _config.time_bonus_max, "con 6 s gastados no es el bonus máximo")
	_expected_revenue = RECIPE.base_points + bonus
	assert_true(_press(_station("OrderStand1")), "puesto 1: entrega")
	assert_signal_emit_count(EventBus, "order_completed", 1)
	assert_signal_not_emitted(EventBus, "delivery_rejected")
	assert_eq(RoundManager.round_state.get_revenue(), _expected_revenue, "base + bonus")
	assert_eq(RoundManager.round_state.get_boxes_delivered(), 1)
	assert_true(_is_released(box), "la caja entregada se libera")
	assert_ne(OrderService.get_active_orders()[0].id, order.id, "el puesto repone la comanda")

	# --- Más entregas hasta la primera estrella ---------------------------------------------
	while _expected_revenue < _config.revenue_thresholds[0]:
		_deliver_directly()

	# --- Caducidad: resta expire_penalty ------------------------------------------------------
	var before_expiry: int = RoundManager.round_state.get_revenue()
	RoundManager.round_state.advance(_order_data.max_time + 1.0)
	assert_signal_emit_count(EventBus, "order_expired", 1)
	_expected_revenue = before_expiry - _config.expire_penalty
	assert_eq(RoundManager.round_state.get_revenue(), _expected_revenue, "caducidad −3")
	assert_eq(_config.expire_penalty, 3, "dato de M1")
	await wait_physics_frames(2)

	# --- Caja errónea: resta wrong_delivery_penalty ---------------------------------------------
	assert_true(_press(_small_box_spawner()))
	var wrong: Box = _hold.get_held_item() as Box
	assert_true(_press(_station("OrderStand1")), "consume la pulsación aunque rechace")
	assert_signal_emit_count(EventBus, "delivery_rejected", 1)
	var rejected: Array = get_signal_parameters(EventBus, "delivery_rejected", 0)
	assert_eq(rejected[2], _config.wrong_delivery_penalty)
	assert_eq(_config.wrong_delivery_penalty, 2, "dato de M1")
	_expected_revenue -= _config.wrong_delivery_penalty
	assert_eq(RoundManager.round_state.get_revenue(), _expected_revenue, "caja errónea −2")
	assert_eq(_hold.get_held_item(), wrong, "la caja errónea se queda en la mano")
	assert_signal_emit_count(EventBus, "order_completed", 1 + _extra_deliveries())

	# --- Fin de ronda: recaudación y estrellas en el game over --------------------------------
	var game_over: GameOver = _level.get_node("UI/GameOver")
	assert_false(game_over.visible)
	# El salto final caduca la comanda viva del puesto: también resta expire_penalty.
	var expiries_before: int = get_signal_emit_count(EventBus, "order_expired")
	RoundManager.round_state.advance(_config.duration)
	assert_signal_emit_count(EventBus, "round_finished", 1)
	var final_expiries: int = get_signal_emit_count(EventBus, "order_expired") - expiries_before
	_expected_revenue = maxi(0, _expected_revenue - _config.expire_penalty * final_expiries)
	var result: RoundResult = RoundManager.round_state.get_result()
	assert_eq(result.revenue, _expected_revenue)
	var stars: int = 0
	for threshold: int in _config.revenue_thresholds:
		if _expected_revenue >= threshold:
			stars += 1
	assert_eq(result.stars, stars)
	assert_gt(result.stars, 0, "la partida alcanza al menos una estrella")
	assert_true(game_over.visible, "game over visible")
	assert_string_contains((game_over.get_node("%Revenue") as Label).text, str(_expected_revenue))
	var star_nodes: Array[Node] = game_over.get_node("%Stars").get_children()
	for i: int in star_nodes.size():
		var expected: Texture2D = STAR_FULL if i < result.stars else STAR_EMPTY
		assert_eq((star_nodes[i] as TextureRect).texture, expected, "estrella %d" % (i + 1))


func _extra_deliveries() -> int:
	return RoundManager.round_state.get_boxes_delivered() - 1
