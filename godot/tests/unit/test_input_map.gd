extends GutTest
## PUL-004 AC3: el InputMap estático de project.godot sigue ADR-004 §1.
## PUL-034 AC4: toda acción p<n>_* y pause tiene binding de teclado y de mando.

## Plantilla de mando de ADR-004: device 0 para J1 y 1 para J2; teclado y globales, -1.
const ANY_DEVICE: int = -1
const P1_PAD: int = 0
const P2_PAD: int = 1

## acción -> [tecla física o KEY_NONE, botón de mando, eje (-1 = ninguno), valor del eje, device].
const BINDINGS: Dictionary = {
	"p1_move_left": [KEY_A, JOY_BUTTON_DPAD_LEFT, JOY_AXIS_LEFT_X, -1.0, P1_PAD],
	"p1_move_right": [KEY_D, JOY_BUTTON_DPAD_RIGHT, JOY_AXIS_LEFT_X, 1.0, P1_PAD],
	"p1_move_up": [KEY_W, JOY_BUTTON_DPAD_UP, JOY_AXIS_LEFT_Y, -1.0, P1_PAD],
	"p1_move_down": [KEY_S, JOY_BUTTON_DPAD_DOWN, JOY_AXIS_LEFT_Y, 1.0, P1_PAD],
	"p1_interact": [KEY_E, JOY_BUTTON_A, -1, 0.0, P1_PAD],
	"p1_switch": [KEY_Q, JOY_BUTTON_Y, -1, 0.0, P1_PAD],
	"p2_move_left": [KEY_LEFT, JOY_BUTTON_DPAD_LEFT, JOY_AXIS_LEFT_X, -1.0, P2_PAD],
	"p2_move_right": [KEY_RIGHT, JOY_BUTTON_DPAD_RIGHT, JOY_AXIS_LEFT_X, 1.0, P2_PAD],
	"p2_move_up": [KEY_UP, JOY_BUTTON_DPAD_UP, JOY_AXIS_LEFT_Y, -1.0, P2_PAD],
	"p2_move_down": [KEY_DOWN, JOY_BUTTON_DPAD_DOWN, JOY_AXIS_LEFT_Y, 1.0, P2_PAD],
	"p2_interact": [KEY_ENTER, JOY_BUTTON_A, -1, 0.0, P2_PAD],
	"pause": [KEY_ESCAPE, JOY_BUTTON_START, -1, 0.0, ANY_DEVICE],
}

const UI_ACTIONS: Array[StringName] = [
	&"ui_accept", &"ui_cancel", &"ui_left", &"ui_right", &"ui_up", &"ui_down"
]


func before_all() -> void:
	# Otros tests llaman a start_level sobre el autoload, que reescribe los mandos.
	GameState.reset_input()


func after_all() -> void:
	GameState.reset_input()


func _has_key(action: StringName, physical_keycode: Key) -> bool:
	for ev: InputEvent in InputMap.action_get_events(action):
		var key: InputEventKey = ev as InputEventKey
		if key and key.physical_keycode == physical_keycode and key.device == ANY_DEVICE:
			return true
	return false


func _has_button(action: StringName, button: JoyButton, device: int) -> bool:
	for ev: InputEvent in InputMap.action_get_events(action):
		var pad: InputEventJoypadButton = ev as InputEventJoypadButton
		if pad and pad.button_index == button and pad.device == device:
			return true
	return false


func _has_axis(action: StringName, axis: JoyAxis, value: float, device: int) -> bool:
	for ev: InputEvent in InputMap.action_get_events(action):
		var motion: InputEventJoypadMotion = ev as InputEventJoypadMotion
		if motion and motion.axis == axis and is_equal_approx(motion.axis_value, value):
			if motion.device == device:
				return true
	return false


func test_ac3_input_map_has_all_adr004_actions() -> void:
	for action: String in BINDINGS:
		assert_true(InputMap.has_action(action), "falta la acción %s" % action)


func test_ac3_actions_have_keyboard_binding() -> void:
	for action: String in BINDINGS:
		var spec: Array = BINDINGS[action]
		assert_true(_has_key(action, spec[0]), "%s sin tecla %d" % [action, spec[0]])


func test_ac3_actions_have_gamepad_button_binding() -> void:
	for action: String in BINDINGS:
		var spec: Array = BINDINGS[action]
		assert_true(_has_button(action, spec[1], spec[4]), "%s sin botón %d" % [action, spec[1]])


func test_ac3_move_actions_have_left_stick_binding() -> void:
	for action: String in BINDINGS:
		var spec: Array = BINDINGS[action]
		if spec[2] < 0:
			continue
		assert_true(_has_axis(action, spec[2], spec[3], spec[4]), "%s sin stick" % action)


func test_ac3_each_action_has_exactly_its_bindings() -> void:
	for action: String in BINDINGS:
		var spec: Array = BINDINGS[action]
		var expected: int = 3 if spec[2] >= 0 else 2
		assert_eq(InputMap.action_get_events(action).size(), expected, action)


func test_ac3_player_actions_do_not_share_gamepad_device() -> void:
	for action: String in BINDINGS:
		if not action.begins_with("p2_"):
			continue
		for ev: InputEvent in InputMap.action_get_events(action):
			if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
				assert_eq(ev.device, P2_PAD, "%s con mando de otro jugador" % action)


func test_ac3_ui_actions_have_keyboard_and_gamepad() -> void:
	for action: StringName in UI_ACTIONS:
		var has_key: bool = false
		var has_pad: bool = false
		for ev: InputEvent in InputMap.action_get_events(action):
			has_key = has_key or ev is InputEventKey
			has_pad = has_pad or ev is InputEventJoypadButton or ev is InputEventJoypadMotion
		assert_true(has_key and has_pad, "%s sin teclado o sin mando" % action)


func test_ac3_ui_accept_and_cancel_use_a_and_b_from_any_pad() -> void:
	assert_true(_has_button(&"ui_accept", JOY_BUTTON_A, ANY_DEVICE))
	assert_true(_has_button(&"ui_cancel", JOY_BUTTON_B, ANY_DEVICE))


func test_ac4_every_player_action_and_pause_has_keyboard_and_pad() -> void:
	var checked: int = 0
	for action: StringName in InputMap.get_actions():
		var name: String = String(action)
		var is_player: bool = name.length() > 2 and name[0] == "p" and name[2] == "_"
		if not is_player and action != &"pause":
			continue
		var has_key: bool = false
		var has_pad: bool = false
		for ev: InputEvent in InputMap.action_get_events(action):
			has_key = has_key or ev is InputEventKey
			has_pad = has_pad or ev is InputEventJoypadButton or ev is InputEventJoypadMotion
		assert_true(has_key, "%s sin teclado" % action)
		assert_true(has_pad, "%s sin mando" % action)
		checked += 1
	assert_eq(checked, BINDINGS.size(), "acciones p<n>_* + pause de ADR-004")
	assert_false(InputMap.has_action(&"p2_switch"), "solo J1 cambia de personaje")
