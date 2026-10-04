extends GutTest
## PUL-021: resultados del recurso de balance y apertura única por ronda.
## PUL-030: recaudación y 0–3 estrellas del RoundResult (AC2 de partida-5-min).

const MENU: PackedScene = preload("res://ui/menus/game_over.tscn")
const CONFIG: RoundConfig = preload("res://data/config/round_config.tres")
const STAR_FULL: Texture2D = preload("res://assets/textures/icons/star_full.svg")
const STAR_EMPTY: Texture2D = preload("res://assets/textures/icons/star_empty.svg")
const REVENUE_THRESHOLDS: Array[int] = [30, 60, 90]

var _menu: Control
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
	_menu = MENU.instantiate()
	_menu.set_game_state(_state)
	add_child_autofree(_menu)
	await get_tree().process_frame


func after_each() -> void:
	GameState.set_paused(false)


func test_ac2_all_four_performance_bands() -> void:
	assert_false(_menu.visible)
	for i: int in range(4):
		EventBus.round_started.emit(120.0)
		assert_false(_menu.visible)
		EventBus.round_finished.emit(_result(i * 2 + 1))
		assert_true(_menu.visible)
		assert_eq(_menu.panel.description.text, CONFIG.performance_texts[i])
		assert_eq(_menu.panel.ratio.text, "Rendimiento: %.2f cajas/minuto" % (i + 0.5))
		assert_eq(get_viewport().gui_get_focus_owner(), _menu.panel.primary_button)


func test_ac2_duplicate_finish_does_not_replace_result_or_steal_focus() -> void:
	EventBus.round_finished.emit(_result(1))
	_menu.panel.exit_button.grab_focus()
	EventBus.round_finished.emit(_result(7))
	assert_eq(_menu.panel.description.text, CONFIG.performance_texts[0])
	assert_eq(get_viewport().gui_get_focus_owner(), _menu.panel.exit_button)


func test_ac3_focus_navigation_while_paused() -> void:
	GameState.set_paused(true)
	EventBus.round_finished.emit(_result(5))
	await _tap("ui_down")
	assert_eq(get_viewport().gui_get_focus_owner(), _menu.panel.exit_button)
	await _tap("ui_up")
	assert_eq(get_viewport().gui_get_focus_owner(), _menu.panel.primary_button)
	await _tap("ui_focus_prev")
	assert_eq(get_viewport().gui_get_focus_owner(), _menu.panel.exit_button)


func test_ac3_exit_calls_game_state_with_ui_actions() -> void:
	EventBus.round_finished.emit(_result(3))
	await _tap("ui_down")
	await _tap("ui_accept")
	assert_eq(_state.exits, 1)
	assert_false(get_tree().paused)


func test_ac3_retry_calls_game_state_with_ui_accept() -> void:
	EventBus.round_finished.emit(_result(3))
	await _tap("ui_accept")
	assert_eq(_state.restarts, 1)


func _result(boxes: int) -> RoundResult:
	return RoundResult.new(120.0, boxes, 0, CONFIG.performance_thresholds, CONFIG.performance_texts)


func _result_with_revenue(revenue: int) -> RoundResult:
	return RoundResult.new(
		120.0,
		3,
		revenue,
		CONFIG.performance_thresholds,
		CONFIG.performance_texts,
		REVENUE_THRESHOLDS
	)


func _star_textures() -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for star: Node in (_menu.get_node("%Stars") as HBoxContainer).get_children():
		textures.append((star as TextureRect).texture)
	return textures


func test_ac2_partida5min_game_over_shows_revenue_and_stars() -> void:
	EventBus.round_finished.emit(_result_with_revenue(65))
	assert_true(_menu.visible)
	assert_eq((_menu.get_node("%Revenue") as Label).text, "Recaudación: 65 €")
	assert_eq(
		_star_textures(),
		[STAR_FULL, STAR_FULL, STAR_EMPTY] as Array[Texture2D],
		"65 € con umbrales 30/60/90: 2 estrellas"
	)


func test_ac2_partida5min_stars_cover_zero_to_three() -> void:
	var cases: Array[Array] = [
		[0, [STAR_EMPTY, STAR_EMPTY, STAR_EMPTY]],
		[30, [STAR_FULL, STAR_EMPTY, STAR_EMPTY]],
		[90, [STAR_FULL, STAR_FULL, STAR_FULL]],
	]
	for test_case: Array in cases:
		EventBus.round_started.emit(120.0)
		EventBus.round_finished.emit(_result_with_revenue(test_case[0] as int))
		assert_eq((_menu.get_node("%Revenue") as Label).text, "Recaudación: %d €" % test_case[0])
		assert_eq(_star_textures(), test_case[1] as Array[Texture2D])


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
