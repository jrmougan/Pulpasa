extends GutTest
## PUL-039: entrega de punta a punta en `level_01.tscn` real, como la juega una persona.
## El personaje se mueve con teclas simuladas (WASD) y cada pulsación de E pasa por el detector
## real (`InteractionDetector`, física incluida) y `InteractionComponent._unhandled_input`; el
## test nunca llama a `interact()` ni publica `target_changed` a mano.
##
## PUL-061 (planta B): la caja se prepara en Individual con un personaje a cada lado de la barra y
## el cambio de personaje (Q), como el pase de `level-layouts.md`: el de servicio deja la caja en
## un pasaplatos; el de cocina cuece, corta sobre ella, la pasa a la bandeja de la estación por el
## lado de pase y echa los cachelos al cuenco; el de servicio condimenta en los dispensadores (y
## alterna cachelos en el cuenco) y la recoge.
## La entrega es en su puesto pulsando E delante de él o entrando en `%DeliveryZone`, con la
## paciencia real de los `.tres` (sin caducar). La zona no hace nada con una caja que no es la del
## puesto (E sí la rechaza, D8) y el puesto al que apunta E se resalta.

const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const Walker: GDScript = preload("res://tests/integration/level_walker.gd")
const CACHELOS_SEASONING: SeasoningData = preload("res://data/seasonings/cachelos.tres")
## Distancia al puesto desde la que se empieza a acercar (m): del lado del kiosco de
## `%DeliveryZone` (PUL-100: marca en Z local 3,40, entre la barra y el kiosco), fuera de ella.
const STAND_FRONT: float = 2.35
## Pasillos (X) por fuera de las cuatro zonas (X -4,03 a 4,43): los puestos 1 y 2 se rodean por la
## izquierda y el 3 y el 4 por la derecha, con holgura de sobra para la cápsula (r 0,21).
const LANE_LEFT: float = -4.8
const LANE_RIGHT: float = 5.1
## Z desde la que se baja por el pasillo: al norte de las zonas (ocupan Z 1,83 a 2,88).
const LANE_ENTRY_Z: float = 1.2
## Z por la que se va de pasillo a puesto: del lado del kiosco, a 0,4 m de las zonas.
const KIOSK_LANE_Z: float = 3.5
## Del centro de una estación al punto desde el que se usa (m).
const ACCESS: float = 1.0
## Rincón de la cocina donde se suelta el pulpo que sobra.
const KITCHEN_DUMP: Vector2 = Vector2(4.5, -2.4)
## Espera tras cambiar de personaje (> `switch_cooldown` de `input_config.tres`).
const SWITCH_WAIT: float = 0.3

var _scene: Node
var _player: Player
var _hold: Holder
var _detector: InteractionDetector
## Personaje del servicio (Player1) y de la cocina (Player2), los dos con las teclas de J1.
var _service: Walker
var _kitchen: Walker


func before_each() -> void:
	GameState.set_paused(false)
	watch_signals(EventBus)
	var previous: Node = get_tree().current_scene
	var previous_id: int = previous.get_instance_id() if previous != null else 0
	assert_eq(GameState.start_level(GameMode.Mode.SINGLE), OK)
	for _i: int in 120:
		await wait_process_frames(1)
		var current: Node = get_tree().current_scene
		if current != null and current.get_instance_id() != previous_id and current.is_node_ready():
			break
	await wait_physics_frames(2)
	_scene = get_tree().current_scene
	_player = _scene.get_node("Characters/Player1") as Player
	_hold = _player.get_node("%HoldComponent") as Holder
	_detector = _player.get_node("%InteractionDetector") as InteractionDetector
	_service = Walker.new(get_tree(), _player)
	_kitchen = Walker.new(get_tree(), _scene.get_node("Characters/Player2") as Player)
	# Paciencia REAL del catálogo (PUL-039: `max_time` ×2): la ruta de bot llega a tiempo.
	var config: RoundConfig = _scene.get("round_config")
	RoundManager.round_state.advance(config.first_order_delay)


func after_each() -> void:
	await _service.release_keys()
	GameState.set_paused(false)
	GameState.reset_input()
	if is_instance_valid(_scene):
		var was_current: bool = _scene == get_tree().current_scene
		_scene.free()
		if was_current:
			get_tree().current_scene = null
	_scene = null


func test_ac3_deliver_with_e_in_front_of_the_stand() -> void:
	var order: ActiveOrder = _order_with_most_seasonings()
	assert_not_null(order)
	var box: Box = await _prepare_box(order)
	assert_eq(_hold.get_held_item(), box, "caja preparada en la mano")
	if _hold.get_held_item() != box:
		return
	var stand: OrderStand = _stand(order.slot_id)
	var revenue: int = RoundManager.round_state.get_revenue()
	# Delante del puesto, de cara a él y fuera de su zona: la entrega la hace la tecla E.
	var front: Vector2 = _xz(stand.global_position) + Vector2(0.0, -STAND_FRONT)
	await _walk_around_zones(stand, front)
	var zone: Area3D = stand.get_node("%DeliveryZone") as Area3D
	assert_gt(
		_xz(_player.global_position).distance_to(_xz(zone.global_position)), 0.7, "fuera de la zona"
	)
	# Paso a paso hacia el puesto hasta que el detector lo elige.
	for _i: int in 20:
		if _detector.get_target() == stand:
			break
		await _service.push_towards(_xz(stand.global_position), 1)
	assert_signal_emit_count(EventBus, "order_completed", 0, "aún no ha entregado")
	assert_true(_highlight(stand).is_highlighted(), "el puesto apuntado se resalta")
	for other: int in [1, 2, 3, 4]:
		if other != order.slot_id:
			assert_false(_highlight(_stand(other)).is_highlighted(), "solo uno resaltado")
	assert_eq(_detector.get_target(), stand, "el detector elige el puesto")
	await _service.tap_interact()
	assert_signal_emit_count(EventBus, "order_completed", 1)
	assert_signal_emit_count(EventBus, "delivery_rejected", 0)
	assert_eq((get_signal_parameters(EventBus, "order_completed")[0] as ActiveOrder).id, order.id)
	assert_gt(RoundManager.round_state.get_revenue(), revenue, "sube la recaudación")
	assert_null(_hold.get_held_item(), "la caja se ha entregado")
	_assert_not_expired(order)


func test_ac3_deliver_by_walking_into_the_delivery_zone() -> void:
	var order: ActiveOrder = _order_with_most_seasonings()
	assert_not_null(order)
	var box: Box = await _prepare_box(order)
	assert_eq(_hold.get_held_item(), box, "caja preparada en la mano")
	if _hold.get_held_item() != box:
		return
	var stand: OrderStand = _stand(order.slot_id)
	var revenue: int = RoundManager.round_state.get_revenue()
	# Llega por un pasillo entre zonas, del lado del kiosco, sin cruzar ninguna zona.
	await _walk_around_zones(stand, _xz(stand.global_position) + Vector2(0.0, -STAND_FRONT))
	assert_signal_emit_count(EventBus, "order_completed", 0, "antes de entrar no ha entregado")
	assert_true(stand.is_zone_lit(), "a menos de 2 m con la caja correcta, la zona se enciende")
	# Sin pulsar E: andar hacia la marca hasta entrar en la zona.
	var zone: Area3D = stand.get_node("%DeliveryZone") as Area3D
	await _service.push_towards(_xz(zone.global_position), 60)
	assert_signal_emit_count(EventBus, "order_completed", 1)
	assert_signal_emit_count(EventBus, "delivery_rejected", 0)
	assert_gt(RoundManager.round_state.get_revenue(), revenue, "sube la recaudación")
	assert_null(_hold.get_held_item(), "la caja se ha entregado")
	_assert_not_expired(order)


func test_pul039_wrong_box_in_zone_does_nothing_and_e_rejects() -> void:
	var order: ActiveOrder = _order_with_most_seasonings()
	assert_not_null(order)
	# Caja vacía de la estantería: no coincide con ninguna comanda.
	await _take_box(order.data.recipe.box)
	var box: Box = _hold.get_held_item() as Box
	assert_not_null(box)
	var stand: OrderStand = _stand(order.slot_id)
	var zone: Area3D = stand.get_node("%DeliveryZone") as Area3D
	var zone_xz: Vector2 = _xz(zone.global_position)
	# Cruza las zonas de los cuatro puestos (a su altura) y se para dentro de la suya.
	await _walk_around_zones(_stand(1), Vector2(LANE_LEFT, KIOSK_LANE_Z))
	await _service.walk_to(Vector2(LANE_LEFT, zone_xz.y))
	var crossing: Vector2 = Vector2(_xz(_stand(4).global_position).x, zone_xz.y)
	await _service.walk_to(crossing)
	assert_almost_eq(
		_xz(_player.global_position).distance_to(crossing), 0.0, 0.2, "cruzó las zonas"
	)
	await _service.walk_to(zone_xz)
	assert_true(zone.overlaps_body(_player), "termina dentro de la zona de su puesto")
	assert_signal_not_emitted(EventBus, "delivery_rejected", "la zona no rechaza ni penaliza")
	assert_signal_not_emitted(EventBus, "order_completed")
	assert_eq(_hold.get_held_item(), box, "la caja sigue en la mano")
	await _service.push_towards(zone_xz, 4)
	assert_true(zone.overlaps_body(_player), "sigue dentro de la zona")
	# Sale hacia el kiosco, enfrente de él, hasta que el detector lo elige.
	var front: Vector2 = Vector2(zone_xz.x, KIOSK_LANE_Z)
	await _service.walk_to(front)
	for _i: int in 20:
		if _detector.get_target() == stand:
			break
		await _service.push_towards(_xz(stand.global_position), 1)
	assert_eq(_detector.get_target(), stand)
	await _service.tap_interact()
	assert_signal_emit_count(EventBus, "delivery_rejected", 1, "E valida y rechaza (D8)")
	assert_eq(_hold.get_held_item(), box)


## Aproximación determinista a los 4 puestos con una caja que coincide inyectada en la mano: rodear
## las zonas sin entregar, zona encendida antes de entrar y entrega al entrar.
func test_pul100_every_stand_lights_and_delivers_on_entry() -> void:
	OrderService.board.set_active_slots([1, 2, 3, 4] as Array[int])
	OrderService.board.fill_slots([1, 2, 3, 4] as Array[int])
	for slot: int in [1, 2, 3, 4]:
		var order: ActiveOrder = null
		for active: ActiveOrder in OrderService.get_active_orders():
			if active.slot_id == slot:
				order = active
		assert_not_null(order, "comanda viva en el puesto %d" % slot)
		if order == null:
			return
		var stand: OrderStand = _stand(slot)
		_inject_box(order)
		var start_x: float = LANE_LEFT if slot <= 2 else LANE_RIGHT
		_player.global_position = Vector3(start_x, 0.0, LANE_ENTRY_Z)
		await wait_physics_frames(3)
		var done: int = get_signal_emit_count(EventBus, "order_completed")
		await _walk_around_zones(stand, _xz(stand.global_position) + Vector2(0.0, -STAND_FRONT))
		assert_eq(
			get_signal_emit_count(EventBus, "order_completed"), done, "puesto %d: aún no" % slot
		)
		assert_true(stand.is_zone_lit(), "puesto %d: zona encendida" % slot)
		var zone: Area3D = stand.get_node("%DeliveryZone") as Area3D
		await _service.push_towards(_xz(zone.global_position), 60)
		assert_eq(get_signal_emit_count(EventBus, "order_completed"), done + 1, "puesto %d" % slot)
		assert_null(_hold.get_held_item(), "puesto %d: caja entregada" % slot)
		assert_signal_emit_count(EventBus, "delivery_rejected", 0)


# --- Preparación de la caja, solo con teclas ----------------------------------------------------


## Comanda activa con más condimentos (la más exigente), o `null`.
func _order_with_most_seasonings() -> ActiveOrder:
	var best: ActiveOrder = null
	for order: ActiveOrder in OrderService.get_active_orders():
		if best == null or order.data.seasonings.size() > best.data.seasonings.size():
			best = order
	return best


## Monta la caja de `order` jugando y la deja en la mano del personaje del servicio. Devuelve la
## caja, o `null` si falla.
func _prepare_box(order: ActiveOrder) -> Box:
	var recipe: RecipeData = order.data.recipe
	var station: SeasoningStation = _scene.get_node("Stations/SeasoningStation")
	var pass_slot: Slot = _scene.get_node("Stations/PassSlot05")
	var pass_xz: Vector2 = Walker.xz(pass_slot.global_position)
	# 1. Servicio: caja de la estantería al pasaplatos.
	await _take_box(recipe.box)
	var box: Box = _hold.get_held_item() as Box
	assert_not_null(box, "caja de la estantería")
	if box == null:
		return null
	assert_eq(box.data, recipe.box)
	assert_eq(await _service.use(pass_xz, Vector2(pass_xz.x, ACCESS)), pass_slot, "pasaplatos")
	assert_eq(pass_slot.get_item(), box, "caja en el pasaplatos")
	# 2. Cocina: pulpo → olla → corte sobre el pasaplatos hasta llenar; cachelos al cuenco (desde el
	# pase, con cachelos cocidos en la mano).
	await _switch()
	var kitchen_hold: Holder = _kitchen.holder()
	var octopi: int = 0
	while not box.is_full() and octopi < 4:
		octopi += 1
		await _kitchen_use(_scene.get_node("Stations/OctopusStorage"))
		await _cook_held()
		var guard: int = 0
		while kitchen_hold.get_held_item() is Ingredient and not box.is_full() and guard < 30:
			var target: Node = await _kitchen.use(pass_xz, Vector2(pass_xz.x, -ACCESS))
			assert_eq(target, box, "corta sobre la caja del pasaplatos")
			guard += 1
		if kitchen_hold.get_held_item() != null:
			await _kitchen.walk_to(KITCHEN_DUMP)
			await _kitchen.face(KITCHEN_DUMP + Vector2(1.0, 0.0))
			await _kitchen.tap_interact()
	assert_true(box.is_full(), "caja llena")
	var bowl: CachelosBowl = station.get_node("CachelosBowl")
	var bowl_xz: Vector2 = Walker.xz(bowl.global_position)
	if _wants_cachelos(order):
		await _kitchen_use(_scene.get_node("Stations/CachelosStorage"))
		await _cook_held()
		assert_eq(await _kitchen.use(bowl_xz, Vector2(bowl_xz.x, -ACCESS)), bowl, "cuenco")
		assert_eq(bowl.stock, 2, "un cachelo cocido = 2 raciones")
	# 3. Servicio: coge la caja llena del pasaplatos y la condimenta en la mano.
	await _switch()
	assert_eq(await _service.use(pass_xz, Vector2(pass_xz.x, ACCESS)), box, "coge la caja")
	assert_eq(_hold.get_held_item(), box, "la caja va en la mano")
	for seasoning: SeasoningData in order.data.seasonings:
		var part: Node3D = bowl if seasoning.same_as(CACHELOS_SEASONING) else _dispenser(seasoning)
		var at: Vector2 = Walker.xz(part.global_position)
		var stand: Vector2 = Walker.station_stand(at, station.global_position.z, 1.0)
		assert_eq(await _service.use(at, stand), part, "objetivo %s" % part.name)
		assert_true(box.has_seasoning(seasoning), "caja con %s" % seasoning.display_name)
	assert_eq(_hold.get_held_item(), box, "la caja condimentada sigue en la mano")
	return box


func _wants_cachelos(order: ActiveOrder) -> bool:
	for seasoning: SeasoningData in order.data.seasonings:
		if seasoning.same_as(CACHELOS_SEASONING):
			return true
	return false


## Cambia de personaje con Q (p1_switch) y espera el enfriamiento.
func _switch() -> void:
	await _service.tap(KEY_Q)
	await wait_seconds(SWITCH_WAIT)


## El personaje de cocina usa una estación de la fila 0 desde delante.
func _kitchen_use(station: Node3D) -> void:
	var pos: Vector2 = Walker.xz(station.global_position)
	var target: Node = await _kitchen.use(pos, pos + Vector2(0.0, ACCESS))
	assert_eq(target, station, "objetivo %s" % station.name)


## Coge de la estantería la caja `data` con el personaje del servicio.
func _take_box(data: BoxData) -> void:
	var spawner: Node3D = _box_spawner(data)
	var pos: Vector2 = Walker.xz(spawner.global_position)
	var target: Node = await _service.use(pos, pos + Vector2(ACCESS * 0.8, 0.0))
	assert_eq(target, spawner, "objetivo %s" % spawner.name)


## Cuece en la olla lo que lleva el personaje de cocina y lo recoge cocido.
func _cook_held() -> void:
	var kitchen: Node3D = _scene.get_node("Stations/Kitchen")
	var held: Ingredient = _kitchen.holder().get_held_item() as Ingredient
	assert_not_null(held, "ingrediente crudo en la mano")
	if held == null:
		return
	await _kitchen_use(kitchen)
	assert_null(_kitchen.holder().get_held_item(), "a la olla")
	await wait_physics_frames(roundi((held.data.cook_time + 0.3) * Engine.physics_ticks_per_second))
	await _kitchen.tap_interact()
	var cooked: Ingredient = _kitchen.holder().get_held_item() as Ingredient
	assert_true(cooked != null and cooked.is_cooked(), "cocido en la mano")


func _dispenser(seasoning: SeasoningData) -> SeasoningDispenser:
	var station: Node = _scene.get_node("Stations/SeasoningStation")
	for child: Node in station.get_node("Dispensers").get_children():
		var dispenser: SeasoningDispenser = child as SeasoningDispenser
		if dispenser != null and dispenser.seasoning.same_as(seasoning):
			return dispenser
	return null


func _box_spawner(data: BoxData) -> Node3D:
	for child: Node in _scene.get_node("Stations/BoxShelf").get_children():
		if child is ItemSpawner and (child as ItemSpawner).data == data:
			return child as Node3D
	return null


func _highlight(stand: OrderStand) -> Highlightable:
	return stand.get_node("%Highlightable") as Highlightable


func _assert_not_expired(order: ActiveOrder) -> void:
	for i: int in get_signal_emit_count(EventBus, "order_expired"):
		var expired: ActiveOrder = get_signal_parameters(EventBus, "order_expired", i)[0]
		assert_ne(expired.id, order.id, "la comanda no caduca con la paciencia real")


## Va a `target` (del lado del kiosco) rodeando las zonas por fuera, sin cruzar ninguna.
func _walk_around_zones(stand: OrderStand, target: Vector2) -> void:
	var lane: float = LANE_LEFT if stand.slot_id <= 2 else LANE_RIGHT
	await _service.walk_to(Vector2(lane, LANE_ENTRY_Z))
	await _service.walk_to(Vector2(lane, KIOSK_LANE_Z))
	await _service.walk_to(Vector2(target.x, KIOSK_LANE_Z))
	await _service.walk_to(target)


## Caja que coincide con `order` en la mano del personaje del servicio, sin prepararla jugando.
func _inject_box(order: ActiveOrder) -> Box:
	var items: Node = _scene.get_node("Items")
	var box: Box = BOX_SCENE.instantiate()
	items.add_child(box)
	box.data = order.data.recipe.box
	var guard: int = 0
	while not box.is_full() and guard < 200:
		var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
		items.add_child(octopus)
		octopus.set_cooked()
		assert_true(_hold.pick_up(octopus))
		while octopus.is_inside_tree() and not box.is_full() and guard < 200:
			box.interact(_player.get_node("%InteractionComponent") as InteractionComponent)
			guard += 1
		if is_instance_valid(octopus):
			_hold.drop()
			octopus.free()
	for seasoning: SeasoningData in order.data.seasonings:
		box.toggle_seasoning(seasoning, true)
	assert_true(_hold.pick_up(box))
	return box


func _stand(slot_id: int) -> OrderStand:
	return _scene.get_node("Stations/OrderStand%d" % slot_id) as OrderStand


func _xz(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)
