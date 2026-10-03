extends GutTest
## PUL-004 AC2: GameState gestiona la pausa y el modo de juego.

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
