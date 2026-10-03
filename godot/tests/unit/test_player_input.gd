extends GutTest
## PUL-011 AC1: PlayerInput de J1 respeta la zona muerta de InputConfig.

var _input: PlayerInput


func before_each() -> void:
	_input = PlayerInput.new(1, 0.2)


func after_each() -> void:
	Input.action_release(&"p1_move_right")
	Input.action_release(&"p1_move_down")
	Input.action_release(&"p1_interact")
	Input.action_release(&"p2_move_right")


func test_ac1_below_deadzone_is_zero() -> void:
	Input.action_press(&"p1_move_right", 0.1)
	assert_eq(_input.get_move_vector(), Vector2.ZERO)


func test_ac1_no_input_is_zero() -> void:
	assert_eq(_input.get_move_vector(), Vector2.ZERO)


func test_ac1_above_deadzone_returns_unit_vector() -> void:
	Input.action_press(&"p1_move_right")
	assert_eq(_input.get_move_vector(), Vector2.RIGHT)


func test_ac1_partial_axial_strength_is_unit_length() -> void:
	Input.action_press(&"p1_move_right", 0.4)
	assert_almost_eq(_input.get_move_vector().length(), 1.0, 0.001)
	assert_almost_eq(_input.get_move_vector().x, 1.0, 0.001)


func test_ac1_partial_diagonal_is_unit_length() -> void:
	Input.action_press(&"p1_move_right", 0.4)
	Input.action_press(&"p1_move_down", 0.4)
	var v: Vector2 = _input.get_move_vector()
	assert_almost_eq(v.length(), 1.0, 0.001)
	assert_almost_eq(v.x, v.y, 0.001)


func test_ac1_just_below_deadzone_is_zero() -> void:
	Input.action_press(&"p1_move_right", 0.19)
	Input.action_press(&"p1_move_down", 0.05)
	assert_eq(_input.get_move_vector(), Vector2.ZERO)


func test_ac1_diagonal_is_normalized() -> void:
	Input.action_press(&"p1_move_right")
	Input.action_press(&"p1_move_down")
	var v: Vector2 = _input.get_move_vector()
	assert_almost_eq(v.length(), 1.0, 0.001)
	assert_gt(v.x, 0.0)
	assert_gt(v.y, 0.0)


func test_ac1_uses_configured_deadzone() -> void:
	var strict: PlayerInput = PlayerInput.new(1, 0.5)
	Input.action_press(&"p1_move_right", 0.4)
	assert_eq(strict.get_move_vector(), Vector2.ZERO)
	assert_almost_eq(_input.get_move_vector().length(), 1.0, 0.001)


func test_ac1_only_reads_its_own_player() -> void:
	Input.action_press(&"p2_move_right")
	assert_eq(_input.get_move_vector(), Vector2.ZERO)
	assert_eq(PlayerInput.new(2, 0.2).get_move_vector(), Vector2.RIGHT)


func test_ac1_interact_just_pressed() -> void:
	assert_false(_input.is_interact_just_pressed())
	Input.action_press(&"p1_interact")
	assert_true(_input.is_interact_just_pressed())


func test_ac1_interact_event() -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = &"p1_interact"
	event.pressed = true
	assert_true(_input.is_interact_event(event))
	event.action = &"p2_interact"
	assert_false(_input.is_interact_event(event))
