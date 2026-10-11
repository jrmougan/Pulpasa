# gdlint: disable=max-public-methods
extends GutTest
## PUL-128 AC8/AC9 (controles-tactiles AC8, AC9): el botón de acción enseña el verbo del bus
## (gris / aro blanco / aro ámbar con aspa y motivo), responde a la pulsación y mantener solo repite
## CORTAR. El icono es el de `ActionIconSet`, el mismo que usa el prompt del mundo.

const SCENE: PackedScene = preload("res://ui/touch/touch_controls.tscn")
const ICONS: ActionIconSet = preload("res://data/config/action_icons.tres")
const SAFE: Rect2 = Rect2(132.0, 0.0, 2076.0, 1017.0)
const ACTION_PX: Vector2 = Vector2(2070.0, 879.0)
const STEP: float = 0.05
const OK: int = ActionHint.State.OK
const BLOCKED: int = ActionHint.State.BLOCKED
const NONE: int = ActionHint.State.NONE

var _original_size: Vector2i
var _controls: TouchControls
var _button: ActionButton
var _control: ControlComponent
var _holder: FakeHolder
var _detector: FakeDetector
var _component: InteractionComponent
var _vibrations: Array[int] = []


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
	_button = _controls.get_node(^"%ActionButton") as ActionButton
	_vibrations.clear()
	_button.vibrate = func(ms: int) -> void: _vibrations.append(ms)
	_control = add_child_autofree(ControlComponent.new())
	_holder = add_child_autofree(FakeHolder.new())
	_detector = add_child_autofree(FakeDetector.new())
	_component = InteractionComponent.new()
	_component.control = _control
	_component.holder = _holder
	_component.detector = _detector
	add_child_autofree(_component)


func after_each() -> void:
	_controls.release_all()
	Input.flush_buffered_events()
	get_window().size = _original_size
	GameState.set_platform(PlatformProfile.Kind.DESKTOP)


func _scale() -> float:
	return get_viewport().get_final_transform().get_scale().y


func _touch(index: int, px: Vector2, pressed: bool) -> void:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = index
	event.position = px / _scale()
	event.pressed = pressed
	get_viewport().push_input(event, true)
	Input.flush_buffered_events()


func _hint(verb: StringName, state: int, reason: StringName = ActionReason.NONE) -> void:
	EventBus.action_hint_changed.emit(1, verb, state, reason)


func _advance(seconds: float) -> void:
	for _i: int in roundi(seconds / STEP):
		_component._physics_process(STEP)


func _target(hint: ActionHint) -> FakeHintedInteractable:
	var target: FakeHintedInteractable = add_child_autofree(FakeHintedInteractable.new())
	target.hint = hint
	_detector.target_changed.emit(null, target)
	return target


# --- AC8: el botón enseña el verbo ---------------------------------------------------------------


func test_ac8_no_target_with_empty_hand_is_grey_with_dimmed_pick_up() -> void:
	_hint(ActionVerb.NONE, NONE)
	assert_eq(_button.get_plate_color(), ICONS.idle_color)
	assert_eq(_button.get_ring_color().a, 0.0, "sin aro")
	assert_eq(_button.get_icon_texture(), ICONS.verb_icons[ActionVerb.PICK_UP])
	assert_almost_eq(_button.get_icon_color().a, 0.4, 0.001)
	assert_false(_button.shows_cross())
	assert_null(_button.get_reason_texture())


func test_ac8_pick_up_octopus_is_white_ring_and_white_icon() -> void:
	_hint(ActionVerb.PICK_UP, OK)
	assert_eq(_button.get_ring_color(), ICONS.ok_color)
	assert_eq(_button.get_icon_color(), ICONS.ok_color)
	assert_eq(_button.get_icon_texture(), ICONS.verb_icons[ActionVerb.PICK_UP])
	assert_ne(_button.get_plate_color(), ICONS.idle_color)
	assert_false(_button.shows_cross())


func test_ac8_cut_with_cooked_octopus() -> void:
	_hint(ActionVerb.CUT, OK)
	assert_eq(_button.get_ring_color(), ICONS.ok_color)
	assert_eq(_button.get_icon_texture(), ICONS.verb_icons[ActionVerb.CUT])


func test_ac8_season_hot_replacing_is_still_ok() -> void:
	_hint(ActionVerb.SEASON_HOT, OK)
	assert_eq(_button.get_ring_color(), ICONS.ok_color)
	assert_eq(_button.get_icon_texture(), ICONS.verb_icons[ActionVerb.SEASON_HOT])


func test_ac8_blocked_by_half_box_is_amber_with_cross_and_reason() -> void:
	_hint(ActionVerb.SEASON_SWEET, BLOCKED, ActionReason.BOX_NOT_FULL)
	assert_eq(_button.get_ring_color(), ICONS.blocked_color)
	assert_eq(_button.get_icon_color(), ICONS.blocked_color)
	assert_eq(_button.get_icon_texture(), ICONS.verb_icons[ActionVerb.SEASON_SWEET])
	assert_true(_button.shows_cross())
	assert_eq(_button.get_reason_texture(), ICONS.reason_icons[ActionReason.BOX_NOT_FULL])


func test_ac8_drop_with_full_hand_and_no_target_is_ok() -> void:
	_hint(ActionVerb.DROP, OK)
	assert_eq(_button.get_ring_color(), ICONS.ok_color)
	assert_eq(_button.get_icon_texture(), ICONS.verb_icons[ActionVerb.DROP])
	assert_false(_button.shows_cross())


func test_ac8_every_verb_and_reason_has_an_icon_in_the_button() -> void:
	for verb: StringName in ActionVerb.ALL:
		_hint(verb, OK)
		assert_not_null(_button.get_icon_texture(), verb)
		assert_eq(_button.get_icon_texture(), ICONS.verb_icons[verb], verb)
	for reason: StringName in ActionReason.ALL:
		_hint(ActionVerb.COOK, BLOCKED, reason)
		assert_not_null(_button.get_reason_texture(), reason)


func test_ac8_blocked_and_idle_colors_are_the_design_colors() -> void:
	assert_eq(ICONS.blocked_color.to_html(false), "ffb020")
	assert_eq(ICONS.idle_color.to_html(false), "6b6b73")


func test_ac8_only_player_one_hints_reach_the_button() -> void:
	_hint(ActionVerb.CUT, OK)
	EventBus.action_hint_changed.emit(2, ActionVerb.TRASH, OK, ActionReason.NONE)
	assert_eq(_button.get_verb(), ActionVerb.CUT)


func test_ac8_returning_to_none_goes_back_to_grey() -> void:
	_hint(ActionVerb.CUT, OK)
	_hint(ActionVerb.NONE, NONE)
	assert_eq(_button.get_plate_color(), ICONS.idle_color)
	assert_eq(_button.get_ring_color().a, 0.0)


func test_ac8_hint_of_a_real_interaction_component_reaches_the_button() -> void:
	var target: FakeHintedInteractable = _target(
		ActionHint.blocked(ActionVerb.CUT, ActionReason.FULL)
	)
	_detector.hint_changed.emit(target, target.hint)
	assert_eq(_button.get_state(), ActionHint.State.BLOCKED)
	assert_eq(_button.get_reason_texture(), ICONS.reason_icons[ActionReason.FULL])
	_detector.hint_changed.emit(null, ActionHint.none())
	assert_eq(_button.get_state(), ActionHint.State.NONE)


func test_ac8_character_switch_hints_show_the_incoming_hint_last() -> void:
	_hint(ActionVerb.CUT, OK)
	_hint(ActionVerb.NONE, NONE)
	_hint(ActionVerb.COOK, BLOCKED, ActionReason.BUSY)
	assert_eq(_button.get_verb(), ActionVerb.COOK)
	assert_eq(_button.get_reason(), ActionReason.BUSY)


func test_ac8_button_draws_every_state_without_errors() -> void:
	for state: int in [NONE, OK, BLOCKED]:
		_hint(ActionVerb.CUT, state, ActionReason.FULL)
		await wait_process_frames(2)
	assert_true(is_instance_valid(_button))


# --- AC9: mantener = atajo solo de corte ---------------------------------------------------------


func test_ac9_holding_cut_for_1_05_s_makes_six_cuts_and_no_seventh() -> void:
	var target: FakeHintedInteractable = _target(ActionHint.ok(ActionVerb.CUT, 0.0))
	_touch(0, ACTION_PX, true)
	assert_eq(target.effect_count, 1, "el primer corte es al pulsar")
	_advance(1.05)
	assert_eq(target.effect_count, 6)
	_touch(0, ACTION_PX, false)
	_advance(1.0)
	assert_eq(target.effect_count, 6, "al soltar no hay un séptimo")


func test_ac9_holding_pick_up_for_2_s_picks_once() -> void:
	var target: FakeHintedInteractable = _target(ActionHint.ok(ActionVerb.PICK_UP))
	_touch(0, ACTION_PX, true)
	_advance(2.0)
	assert_eq(target.effect_count, 1)
	_touch(0, ACTION_PX, false)


func test_ac9_lifting_the_finger_stops_the_repeat() -> void:
	var target: FakeHintedInteractable = _target(ActionHint.ok(ActionVerb.CUT, 0.0))
	_touch(0, ACTION_PX, true)
	_advance(0.45)
	_touch(0, ACTION_PX, false)
	var cuts: int = target.effect_count
	_advance(1.0)
	assert_eq(target.effect_count, cuts)


func test_ac9_holding_keeps_interact_pressed_for_the_game() -> void:
	_touch(0, ACTION_PX, true)
	assert_true(Input.is_action_pressed(&"p1_interact"))
	await wait_process_frames(3)
	assert_true(Input.is_action_pressed(&"p1_interact"))
	_touch(0, ACTION_PX, false)
	assert_false(Input.is_action_pressed(&"p1_interact"))


func test_ac9_pressing_without_a_target_still_sends_interact_and_stays_silent() -> void:
	watch_signals(EventBus)
	_touch(0, ACTION_PX, true)
	assert_true(Input.is_action_pressed(&"p1_interact"))
	_touch(0, ACTION_PX, false)
	assert_signal_not_emitted(EventBus, "interaction_resolved", "mano vacía y sin objetivo: nada")


# --- Respuesta y háptica -------------------------------------------------------------------------


func test_response_ok_jumps_and_settles() -> void:
	_hint(ActionVerb.PICK_UP, OK)
	EventBus.interaction_resolved.emit(1, ActionVerb.PICK_UP, OK, ActionReason.NONE)
	await wait_seconds(0.12)
	assert_lt(_button._offset.y, -1.0, "el icono sube")
	assert_gt(_button._icon_scale, 1.05)
	await wait_seconds(0.4)
	assert_eq(_button._offset, Vector2.ZERO)
	assert_eq(_button._icon_scale, 1.0)


func test_response_blocked_shakes_horizontally_and_settles() -> void:
	_hint(ActionVerb.CUT, BLOCKED, ActionReason.FULL)
	EventBus.interaction_resolved.emit(1, ActionVerb.CUT, BLOCKED, ActionReason.FULL)
	var max_shake: float = 0.0
	for _i: int in 18:
		await wait_process_frames(1)
		max_shake = maxf(max_shake, absf(_button._offset.x))
		assert_eq(_button._offset.y, 0.0)
	assert_gt(max_shake, 1.0)
	await wait_seconds(0.4)
	assert_eq(_button._offset, Vector2.ZERO)


func test_response_lasts_at_least_0_3_s() -> void:
	EventBus.interaction_resolved.emit(1, ActionVerb.CUT, OK, ActionReason.NONE)
	await wait_seconds(0.28)
	assert_true(_button._response_tween.is_running())


func test_response_ignores_player_two() -> void:
	EventBus.interaction_resolved.emit(2, ActionVerb.CUT, BLOCKED, ActionReason.FULL)
	assert_null(_button._response_tween)
	assert_eq(_vibrations, [] as Array[int])


func test_haptics_ok_vibrates_once() -> void:
	EventBus.interaction_resolved.emit(1, ActionVerb.CUT, OK, ActionReason.NONE)
	await wait_seconds(0.1)
	assert_eq(_vibrations, [20] as Array[int])


func test_haptics_reject_vibrates_twice() -> void:
	EventBus.interaction_resolved.emit(1, ActionVerb.CUT, BLOCKED, ActionReason.FULL)
	assert_eq(_vibrations, [20] as Array[int])
	await wait_seconds(0.15)
	assert_eq(_vibrations, [20, 20] as Array[int])


func test_haptics_can_be_disabled() -> void:
	var config: TouchConfig = _button.config.duplicate() as TouchConfig
	config.haptics_enabled = false
	_button.config = config
	EventBus.interaction_resolved.emit(1, ActionVerb.CUT, BLOCKED, ActionReason.FULL)
	await wait_seconds(0.15)
	assert_eq(_vibrations, [] as Array[int])


func test_button_sinks_to_0_92_on_press_and_recovers() -> void:
	_touch(0, ACTION_PX, true)
	await wait_seconds(0.2)
	assert_almost_eq(_button.scale.x, 0.92, 0.01)
	_touch(0, ACTION_PX, false)
	await wait_seconds(0.2)
	assert_almost_eq(_button.scale.x, 1.0, 0.01)
