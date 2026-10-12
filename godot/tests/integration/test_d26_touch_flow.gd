extends GutTest
## PUL-132 AC2 (D26, controles-tactiles AC5-AC7 y AC12): una partida entera en `level_01.tscn` real
## con el perfil MOBILE (`--touch`) jugada SOLO con eventos de pantalla (`InputEventScreenTouch` y
## `InputEventScreenDrag` a 2340×1080 con la safe area simulada): el stick flotante mueve, el botón
## de acción pulsa y mantiene, el botón de cambiar pasa de personaje y el de pausa pausa. Ni una
## tecla: una sonda cuenta los `InputEventKey` y el test exige que sean 0.
## Flujo (Individual, una comanda «Á feira»): cambiar al cocinero → nevera → olla → cocido →
## cambiar al servidor → caja del estante al pasaplatos → cambiar al cocinero → 6 cortes
## manteniendo el botón de acción (D26: mantener repite solo el corte) → cambiar al servidor →
## coger la caja → aliño dulce → entrar en la zona del puesto (entrega).
## Multitáctil: en la nevera se mantiene el stick empujando contra ella mientras otro dedo pulsa
## el botón de acción (stick + acción a la vez).

const LEVEL: PackedScene = preload("res://scenes/levels/level_01.tscn")
const Walker: GDScript = preload("res://tests/integration/level_walker.gd")
const A_FEIRA: OrderData = preload("res://data/orders/a_feira.tres")
const SWEET: SeasoningData = preload("res://data/seasonings/sweet_dressing.tres")
const BOX: BoxData = preload("res://data/boxes/box.tres")
const WINDOW: Vector2i = Vector2i(2340, 1080)
const SAFE: Rect2 = Rect2(132.0, 0.0, 2076.0, 1017.0)
## Controles a 2340×1080 con esa safe area (controles-tactiles AC2 y AC3), en px de pantalla.
const STICK_PX: Vector2 = Vector2(300.0, 700.0)
const STICK_RADIUS_PX: float = 150.0
const ACTION_PX: Vector2 = Vector2(2070.0, 879.0)
## Cambiar en fila a la izquierda de acción (D27.1): acción + (−(90 + 24 + 60), 90 − 60).
const SWITCH_PX: Vector2 = Vector2(1896.0, 909.0)
const PAUSE_PX: Vector2 = Vector2(2100.0, 108.0)
const PATIENCE: float = 900.0
const BACK_ACCESS: float = 0.9
const SHELF_ACCESS: float = 0.9
const COOK_MARGIN: float = 3.0
const SWITCH_WAIT: float = 0.3
## Mantener el botón de acción sobre el corte: 6 cortes caben en 1,0 s (`cut_repeat_interval`).
const CUT_HOLD_S: float = 1.15

var _original_size: Vector2i
var _level: Node
var _station: SeasoningStation
var _probe: Probe
var _rejections: Array[String] = []


## Cuenta las teclas que llegan al juego (deben ser 0) y las pulsaciones de interactuar.
class Probe:
	extends Node
	var keys: int = 0
	var interact_presses: int = 0
	var switch_presses: int = 0

	func _input(event: InputEvent) -> void:
		if event is InputEventKey:
			keys += 1
		var action: InputEventAction = event as InputEventAction
		if action != null and action.pressed:
			if action.action == &"p1_interact":
				interact_presses += 1
			elif action.action == &"p1_switch":
				switch_presses += 1


## Mueve y pulsa como un dedo: el mismo recorrido que `level_walker.gd`, pero cada tecla es un
## contacto en pantalla. El stick sale en `STICK_PX` y el dedo se arrastra a `STICK_RADIUS_PX` en la
## dirección del destino (magnitud 1,0); el botón de acción y el de cambiar son sus contactos.
class TouchWalker:
	extends "res://tests/integration/level_walker.gd"
	const STICK_FINGER: int = 0
	const ACTION_FINGER: int = 1
	const SWITCH_FINGER: int = 2
	var stick_down: bool = false

	func _scale() -> float:
		return _tree.root.get_final_transform().get_scale().y

	func _deliver(event: InputEvent) -> void:
		_tree.root.push_input(event, true)
		Input.flush_buffered_events()

	func touch(index: int, px: Vector2, pressed: bool) -> void:
		var event: InputEventScreenTouch = InputEventScreenTouch.new()
		event.index = index
		event.position = px / _scale()
		event.pressed = pressed
		_deliver(event)

	func drag(index: int, px: Vector2) -> void:
		var event: InputEventScreenDrag = InputEventScreenDrag.new()
		event.index = index
		event.position = px / _scale()
		_deliver(event)

	func _hold_keys(delta: Vector2, _dead: float) -> void:
		var direction: Vector2 = delta.normalized()
		if not stick_down:
			touch(STICK_FINGER, STICK_PX, true)
			stick_down = true
		drag(STICK_FINGER, STICK_PX + direction * STICK_RADIUS_PX)

	func release_keys() -> void:
		if stick_down:
			touch(STICK_FINGER, STICK_PX, false)
			stick_down = false
		await _tree.physics_frame

	func tap_interact() -> void:
		touch(ACTION_FINGER, ACTION_PX, true)
		await _frames(2)
		touch(ACTION_FINGER, ACTION_PX, false)
		await _frames(2)

	func tap(keycode: Key) -> void:
		assert(keycode == KEY_Q, "solo hay un botón de cambiar")
		touch(SWITCH_FINGER, SWITCH_PX, true)
		await _frames(2)
		touch(SWITCH_FINGER, SWITCH_PX, false)
		await _frames(2)

	## Mantiene el botón de acción `seconds` de juego.
	func hold_interact(seconds: float) -> void:
		touch(ACTION_FINGER, ACTION_PX, true)
		await _frames(roundi(seconds * 60.0))
		touch(ACTION_FINGER, ACTION_PX, false)
		await _frames(2)

	## Stick y acción a la vez: empuja contra `aim` `frames` ticks y, sin soltar el stick, otro
	## dedo pulsa el botón de acción. Devuelve si el stick seguía activo con la acción pulsada.
	func push_and_tap(aim: Vector2, frames: int) -> bool:
		for _i: int in frames:
			_hold_keys(aim - position(), 0.05)
			await _tree.physics_frame
		touch(ACTION_FINGER, ACTION_PX, true)
		await _frames(2)
		var both: bool = stick_down and Input.is_action_pressed(&"p1_interact")
		touch(ACTION_FINGER, ACTION_PX, false)
		await _frames(2)
		await release_keys()
		return both


func before_each() -> void:
	PhaselessConfig.disable()
	GameState.set_paused(false)
	_original_size = get_window().size
	GameState.set_platform(PlatformProfile.Kind.MOBILE)
	GameState.mode = GameMode.Mode.SINGLE
	get_window().size = WINDOW
	await wait_process_frames(3)
	watch_signals(EventBus)
	_rejections.clear()
	_let_pointer_through_gut_output()


## El panel de salida de GUT (`TestOutput`) cubre la ventana y se queda con el puntero, también en
## headless: sin esto el toque emulado como clic nunca llega a «Reanudar». Solo toca su filtro.
func _let_pointer_through_gut_output() -> void:
	for output: Node in get_tree().root.find_children("TestOutput", "", true, false):
		var node: Node = output
		while node != null and node != get_tree().root:
			if node is Control:
				(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
			node = node.get_parent()


func after_each() -> void:
	for node: Node in get_tree().root.find_children("*", "TouchControls", true, false):
		(node as TouchControls).release_all()
	get_window().size = _original_size
	GameState.set_platform(PlatformProfile.Kind.DESKTOP)
	GameState.set_paused(false)
	GameState.reset_input()
	PhaselessConfig.restore()


## Nivel real en MOBILE con una sola comanda («Á feira», sin caducidad práctica).
func _load_level() -> void:
	var catalog: OrderCatalog = OrderCatalog.new()
	var order: OrderData = A_FEIRA.duplicate() as OrderData
	order.max_time = PATIENCE
	catalog.orders = [order] as Array[OrderData]
	catalog.max_active_orders = 1
	_level = LEVEL.instantiate()
	_level.set("order_catalog", catalog)
	(_level.get_node("CharacterSwitcher") as CharacterSwitcher).set_mode(GameMode.Mode.SINGLE)
	add_child_autofree(_level)
	_probe = add_child_autofree(Probe.new())
	_station = _level.get_node("Stations/SeasoningStation")
	for dispenser: Node in _station.get_node("Dispensers").get_children():
		dispenser.connect(&"rejected", _on_rejected.bind(dispenser.name))
	_station.get_node("CachelosBowl").connect(&"rejected", _on_rejected.bind(&"CachelosBowl"))
	await wait_physics_frames(2)
	_controls().apply_safe_rect(SAFE, Vector2(WINDOW))
	await wait_process_frames(2)
	var config: RoundConfig = _level.get("round_config")
	RoundManager.round_state.advance(config.first_order_delay)
	assert_eq(OrderService.get_active_orders().size(), 1, "una comanda activa")


func _on_rejected(reason: SeasoningRules.Rejection, part: StringName) -> void:
	_rejections.append("%s:%d" % [part, reason])


func _controls() -> TouchControls:
	return _level.get_node("UI/TouchControls") as TouchControls


func _character(index: int) -> Player:
	return _level.get_node("Characters/Player%d" % index) as Player


func _controlled_by(index: int) -> int:
	return (_character(index).get_node("%Control") as ControlComponent).controlled_by


func _stations(path: String) -> Node3D:
	return _level.get_node("Stations/" + path) as Node3D


func _xz(node: Node3D) -> Vector2:
	return Walker.xz(node.global_position)


func _held(walker: TouchWalker) -> Node:
	return walker.holder().get_held_item()


## Estación del mostrador trasero, usada de frente desde la cocina.
func _use_back(walker: TouchWalker, path: String) -> Node:
	var at: Vector2 = _xz(_stations(path))
	return await walker.use(at, at + Vector2(0.0, BACK_ACCESS))


## Pieza de la estación de condimentos usada de frente por un lado (−1 pase, +1 condimentar).
func _use_station(walker: TouchWalker, part: Node3D, side: float) -> Node:
	var at: Vector2 = _xz(part)
	return await walker.use(at, Walker.station_stand(at, _station.global_position.z, side))


## Cambia de personaje con el botón de cambiar y comprueba que el control pasó.
func _switch(walker: TouchWalker, to_player: int) -> void:
	await walker.tap(KEY_Q)
	await wait_seconds(SWITCH_WAIT)
	assert_eq(_controlled_by(to_player), 1, "el control pasa al personaje %d" % to_player)


func _dispenser(seasoning: SeasoningData) -> SeasoningDispenser:
	for child: Node in _station.get_node("Dispensers").get_children():
		if (child as SeasoningDispenser).seasoning.same_as(seasoning):
			return child as SeasoningDispenser
	return null


## Pausa con el botón de pausa y reanuda tocando «Reanudar» (un contacto de pantalla, que el motor
## emula como clic).
func _pause_and_resume(walker: TouchWalker) -> void:
	walker.touch(TouchWalker.SWITCH_FINGER, PAUSE_PX, true)
	await wait_process_frames(2)
	walker.touch(TouchWalker.SWITCH_FINGER, PAUSE_PX, false)
	await wait_process_frames(2)
	assert_true(get_tree().paused, "el botón de pausa pausa")
	var menu: Control = _level.get_node("UI/PauseMenu") as Control
	assert_true(menu.visible, "menú de pausa visible")
	var resume: Button = null
	for button: Node in menu.find_children("*", "Button", true, false):
		if (button as Button).is_visible_in_tree() and resume == null:
			resume = button as Button
	assert_not_null(resume, "botón de reanudar")
	var scale: float = get_tree().root.get_final_transform().get_scale().y
	# `Input.parse_input_event` entra como un evento del SO: en px de ventana, no en unidades.
	var center: Vector2 = resume.get_global_rect().get_center() * scale
	for pressed: bool in [true, false]:
		var event: InputEventScreenTouch = InputEventScreenTouch.new()
		event.index = 3
		event.position = center
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await wait_process_frames(2)
	assert_false(get_tree().paused, "tocar «Reanudar» reanuda")


func test_ac2_single_player_cooks_cuts_seasons_and_delivers_with_touch_only() -> void:
	await _load_level()
	assert_eq(GameState.platform, PlatformProfile.Kind.MOBILE, "perfil MOBILE (--touch)")
	assert_true(_controls().visible, "controles táctiles visibles")
	var cook: TouchWalker = TouchWalker.new(get_tree(), _character(2))
	var server: TouchWalker = TouchWalker.new(get_tree(), _character(1))
	assert_eq(_controlled_by(1), 1, "empieza J1 con el servidor")
	# Cambiar al cocinero (Player2) y probar pausa/reanudar con contactos de pantalla.
	await _switch(cook, 2)
	await _pause_and_resume(cook)
	# Cocinar: nevera con stick + acción a la vez, y a la olla.
	var fridge: Vector2 = _xz(_stations("OctopusStorage"))
	await cook.walk_to(fridge + Vector2(0.0, BACK_ACCESS))
	var both: bool = await cook.push_and_tap(fridge, 8)
	assert_true(both, "stick y acción a la vez (multitáctil)")
	var octopus: Ingredient = _held(cook) as Ingredient
	assert_not_null(octopus, "el pulpo está en la mano (cogido con el botón de acción)")
	assert_eq(await _use_back(cook, "Kitchen"), _stations("Kitchen"), "olla")
	assert_null(_held(cook), "pulpo en la olla (COCER)")
	var cooked: Callable = func() -> bool: return octopus.is_cooked()
	assert_true(await wait_until(cooked, octopus.data.cook_time + COOK_MARGIN), "cocido")
	assert_eq(await _use_back(cook, "Kitchen"), _stations("Kitchen"), "sacar el cocido")
	assert_eq(_held(cook), octopus, "pulpo cocido en la mano")
	# Servidor: caja del estante al pasaplatos por el lado de servicio.
	await _switch(cook, 1)
	var spawner: Node3D = null
	for child: Node in _stations("BoxShelf").get_children():
		if child is ItemSpawner and (child as ItemSpawner).data == BOX:
			spawner = child as Node3D
	assert_not_null(spawner, "plaza de la caja")
	var shelf: Vector2 = _xz(spawner)
	assert_eq(await server.use(shelf, shelf + Vector2(SHELF_ACCESS, 0.0)), spawner, "estantería")
	var box: Box = _held(server) as Box
	assert_not_null(box, "caja en la mano")
	var slot: Slot = _stations("PassSlot05") as Slot
	assert_eq(await _use_station(server, slot, 1.0), slot, "pasaplatos por el servicio")
	assert_eq(slot.get_item(), box, "caja en el pasaplatos (SOLTAR)")
	# Cocinero: 6 cortes manteniendo el botón de acción.
	await _switch(server, 2)
	var slot_at: Vector2 = _xz(slot)
	await cook.walk_to(Walker.station_stand(slot_at, _station.global_position.z, -1.0))
	await cook.face(slot_at)
	assert_eq(cook.detector().get_target(), box, "de cara a la caja del pasaplatos")
	var rejects_before: int = _blocked_responses()
	await cook.hold_interact(CUT_HOLD_S)
	assert_true(box.is_full(), "mantener el botón de acción corta hasta llenar la caja (6 cortes)")
	assert_eq(_blocked_responses(), rejects_before, "mantener no genera un 7.º corte rechazado")
	# Servidor: caja a la mano, aliño dulce y entrega por la zona.
	await _switch(cook, 1)
	assert_eq(await _use_station(server, slot, 1.0), box, "coge la caja llena")
	assert_eq(_held(server), box)
	var sweet: SeasoningDispenser = _dispenser(SWEET)
	assert_eq(await _use_station(server, sweet, 1.0), sweet, "dispensador dulce")
	assert_true(box.has_seasoning(SWEET), "caja con aliño dulce")
	var order: ActiveOrder = OrderService.get_active_orders()[0]
	await server.walk_into_zone(_stations("OrderStand%d" % order.slot_id))
	assert_signal_emit_count(EventBus, "order_completed", 1, "entrega por la zona")
	assert_null(_held(server), "mano vacía tras entregar")
	assert_eq(RoundManager.round_state.get_boxes_delivered(), 1)
	assert_signal_not_emitted(EventBus, "delivery_rejected")
	assert_signal_not_emitted(EventBus, "order_expired")
	assert_eq(_rejections, [] as Array[String], "sin pulsaciones de error en la estación")
	assert_eq(_probe.keys, 0, "ni una sola tecla: todo fue por pantalla")
	assert_gte(_probe.interact_presses, 8, "pulsaciones del botón de acción")
	assert_gte(_probe.switch_presses, 4, "pulsaciones del botón de cambiar")
	assert_gt(get_signal_emit_count(EventBus, "character_switched"), 4, "usa el cambio")


## Respuestas BLOQUEADAS de J1 desde el principio del test.
func _blocked_responses() -> int:
	var blocked: int = 0
	for i: int in get_signal_emit_count(EventBus, "interaction_resolved"):
		var args: Array = get_signal_parameters(EventBus, "interaction_resolved", i)
		if args[2] == int(ActionHint.State.BLOCKED):
			blocked += 1
	return blocked
