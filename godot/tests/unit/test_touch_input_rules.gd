extends GutTest
## PUL-128: reglas puras de los controles táctiles (ADR-004 §6.3) y datos de TouchConfig.

const MOBILE: PlatformProfile.Kind = PlatformProfile.Kind.MOBILE
const DESKTOP: PlatformProfile.Kind = PlatformProfile.Kind.DESKTOP
const SINGLE: GameMode.Mode = GameMode.Mode.SINGLE
const COOP: GameMode.Mode = GameMode.Mode.COOP_2P
const CONFIG: TouchConfig = preload("res://data/config/touch_config.tres")


func _motion(value: float) -> InputEventJoypadMotion:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = value
	return event


func test_source_of_touch_events() -> void:
	assert_eq(TouchInput.source_of(InputEventScreenTouch.new()), TouchInput.Source.TOUCH)
	assert_eq(TouchInput.source_of(InputEventScreenDrag.new()), TouchInput.Source.TOUCH)


func test_source_of_keys_and_joypad() -> void:
	assert_eq(TouchInput.source_of(InputEventKey.new()), TouchInput.Source.KEYS)
	assert_eq(TouchInput.source_of(InputEventJoypadButton.new()), TouchInput.Source.JOYPAD)
	assert_eq(TouchInput.source_of(_motion(0.9)), TouchInput.Source.JOYPAD)
	assert_eq(TouchInput.source_of(_motion(-0.9)), TouchInput.Source.JOYPAD)


func test_joypad_motion_inside_deadzone_is_not_a_source() -> void:
	assert_eq(TouchInput.source_of(_motion(0.1)), TouchInput.Source.NONE)
	assert_eq(TouchInput.source_of(_motion(0.0)), TouchInput.Source.NONE)


func test_mouse_and_actions_do_not_change_the_source() -> void:
	assert_eq(TouchInput.source_of(InputEventMouseButton.new()), TouchInput.Source.NONE)
	assert_eq(TouchInput.source_of(InputEventMouseMotion.new()), TouchInput.Source.NONE)
	assert_eq(TouchInput.source_of(InputEventAction.new()), TouchInput.Source.NONE)


func test_controls_visible_only_on_mobile_single() -> void:
	assert_true(TouchInput.controls_visible(MOBILE, SINGLE, TouchInput.Source.NONE))
	assert_true(TouchInput.controls_visible(MOBILE, SINGLE, TouchInput.Source.TOUCH))
	assert_false(TouchInput.controls_visible(DESKTOP, SINGLE, TouchInput.Source.TOUCH))
	assert_false(TouchInput.controls_visible(MOBILE, COOP, TouchInput.Source.TOUCH))


func test_joypad_hides_and_keys_do_not() -> void:
	assert_false(TouchInput.controls_visible(MOBILE, SINGLE, TouchInput.Source.JOYPAD))
	assert_true(TouchInput.controls_visible(MOBILE, SINGLE, TouchInput.Source.KEYS))


func test_stick_vector_is_analog_with_a_deadzone() -> void:
	var center: Vector2 = Vector2(100.0, 100.0)
	assert_eq(TouchInput.stick_vector(center, center, 150.0, 0.2), Vector2.ZERO)
	assert_eq(
		TouchInput.stick_vector(center, center + Vector2(20.0, 0.0), 150.0, 0.2), Vector2.ZERO
	)
	var half: Vector2 = TouchInput.stick_vector(center, center + Vector2(75.0, 0.0), 150.0, 0.2)
	assert_almost_eq(half.length(), 0.5, 0.001)
	assert_almost_eq(half.x, 0.5, 0.001)


func test_stick_vector_is_clamped_to_one_and_keeps_direction() -> void:
	var far: Vector2 = TouchInput.stick_vector(Vector2.ZERO, Vector2(0.0, -400.0), 150.0, 0.2)
	assert_almost_eq(far.length(), 1.0, 0.001)
	assert_almost_eq(far.y, -1.0, 0.001)
	var diagonal: Vector2 = TouchInput.stick_vector(Vector2.ZERO, Vector2(300.0, 300.0), 150.0, 0.2)
	assert_almost_eq(diagonal.length(), 1.0, 0.001)
	assert_almost_eq(diagonal.x, diagonal.y, 0.001)


func test_stick_vector_with_no_radius_is_zero() -> void:
	assert_eq(TouchInput.stick_vector(Vector2.ZERO, Vector2(10.0, 0.0), 0.0, 0.2), Vector2.ZERO)


func test_follow_center_stays_while_inside_the_radius() -> void:
	var center: Vector2 = Vector2(50.0, 50.0)
	assert_eq(TouchInput.follow_center(center, center + Vector2(149.0, 0.0), 150.0), center)


func test_follow_center_drags_the_base_so_the_finger_is_on_the_edge() -> void:
	var finger: Vector2 = Vector2(400.0, 0.0)
	var moved: Vector2 = TouchInput.follow_center(Vector2.ZERO, finger, 150.0)
	assert_almost_eq(moved.distance_to(finger), 150.0, 0.001)
	assert_almost_eq(moved.x, 250.0, 0.001)


func test_clamp_center_keeps_the_whole_base_inside_the_area() -> void:
	var area: Rect2 = Rect2(132.0, 0.0, 2076.0, 1017.0)
	assert_eq(TouchInput.clamp_center(Vector2(300.0, 700.0), 150.0, area), Vector2(300.0, 700.0))
	assert_eq(TouchInput.clamp_center(Vector2(140.0, 1000.0), 150.0, area), Vector2(282.0, 867.0))
	assert_eq(TouchInput.clamp_center(Vector2(5000.0, -9.0), 150.0, area), Vector2(2058.0, 150.0))


func test_clamp_center_in_an_area_smaller_than_the_base_centers_it() -> void:
	var area: Rect2 = Rect2(0.0, 0.0, 100.0, 100.0)
	assert_eq(TouchInput.clamp_center(Vector2(10.0, 10.0), 150.0, area), Vector2(50.0, 50.0))


func test_axis_strengths_split_the_vector_by_axis() -> void:
	var strengths: Dictionary[StringName, float] = TouchInput.axis_strengths(Vector2(0.6, -0.3))
	assert_almost_eq(strengths[TouchInput.MOVE_RIGHT], 0.6, 0.0001)
	assert_eq(strengths[TouchInput.MOVE_LEFT], 0.0)
	assert_almost_eq(strengths[TouchInput.MOVE_UP], 0.3, 0.0001)
	assert_eq(strengths[TouchInput.MOVE_DOWN], 0.0)
	assert_eq(strengths.size(), 4)


func test_axis_strengths_of_zero_release_everything() -> void:
	for strength: float in TouchInput.axis_strengths(Vector2.ZERO).values():
		assert_eq(strength, 0.0)


func test_move_actions_are_player_one_only() -> void:
	for action: StringName in TouchInput.MOVE_ACTIONS:
		assert_true(String(action).begins_with("p1_move_"), action)
		assert_true(InputMap.has_action(action), action)


# --- Datos (TouchConfig) -------------------------------------------------------------------------


func test_config_buttons_meet_the_touch_target_minimums() -> void:
	assert_gte(CONFIG.action_button_dp, 72.0)
	assert_gte(CONFIG.small_button_dp, 48.0)


func test_config_measures_match_the_design_at_1080() -> void:
	var px: float = CONFIG.px_per_dp_at_1080
	assert_almost_eq(CONFIG.action_button_dp * px, 180.0, 0.01)
	assert_almost_eq(CONFIG.small_button_dp * px, 120.0, 0.01)
	assert_almost_eq(CONFIG.stick_base_dp * px, 300.0, 0.01)
	assert_almost_eq(CONFIG.stick_radius_dp * px, 150.0, 0.01)
	assert_eq(CONFIG.hit_slop_px_1080, 12.0)
	assert_eq(CONFIG.button_margin_px_1080, 48.0)
	assert_eq(CONFIG.button_gap_px_1080, 24.0)
	assert_eq(CONFIG.stick_deadzone, 0.2)
	assert_eq(CONFIG.stick_zone_fraction, 0.5)
	assert_eq(CONFIG.stick_zone_top_px_1080, 200.0)
	assert_eq(CONFIG.stick_fade_s, 0.15)


func test_config_haptics_default_to_short_pulses() -> void:
	assert_true(CONFIG.haptics_enabled)
	assert_eq(CONFIG.haptic_ok_ms, 20)
	assert_eq(CONFIG.haptic_reject_ms, 20)


func test_touch_adds_no_events_to_the_input_map() -> void:
	for action: StringName in InputMap.get_actions():
		if not String(action).begins_with("p1_") and action != &"pause":
			continue
		for event: InputEvent in InputMap.action_get_events(action):
			assert_false(event is InputEventScreenTouch, action)
			assert_false(event is InputEventScreenDrag, action)
			assert_false(event is InputEventAction, action)
