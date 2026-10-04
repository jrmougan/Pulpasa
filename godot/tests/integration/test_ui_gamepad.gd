extends GutTest
## PUL-036: menú, pausa y game over se completan solo con eventos de mando.

const MAIN_MENU: PackedScene = preload("res://ui/menus/main_menu.tscn")
const PAUSE: PackedScene = preload("res://ui/menus/pause_menu.tscn")
const GAME_OVER: PackedScene = preload("res://ui/menus/game_over.tscn")

var _state: SessionSpy


class SessionSpy:
	extends Node
	var exits: int = 0
	var restarts: int = 0

	func set_paused(paused: bool) -> void:
		GameState.set_paused(paused)

	func go_to_main_menu() -> Error:
		exits += 1
		set_paused(false)
		return OK

	func restart_level() -> Error:
		restarts += 1
		set_paused(false)
		return OK


func before_each() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_state = add_child_autofree(SessionSpy.new())


func after_each() -> void:
	GameState.set_paused(false)


func test_ac2_main_menu_three_options_reachable_with_joypad() -> void:
	var modes: Array[GameMode.Mode] = []
	var quits: Array[int] = [0]
	var menu: Control = MAIN_MENU.instantiate()
	menu.set_actions(
		func(mode: GameMode.Mode) -> Error:
			modes.append(mode)
			return ERR_FILE_NOT_FOUND,
		func() -> void: quits[0] += 1
	)
	add_child_autofree(menu)
	await get_tree().process_frame
	assert_eq(get_viewport().gui_get_focus_owner(), menu.get_node("%Play"))
	await _joypad(JOY_BUTTON_A)
	assert_eq(modes, [GameMode.Mode.SINGLE] as Array[GameMode.Mode])
	await _joypad(JOY_BUTTON_DPAD_DOWN)
	assert_eq(get_viewport().gui_get_focus_owner(), menu.get_node("%Local2P"))
	await _joypad(JOY_BUTTON_A)
	assert_eq(modes[1], GameMode.Mode.COOP_2P)
	await _joypad(JOY_BUTTON_DPAD_DOWN)
	assert_eq(get_viewport().gui_get_focus_owner(), menu.get_node("%Exit"))
	await _joypad(JOY_BUTTON_A)
	assert_eq(quits[0], 1)


func test_ac4_pause_focuses_button_and_completes_with_joypad() -> void:
	var menu: PauseMenu = PAUSE.instantiate()
	menu.set_game_state(_state)
	add_child_autofree(menu)
	await get_tree().process_frame
	await _joypad(JOY_BUTTON_START)
	assert_true(menu.visible)
	assert_eq(get_viewport().gui_get_focus_owner(), menu.panel.primary_button)
	await _joypad(JOY_BUTTON_DPAD_DOWN)
	assert_eq(get_viewport().gui_get_focus_owner(), menu.panel.exit_button)
	await _joypad(JOY_BUTTON_A)
	assert_eq(_state.exits, 1)


func test_ac4_game_over_retry_and_exit_with_joypad() -> void:
	var menu: GameOver = GAME_OVER.instantiate()
	menu.set_game_state(_state)
	add_child_autofree(menu)
	await get_tree().process_frame
	EventBus.round_finished.emit(RoundResult.new())
	assert_true(menu.visible)
	assert_eq(get_viewport().gui_get_focus_owner(), menu.panel.primary_button)
	await _joypad(JOY_BUTTON_A)
	assert_eq(_state.restarts, 1)
	await _joypad(JOY_BUTTON_DPAD_DOWN)
	assert_eq(get_viewport().gui_get_focus_owner(), menu.panel.exit_button)
	await _joypad(JOY_BUTTON_A)
	assert_eq(_state.exits, 1)


func _joypad(button: JoyButton) -> void:
	for pressed: bool in [true, false]:
		var event: InputEventJoypadButton = InputEventJoypadButton.new()
		event.device = 0
		event.button_index = button
		event.pressed = pressed
		Input.parse_input_event(event)
		await get_tree().process_frame
