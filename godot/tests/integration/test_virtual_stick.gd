extends GutTest
## PUL-128 AC4 (controles-tactiles AC4): stick flotante. Eventos de pantalla sintéticos en px de
## pantalla a 2340x1080 con la safe area simulada 132 / 0 / 132 / 63.

const SCENE: PackedScene = preload("res://ui/touch/touch_controls.tscn")
const SAFE: Rect2 = Rect2(132.0, 0.0, 2076.0, 1017.0)

var _original_size: Vector2i
var _controls: TouchControls
var _stick: VirtualStick


func before_each() -> void:
	_original_size = get_window().size
	GameState.set_platform(PlatformProfile.Kind.MOBILE)
	GameState.mode = GameMode.Mode.SINGLE
	get_window().size = Vector2i(2340, 1080)
	await wait_process_frames(3)
	_controls = SCENE.instantiate()
	add_child_autofree(_controls)
	await wait_process_frames(2)
	_controls.apply_safe_rect(SAFE, Vector2(2340.0, 1080.0))
	await wait_process_frames(2)
	_stick = _controls.get_node(^"%MoveStick") as VirtualStick


func after_each() -> void:
	_stick.release_all()
	get_window().size = _original_size
	GameState.set_platform(PlatformProfile.Kind.DESKTOP)


func _scale() -> float:
	return get_viewport().get_final_transform().get_scale().y


func _send(event: InputEvent) -> void:
	get_viewport().push_input(event, true)


## Toque o arrastre en px de pantalla.
func _touch(index: int, px: Vector2, pressed: bool) -> void:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = index
	event.position = px / _scale()
	event.pressed = pressed
	_send(event)


func _drag(index: int, px: Vector2) -> void:
	var event: InputEventScreenDrag = InputEventScreenDrag.new()
	event.index = index
	event.position = px / _scale()
	_send(event)


func _base_px() -> Vector2:
	return _stick.get_base_center() * _scale()


func _finger_px() -> Vector2:
	return _stick.get_finger_position() * _scale()


func test_ac4_base_appears_centered_on_a_new_touch() -> void:
	_touch(0, Vector2(300.0, 700.0), true)
	assert_true(_stick.is_active())
	assert_almost_eq(_base_px().x, 300.0, 1.0)
	assert_almost_eq(_base_px().y, 700.0, 1.0)
	assert_almost_eq(_stick.get_base_diameter() * _scale(), 300.0, 1.0)
	assert_almost_eq(_stick.get_base_alpha(), 1.0, 0.001)


func test_ac4_just_touching_gives_no_movement() -> void:
	_touch(0, Vector2(300.0, 700.0), true)
	assert_eq(_stick.get_vector(), Vector2.ZERO)


func test_ac4_75_px_drag_is_half_magnitude() -> void:
	_touch(0, Vector2(300.0, 700.0), true)
	_drag(0, Vector2(375.0, 700.0))
	assert_almost_eq(_stick.get_vector().length(), 0.5, 0.02)
	assert_almost_eq(Input.get_action_strength(&"p1_move_right"), 0.5, 0.02)
	assert_eq(Input.get_action_strength(&"p1_move_left"), 0.0)


func test_ac4_20_px_is_inside_the_deadzone() -> void:
	_touch(0, Vector2(300.0, 700.0), true)
	_drag(0, Vector2(320.0, 700.0))
	assert_eq(_stick.get_vector(), Vector2.ZERO)
	assert_eq(Input.get_action_strength(&"p1_move_right"), 0.0)


func test_ac4_150_px_or_more_is_full_magnitude() -> void:
	_touch(0, Vector2(300.0, 700.0), true)
	_drag(0, Vector2(450.0, 700.0))
	assert_almost_eq(_stick.get_vector().length(), 1.0, 0.001)
	_drag(0, Vector2(300.0, 900.0))
	assert_almost_eq(_stick.get_vector().length(), 1.0, 0.001)
	assert_almost_eq(Input.get_action_strength(&"p1_move_down"), 1.0, 0.001)


func test_ac4_base_follows_a_finger_that_goes_past_the_radius() -> void:
	_touch(0, Vector2(300.0, 700.0), true)
	_drag(0, Vector2(400.0, 700.0))
	_drag(0, Vector2(700.0, 700.0))
	assert_almost_eq(_stick.get_vector().length(), 1.0, 0.001)
	assert_almost_eq(_finger_px().distance_to(_base_px()), 150.0, 1.0)
	assert_almost_eq(_base_px().x, 550.0, 1.0)


func test_ac4_diagonal_pushes_two_axes() -> void:
	_touch(0, Vector2(300.0, 700.0), true)
	_drag(0, Vector2(375.0, 625.0))
	assert_gt(Input.get_action_strength(&"p1_move_right"), 0.3)
	assert_gt(Input.get_action_strength(&"p1_move_up"), 0.3)
	assert_eq(Input.get_action_strength(&"p1_move_left"), 0.0)
	assert_eq(Input.get_action_strength(&"p1_move_down"), 0.0)


func test_ac4_lifting_zeroes_the_vector_in_the_same_frame() -> void:
	_touch(0, Vector2(300.0, 700.0), true)
	_drag(0, Vector2(450.0, 700.0))
	assert_gt(Input.get_action_strength(&"p1_move_right"), 0.9)
	_touch(0, Vector2(450.0, 700.0), false)
	assert_false(_stick.is_active())
	assert_eq(_stick.get_vector(), Vector2.ZERO)
	for action: StringName in TouchInput.MOVE_ACTIONS:
		assert_eq(Input.get_action_strength(action), 0.0, action)
		assert_false(Input.is_action_pressed(action), action)


func test_ac4_base_fades_out_in_0_15_s() -> void:
	_touch(0, Vector2(300.0, 700.0), true)
	_touch(0, Vector2(300.0, 700.0), false)
	await wait_seconds(0.07)
	assert_gt(_stick.get_base_alpha(), 0.0)
	assert_lt(_stick.get_base_alpha(), 1.0)
	await wait_seconds(0.2)
	assert_eq(_stick.get_base_alpha(), 0.0)


func test_ac4_a_new_touch_during_the_fade_restores_the_base() -> void:
	_touch(0, Vector2(300.0, 700.0), true)
	_touch(0, Vector2(300.0, 700.0), false)
	await wait_seconds(0.05)
	_touch(1, Vector2(500.0, 600.0), true)
	await wait_seconds(0.2)
	assert_almost_eq(_stick.get_base_alpha(), 1.0, 0.001)


func test_ac4_touch_near_the_corner_keeps_the_base_inside_the_safe_area() -> void:
	_touch(0, Vector2(140.0, 1000.0), true)
	assert_almost_eq(_base_px().x, 282.0, 1.0)
	assert_almost_eq(_base_px().y, 867.0, 1.0)


func test_ac4_touch_in_the_right_half_does_not_start_a_stick() -> void:
	_touch(0, Vector2(1170.0, 700.0), true)
	assert_false(_stick.is_active())
	_touch(0, Vector2(1500.0, 700.0), true)
	assert_false(_stick.is_active())


func test_ac4_touch_in_the_top_band_does_not_start_a_stick() -> void:
	_touch(0, Vector2(300.0, 150.0), true)
	assert_false(_stick.is_active())


func test_ac4_touch_just_inside_the_zone_edges_starts_it() -> void:
	_touch(0, Vector2(1165.0, 205.0), true)
	assert_true(_stick.is_active())


func test_ac4_touch_over_a_button_does_not_start_a_stick() -> void:
	# Un botón dentro de la zona del stick (lo coloca el test) tampoco lo inicia.
	var action: ActionButton = _controls.get_node(^"%ActionButton") as ActionButton
	var inside: Vector2 = Vector2(600.0, 700.0) / _scale()
	action.global_position = inside - action.size / 2.0
	_touch(0, Vector2(600.0, 700.0), true)
	assert_false(_stick.is_active())


func test_ac4_a_second_finger_in_the_zone_does_not_move_the_stick() -> void:
	_touch(0, Vector2(300.0, 700.0), true)
	_touch(1, Vector2(800.0, 500.0), true)
	_drag(1, Vector2(900.0, 500.0))
	assert_eq(_stick.get_touch_index(), 0)
	assert_almost_eq(_base_px().x, 300.0, 1.0)
	assert_eq(_stick.get_vector(), Vector2.ZERO)


func test_ac4_hiding_the_controls_releases_the_stick() -> void:
	_touch(0, Vector2(300.0, 700.0), true)
	_drag(0, Vector2(450.0, 700.0))
	_controls.set_last_source(TouchInput.Source.JOYPAD)
	assert_false(_stick.is_active())
	assert_eq(Input.get_action_strength(&"p1_move_right"), 0.0)


func test_ac4_pausing_releases_the_stick() -> void:
	_touch(0, Vector2(300.0, 700.0), true)
	_drag(0, Vector2(450.0, 700.0))
	EventBus.pause_changed.emit(true)
	assert_false(_stick.is_active())
	assert_eq(Input.get_action_strength(&"p1_move_right"), 0.0)
	EventBus.pause_changed.emit(false)
