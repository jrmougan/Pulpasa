# gdlint: disable=max-public-methods
extends GutTest
## PUL-004 AC2: GameState gestiona la pausa y el modo de juego.
## PUL-034 AC3/AC5: hot-plug de mandos y zona muerta de InputConfig.

const EventBusScript: GDScript = preload("res://autoload/event_bus.gd")
const GameStateScript: GDScript = preload("res://autoload/game_state.gd")

var _bus: Node
var _state: Node


func before_each() -> void:
	_bus = add_child_autofree(EventBusScript.new())
	_state = GameStateScript.new()
	_state.set_bus(_bus)
	add_child_autofree(_state)
	watch_signals(_bus)


func after_each() -> void:
	get_tree().paused = false
	_state.reset_input()


func _pads(ids: Array) -> Array[int]:
	var out: Array[int] = []
	out.assign(ids)
	return out


func _stick_left(device: int) -> InputEventJoypadMotion:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.device = device
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = -1.0
	return event


func _key(physical_keycode: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = physical_keycode
	event.pressed = true
	return event


## COOP con teclado + mando 3 (J2) y la ronda en curso.
func _coop_round_with_p2_pad() -> void:
	_state.assign_devices(GameMode.Mode.COOP_2P, _pads([3]))
	_bus.round_started.emit(60.0)
	clear_signal_watcher()
	watch_signals(_bus)


func test_ac2_set_paused_true_pauses_tree_and_emits_once() -> void:
	_state.set_paused(true)
	assert_true(get_tree().paused)
	assert_signal_emit_count(_bus, "pause_changed", 1)
	assert_signal_emitted_with_parameters(_bus, "pause_changed", [true])


func test_ac2_set_paused_false_resumes_tree() -> void:
	_state.set_paused(true)
	_state.set_paused(false)
	assert_false(get_tree().paused)
	assert_signal_emit_count(_bus, "pause_changed", 2)
	assert_signal_emitted_with_parameters(_bus, "pause_changed", [false], 1)


func test_ac2_set_paused_without_change_does_not_emit() -> void:
	_state.set_paused(false)
	assert_signal_not_emitted(_bus, "pause_changed")
	_state.set_paused(true)
	_state.set_paused(true)
	assert_signal_emit_count(_bus, "pause_changed", 1)


func test_ac2_game_state_runs_while_paused() -> void:
	assert_eq(_state.process_mode, Node.PROCESS_MODE_ALWAYS)


func test_default_mode_is_single() -> void:
	assert_eq(_state.mode, GameMode.Mode.SINGLE)


func test_start_level_sets_mode_and_tolerates_missing_scene() -> void:
	if ResourceLoader.exists(_state.LEVEL_SCENE):
		pass_test("level_01.tscn ya existe: el cambio real se prueba en integración")
		return
	assert_eq(_state.start_level(GameMode.Mode.COOP_2P), ERR_FILE_NOT_FOUND)
	assert_eq(_state.mode, GameMode.Mode.COOP_2P)


func test_go_to_main_menu_tolerates_missing_scene() -> void:
	if ResourceLoader.exists(_state.MAIN_MENU_SCENE):
		pass_test("main_menu.tscn ya existe: el cambio real se prueba en integración")
		return
	assert_eq(_state.go_to_main_menu(), ERR_FILE_NOT_FOUND)


func test_start_level_unpauses() -> void:
	if ResourceLoader.exists(_state.LEVEL_SCENE):
		pass_test("level_01.tscn ya existe: el cambio real se prueba en integración")
		return
	_state.set_paused(true)
	_state.start_level(GameMode.Mode.SINGLE)
	assert_false(get_tree().paused)


func test_restart_level_unpauses() -> void:
	_state.set_paused(true)
	_state.mode = GameMode.Mode.COOP_2P
	var expected: Error = OK if ResourceLoader.exists(_state.LEVEL_SCENE) else ERR_FILE_NOT_FOUND
	assert_eq(_state.restart_level(), expected)
	assert_false(get_tree().paused)
	assert_eq(_state.mode, GameMode.Mode.COOP_2P, "restart conserva el modo")


func test_ac3_assign_devices_emits_device_assigned_per_player() -> void:
	_state.assign_devices(GameMode.Mode.COOP_2P, _pads([3]))
	assert_eq(_state.mode, GameMode.Mode.COOP_2P)
	assert_eq(_state.get_device(1), DeviceAssignment.NONE)
	assert_eq(_state.get_device(2), 3)
	assert_signal_emit_count(_bus, "device_assigned", 2)
	assert_signal_emitted_with_parameters(_bus, "device_assigned", [1, DeviceAssignment.NONE], 0)
	assert_signal_emitted_with_parameters(_bus, "device_assigned", [2, 3], 1)


func test_ac3_get_device_before_assignment_is_none() -> void:
	assert_eq(_state.get_device(1), DeviceAssignment.NONE)
	assert_eq(_state.get_device(3), DeviceAssignment.NONE)


func test_ac3_disconnecting_assigned_pad_in_round_pauses_and_emits_once() -> void:
	_coop_round_with_p2_pad()
	_state.handle_joy_connection(3, false)
	assert_true(get_tree().paused)
	assert_signal_emit_count(_bus, "device_disconnected", 1)
	assert_signal_emitted_with_parameters(_bus, "device_disconnected", [2])
	assert_signal_not_emitted(_bus, "device_assigned")
	assert_eq(_state.get_device(2), DeviceAssignment.NONE)
	_state.handle_joy_connection(3, false)
	assert_signal_emit_count(_bus, "device_disconnected", 1, "un mando ya quitado no repite")


func test_ac3_disconnected_player_keeps_keyboard_and_loses_pad() -> void:
	_coop_round_with_p2_pad()
	_state.handle_joy_connection(3, false)
	assert_true(InputMap.event_is_action(_key(KEY_LEFT), &"p2_move_left"))
	assert_false(InputMap.event_is_action(_stick_left(3), &"p2_move_left"))
	assert_false(InputMap.event_is_action(_stick_left(3), &"p1_move_left"), "J1 no gana el mando")


func test_ac3_disconnecting_unassigned_pad_does_nothing() -> void:
	_coop_round_with_p2_pad()
	_state.handle_joy_connection(5, false)
	assert_false(get_tree().paused)
	assert_signal_not_emitted(_bus, "device_disconnected")


func test_ac3_disconnection_outside_round_does_not_pause() -> void:
	_coop_round_with_p2_pad()
	_bus.round_finished.emit(RoundResult.new())
	_state.handle_joy_connection(3, false)
	assert_false(get_tree().paused)
	assert_signal_not_emitted(_bus, "device_disconnected")
	assert_signal_emitted_with_parameters(_bus, "device_assigned", [2, DeviceAssignment.NONE])


func test_ac3_reconnection_emits_device_assigned_and_returns_pad_to_p2() -> void:
	_coop_round_with_p2_pad()
	_state.handle_joy_connection(3, false)
	_state.handle_joy_connection(3, true)
	assert_signal_emit_count(_bus, "device_assigned", 1)
	assert_signal_emitted_with_parameters(_bus, "device_assigned", [2, 3])
	assert_eq(_state.get_device(1), DeviceAssignment.NONE, "nunca a ambos")
	assert_eq(_state.get_device(2), 3)
	assert_true(InputMap.event_is_action(_stick_left(3), &"p2_move_left"))
	assert_false(InputMap.event_is_action(_stick_left(3), &"p1_move_left"))


func test_ac3_new_pad_in_coop_goes_to_free_player() -> void:
	_coop_round_with_p2_pad()
	_state.handle_joy_connection(4, true)
	assert_signal_emitted_with_parameters(_bus, "device_assigned", [1, 4])
	assert_true(InputMap.event_is_action(_stick_left(4), &"p1_move_left"))
	assert_false(InputMap.event_is_action(_stick_left(4), &"p2_move_left"))


func test_ac3_single_pad_loss_in_round_pauses_and_keeps_any() -> void:
	_state.assign_devices(GameMode.Mode.SINGLE, _pads([0]))
	_bus.round_started.emit(60.0)
	_state.handle_joy_connection(0, false)  # en headless no queda ningún mando conectado
	assert_true(get_tree().paused)
	assert_signal_emitted_with_parameters(_bus, "device_disconnected", [1])
	assert_eq(_state.get_device(1), DeviceAssignment.ANY)


func test_ac3_hot_plug_before_any_assignment_is_ignored() -> void:
	_state.handle_joy_connection(0, true)
	_state.handle_joy_connection(0, false)
	assert_signal_not_emitted(_bus, "device_assigned")
	assert_signal_not_emitted(_bus, "device_disconnected")


func test_ac5_move_deadzone_comes_from_input_config() -> void:
	var config: InputConfig = load("res://data/config/input_config.tres")
	assert_almost_eq(config.deadzone, 0.2, 0.0001)
	for player: int in [1, 2]:
		for move: String in ["move_left", "move_right", "move_up", "move_down"]:
			var action: StringName = StringName("p%d_%s" % [player, move])
			assert_almost_eq(InputMap.action_get_deadzone(action), config.deadzone, 0.0001, action)
