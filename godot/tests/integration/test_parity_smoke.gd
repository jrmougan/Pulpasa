extends GutTest
## PUL-025: smoke checklist de paridad M0 (`docs/design/features/paridad-unity.md`, AC1–AC6) sobre
## el proyecto real: menú principal → «Jugar» → `level_01.tscn` con los autoloads de verdad.
##
## Cada pulsación de interactuar pasa por `InteractionComponent.interact_pressed()` con el objetivo
## que publicaría el detector (`target_changed`), como en `test_kitchen_flow.gd`. El detector del
## jugador se congela para que no cambie de objetivo por su cuenta; el jugador no se mueve (el
## recorrido físico hasta cada puesto ya lo cubre `test_level_01.gd` AC4).

const MENU_SCENE: String = "res://ui/menus/main_menu.tscn"
const LEVEL_SCENE: String = "res://scenes/levels/level_01.tscn"
const ROUND_CONFIG: RoundConfig = preload("res://data/config/round_config.tres")
## AC1: del arranque al menú.
const MENU_BUDGET_MS: int = 5000
const STAND_COUNT: int = 4
## AC4: entregas seguidas.
const DELIVERIES: int = 20
## AC5: tolerancia de la pausa y tiempo real que se deja pasar en pausa.
const PAUSE_TOLERANCE: float = 0.05
const PAUSE_SECONDS: float = 0.5
## Margen sobre `cook_time` para esperar la cocción.
const COOK_MARGIN: float = 3.0
const SPICE_JARS: int = 4

var _level: Node
var _menu: Node


func before_each() -> void:
	GameState.set_paused(false)


func after_each() -> void:
	GameState.set_paused(false)
	if is_instance_valid(_menu):
		_menu.free()
	_menu = null
	if is_instance_valid(_level):
		var was_current: bool = _level == get_tree().current_scene
		_level.free()
		if was_current:
			get_tree().current_scene = null
	_level = null


# --- Utilidades --------------------------------------------------------------------------------


## Espera a que `change_scene_to_file` deje una escena actual nueva y lista; la devuelve.
func _await_new_scene(previous: Node) -> Node:
	for _i: int in 120:
		await get_tree().process_frame
		var current: Node = get_tree().current_scene
		if current != null and current != previous and current.is_node_ready():
			break
	await wait_physics_frames(2)
	_level = get_tree().current_scene
	return _level


## Menú principal → «Jugar» con la acción `ui_accept` sobre el foco inicial → nivel cargado.
func _play_from_menu() -> Node:
	_menu = (load(MENU_SCENE) as PackedScene).instantiate()
	add_child(_menu)
	await get_tree().process_frame
	var previous: Node = get_tree().current_scene
	await _tap(&"ui_accept")
	await _await_new_scene(previous)
	_menu.free()
	_menu = null
	_freeze_detector()
	return _level


func _tap(action: StringName) -> void:
	for pressed: bool in [true, false]:
		var event: InputEventAction = InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
		await get_tree().process_frame


func _player() -> Player:
	return _level.get_node("Characters/Player1") as Player


func _hold() -> Holder:
	return _player().get_node("%HoldComponent") as Holder


func _kitchen() -> CookingStation:
	return _level.get_node("Stations/Kitchen") as CookingStation


func _freeze_detector() -> void:
	_player().get_node("%InteractionDetector").set_physics_process(false)


## Una pulsación de interactuar con `target` delante (`null` = nada: suelta lo que lleva).
func _press(target: Node) -> bool:
	_player().get_node("%InteractionDetector").emit_signal(&"target_changed", null, target)
	return (_player().get_node("%InteractionComponent") as InteractionComponent).interact_pressed()


func _stand(slot_id: int) -> OrderStand:
	return _level.get_node("Stations/OrderStand%d" % slot_id) as OrderStand


func _order_for(slot_id: int) -> ActiveOrder:
	for order: ActiveOrder in OrderService.get_active_orders():
		if order.slot_id == slot_id:
			return order
	return null


func _box_spawner(box_data: BoxData) -> ItemSpawner:
	for child: Node in _level.get_node("Stations/BoxShelf").get_children():
		if child is ItemSpawner and (child as ItemSpawner).data == box_data:
			return child
	return null


func _spice_slot(seasoning: SeasoningData) -> Slot:
	for child: Node in _level.get_node("Stations/SpiceShelf").get_children():
		var slot: Slot = child as Slot
		if slot != null and slot.get_item() is SeasoningItem:
			if (slot.get_item() as SeasoningItem).data == seasoning:
				return slot
	return null


func _released(node: Variant) -> bool:
	return not is_instance_valid(node) or (node as Node).is_queued_for_deletion()


## Nodos vivos de `type` en todo el nivel (cajas, pulpos, botes).
func _alive(type: String) -> Array[Node]:
	var alive: Array[Node] = []
	for node: Node in _level.find_children("*", type, true, false):
		if not node.is_queued_for_deletion():
			alive.append(node)
	return alive


## Deja en la mano un pulpo cocido: el sobrante del suelo si queda, o uno nuevo de la nevera
## cocido en la olla (`leftover` nulo). Devuelve el pulpo.
func _cooked_octopus(leftover: Ingredient) -> Ingredient:
	if leftover != null:
		assert_true(_press(leftover), "recoge el pulpo sobrante")
		return leftover
	assert_true(_press(_level.get_node("Stations/OctopusStorage")), "nevera: da un pulpo")
	var octopus: Ingredient = _hold().get_held_item() as Ingredient
	assert_not_null(octopus)
	assert_true(_press(_kitchen()), "olla: acepta el pulpo crudo")
	assert_true(_kitchen().is_cooking())
	await wait_for_signal(_kitchen().cooking_finished, octopus.data.cook_time + COOK_MARGIN)
	assert_true(octopus.is_cooked(), "cocido tras cook_time")
	assert_true(_press(_kitchen()), "olla: devuelve el pulpo cocido")
	assert_eq(_hold().get_held_item(), octopus)
	return octopus


## Flujo completo para la comanda del puesto `slot_id`: caja de la estantería al suelo, pulpo
## cocido, cortes hasta llenarla, condimentos de la comanda y entrega. Devuelve el pulpo que
## sobra en el suelo, o `null` si se gastó entero.
func _serve(slot_id: int, leftover: Ingredient) -> Ingredient:
	var order: ActiveOrder = _order_for(slot_id)
	assert_not_null(order, "el puesto %d tiene comanda" % slot_id)
	var spawner: ItemSpawner = _box_spawner(order.data.recipe.box)
	assert_not_null(spawner, "hay estantería para la caja de la comanda")
	assert_true(_press(spawner), "estantería: da la caja")
	var box: Box = _hold().get_held_item() as Box
	assert_not_null(box)
	assert_not_null(_press(null), "suelta la caja delante")
	assert_null(_hold().get_held_item())

	var octopus: Ingredient = leftover
	var presses: int = 0
	while not box.is_full() and presses < 100:
		if _released(octopus):
			octopus = null
		if octopus == null or _hold().get_held_item() != octopus:
			octopus = await _cooked_octopus(octopus)
		assert_true(_press(box), "corte")
		presses += 1
	assert_true(box.is_full(), "caja llena tras %d cortes" % presses)
	if _released(octopus):
		octopus = null
	else:
		_press(null)
	assert_null(_hold().get_held_item())

	for seasoning: SeasoningData in order.data.seasonings:
		var jar_slot: Slot = _spice_slot(seasoning)
		assert_not_null(jar_slot, "estantería de %s" % seasoning.resource_path)
		assert_true(_press(jar_slot.get_item()), "coge el bote")
		assert_true(_press(box), "condimenta la caja")
		assert_true(_press(jar_slot), "devuelve el bote")
	assert_true(_press(box), "coge la caja")
	assert_eq(_hold().get_held_item(), box)
	assert_true(_press(_stand(slot_id)), "puesto %d: entrega" % slot_id)
	assert_true(_released(box), "la caja entregada se libera")
	assert_null(_hold().get_held_item())
	# El puesto ignora dos intentos con la misma caja en un tick; deja pasar uno.
	await wait_physics_frames(1)
	return octopus


## Ids de las comandas activas, por puesto (el servicio devuelve copias).
func _order_ids() -> Array[int]:
	var ids: Array[int] = []
	for slot_id: int in range(1, STAND_COUNT + 1):
		var order: ActiveOrder = _order_for(slot_id)
		ids.append(order.id if order != null else -1)
	return ids


func _assert_every_stand_has_its_order() -> void:
	var orders: Array[ActiveOrder] = OrderService.get_active_orders()
	assert_eq(orders.size(), STAND_COUNT, "una comanda por puesto")
	var ids: Dictionary[int, bool] = {}
	for slot_id: int in range(1, STAND_COUNT + 1):
		var order: ActiveOrder = _order_for(slot_id)
		assert_not_null(order, "puesto %d con comanda" % slot_id)
		if order == null:
			continue
		ids[order.id] = true
		var label: Label3D = _stand(slot_id).get_node("%OrderLabel")
		assert_eq(label.text, "#%d" % order.id, "etiqueta del puesto %d" % slot_id)
	assert_eq(ids.size(), STAND_COUNT, "sin comandas repetidas")


# --- AC1 ---------------------------------------------------------------------------------------


func test_ac1_main_scene_is_menu_and_loads_under_budget_without_errors() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), MENU_SCENE)
	var start: int = Time.get_ticks_msec()
	_menu = (load(MENU_SCENE) as PackedScene).instantiate()
	add_child(_menu)
	await get_tree().process_frame
	var elapsed: int = Time.get_ticks_msec() - start
	assert_lt(elapsed, MENU_BUDGET_MS, "menú listo en %d ms" % elapsed)
	var play: Button = _menu.get_node("%Play")
	assert_true(play.visible and not play.disabled)
	assert_eq(_menu.get_viewport().gui_get_focus_owner(), play, "foco inicial en Jugar")
	assert_eq(get_errors().size(), 0, "sin errores en consola")


# --- AC2 ---------------------------------------------------------------------------------------


func test_ac2_play_loads_level_with_one_controllable_player() -> void:
	await _play_from_menu()
	assert_eq(_level.scene_file_path, LEVEL_SCENE)
	assert_eq(GameState.mode, GameMode.Mode.SINGLE)
	var players: Array[Node] = _level.get_node("Characters").get_children()
	assert_eq(players.size(), 1, "un solo personaje")
	var control: ControlComponent = _player().get_node("%Control")
	assert_eq(control.controlled_by, 1, "controlado por el jugador 1")
	assert_true(RoundManager.round_state.is_running(), "la ronda arranca con el nivel")
	assert_almost_eq(RoundManager.round_state.get_time_left(), ROUND_CONFIG.duration, 0.1)
	_assert_every_stand_has_its_order()
	assert_eq(get_errors().size(), 0, "sin errores en consola")


# --- AC3 ---------------------------------------------------------------------------------------


func test_ac3_full_flow_completes_one_order_and_adds_exactly_one() -> void:
	await _play_from_menu()
	watch_signals(EventBus)
	var slot_id: int = 1
	for candidate: int in range(1, STAND_COUNT + 1):
		if _order_for(candidate).data.seasonings.size() > 0:
			slot_id = candidate
			break
	var order: ActiveOrder = _order_for(slot_id)
	assert_gt(order.data.seasonings.size(), 0, "comanda con condimentos: flujo completo")
	var others: Dictionary[int, ActiveOrder] = {}
	for other: int in range(1, STAND_COUNT + 1):
		if other != slot_id:
			others[other] = _order_for(other)

	await _serve(slot_id, null)
	assert_signal_emit_count(EventBus, "order_completed", 1)
	assert_signal_not_emitted(EventBus, "delivery_rejected")
	var completed: ActiveOrder = get_signal_parameters(EventBus, "order_completed", 0)[0]
	assert_eq(completed.id, order.id, "se completa la comanda entregada")
	assert_eq(RoundManager.round_state.get_boxes_delivered(), 1, "+1 exacto")
	assert_eq(get_signal_parameters(EventBus, "score_changed")[0], 1)
	var hud_rate: Label = _level.get_node("UI/HUD/%BoxesPerMinute")
	assert_ne(hud_rate.text, "0.00", "el HUD cuenta la entrega")
	assert_ne(_order_for(slot_id).id, order.id, "el puesto recibe comanda nueva")
	for other: int in others:
		assert_eq(_order_for(other).id, others[other].id, "el puesto %d no cambia" % other)
	await wait_physics_frames(5)
	assert_signal_emit_count(EventBus, "order_completed", 1, "una sola vez, también después")
	_assert_every_stand_has_its_order()


# --- AC4 ---------------------------------------------------------------------------------------


func test_ac4_twenty_deliveries_leave_no_empty_stands_duplicates_or_ghosts() -> void:
	await _play_from_menu()
	watch_signals(EventBus)
	var leftover: Ingredient = null
	for i: int in DELIVERIES:
		leftover = await _serve(i % STAND_COUNT + 1, leftover)
		assert_eq(get_signal_emit_count(EventBus, "order_completed"), i + 1, "entrega %d" % (i + 1))
		assert_eq(OrderService.get_active_orders().size(), STAND_COUNT, "tras entrega %d" % (i + 1))
	assert_true(RoundManager.round_state.is_running(), "las 20 entregas caben en la ronda")
	assert_signal_emit_count(EventBus, "order_completed", DELIVERIES)
	assert_signal_not_emitted(EventBus, "delivery_rejected")
	assert_eq(RoundManager.round_state.get_boxes_delivered(), DELIVERIES)
	_assert_every_stand_has_its_order()
	await wait_physics_frames(5)

	assert_eq(_alive("Box").size(), 0, "sin cajas fantasma")
	assert_eq(_alive("Ingredient").size(), 0, "20 cajas = 10 pulpos exactos, sin sobrantes")
	assert_eq(_alive("SeasoningItem").size(), SPICE_JARS, "ni botes duplicados ni perdidos")
	var jars: Array[Node] = []
	for child: Node in _level.get_node("Stations/SpiceShelf").get_children():
		if child is Slot and (child as Slot).get_item() is SeasoningItem:
			jars.append((child as Slot).get_item())
	assert_eq(jars.size(), SPICE_JARS, "cada bote vuelve a su slot")
	assert_eq(_level.get_node("Items").get_child_count(), 0)
	assert_null(_hold().get_held_item())
	assert_false(_kitchen().is_cooking())
	assert_null(_kitchen().get_ingredient(), "olla libre")


# --- AC5 ---------------------------------------------------------------------------------------


func test_ac5_pause_and_resume_keeps_state_within_tolerance() -> void:
	await _play_from_menu()
	assert_true(_press(_level.get_node("Stations/OctopusStorage")))
	assert_true(_press(_kitchen()))
	await wait_physics_frames(30)
	var player: Player = _player()
	var orders: Array[int] = _order_ids()
	var time_before: float = RoundManager.round_state.get_time_left()
	# Progreso interno de la olla: no hay getter público y el AC pide estado idéntico.
	var cook_before: float = _kitchen().get(&"_elapsed")
	var position_before: Vector3 = player.global_position

	await _tap(&"pause")
	assert_true(get_tree().paused, "la acción pause congela el árbol")
	assert_true((_level.get_node("UI/PauseMenu") as Control).visible)
	await get_tree().create_timer(PAUSE_SECONDS, true).timeout
	assert_almost_eq(RoundManager.round_state.get_time_left(), time_before, PAUSE_TOLERANCE)
	assert_almost_eq(_kitchen().get(&"_elapsed") as float, cook_before, PAUSE_TOLERANCE)

	await _tap(&"pause")
	assert_false(get_tree().paused, "pause otra vez reanuda")
	assert_false((_level.get_node("UI/PauseMenu") as Control).visible)
	assert_almost_eq(RoundManager.round_state.get_time_left(), time_before, PAUSE_TOLERANCE)
	assert_almost_eq(_kitchen().get(&"_elapsed") as float, cook_before, PAUSE_TOLERANCE)
	assert_almost_eq(player.global_position, position_before, Vector3.ONE * PAUSE_TOLERANCE)
	assert_eq(_order_ids(), orders, "mismas comandas")
	assert_true(_kitchen().is_cooking(), "la olla sigue cociendo")

	await wait_physics_frames(30)
	assert_lt(RoundManager.round_state.get_time_left(), time_before, "el reloj sigue al reanudar")


# --- AC6 ---------------------------------------------------------------------------------------


func test_ac6_round_end_and_retry_reset_state() -> void:
	assert_eq(ROUND_CONFIG.duration, 180.0, "M0: ronda de 180 s")
	await _play_from_menu()
	watch_signals(EventBus)
	var old_level: Node = _level
	# Ensucia la ronda: una entrega y un pulpo en la olla.
	await _serve(1, null)
	assert_true(_press(_level.get_node("Stations/OctopusStorage")))
	assert_true(_press(_kitchen()))
	assert_eq(RoundManager.round_state.get_boxes_delivered(), 1)
	# Fin de partida: se agota el reloj único sin esperar 180 s reales.
	RoundManager.round_state.advance(RoundManager.round_state.get_time_left())
	await get_tree().process_frame
	assert_signal_emit_count(EventBus, "round_finished", 1)
	var game_over: GameOver = _level.get_node("UI/GameOver")
	assert_true(game_over.visible, "sale el game over")
	assert_false((_level.get_node("UI/PauseMenu") as Control).visible)
	var retry: Button = game_over.panel.primary_button
	assert_eq(retry.get_viewport().gui_get_focus_owner(), retry, "foco en Reintentar")

	var generated_before: int = get_signal_emit_count(EventBus, "order_generated")
	await _tap(&"ui_accept")
	await _await_new_scene(old_level)
	_freeze_detector()
	assert_ne(_level, old_level, "nivel nuevo")
	assert_eq(_level.scene_file_path, LEVEL_SCENE)
	assert_signal_emit_count(EventBus, "round_started", 1)
	assert_signal_emit_count(EventBus, "round_finished", 1, "Reintentar no vuelve a terminar")
	assert_almost_eq(RoundManager.round_state.get_time_left(), ROUND_CONFIG.duration, 0.1)
	assert_eq(RoundManager.round_state.get_boxes_delivered(), 0)
	assert_true(RoundManager.round_state.is_running())
	assert_signal_emit_count(EventBus, "orders_reset", 1, "tablero vaciado")
	assert_eq(
		get_signal_emit_count(EventBus, "order_generated") - generated_before,
		STAND_COUNT,
		"comandas nuevas en los 4 puestos"
	)
	_assert_every_stand_has_its_order()
	assert_false(_kitchen().is_cooking(), "olla libre")
	assert_null(_kitchen().get_ingredient())
	assert_eq(_alive("Box").size() + _alive("Ingredient").size(), 0)
	assert_false((_level.get_node("UI/GameOver") as Control).visible)
	assert_eq((_level.get_node("UI/HUD/%TimeLeft") as Label).text, "180.0s")
	assert_false(get_tree().paused)
