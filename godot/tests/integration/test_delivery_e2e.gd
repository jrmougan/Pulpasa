extends GutTest
## PUL-039: entrega de punta a punta en `level_01.tscn` real, como la juega una persona.
## El personaje se mueve con teclas simuladas (WASD) y cada pulsación de E pasa por el detector
## real (`InteractionDetector`, física incluida) y `InteractionComponent._unhandled_input`; el
## test nunca llama a `interact()` ni publica `target_changed` a mano.
##
## Prepara de verdad la caja de la comanda de un puesto (estantería de cajas, nevera, olla, corte,
## condimentos de la estantería o cachelos cocidos) y la entrega en su puesto pulsando E delante
## de él o entrando en `%DeliveryZone`.

const LEVEL_SCENE: String = "res://scenes/levels/level_01.tscn"
const OCTOPUS: IngredientData = preload("res://data/ingredients/octopus.tres")
const CACHELOS_SEASONING: SeasoningData = preload("res://data/seasonings/cachelos.tres")
## Distancia a la que se considera alcanzado un punto del camino (m).
const ARRIVED: float = 0.12
## Frames máximos para recorrer un tramo.
const WALK_FRAMES: int = 400
## Frames empujando hacia un objetivo para quedar de cara a él.
const FACE_FRAMES: int = 8
## Separación entre el punto de llegada y la estación (m).
const APPROACH: float = 0.75
## Sitio despejado donde se dejan la caja y lo que sobra.
const BOX_SPOT: Vector2 = Vector2(0.0, -1.2)
const DUMP_SPOT: Vector2 = Vector2(5.5, 2.0)
## Distancia al puesto desde la que se empieza a acercar, fuera de `%DeliveryZone` (m).
const STAND_FRONT: float = 2.5

var _scene: Node
var _player: Player
var _hold: Holder
var _detector: InteractionDetector
## Teclas de movimiento pulsadas ahora (physical keycode → true).
var _down: Dictionary = {}


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
	# Paciencia fuera: preparar con teclado tarda más que algunos `max_time` del catálogo (hallazgo
	# de balance de PUL-039, ver la ficha); aquí se prueba la entrega, no el balance. Mismas
	# recetas y condimentos del catálogo real, mismo nivel y mismos puestos.
	var config: RoundConfig = _scene.get("round_config")
	var catalog: OrderCatalog = (_scene.get("order_catalog") as OrderCatalog).duplicate()
	var orders: Array[OrderData] = []
	for data: OrderData in catalog.orders:
		var copy: OrderData = data.duplicate()
		copy.max_time = 0.0
		orders.append(copy)
	catalog.orders = orders
	OrderService.setup(catalog, null, config)
	RoundManager.start_round(config, _scene.call(&"get_slot_ids"))
	RoundManager.round_state.advance(config.first_order_delay)


func after_each() -> void:
	await _release_keys()
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
	await _walk_to(front + Vector2(0.0, -1.0))
	await _walk_to(front)
	# Paso a paso hacia el puesto hasta que el detector lo elige.
	for _i: int in 20:
		if _detector.get_target() == stand:
			break
		await _push_towards(_xz(stand.global_position), 1)
	assert_signal_emit_count(EventBus, "order_completed", 0, "aún no ha entregado")
	assert_eq(_detector.get_target(), stand, "el detector elige el puesto")
	await _tap(KEY_E)
	assert_signal_emit_count(EventBus, "order_completed", 1)
	assert_signal_emit_count(EventBus, "delivery_rejected", 0)
	assert_eq((get_signal_parameters(EventBus, "order_completed")[0] as ActiveOrder).id, order.id)
	assert_gt(RoundManager.round_state.get_revenue(), revenue, "sube la recaudación")
	assert_null(_hold.get_held_item(), "la caja se ha entregado")


func test_ac3_deliver_by_walking_into_the_delivery_zone() -> void:
	var order: ActiveOrder = _order_with_most_seasonings()
	assert_not_null(order)
	var box: Box = await _prepare_box(order)
	assert_eq(_hold.get_held_item(), box, "caja preparada en la mano")
	if _hold.get_held_item() != box:
		return
	var stand: OrderStand = _stand(order.slot_id)
	var revenue: int = RoundManager.round_state.get_revenue()
	await _walk_to(_xz(stand.global_position) + Vector2(0.0, -STAND_FRONT))
	assert_signal_emit_count(EventBus, "order_completed", 0)
	# Sin pulsar E: andar hacia el puesto hasta entrar en la zona.
	await _push_towards(_xz(stand.global_position), 60)
	assert_signal_emit_count(EventBus, "order_completed", 1)
	assert_signal_emit_count(EventBus, "delivery_rejected", 0)
	assert_gt(RoundManager.round_state.get_revenue(), revenue, "sube la recaudación")
	assert_null(_hold.get_held_item(), "la caja se ha entregado")


# --- Preparación de la caja, solo con teclas ----------------------------------------------------


## Comanda activa con más condimentos (la más exigente), o `null`.
func _order_with_most_seasonings() -> ActiveOrder:
	var best: ActiveOrder = null
	for order: ActiveOrder in OrderService.get_active_orders():
		if best == null or order.data.seasonings.size() > best.data.seasonings.size():
			best = order
	return best


## Monta la caja de `order` jugando y la deja en la mano. Devuelve la caja, o `null` si falla.
func _prepare_box(order: ActiveOrder) -> Box:
	var recipe: RecipeData = order.data.recipe
	# 1. Caja de la estantería, dejada en el suelo.
	await _use_station(_box_spawner(recipe.box))
	var box: Box = _hold.get_held_item() as Box
	assert_not_null(box, "caja de la estantería")
	if box == null:
		return null
	assert_eq(box.data, recipe.box)
	await _walk_to(BOX_SPOT)
	await _face(BOX_SPOT + Vector2(0.0, -1.0))
	await _tap(KEY_E)
	assert_null(_hold.get_held_item(), "caja soltada")
	# 2. Pulpo: nevera → olla → corte hasta llenar.
	while not box.is_full():
		await _use_station(_scene.get_node("Stations/OctopusStorage"))
		await _cook_held()
		var guard: int = 0
		while _hold.get_held_item() is Ingredient and not box.is_full() and guard < 30:
			await _use_item(box)
			guard += 1
		await _dump_held()
	assert_true(box.is_full(), "caja llena")
	# 3. Condimentos.
	for seasoning: SeasoningData in order.data.seasonings:
		if seasoning.same_as(CACHELOS_SEASONING):
			await _use_station(_scene.get_node("Stations/CachelosStorage"))
			await _cook_held()
		else:
			await _use_station(_spice_item(seasoning))
		assert_not_null(_hold.get_held_item(), "condimento en la mano")
		await _use_item(box)
		assert_true(box.has_seasoning(seasoning), "caja con %s" % seasoning.display_name)
		await _dump_held()
	# 4. Caja a la mano.
	await _use_item(box)
	return box


## Cuece lo que hay en la mano en la olla y lo recoge cocido.
func _cook_held() -> void:
	var kitchen: Node3D = _scene.get_node("Stations/Kitchen")
	var held: Ingredient = _hold.get_held_item() as Ingredient
	assert_not_null(held, "ingrediente crudo en la mano")
	if held == null:
		return
	await _use_station(kitchen)
	assert_null(_hold.get_held_item(), "a la olla")
	await wait_physics_frames(roundi((held.data.cook_time + 0.3) * Engine.physics_ticks_per_second))
	await _tap(KEY_E)
	var cooked: Ingredient = _hold.get_held_item() as Ingredient
	assert_true(cooked != null and cooked.is_cooked(), "cocido en la mano")


## Lleva lo que haya en la mano a un rincón despejado y lo suelta.
func _dump_held() -> void:
	if _hold.get_held_item() == null:
		return
	await _walk_to(DUMP_SPOT)
	await _face(DUMP_SPOT + Vector2(1.0, 0.0))
	await _tap(KEY_E)
	assert_null(_hold.get_held_item(), "suelto en el rincón")


## Va delante de una estación fija (lado de la sala) y pulsa E.
func _use_station(station: Node3D) -> void:
	var pos: Vector2 = _xz(station.global_position)
	var inward: Vector2 = Vector2(0.0, 0.0) - pos
	inward = Vector2(signf(inward.x), 0.0) if absf(pos.y) < 3.0 else Vector2(0.0, signf(inward.y))
	await _walk_to(pos + inward * APPROACH)
	await _face(pos)
	assert_eq(_detector.get_target(), station, "objetivo %s" % station.name)
	await _tap(KEY_E)


## Va hasta un objeto suelto en el suelo (por el lado de la cámara) y pulsa E.
func _use_item(item: Node3D) -> void:
	var pos: Vector2 = _xz(item.global_position)
	await _walk_to(pos + Vector2(0.0, APPROACH))
	await _face(pos)
	assert_eq(_detector.get_target(), item, "objetivo %s" % item.name)
	await _tap(KEY_E)


func _box_spawner(data: BoxData) -> Node3D:
	for child: Node in _scene.get_node("Stations/BoxShelf").get_children():
		if child is ItemSpawner and (child as ItemSpawner).data == data:
			return child as Node3D
	return null


func _spice_item(seasoning: SeasoningData) -> Node3D:
	for child: Node in _scene.get_node("Stations/SpiceShelf").get_children():
		var slot: Slot = child as Slot
		if slot != null and slot.has_item():
			var item: SeasoningItem = slot.get_item() as SeasoningItem
			if item != null and item.data != null and item.data.same_as(seasoning):
				return item
	return null


func _stand(slot_id: int) -> OrderStand:
	return _scene.get_node("Stations/OrderStand%d" % slot_id) as OrderStand


# --- Movimiento con teclas ----------------------------------------------------------------------


func _xz(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


## Anda en línea recta (WASD) hasta `target`.
func _walk_to(target: Vector2) -> void:
	for _i: int in WALK_FRAMES:
		var delta: Vector2 = target - _xz(_player.global_position)
		if delta.length() <= ARRIVED:
			break
		await _hold_keys(delta, ARRIVED * 0.5)
		await wait_physics_frames(1)
	await _release_keys()
	await wait_physics_frames(1)


## Empuja hacia `target` unos frames para girarse hacia él.
func _face(target: Vector2) -> void:
	await _push_towards(target, FACE_FRAMES)


func _push_towards(target: Vector2, frames: int) -> void:
	for _i: int in frames:
		await _hold_keys(target - _xz(_player.global_position), 0.05)
		await wait_physics_frames(1)
	await _release_keys()
	await wait_physics_frames(2)


## Pulsa las teclas de dirección de `delta` (ejes con |valor| > `dead`) y suelta las demás.
func _hold_keys(delta: Vector2, dead: float) -> void:
	var dir: Vector2 = delta.normalized()
	var limit: float = dead / maxf(delta.length(), 0.0001)
	_set_key(KEY_D, dir.x > limit and dir.x > 0.38)
	_set_key(KEY_A, dir.x < -limit and dir.x < -0.38)
	_set_key(KEY_S, dir.y > limit and dir.y > 0.38)
	_set_key(KEY_W, dir.y < -limit and dir.y < -0.38)
	Input.flush_buffered_events()


func _release_keys() -> void:
	for key: Key in [KEY_W, KEY_A, KEY_S, KEY_D]:
		_set_key(key, false)
	Input.flush_buffered_events()
	await wait_physics_frames(1)


func _set_key(keycode: Key, pressed: bool) -> void:
	if bool(_down.get(keycode, false)) == pressed:
		return
	_down[keycode] = pressed
	Input.parse_input_event(_key_event(keycode, pressed))


func _key_event(keycode: Key, pressed: bool) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = pressed
	return event


## Pulsa y suelta una tecla como el teclado (llega a `_unhandled_input`).
func _tap(keycode: Key) -> void:
	Input.parse_input_event(_key_event(keycode, true))
	Input.flush_buffered_events()
	await wait_physics_frames(2)
	Input.parse_input_event(_key_event(keycode, false))
	Input.flush_buffered_events()
	await wait_physics_frames(2)
