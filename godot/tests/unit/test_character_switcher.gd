extends GutTest
## PUL-035 AC2/AC6/AC7: CharacterSwitcher sin escena, con dos ControlComponent sueltos y un bus
## propio. El cooldown avanza con `advance()` para no depender del reloj real.

const SWITCHER_SCENE: PackedScene = preload("res://entities/player/character_switcher.tscn")
const EventBusScript: GDScript = preload("res://autoload/event_bus.gd")

var _bus: Node
var _switcher: CharacterSwitcher
var _first: ControlComponent
var _second: ControlComponent


func before_each() -> void:
	_bus = autofree(EventBusScript.new())
	_first = add_child_autofree(_control(1))
	_second = add_child_autofree(_control(2))
	_switcher = SWITCHER_SCENE.instantiate()
	_switcher.set_bus(_bus)
	_switcher.set_mode(GameMode.Mode.SINGLE)
	_switcher.characters = [_first, _second]
	add_child_autofree(_switcher)
	watch_signals(_bus)


func _control(index: int) -> ControlComponent:
	var control: ControlComponent = ControlComponent.new()
	control.player_index = index
	return control


func _start_round() -> void:
	_bus.round_started.emit(180.0)


func _controlled_by_one() -> int:
	var count: int = 0
	for control: ControlComponent in [_first, _second]:
		if control.controlled_by == 1:
			count += 1
	return count


func _switches() -> int:
	return get_signal_emit_count(_bus, "character_switched")


func _switch_event() -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = &"p1_switch"
	event.pressed = true
	return event


func test_scene_uses_input_config_cooldown() -> void:
	assert_not_null(_switcher.config)
	assert_almost_eq(_switcher.config.switch_cooldown, 0.2, 0.0001)


func test_single_round_start_gives_player_one_the_first_character() -> void:
	_first.controlled_by = 0
	_second.controlled_by = 1
	_start_round()
	assert_eq(_first.controlled_by, 1)
	assert_eq(_second.controlled_by, 0)
	assert_signal_emit_count(_bus, "character_switched", 1)
	assert_signal_emitted_with_parameters(_bus, "character_switched", [1, 1])


func test_coop_round_start_assigns_one_and_two() -> void:
	_switcher.set_mode(GameMode.Mode.COOP_2P)
	_start_round()
	assert_eq(_first.controlled_by, 1)
	assert_eq(_second.controlled_by, 2)
	assert_signal_emit_count(_bus, "character_switched", 2)
	assert_signal_emitted_with_parameters(_bus, "character_switched", [1, 1], 0)
	assert_signal_emitted_with_parameters(_bus, "character_switched", [2, 2], 1)


func test_ac2_switch_passes_control_in_the_same_call() -> void:
	_start_round()
	assert_true(_switcher.switch_pressed())
	assert_eq(_first.controlled_by, 0)
	assert_eq(_second.controlled_by, 1)
	assert_not_null(_second.get_player_input(), "el nuevo ya lee input en este frame")


func test_ac2_switch_emits_character_switched_once() -> void:
	_start_round()
	var before: int = _switches()
	_switcher.switch_pressed()
	assert_eq(_switches() - before, 1)
	assert_signal_emitted_with_parameters(_bus, "character_switched", [1, 2])


func test_ac2_switch_action_event_switches() -> void:
	_start_round()
	_switcher._unhandled_input(_switch_event())
	assert_eq(_second.controlled_by, 1)


func test_ac2_switch_alternates_back_to_the_first() -> void:
	_start_round()
	_switcher.switch_pressed()
	_switcher.advance(0.2)
	_switcher.switch_pressed()
	assert_eq(_first.controlled_by, 1)
	assert_eq(_second.controlled_by, 0)


func test_ac2_respects_cooldown() -> void:
	_start_round()
	_switcher.switch_pressed()
	_switcher.advance(0.1)
	assert_false(_switcher.switch_pressed())
	assert_eq(_second.controlled_by, 1)
	_switcher.advance(0.1)
	assert_true(_switcher.switch_pressed())
	assert_eq(_first.controlled_by, 1)


func test_ac2_cooldown_comes_from_config() -> void:
	var config: InputConfig = InputConfig.new()
	config.switch_cooldown = 1.0
	_switcher.config = config
	_start_round()
	_switcher.switch_pressed()
	_switcher.advance(0.5)
	assert_false(_switcher.switch_pressed())


func test_ac6_ten_switches_in_two_seconds_keep_one_active() -> void:
	_start_round()
	var before: int = _switches()
	var switched: int = 0
	for i: int in 10:
		if _switcher.switch_pressed():
			switched += 1
		assert_eq(_controlled_by_one(), 1, "cambio %d" % i)
		_switcher.advance(0.2)
	assert_eq(switched, 10)
	assert_eq(_switches() - before, 10)
	assert_eq(_first.controlled_by, 1, "tras un número par de cambios vuelve al primero")


func test_ac6_spam_within_cooldown_keeps_one_active() -> void:
	_start_round()
	for i: int in 40:
		_switcher.switch_pressed()
		assert_eq(_controlled_by_one(), 1)
		_switcher.advance(0.05)


func test_ac7_coop_ignores_switch() -> void:
	_switcher.set_mode(GameMode.Mode.COOP_2P)
	_start_round()
	var before: int = _switches()
	assert_false(_switcher.switch_pressed())
	_switcher._unhandled_input(_switch_event())
	assert_eq(_first.controlled_by, 1)
	assert_eq(_second.controlled_by, 2)
	assert_eq(_switches(), before)


func test_ac7_no_switch_after_round_finished() -> void:
	_start_round()
	_bus.round_finished.emit(RoundResult.new())
	var before: int = _switches()
	assert_false(_switcher.switch_pressed())
	assert_eq(_first.controlled_by, 1)
	assert_eq(_second.controlled_by, 0)
	assert_eq(_switches(), before)


func test_no_switch_before_round_started() -> void:
	assert_false(_switcher.switch_pressed())
	assert_signal_not_emitted(_bus, "character_switched")
