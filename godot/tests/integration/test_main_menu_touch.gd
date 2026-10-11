extends GutTest
## PUL-122 AC4 (controles-tactiles AC1, menu-principal AC6): el menú en el perfil táctil.

const MENU: PackedScene = preload("res://ui/menus/main_menu.tscn")

var _menu: Control
var _calls: Array[GameMode.Mode] = []
var _quit_calls: int = 0


func after_each() -> void:
	GameState.set_platform(PlatformProfile.Kind.DESKTOP)


func _mount(kind: PlatformProfile.Kind) -> void:
	GameState.set_platform(kind)
	_menu = MENU.instantiate()
	_menu.set_actions(_start_level, _quit)
	add_child_autofree(_menu)
	await get_tree().process_frame


func _start_level(mode: GameMode.Mode) -> Error:
	_calls.append(mode)
	return OK


func _quit() -> void:
	_quit_calls += 1


func _tap(action: StringName) -> void:
	for pressed: bool in [true, false]:
		var event: InputEventAction = InputEventAction.new()
		event.action = action
		event.pressed = pressed
		_menu.get_viewport().push_input(event)
		await get_tree().process_frame


func test_touch_profile_shows_only_individual_with_focus() -> void:
	await _mount(PlatformProfile.Kind.MOBILE)
	assert_true((_menu.get_node("%Play") as Button).visible)
	assert_false((_menu.get_node("%Local2P") as Button).visible)
	assert_false((_menu.get_node("%Exit") as Button).visible)
	assert_false((_menu.get_node("%Mode") as Label).visible)
	assert_eq(_menu.get_viewport().gui_get_focus_owner(), _menu.get_node("%Play"))


func test_touch_profile_pressing_individual_starts_single() -> void:
	await _mount(PlatformProfile.Kind.MOBILE)
	(_menu.get_node("%Play") as Button).pressed.emit()
	assert_eq(_calls, [GameMode.Mode.SINGLE] as Array[GameMode.Mode])
	assert_eq(_quit_calls, 0)


func test_touch_profile_navigation_keeps_focus_on_individual() -> void:
	await _mount(PlatformProfile.Kind.MOBILE)
	for action: StringName in [&"ui_down", &"ui_up", &"ui_focus_next", &"ui_focus_prev"]:
		await _tap(action)
		assert_eq(_menu.get_viewport().gui_get_focus_owner(), _menu.get_node("%Play"), action)


func test_touch_profile_tap_with_screen_event_activates_individual() -> void:
	await _mount(PlatformProfile.Kind.MOBILE)
	var play: Button = _menu.get_node("%Play")
	var position: Vector2 = play.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var touch: InputEventMouseButton = InputEventMouseButton.new()
		touch.button_index = MOUSE_BUTTON_LEFT
		touch.pressed = pressed
		touch.position = position
		touch.global_position = position
		_menu.get_viewport().push_input(touch)
		await get_tree().process_frame
	assert_eq(_calls, [GameMode.Mode.SINGLE] as Array[GameMode.Mode])


func test_desktop_profile_keeps_three_buttons() -> void:
	await _mount(PlatformProfile.Kind.DESKTOP)
	for node_name: String in ["%Play", "%Local2P", "%Exit", "%Mode"]:
		assert_true((_menu.get_node(node_name) as Control).visible, node_name)
	assert_eq(_menu.get_viewport().gui_get_focus_owner(), _menu.get_node("%Play"))
