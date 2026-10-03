extends GutTest
## PUL-021: pausa real, foco y navegación sin ratón.

const MENU: PackedScene = preload("res://ui/menus/pause_menu.tscn")

var _menu: Control
var _state: SessionSpy


class SessionSpy:
	extends Node
	var exits: int = 0

	func set_paused(paused: bool) -> void:
		GameState.set_paused(paused)

	func go_to_main_menu() -> Error:
		exits += 1
		set_paused(false)
		return OK


func before_each() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_state = add_child_autofree(SessionSpy.new())
	_menu = MENU.instantiate()
	_menu.set_game_state(_state)
	add_child_autofree(_menu)
	await get_tree().process_frame


func after_each() -> void:
	GameState.set_paused(false)


func test_ac1_pause_freezes_tree_and_focuses_resume() -> void:
	var timer: Timer = Timer.new()
	timer.wait_time = 10.0
	timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child_autofree(timer)
	timer.start()
	await _tap("pause")
	assert_true(get_tree().paused)
	assert_true(_menu.visible)
	assert_eq(get_viewport().gui_get_focus_owner(), _menu.panel.primary_button)
	var remaining: float = timer.time_left
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(timer.time_left, remaining)
	await _tap("pause")
	assert_false(get_tree().paused)
	assert_false(_menu.visible)
	await get_tree().create_timer(0.05).timeout
	assert_lt(timer.time_left, remaining)


func test_ac1_ac3_ui_accept_resumes_and_focus_cycles() -> void:
	await _tap("pause")
	await _tap("ui_down")
	assert_eq(get_viewport().gui_get_focus_owner(), _menu.panel.exit_button)
	await _tap("ui_down")
	assert_eq(get_viewport().gui_get_focus_owner(), _menu.panel.primary_button)
	await _tap("ui_up")
	assert_eq(get_viewport().gui_get_focus_owner(), _menu.panel.exit_button)
	await _tap("ui_focus_next")
	assert_eq(get_viewport().gui_get_focus_owner(), _menu.panel.primary_button)
	await _tap("ui_accept")
	assert_false(_menu.visible)
	assert_false(get_tree().paused)


func test_ac1_external_pause_signal_and_round_end() -> void:
	GameState.set_paused(true)
	assert_true(_menu.visible)
	EventBus.round_finished.emit(RoundResult.new())
	assert_false(_menu.visible)
	await _tap("pause")
	assert_false(_menu.visible)
	GameState.set_paused(false)
	EventBus.round_started.emit(180.0)
	await _tap("pause")
	assert_true(_menu.visible)


func test_ac3_exit_calls_game_state_with_ui_actions() -> void:
	await _tap("pause")
	await _tap("ui_down")
	await _tap("ui_accept")
	assert_eq(_state.exits, 1)
	assert_false(get_tree().paused)


func test_ac3_joypad_start_dpad_and_accept() -> void:
	await _joypad_tap(JOY_BUTTON_START)
	assert_true(get_tree().paused)
	await _joypad_tap(JOY_BUTTON_DPAD_DOWN)
	assert_eq(get_viewport().gui_get_focus_owner(), _menu.panel.exit_button)
	await _joypad_tap(JOY_BUTTON_DPAD_UP)
	assert_eq(get_viewport().gui_get_focus_owner(), _menu.panel.primary_button)
	await _joypad_tap(JOY_BUTTON_A)
	assert_false(get_tree().paused)
	assert_false(_menu.visible)


func _joypad_tap(button: JoyButton) -> void:
	for pressed: bool in [true, false]:
		var event: InputEventJoypadButton = InputEventJoypadButton.new()
		event.device = 0
		event.button_index = button
		event.pressed = pressed
		Input.parse_input_event(event)
		await get_tree().process_frame


func _tap(action: String) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await get_tree().process_frame
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await get_tree().process_frame
