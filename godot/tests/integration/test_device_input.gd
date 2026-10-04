extends GutTest
## PUL-034 AC2: la asignación de GameState filtra por mando en el InputMap; teclado intacto.

const EventBusScript: GDScript = preload("res://autoload/event_bus.gd")
const GameStateScript: GDScript = preload("res://autoload/game_state.gd")
const MOVES: Array[String] = ["move_left", "move_right", "move_up", "move_down"]

var _state: Node
var _keyboard_before: Dictionary = {}


func before_each() -> void:
	var bus: Node = add_child_autofree(EventBusScript.new())
	_state = GameStateScript.new()
	_state.set_bus(bus)
	add_child_autofree(_state)
	_keyboard_before = _keyboard_events()


func after_each() -> void:
	_state.reset_input()


func _pads(ids: Array) -> Array[int]:
	var out: Array[int] = []
	out.assign(ids)
	return out


func _stick_left(device: int) -> InputEventJoypadMotion:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.device = device
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = -1.0
	return event


func _button(device: int, button: JoyButton) -> InputEventJoypadButton:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	event.pressed = true
	return event


func _keyboard_events() -> Dictionary:
	var out: Dictionary = {}
	for action: StringName in InputMap.get_actions():
		if not String(action).begins_with("p"):
			continue
		var keys: Array[String] = []
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				keys.append("%d/%d" % [event.physical_keycode, event.device])
		out[action] = keys
	return out


func test_ac2_coop_keyboard_and_one_pad_moves_only_p2() -> void:
	_state.assign_devices(GameMode.Mode.COOP_2P, _pads([0]))
	var event: InputEventJoypadMotion = _stick_left(0)
	assert_true(InputMap.event_is_action(event, &"p2_move_left"))
	assert_false(InputMap.event_is_action(event, &"p1_move_left"))
	assert_false(InputMap.event_is_action(_button(0, JOY_BUTTON_A), &"p1_interact"))
	assert_true(InputMap.event_is_action(_button(0, JOY_BUTTON_A), &"p2_interact"))


func test_ac2_pad_of_p2_drives_p2_vector_through_input() -> void:
	_state.assign_devices(GameMode.Mode.COOP_2P, _pads([0]))
	Input.parse_input_event(_stick_left(0))
	Input.flush_buffered_events()
	assert_gt(Input.get_action_strength(&"p2_move_left"), 0.5)
	assert_eq(Input.get_action_strength(&"p1_move_left"), 0.0)
	var release: InputEventJoypadMotion = _stick_left(0)
	release.axis_value = 0.0
	Input.parse_input_event(release)
	Input.flush_buffered_events()


func test_ac2_two_pads_each_moves_only_its_player() -> void:
	_state.assign_devices(GameMode.Mode.COOP_2P, _pads([0, 1]))
	for move: String in MOVES:
		var p1: StringName = StringName("p1_" + move)
		var p2: StringName = StringName("p2_" + move)
		for event: InputEvent in InputMap.action_get_events(p1):
			if event is InputEventJoypadMotion or event is InputEventJoypadButton:
				assert_eq(event.device, 0, String(p1))
		for event: InputEvent in InputMap.action_get_events(p2):
			if event is InputEventJoypadMotion or event is InputEventJoypadButton:
				assert_eq(event.device, 1, String(p2))
	assert_true(InputMap.event_is_action(_stick_left(0), &"p1_move_left"))
	assert_false(InputMap.event_is_action(_stick_left(0), &"p2_move_left"))
	assert_true(InputMap.event_is_action(_stick_left(1), &"p2_move_left"))
	assert_false(InputMap.event_is_action(_stick_left(1), &"p1_move_left"))


func test_ac2_coop_without_pads_leaves_players_keyboard_only() -> void:
	_state.assign_devices(GameMode.Mode.COOP_2P, _pads([]))
	assert_false(InputMap.event_is_action(_stick_left(0), &"p1_move_left"))
	assert_false(InputMap.event_is_action(_stick_left(0), &"p2_move_left"))


func test_ac2_single_accepts_any_pad_for_p1_and_none_for_p2() -> void:
	_state.assign_devices(GameMode.Mode.SINGLE, _pads([]))
	for device: int in [0, 1, 4]:
		assert_true(InputMap.event_is_action(_stick_left(device), &"p1_move_left"), str(device))
		assert_false(InputMap.event_is_action(_stick_left(device), &"p2_move_left"), str(device))
	assert_true(InputMap.event_is_action(_button(2, JOY_BUTTON_Y), &"p1_switch"))


func test_ac2_keyboard_events_are_never_touched() -> void:
	for mode: GameMode.Mode in [GameMode.Mode.SINGLE, GameMode.Mode.COOP_2P]:
		for pads: Array in [[], [0], [0, 1]]:
			_state.assign_devices(mode, _pads(pads))
			assert_eq(_keyboard_events(), _keyboard_before, "%d %s" % [mode, pads])
	_state.reset_input()
	assert_eq(_keyboard_events(), _keyboard_before)


func test_ac2_reset_input_restores_template_devices() -> void:
	_state.assign_devices(GameMode.Mode.SINGLE, _pads([]))
	_state.reset_input()
	assert_true(InputMap.event_is_action(_stick_left(0), &"p1_move_left"))
	assert_false(InputMap.event_is_action(_stick_left(1), &"p1_move_left"))
	assert_true(InputMap.event_is_action(_stick_left(1), &"p2_move_left"))
