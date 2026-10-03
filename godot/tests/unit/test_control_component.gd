extends GutTest
## PUL-011 AC2: ControlComponent emite control_changed y expone el PlayerInput correcto.

var _control: ControlComponent


func before_each() -> void:
	_control = add_child_autofree(ControlComponent.new())
	watch_signals(_control)


func test_ac2_m0_default_is_controlled_by_player_one() -> void:
	assert_eq(_control.controlled_by, 1)
	assert_eq(_control.get_player_input().player_index, 1)


func test_ac2_emits_control_changed_once_on_change() -> void:
	_control.controlled_by = 2
	assert_signal_emit_count(_control, "control_changed", 1)
	assert_signal_emitted_with_parameters(_control, "control_changed", [2])


func test_ac2_same_value_does_not_emit() -> void:
	_control.controlled_by = 1
	assert_signal_not_emitted(_control, "control_changed")


func test_ac2_exposes_input_of_controlling_player() -> void:
	_control.controlled_by = 2
	assert_eq(_control.get_player_input().player_index, 2)


func test_ac2_nobody_controls_has_no_input() -> void:
	_control.controlled_by = 0
	assert_null(_control.get_player_input())
	assert_signal_emit_count(_control, "control_changed", 1)


func test_ac2_player_index_is_identity_independent_of_controller() -> void:
	_control.player_index = 2
	_control.controlled_by = 1
	assert_eq(_control.player_index, 2)
	assert_eq(_control.get_player_input().player_index, 1)


func test_ac2_input_uses_config_deadzone() -> void:
	var config: InputConfig = InputConfig.new()
	config.deadzone = 0.6
	_control.config = config
	_control.controlled_by = 0
	_control.controlled_by = 1
	assert_eq(_control.get_player_input().deadzone, 0.6)
