extends GutTest
## PUL-037: M2 sobre `level_01.tscn` real con los autoloads reales. Dos personajes y
## `CharacterSwitcher` en el nivel (scene-tree.md §2).
## - SINGLE: un jugador cambia de personaje con `p1_switch` y entrega con cada uno.
## - COOP_2P: cada jugador entrega con el suyo y la recaudación es la misma.
## - Dos mandos simulados: cada stick mueve solo a su personaje.
## - Menú → partida → game over → reintentar solo con eventos de mando.
##
## La entrega pasa por el input real (`p<n>_interact` → `InteractionComponent._unhandled_input`)
## con el objetivo que publicaría el detector (`target_changed`), como en `test_m1_flow.gd`.

const MENU_SCENE: String = "res://ui/menus/main_menu.tscn"
const LEVEL_SCENE: String = "res://scenes/levels/level_01.tscn"
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const CACHELOS_SCENE: PackedScene = preload("res://entities/items/cachelos.tscn")
## Frames de física con el stick pulsado.
const MOVE_FRAMES: int = 10
## Desplazamiento mínimo que cuenta como "se ha movido" (m).
const MOVED: float = 0.2

var _scene: Node
## Reloj de los dispensadores: cada pulsación avanza 1 s (antirrebote sin esperas reales).
var _now: float = 100.0


func before_each() -> void:
	GameState.set_paused(false)
	watch_signals(EventBus)


func after_each() -> void:
	_release_all()
	GameState.set_paused(false)
	GameState.reset_input()
	if is_instance_valid(_scene):
		var was_current: bool = _scene == get_tree().current_scene
		_scene.free()
		if was_current:
			get_tree().current_scene = null
	_scene = null


## Cambia de escena como el juego y devuelve la escena actual ya lista (ver `test_level_01.gd`).
func _enter(start: Callable) -> Node:
	var previous: Node = get_tree().current_scene
	assert_eq(start.call(), OK)
	await _wait_new_scene(previous.get_instance_id() if previous != null else 0)
	return _scene


## Espera a que `current_scene` sea otra escena (`previous_id`: id de la anterior; 0 si no había).
func _wait_new_scene(previous_id: int) -> void:
	for _i: int in 120:
		await wait_process_frames(1)
		var current: Node = get_tree().current_scene
		if current != null and current.get_instance_id() != previous_id and current.is_node_ready():
			break
	await wait_physics_frames(2)
	_scene = get_tree().current_scene


func _character(index: int) -> Player:
	return _scene.get_node("Characters/Player%d" % index) as Player


func _control(index: int) -> ControlComponent:
	return _character(index).get_node("%Control") as ControlComponent


func _stand(slot_id: int) -> OrderStand:
	return _scene.get_node("Stations/OrderStand%d" % slot_id) as OrderStand


func _order_for(slot_id: int) -> ActiveOrder:
	for order: ActiveOrder in OrderService.get_active_orders():
		if order.slot_id == slot_id:
			return order
	return null


## Primeras comandas: hasta `first_order_delay` (dato) no hay ninguna.
func _open_orders() -> void:
	var config: RoundConfig = _scene.get("round_config")
	RoundManager.round_state.advance(config.first_order_delay)
	assert_eq(OrderService.get_active_orders().size(), 4)


## Llena en la mano de `character` la caja que pide `order`: cortes reales y condimentos en los
## dispensadores de la estación del nivel (la caja pasa por la bandeja, PUL-061).
func _box_in_hand(character: Player, order: ActiveOrder) -> Box:
	var actor: InteractionComponent = character.get_node("%InteractionComponent")
	var hold: Holder = character.get_node("%HoldComponent")
	var box: Box = BOX_SCENE.instantiate()
	box.data = order.data.recipe.box
	_scene.add_child(box)
	var guard: int = 0
	while not box.is_full() and guard < 200:
		var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
		_scene.add_child(octopus)
		octopus.set_cooked()
		assert_true(hold.pick_up(octopus))
		while octopus.is_inside_tree() and not box.is_full() and guard < 200:
			assert_true(box.interact(actor))
			guard += 1
		if is_instance_valid(octopus):
			hold.drop()
			octopus.free()
	var station: SeasoningStation = _scene.get_node("Stations/SeasoningStation")
	assert_true(hold.pick_up(box))
	assert_true(station.get_tray().interact(actor), "caja a la bandeja")
	for seasoning: SeasoningData in order.data.seasonings:
		var dispenser: SeasoningDispenser = _dispenser(station, seasoning)
		if dispenser == null:
			_cachelos_from_bowl(station, actor)
		else:
			dispenser.clock = func() -> float: return _now
			assert_true(dispenser.interact(actor))
		_now += 1.0
		assert_true(box.has_seasoning(seasoning), "caja con %s" % seasoning.display_name)
	assert_true(station.get_tray().interact(actor), "caja de la bandeja a la mano")
	assert_eq(hold.get_held_item(), box)
	return box


## Cachelos cocidos al cuenco y, con la mano vacía, alterna cachelos en la caja de la bandeja.
func _cachelos_from_bowl(station: SeasoningStation, actor: InteractionComponent) -> void:
	var bowl: CachelosBowl = station.get_node("CachelosBowl")
	bowl.clock = func() -> float: return _now
	var cachelos: Ingredient = CACHELOS_SCENE.instantiate()
	_scene.add_child(cachelos)
	cachelos.state = IngredientData.CookingState.COOKED
	assert_true(actor.holder.pick_up(cachelos))
	assert_true(bowl.interact(actor), "cachelos al cuenco")
	_now += 1.0
	assert_true(bowl.interact(actor), "cachelos a la caja")


func _dispenser(station: SeasoningStation, seasoning: SeasoningData) -> SeasoningDispenser:
	for child: Node in station.get_node("Dispensers").get_children():
		if (child as SeasoningDispenser).seasoning.same_as(seasoning):
			return child as SeasoningDispenser
	return null


## Pone el puesto como objetivo del detector de `character` (lo que publicaría al acercarse).
func _aim(character: Player, target: Node) -> void:
	character.get_node("%InteractionDetector").emit_signal(&"target_changed", null, target)


func _key_event(keycode: Key, pressed: bool) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = pressed
	return event


## Pulsa y suelta una tecla por el viewport (llega a `_unhandled_input`).
func _tap_key(keycode: Key) -> void:
	get_viewport().push_input(_key_event(keycode, true))
	await wait_physics_frames(1)
	get_viewport().push_input(_key_event(keycode, false))
	await wait_physics_frames(1)


func _stick_x(device: int, value: float) -> void:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.device = device
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _joypad(button: JoyButton) -> void:
	for pressed: bool in [true, false]:
		var event: InputEventJoypadButton = InputEventJoypadButton.new()
		event.device = 0
		event.button_index = button
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await wait_process_frames(2)


func _release_all() -> void:
	for device: int in [0, 1]:
		_stick_x(device, 0.0)
	for keycode: Key in [KEY_D, KEY_RIGHT]:
		Input.parse_input_event(_key_event(keycode, false))
	Input.flush_buffered_events()


func _completed_id(index: int) -> int:
	return (get_signal_parameters(EventBus, "order_completed", index)[0] as ActiveOrder).id


## Recaudación de la última `score_changed` (la que pinta el HUD).
func _last_score_revenue() -> int:
	return get_signal_parameters(EventBus, "score_changed")[1] as int


# --- AC1: SINGLE ---------------------------------------------------------------------------------


func test_ac1_level_has_two_characters_and_switcher() -> void:
	await _enter(func() -> Error: return GameState.start_level(GameMode.Mode.SINGLE))
	assert_eq(_scene.get_node("Characters").get_child_count(), 2)
	assert_eq(_control(1).player_index, 1)
	assert_eq(_control(2).player_index, 2)
	var switcher: CharacterSwitcher = _scene.get_node("CharacterSwitcher")
	assert_eq(switcher.characters, [_control(1), _control(2)] as Array[ControlComponent])
	for index: int in [1, 2]:
		assert_eq(_character(index).items_root, _scene.get_node("Items"))
		assert_eq(_character(index).camera, _scene.get_node("CameraRig"))
	var gap: float = _character(1).global_position.distance_to(_character(2).global_position)
	assert_gt(gap, 2.0, "salidas separadas")


func test_ac1_single_switch_moves_and_delivers_with_each_character() -> void:
	await _enter(func() -> Error: return GameState.start_level(GameMode.Mode.SINGLE))
	_open_orders()
	var p1: Player = _character(1)
	var p2: Player = _character(2)
	assert_eq(_control(1).controlled_by, 1, "J1 empieza con el primero")
	assert_eq(_control(2).controlled_by, 0)
	assert_true(p1.get_node("%ActiveIndicator").visible)
	assert_false(p2.get_node("%ActiveIndicator").visible)

	# Entrega con el primero (tecla E = p1_interact).
	var first: ActiveOrder = _order_for(1)
	var box1: Box = _box_in_hand(p1, first)
	_aim(p1, _stand(1))
	await _tap_key(KEY_E)
	assert_signal_emit_count(EventBus, "order_completed", 1)
	assert_eq(_completed_id(0), first.id)
	assert_true(not is_instance_valid(box1) or box1.is_queued_for_deletion())

	# Cambio (tecla Q = p1_switch): J1 pasa al segundo.
	await _tap_key(KEY_Q)
	assert_signal_emitted_with_parameters(EventBus, "character_switched", [1, 2])
	assert_eq(_control(1).controlled_by, 0)
	assert_eq(_control(2).controlled_by, 1)
	assert_false(p1.get_node("%ActiveIndicator").visible)
	assert_true(p2.get_node("%ActiveIndicator").visible)

	# El input de J1 mueve ahora al segundo; el primero se queda quieto.
	var p1_start: Vector3 = p1.global_position
	var p2_start: Vector3 = p2.global_position
	Input.parse_input_event(_key_event(KEY_D, true))
	Input.flush_buffered_events()
	await wait_physics_frames(MOVE_FRAMES)
	Input.parse_input_event(_key_event(KEY_D, false))
	Input.flush_buffered_events()
	assert_gt(p2.global_position.x - p2_start.x, MOVED, "el segundo se mueve")
	assert_almost_eq(p1.global_position.distance_to(p1_start), 0.0, 0.01, "el primero, quieto")

	# Entrega con el segundo; el primero, sin jugador, ya no responde a E.
	var second: ActiveOrder = _order_for(2)
	var box_idle: Box = _box_in_hand(p1, _order_for(3))
	_aim(p1, _stand(3))
	var box2: Box = _box_in_hand(p2, second)
	_aim(p2, _stand(2))
	await _tap_key(KEY_E)
	assert_signal_emit_count(EventBus, "order_completed", 2)
	assert_eq(_completed_id(1), second.id)
	assert_true(not is_instance_valid(box2) or box2.is_queued_for_deletion())
	assert_eq(p1.get_node("%HoldComponent").get_held_item(), box_idle, "sin control no entrega")
	assert_eq(RoundManager.round_state.get_boxes_delivered(), 2)

	# Y vuelta al primero.
	await wait_physics_frames(roundi(0.3 * Engine.physics_ticks_per_second))
	await _tap_key(KEY_Q)
	assert_eq(_control(1).controlled_by, 1)
	assert_eq(_control(2).controlled_by, 0)


# --- AC2: COOP_2P --------------------------------------------------------------------------------


func test_ac2_coop_deliveries_of_both_players_share_revenue() -> void:
	await _enter(func() -> Error: return GameState.start_level(GameMode.Mode.COOP_2P))
	_open_orders()
	assert_eq(_control(1).controlled_by, 1)
	assert_eq(_control(2).controlled_by, 2)
	assert_true(_character(2).get_node("%ActiveIndicator").visible)

	var box1: Box = _box_in_hand(_character(1), _order_for(1))
	_aim(_character(1), _stand(1))
	await _tap_key(KEY_E)
	assert_signal_emit_count(EventBus, "order_completed", 1)
	var after_p1: int = RoundManager.round_state.get_revenue()
	assert_eq(_last_score_revenue(), after_p1)
	assert_gt(after_p1, 0)
	assert_true(not is_instance_valid(box1) or box1.is_queued_for_deletion())

	# J2 entrega con Intro (p2_interact): suma a la misma recaudación.
	var box2: Box = _box_in_hand(_character(2), _order_for(2))
	_aim(_character(2), _stand(2))
	await _tap_key(KEY_ENTER)
	assert_signal_emit_count(EventBus, "order_completed", 2)
	assert_true(not is_instance_valid(box2) or box2.is_queued_for_deletion())
	assert_eq(_last_score_revenue(), RoundManager.round_state.get_revenue(), "una sola recaudación")
	assert_gt(RoundManager.round_state.get_revenue(), after_p1, "J2 suma a la recaudación de J1")
	assert_eq(RoundManager.round_state.get_boxes_delivered(), 2)

	# p1_switch no hace nada en COOP_2P.
	await _tap_key(KEY_Q)
	assert_eq(_control(1).controlled_by, 1)
	assert_eq(_control(2).controlled_by, 2)


# --- AC3: dos mandos -----------------------------------------------------------------------------


func test_ac3_two_pads_each_moves_only_its_character() -> void:
	await _enter(func() -> Error: return GameState.start_level(GameMode.Mode.COOP_2P))
	# Sin mandos reales: el reparto de dos mandos conectados (0 y 1) como al arrancar.
	GameState.assign_devices(GameMode.Mode.COOP_2P, [0, 1] as Array[int])
	assert_eq(GameState.get_device(1), 0)
	assert_eq(GameState.get_device(2), 1)
	var p1: Player = _character(1)
	var p2: Player = _character(2)

	for pad: int in [0, 1]:
		var own: Player = p1 if pad == 0 else p2
		var other: Player = p2 if pad == 0 else p1
		var own_start: Vector3 = own.global_position
		var other_start: Vector3 = other.global_position
		_stick_x(pad, -1.0)
		await wait_physics_frames(MOVE_FRAMES)
		_stick_x(pad, 0.0)
		await wait_physics_frames(1)
		assert_lt(
			own.global_position.x - own_start.x, -MOVED, "mando %d mueve a su personaje" % pad
		)
		assert_almost_eq(
			other.global_position.distance_to(other_start),
			0.0,
			0.01,
			"mando %d no mueve al otro" % pad
		)


# --- AC4: menú → partida → game over → reintentar con mando ---------------------------------------


func test_ac4_menu_to_game_over_and_retry_with_joypad_only() -> void:
	await _enter(func() -> Error: return GameState.go_to_main_menu())
	assert_eq(_scene.scene_file_path, MENU_SCENE)
	await wait_process_frames(2)

	# Local 2P con la cruceta y A.
	var menu: Node = _scene
	var menu_id: int = menu.get_instance_id()
	await _joypad(JOY_BUTTON_DPAD_DOWN)
	assert_eq(_scene.get_viewport().gui_get_focus_owner(), menu.get_node("%Local2P"))
	await _joypad(JOY_BUTTON_A)
	await _wait_new_scene(menu_id)
	assert_eq(_scene.scene_file_path, LEVEL_SCENE, "A en Local 2P carga el nivel")
	assert_eq(GameState.mode, GameMode.Mode.COOP_2P)
	assert_signal_emit_count(EventBus, "round_started", 1)
	assert_eq(_control(2).controlled_by, 2)

	# Fin de ronda: game over con el foco en Reintentar.
	var config: RoundConfig = _scene.get("round_config")
	RoundManager.round_state.advance(config.duration + 1.0)
	assert_signal_emit_count(EventBus, "round_finished", 1)
	var game_over: GameOver = _scene.get_node("UI/GameOver")
	assert_true(game_over.visible)
	assert_eq(_scene.get_viewport().gui_get_focus_owner(), game_over.panel.primary_button)

	# A: reintentar con el mismo modo.
	var old_id: int = _scene.get_instance_id()
	await _joypad(JOY_BUTTON_A)
	await _wait_new_scene(old_id)
	assert_ne(_scene.get_instance_id(), old_id, "nivel nuevo")
	assert_eq(_scene.scene_file_path, LEVEL_SCENE)
	assert_false(get_tree().paused)
	assert_eq(GameState.mode, GameMode.Mode.COOP_2P)
	assert_signal_emit_count(EventBus, "round_started", 2)
	assert_false((_scene.get_node("UI/GameOver") as GameOver).visible)
	assert_eq(_control(1).controlled_by, 1)
	assert_eq(_control(2).controlled_by, 2)
