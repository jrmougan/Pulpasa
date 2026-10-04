extends GutTest
## PUL-022: entrada, órdenes únicas y navegación nativa del menú.

const MENU: PackedScene = preload("res://ui/menus/main_menu.tscn")

var _menu: Control
var _calls: Array[GameMode.Mode] = []
var _quit_calls: int = 0
var _result: Error = OK


func before_each() -> void:
	_calls.clear()
	_quit_calls = 0
	_result = OK
	_menu = MENU.instantiate()
	_menu.set_actions(_start_level, _quit)
	add_child_autofree(_menu)
	await get_tree().process_frame


func test_ac1_startup_scene_and_initial_focus() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), MENU.resource_path)
	assert_eq(_menu.get_viewport().gui_get_focus_owner(), _menu.get_node("%Play"))
	assert_eq(_menu.get_node("%Local2P").text, "Local 2P")
	assert_eq(_menu.get_node("%Play").text, "Individual")
	assert_eq(_menu.theme, load("res://ui/theme/default_theme.tres"))


func test_ac2_accept_starts_single_exactly_once() -> void:
	await _tap(&"ui_accept")
	assert_eq(_calls.size(), 1)
	assert_eq(_calls[0], GameMode.Mode.SINGLE)
	assert_eq(_quit_calls, 0)


func test_double_accept_starts_level_once() -> void:
	await _tap(&"ui_accept")
	await _tap(&"ui_accept")
	assert_eq(_calls.size(), 1)


func test_ac2_exit_invokes_tree_quit_action_once() -> void:
	await _tap(&"ui_down")
	await _tap(&"ui_down")
	await _tap(&"ui_accept")
	assert_eq(_quit_calls, 1)
	assert_eq(_calls.size(), 0)


func test_ac1_local_2p_starts_coop() -> void:
	await _tap(&"ui_down")
	await _tap(&"ui_accept")
	assert_eq(_calls, [GameMode.Mode.COOP_2P] as Array[GameMode.Mode])
	assert_eq(_quit_calls, 0)


func test_ac3_native_navigation_wraps_and_tabs() -> void:
	var order: Array[String] = ["%Play", "%Local2P", "%Exit"]
	for pair: Array in [[&"ui_down", &"ui_up"], [&"ui_focus_next", &"ui_focus_prev"]]:
		for i: int in range(1, 4):
			await _tap(pair[0])
			assert_eq(_focus(), _menu.get_node(order[i % 3]))
		for i: int in range(1, 4):
			await _tap(pair[1])
			assert_eq(_focus(), _menu.get_node(order[(3 - i) % 3]))


func _focus() -> Control:
	return _menu.get_viewport().gui_get_focus_owner()


func test_ac3_joypad_dpad_and_accept_use_native_actions() -> void:
	await _joypad(JOY_BUTTON_DPAD_DOWN)
	assert_eq(_focus(), _menu.get_node("%Local2P"))
	await _joypad(JOY_BUTTON_DPAD_UP)
	assert_eq(_focus(), _menu.get_node("%Play"))
	await _joypad(JOY_BUTTON_A)
	assert_eq(_calls.size(), 1)
	assert_eq(_calls[0], GameMode.Mode.SINGLE)


func test_missing_level_keeps_menu_usable() -> void:
	_result = ERR_FILE_NOT_FOUND
	await _tap(&"ui_accept")
	assert_eq(_calls.size(), 1)
	assert_false(_menu.get_node("%Play").disabled)
	assert_true(_menu.get_node("%Status").visible)
	assert_eq(_menu.get_viewport().gui_get_focus_owner(), _menu.get_node("%Play"))
	await _tap(&"ui_up")
	await _tap(&"ui_accept")
	assert_eq(_quit_calls, 1)


func _tap(action: StringName) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	_menu.get_viewport().push_input(event)
	await get_tree().process_frame
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	_menu.get_viewport().push_input(event)
	await get_tree().process_frame


func _start_level(mode: GameMode.Mode) -> Error:
	_calls.append(mode)
	return _result


func _quit() -> void:
	_quit_calls += 1


func _joypad(button: JoyButton) -> void:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	_menu.get_viewport().push_input(event)
	await get_tree().process_frame
	event = InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = false
	_menu.get_viewport().push_input(event)
	await get_tree().process_frame
