extends GutTest
## PUL-062: regresión de la estación de condimentos en la planta B (`level_01.tscn` real), una
## partida por modo con tres entregas seguidas y el flujo completo: nevera → olla → cachelos al
## cuenco y cortes sobre la caja de un pasaplatos por el lado de pase → la caja a la mano →
## dispensadores y cuenco por el lado de condimentar → entrega. Todo con el teclado y el detector
## reales (`level_walker.gd`): el
## test nunca llama a `interact()` ni publica `target_changed`.
## - SINGLE: J1 lleva al cocinero (Player2, cocina) y al servidor (Player1, servicio) y cambia con
##   Q; ningún personaje cruza la barra.
## - COOP_2P: J2 (flechas + Intro) cocina y J1 (WASD + E) condimenta y entrega.
## En los dos: cero rechazos de la estación y del puesto, ninguna comanda caducada y el pimentón
## se intercambia en la propia estación (se pulsa primero el otro, D18 `paprika_swap`).

const LEVEL: PackedScene = preload("res://scenes/levels/level_01.tscn")
const Walker: GDScript = preload("res://tests/integration/level_walker.gd")
## Comandas de caja pequeña del catálogo real: dulce+sal, aceite+dulce, picante+cachelos y
## aceite+cachelos. Un pulpo da 15 cortes y una caja pequeña lleva 5.
const ORDERS: Array[OrderData] = [
	preload("res://data/orders/order_2.tres"),
	preload("res://data/orders/order_4.tres"),
	preload("res://data/orders/order_5.tres"),
	preload("res://data/orders/order_6.tres"),
]
const PAPRIKA: SeasoningData = preload("res://data/seasonings/paprika.tres")
const HOT_PAPRIKA: SeasoningData = preload("res://data/seasonings/hot_paprika.tres")
const CACHELOS: SeasoningData = preload("res://data/seasonings/cachelos.tres")
## Entregas por partida (AC1 de la ficha).
const DELIVERIES: int = 3
## Paciencia de las comandas del test: el flujo dura más que los 80–150 s del catálogo con las
## esperas de cocción reales y no se mide aquí.
const PATIENCE: float = 900.0
## Distancia en z desde el centro de una estación del mostrador trasero al punto de uso (m).
const BACK_ACCESS: float = 0.9
## Distancia en x desde una plaza de la estantería de cajas al punto de uso (m).
const SHELF_ACCESS: float = 0.9
## Distancia al puesto desde la que se le pulsa interactuar, fuera de su `%DeliveryZone` (m).
const STAND_FRONT: float = 2.5
## Margen sobre `cook_time` para la espera de la cocción (s).
const COOK_MARGIN: float = 3.0
## Espera tras cambiar de personaje (> `switch_cooldown` de `input_config.tres`).
const SWITCH_WAIT: float = 0.3

var _level: Node
var _station: SeasoningStation
var _mode: GameMode.Mode = GameMode.Mode.SINGLE
## Rechazos de los dispensadores y del cuenco (pulsaciones de error).
var _rejections: Array[String] = []
## Lados de la barra (−1 cocina, +1 servicio) por los que ha pasado cada personaje.
var _sides: Dictionary[String, Dictionary] = {}


func before_each() -> void:
	PhaselessConfig.disable()
	GameState.set_paused(false)
	watch_signals(EventBus)
	_rejections.clear()
	_sides.clear()


func after_each() -> void:
	if get_tree().physics_frame.is_connected(_track_sides):
		get_tree().physics_frame.disconnect(_track_sides)
	for keycode: Key in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = keycode
		Input.parse_input_event(event)
	Input.flush_buffered_events()
	GameState.set_paused(false)
	GameState.reset_input()
	PhaselessConfig.restore()


## Nivel real con una comanda activa a la vez, sacada de `ORDERS` sin caducidad práctica.
func _load_level(mode: GameMode.Mode) -> void:
	_mode = mode
	var catalog: OrderCatalog = OrderCatalog.new()
	var orders: Array[OrderData] = []
	for order: OrderData in ORDERS:
		var copy: OrderData = order.duplicate() as OrderData
		copy.max_time = PATIENCE
		orders.append(copy)
	catalog.orders = orders
	catalog.max_active_orders = 1
	_level = LEVEL.instantiate()
	_level.set("order_catalog", catalog)
	(_level.get_node("CharacterSwitcher") as CharacterSwitcher).set_mode(mode)
	add_child_autofree(_level)
	_station = _level.get_node("Stations/SeasoningStation")
	for dispenser: Node in _station.get_node("Dispensers").get_children():
		dispenser.connect(&"rejected", _on_rejected.bind(dispenser.name))
	_station.get_node("CachelosBowl").connect(&"rejected", _on_rejected.bind(&"CachelosBowl"))
	await wait_physics_frames(2)
	var config: RoundConfig = _level.get("round_config")
	RoundManager.round_state.advance(config.first_order_delay)
	assert_eq(OrderService.get_active_orders().size(), 1)
	get_tree().physics_frame.connect(_track_sides)


func _on_rejected(reason: SeasoningRules.Rejection, part: StringName) -> void:
	_rejections.append("%s:%d" % [part, reason])


func _track_sides() -> void:
	for index: int in [1, 2]:
		var key: String = "Player%d" % index
		if not _sides.has(key):
			_sides[key] = {}
		_sides[key][Walker.side_of(Walker.xz(_character(index).global_position))] = true


func _character(index: int) -> Player:
	return _level.get_node("Characters/Player%d" % index) as Player


func _stations(path: String) -> Node3D:
	return _level.get_node("Stations/" + path) as Node3D


func _xz(node: Node3D) -> Vector2:
	return Walker.xz(node.global_position)


func _active_order() -> ActiveOrder:
	var active: Array[ActiveOrder] = OrderService.get_active_orders()
	assert_eq(active.size(), 1, "una comanda activa")
	return active[0]


func _held(walker: Walker) -> Node:
	return walker.holder().get_held_item()


func _bowl() -> CachelosBowl:
	return _station.get_node("CachelosBowl") as CachelosBowl


func _dispenser(seasoning: SeasoningData) -> SeasoningDispenser:
	for child: Node in _station.get_node("Dispensers").get_children():
		if (child as SeasoningDispenser).seasoning.same_as(seasoning):
			return child as SeasoningDispenser
	return null


## Estación del mostrador trasero (nevera, cachelera, ollas), usada de frente desde la cocina.
func _use_back(walker: Walker, path: String) -> Node:
	var at: Vector2 = _xz(_stations(path))
	return await walker.use(at, at + Vector2(0.0, BACK_ACCESS))


## Pieza de la estación de condimentos usada de frente por un lado (−1 pase, +1 condimentar).
func _use_station(walker: Walker, part: Node3D, side: float) -> Node:
	var at: Vector2 = _xz(part)
	return await walker.use(at, Walker.station_stand(at, _station.global_position.z, side))


# --- Cocina (lado de pase) -----------------------------------------------------------------------


## Nevera → olla `pot`; devuelve el pulpo crudo que se está cociendo.
func _start_octopus(cook: Walker, pot: String) -> Ingredient:
	assert_eq(await _use_back(cook, "OctopusStorage"), _stations("OctopusStorage"), "nevera")
	var octopus: Ingredient = _held(cook) as Ingredient
	assert_not_null(octopus, "pulpo en la mano")
	assert_eq(await _use_back(cook, pot), _stations(pot), pot)
	assert_null(_held(cook), "pulpo en la olla")
	return octopus


## Cachelera → olla `pot`; devuelve los cachelos crudos que se están cociendo.
func _start_cachelos(cook: Walker, pot: String) -> Ingredient:
	assert_eq(await _use_back(cook, "CachelosStorage"), _stations("CachelosStorage"), "cachelera")
	var cachelos: Ingredient = _held(cook) as Ingredient
	assert_not_null(cachelos, "cachelos en la mano")
	assert_eq(await _use_back(cook, pot), _stations(pot), pot)
	assert_null(_held(cook), "cachelos en la olla")
	return cachelos


## Espera a que `item` esté cocido y lo saca de la olla `pot` (FIFO: debe ser el primero).
func _collect(cook: Walker, pot: String, item: Ingredient) -> void:
	var cooked: Callable = func() -> bool: return item.is_cooked()
	assert_true(await wait_until(cooked, item.data.cook_time + COOK_MARGIN), "cocido")
	assert_eq(await _use_back(cook, pot), _stations(pot), pot)
	assert_eq(_held(cook), item, "sale de la olla")


## Pone la cocina en marcha al empezar: un pulpo y cuatro raciones de cachelos al cuenco por el pase
## (dos cachelos de 2 raciones, el máximo `cachelos_stock_max`), y deja el pulpo cocido en la mano
## del cocinero.
func _prepare_kitchen(cook: Walker) -> void:
	var first: Ingredient = await _start_cachelos(cook, "Kitchen")
	var octopus: Ingredient = await _start_octopus(cook, "Kitchen")
	var second: Ingredient = await _start_cachelos(cook, "Kitchen2")
	for pair: Array in [[first, "Kitchen"], [second, "Kitchen2"]]:
		await _collect(cook, pair[1], pair[0])
		var stock: int = _bowl().stock
		assert_eq(await _use_station(cook, _bowl(), -1.0), _bowl(), "cuenco por el pase")
		assert_eq(_bowl().stock, stock + 2, "dos raciones más")
		assert_null(_held(cook))
	await _collect(cook, "Kitchen", octopus)


## Pasaplatos de la barra en que se deja la caja a medio hacer (visible desde los dos lados).
func _pass_slot() -> Slot:
	return _stations("PassSlot05") as Slot


## Corta sobre la caja del pasaplatos desde el pase hasta llenarla; si se acaba el pulpo, cuece
## otro. El sobrante se queda en la mano para la caja siguiente.
func _fill_box(cook: Walker, box: Box) -> void:
	var slot: Vector2 = _xz(_pass_slot())
	var stand: Vector2 = Walker.station_stand(slot, _station.global_position.z, -1.0)
	var guard: int = 0
	while not box.is_full() and guard < 40:
		guard += 1
		if not (_held(cook) is Ingredient):
			var octopus: Ingredient = await _start_octopus(cook, "Kitchen")
			await _collect(cook, "Kitchen", octopus)
		await cook.walk_to(stand)
		await cook.face(slot)
		assert_eq(cook.detector().get_target(), box, "de cara a la caja del pasaplatos")
		await cook.tap_interact()
	assert_true(box.is_full(), "caja llena por el pase")


# --- Servicio (lado de condimentar) --------------------------------------------------------------


## Estantería → caja de la comanda al pasaplatos por el lado de condimentar.
func _box_to_slot(server: Walker, order: ActiveOrder) -> Box:
	var spawner: Node3D = null
	for child: Node in _stations("BoxShelf").get_children():
		if child is ItemSpawner and (child as ItemSpawner).data == order.data.recipe.box:
			spawner = child as Node3D
	assert_not_null(spawner, "plaza de la caja de la comanda")
	var at: Vector2 = _xz(spawner)
	assert_eq(await server.use(at, at + Vector2(SHELF_ACCESS, 0.0)), spawner, "estantería")
	var box: Box = _held(server) as Box
	assert_not_null(box, "caja en la mano")
	var slot: Slot = _pass_slot()
	assert_eq(await _use_station(server, slot, 1.0), slot, "pasaplatos por el lado de servicio")
	assert_eq(slot.get_item(), box, "caja en el pasaplatos")
	return box


## Coge la caja llena del pasaplatos y pone los condimentos de la comanda con ella en la mano. Para
## el pimentón pulsa antes el otro y comprueba que el bueno lo sustituye en una pulsación.
func _season(server: Walker, box: Box, order: ActiveOrder) -> void:
	assert_eq(await _use_station(server, _pass_slot(), 1.0), box, "coge la caja llena")
	assert_eq(_held(server), box)
	for seasoning: SeasoningData in order.data.seasonings:
		if seasoning.same_as(CACHELOS):
			assert_eq(await _use_station(server, _bowl(), 1.0), _bowl(), "cuenco")
		else:
			if seasoning.same_as(PAPRIKA) or seasoning.same_as(HOT_PAPRIKA):
				var other: SeasoningData = HOT_PAPRIKA if seasoning.same_as(PAPRIKA) else PAPRIKA
				var wrong: SeasoningDispenser = _dispenser(other)
				assert_eq(await _use_station(server, wrong, 1.0), wrong, wrong.name)
				assert_true(box.has_seasoning(other), "primero el otro pimentón")
			var dispenser: SeasoningDispenser = _dispenser(seasoning)
			assert_eq(await _use_station(server, dispenser, 1.0), dispenser, dispenser.name)
		assert_true(box.has_seasoning(seasoning), "caja con %s" % seasoning.display_name)
	assert_eq(
		box.get_contents().seasonings.size(), order.data.seasonings.size(), "solo lo que se pide"
	)


## Entrega en el puesto de la comanda la caja condimentada que lleva en la mano.
func _deliver(server: Walker, box: Box, order: ActiveOrder) -> void:
	assert_eq(_held(server), box, "la caja condimentada va en la mano")
	var stand: OrderStand = _stations("OrderStand%d" % order.slot_id) as OrderStand
	var stand_xz: Vector2 = _xz(stand)
	await server.walk_to(stand_xz + Vector2(0.0, -STAND_FRONT))
	for _i: int in 20:
		if server.detector().get_target() == stand:
			break
		await server.push_towards(stand_xz, 1)
	assert_eq(server.detector().get_target(), stand, "de cara al puesto %d" % order.slot_id)
	await server.tap_interact()


func _switch(walker: Walker) -> void:
	await walker.tap(KEY_Q)
	await wait_seconds(SWITCH_WAIT)


## Una ronda: tres comandas seguidas. `cook` y `server` mueven a Player2 y Player1; en SINGLE son
## el mismo jugador y se cambia con Q cada vez que la caja pasa de lado.
func _play(cook: Walker, server: Walker) -> void:
	var single: bool = _mode == GameMode.Mode.SINGLE
	if single:
		await _switch(server)
	await _prepare_kitchen(cook)
	for delivery: int in DELIVERIES:
		var order: ActiveOrder = _active_order()
		var started: int = Time.get_ticks_msec()
		if single:
			await _switch(cook)
		var box: Box = await _box_to_slot(server, order)
		if single:
			await _switch(server)
		await _fill_box(cook, box)
		if single:
			await _switch(cook)
		await _season(server, box, order)
		await _deliver(server, box, order)
		assert_signal_emit_count(EventBus, "order_completed", delivery + 1, "entrega %d" % delivery)
		var done: ActiveOrder = get_signal_parameters(EventBus, "order_completed", delivery)[0]
		assert_eq(done.id, order.id, "entrega la comanda %d" % order.id)
		assert_null(_held(server), "mano vacía tras entregar")
		# Referencia para la guía de playtest (m2b-gate.md): ritmo de un jugador sin errores.
		gut.p("comanda %d (%s): %.1f s" % [order.id, _names(order), _since(started)])
		if single:
			await _switch(server)


func _since(started: int) -> float:
	return (Time.get_ticks_msec() - started) / 1000.0


func _names(order: ActiveOrder) -> String:
	var names: Array[String] = []
	for seasoning: SeasoningData in order.data.seasonings:
		names.append(seasoning.resource_path.get_file().get_basename())
	return "+".join(names)


func _assert_clean_round() -> void:
	assert_signal_emit_count(EventBus, "order_completed", DELIVERIES)
	assert_eq(RoundManager.round_state.get_boxes_delivered(), DELIVERIES)
	assert_signal_not_emitted(EventBus, "delivery_rejected")
	assert_signal_not_emitted(EventBus, "order_expired")
	assert_eq(_rejections, [] as Array[String], "sin pulsaciones de error en la estación")
	assert_eq(_sides["Player2"].keys(), [-1.0], "el cocinero no sale de la cocina")
	assert_eq(_sides["Player1"].keys(), [1.0], "el servidor no sale del servicio")


# --- AC1: Individual -----------------------------------------------------------------------------


func test_ac1_single_three_deliveries_through_the_pass_switching_characters() -> void:
	await _load_level(GameMode.Mode.SINGLE)
	var cook: Walker = Walker.new(get_tree(), _character(2))
	var server: Walker = Walker.new(get_tree(), _character(1))
	assert_eq((_character(1).get_node("%Control") as ControlComponent).controlled_by, 1)
	await _play(cook, server)
	_assert_clean_round()
	assert_gt(
		get_signal_emit_count(EventBus, "character_switched"), DELIVERIES * 2, "usa el cambio"
	)


# --- AC1: Local 2P -------------------------------------------------------------------------------


func test_ac1_coop_three_deliveries_cook_and_server_each_on_their_side() -> void:
	await _load_level(GameMode.Mode.COOP_2P)
	assert_eq((_character(1).get_node("%Control") as ControlComponent).controlled_by, 1)
	assert_eq((_character(2).get_node("%Control") as ControlComponent).controlled_by, 2)
	var cook: Walker = Walker.new(get_tree(), _character(2), 2)
	var server: Walker = Walker.new(get_tree(), _character(1), 1)
	await _play(cook, server)
	_assert_clean_round()
	assert_eq((_character(1).get_node("%Control") as ControlComponent).controlled_by, 1, "J1 sigue")
	assert_eq((_character(2).get_node("%Control") as ControlComponent).controlled_by, 2, "J2 sigue")
