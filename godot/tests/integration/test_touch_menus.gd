extends GutTest
## PUL-122 AC6 (controles-tactiles AC18): en el perfil MOBILE los botones de menú, pausa y game
## over miden >= 120 px de alto con >= 24 px entre ellos (a 1080 de alto), reanudar tarda <= 0,1 s
## y el contenido respeta la safe area.

const MAIN_MENU: PackedScene = preload("res://ui/menus/main_menu.tscn")
const PAUSE: PackedScene = preload("res://ui/menus/pause_menu.tscn")
const GAME_OVER: PackedScene = preload("res://ui/menus/game_over.tscn")
const CONFIG: RoundConfig = preload("res://data/config/round_config.tres")
const REVENUE_THRESHOLDS: Array[int] = [30, 60, 90]

var _original_size: Vector2i
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
	_original_size = get_window().size
	GameState.set_platform(PlatformProfile.Kind.MOBILE)
	_state = add_child_autofree(SessionSpy.new())


func after_each() -> void:
	get_window().size = _original_size
	GameState.set_platform(PlatformProfile.Kind.DESKTOP)
	GameState.set_paused(false)


func _resize(resolution: Vector2i) -> float:
	get_window().size = resolution
	await wait_process_frames(3)
	return get_viewport().get_final_transform().get_scale().y


func _pause_menu() -> Control:
	var menu: Control = PAUSE.instantiate()
	menu.set_game_state(_state)
	add_child_autofree(menu)
	return menu


func _game_over() -> Control:
	var menu: Control = GAME_OVER.instantiate()
	menu.set_game_state(_state)
	add_child_autofree(menu)
	return menu


func _result() -> RoundResult:
	return RoundResult.new(
		120.0, 3, 90, CONFIG.performance_thresholds, CONFIG.performance_texts, REVENUE_THRESHOLDS
	)


func _visible_buttons(root: Node) -> Array[Button]:
	var buttons: Array[Button] = []
	for node: Node in root.find_children("*", "Button", true, false):
		if (node as Button).is_visible_in_tree():
			buttons.append(node as Button)
	buttons.sort_custom(_by_y)
	return buttons


func _by_y(a: Button, b: Button) -> bool:
	return a.global_position.y < b.global_position.y


func _assert_buttons(root: Node, stretch: float, label: String) -> void:
	var buttons: Array[Button] = _visible_buttons(root)
	assert_gt(buttons.size(), 0, label)
	var height_px: float = 120.0 * get_window().size.y / 1080.0
	var gap_px: float = 24.0 * get_window().size.y / 1080.0
	for i: int in buttons.size():
		var height: float = buttons[i].size.y * stretch
		assert_gte(height, height_px - 0.01, "%s: %s alto" % [label, buttons[i].name])
		if i > 0:
			var gap: float = (
				(buttons[i].get_global_rect().position.y - buttons[i - 1].get_global_rect().end.y)
				* stretch
			)
			assert_gte(gap, gap_px - 0.01, "%s: separación %s" % [label, buttons[i].name])


func _tap(action: StringName) -> void:
	for pressed: bool in [true, false]:
		var event: InputEventAction = InputEventAction.new()
		event.action = action
		event.pressed = pressed
		get_viewport().push_input(event)
		await get_tree().process_frame


func test_ac6_main_menu_button_is_120_px_at_2340x1080() -> void:
	var menu: Control = MAIN_MENU.instantiate()
	add_child_autofree(menu)
	var stretch: float = await _resize(Vector2i(2340, 1080))
	_assert_buttons(menu, stretch, "menú")


func test_ac6_pause_menu_buttons_are_120_px_and_24_px_apart() -> void:
	var menu: Control = _pause_menu()
	var stretch: float = await _resize(Vector2i(2340, 1080))
	GameState.set_paused(true)
	await wait_process_frames(2)
	assert_true(menu.visible)
	assert_eq(_visible_buttons(menu).size(), 3, "Reanudar, Reiniciar y Menú")
	_assert_buttons(menu, stretch, "pausa")


func test_ac6_game_over_buttons_are_120_px_and_24_px_apart() -> void:
	var menu: Control = _game_over()
	var stretch: float = await _resize(Vector2i(2340, 1080))
	EventBus.round_finished.emit(_result())
	await wait_process_frames(2)
	assert_true(menu.visible)
	assert_eq(_visible_buttons(menu).size(), 2, "Reintentar y Menú")
	_assert_buttons(menu, stretch, "game over")


func test_ac6_buttons_keep_the_proportion_at_1600x720() -> void:
	var menu: Control = _pause_menu()
	var stretch: float = await _resize(Vector2i(1600, 720))
	GameState.set_paused(true)
	await wait_process_frames(2)
	_assert_buttons(menu, stretch, "pausa 720")


func test_ac6_resume_unpauses_within_100_ms() -> void:
	var menu: Control = PAUSE.instantiate()
	add_child_autofree(menu)
	await _resize(Vector2i(2340, 1080))
	GameState.set_paused(true)
	await wait_process_frames(2)
	var started: int = Time.get_ticks_msec()
	(menu.get_node("%MenuPanel") as MenuPanel).primary_button.pressed.emit()
	assert_false(get_tree().paused)
	assert_lte(Time.get_ticks_msec() - started, 100)
	assert_false(menu.visible)


func test_ac6_pause_restart_button_restarts_and_exit_goes_to_menu() -> void:
	var menu: Control = _pause_menu()
	GameState.set_paused(true)
	await wait_process_frames(2)
	var panel: MenuPanel = menu.get_node("%MenuPanel")
	assert_true(panel.restart_button.visible)
	assert_eq(panel.restart_button.text, "Reiniciar")
	assert_eq(panel.exit_button.text, "Menú")
	panel.restart_button.pressed.emit()
	assert_eq(_state.restarts, 1)
	GameState.set_paused(true)
	await wait_process_frames(2)
	panel.exit_button.pressed.emit()
	assert_eq(_state.exits, 1)


func test_ac6_pause_focus_cycles_through_three_buttons_with_nav_actions() -> void:
	var menu: Control = _pause_menu()
	GameState.set_paused(true)
	await wait_process_frames(2)
	var panel: MenuPanel = menu.get_node("%MenuPanel")
	assert_eq(get_viewport().gui_get_focus_owner(), panel.primary_button)
	var order: Array[Button] = [panel.primary_button, panel.restart_button, panel.exit_button]
	for i: int in range(1, 4):
		await _tap(&"ui_down")
		assert_eq(get_viewport().gui_get_focus_owner(), order[i % 3], "abajo %d" % i)
	for i: int in range(1, 4):
		await _tap(&"ui_up")
		assert_eq(get_viewport().gui_get_focus_owner(), order[(3 - i) % 3], "arriba %d" % i)


func test_ac6_content_respects_the_safe_area_at_2340x1080() -> void:
	var menu: Control = MAIN_MENU.instantiate()
	add_child_autofree(menu)
	var stretch: float = await _resize(Vector2i(2340, 1080))
	var safe: SafeAreaMargin = menu.get_node("SafeArea")
	safe.set_safe_rect(Rect2(132, 0, 2340 - 132 - 132, 1080 - 63), Vector2(2340, 1080))
	await wait_process_frames(2)
	assert_almost_eq(safe.get_theme_constant(&"margin_left") * stretch, 132.0, 1.0)
	assert_almost_eq(safe.get_theme_constant(&"margin_right") * stretch, 132.0, 1.0)
	assert_almost_eq(safe.get_theme_constant(&"margin_bottom") * stretch, 63.0, 1.0)
	assert_eq(safe.get_theme_constant(&"margin_top"), 0)
	var column: Control = menu.get_node("%Column")
	var bottom_limit: float = menu.size.y - safe.get_theme_constant(&"margin_bottom")
	assert_lte(column.get_global_rect().end.y, bottom_limit + 0.5)


func test_ac6_cards_fit_in_the_canvas_at_2340x1080() -> void:
	var pause: Control = _pause_menu()
	var game_over: Control = _game_over()
	await _resize(Vector2i(2340, 1080))
	GameState.set_paused(true)
	await wait_process_frames(3)
	var canvas: Rect2 = get_viewport().get_visible_rect()
	var card: Control = pause.find_child("Card", true, false)
	assert_true(canvas.encloses(card.get_global_rect()), "pausa: %s" % card.get_global_rect())
	GameState.set_paused(false)
	EventBus.round_finished.emit(_result())
	await wait_process_frames(3)
	card = game_over.find_child("Card", true, false)
	assert_true(canvas.encloses(card.get_global_rect()), "game over: %s" % card.get_global_rect())
