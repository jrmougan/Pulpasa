# gdlint: disable=max-public-methods
extends GutTest
## PUL-014 AC2: InteractionComponent despacha la pulsación de interactuar.
## PUL-121 AC5/AC6 (D26): una respuesta por pulsación, suelo, bus y corte al mantener.

## Paso de física con el que se avanza el corte al mantener (s).
const REPEAT_STEP: float = 0.05

var _control: ControlComponent
var _holder: FakeHolder
var _detector: FakeDetector
var _component: InteractionComponent


func before_each() -> void:
	watch_signals(EventBus)
	_control = add_child_autofree(ControlComponent.new())
	_holder = add_child_autofree(FakeHolder.new())
	_detector = add_child_autofree(FakeDetector.new())
	_component = InteractionComponent.new()
	_component.control = _control
	_component.holder = _holder
	_component.detector = _detector
	add_child_autofree(_component)


func after_each() -> void:
	Input.action_release(&"p1_interact")
	GameState.set_paused(false)


func _target(accepts: bool = true, consumes: bool = true) -> FakeInteractable:
	var target: FakeInteractable = add_child_autofree(FakeInteractable.new())
	target.accepts = accepts
	target.consumes = consumes
	_detector.target_changed.emit(null, target)
	return target


func _hold() -> FakePickable:
	var item: FakePickable = add_child_autofree(FakePickable.new())
	_holder.pick_up(item)
	return item


func _press() -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = &"p1_interact"
	event.pressed = true
	_component._unhandled_input(event)


func test_ac2_accepting_target_gets_one_interact_and_hand_is_kept() -> void:
	var target: FakeInteractable = _target()
	var item: FakePickable = _hold()
	_press()
	assert_eq(target.interact_count, 1)
	assert_eq(target.last_actor, _component)
	assert_eq(_holder.get_held_item(), item)


func test_ac2_rejecting_target_and_full_hand_drops() -> void:
	var target: FakeInteractable = _target(false)
	var item: FakePickable = _hold()
	_press()
	assert_eq(target.interact_count, 0)
	assert_null(_holder.get_held_item())
	assert_false(item.is_held)


func test_ac2_target_that_does_not_consume_and_full_hand_drops() -> void:
	var target: FakeInteractable = _target(true, false)
	_hold()
	_press()
	assert_eq(target.interact_count, 1)
	assert_null(_holder.get_held_item())


func test_ac2_no_target_and_full_hand_drops() -> void:
	_hold()
	_press()
	assert_null(_holder.get_held_item())


func test_ac2_no_target_and_empty_hand_does_nothing() -> void:
	_press()
	assert_eq(_holder.log, [] as Array[String])


func test_ac2_rejecting_target_and_empty_hand_does_nothing() -> void:
	var target: FakeInteractable = _target(false)
	_press()
	assert_eq(target.interact_count, 0)
	assert_eq(_holder.log, [] as Array[String])


func test_ac2_ignores_press_when_nobody_controls() -> void:
	var target: FakeInteractable = _target()
	_hold()
	_control.controlled_by = 0
	_press()
	assert_eq(target.interact_count, 0)
	assert_not_null(_holder.get_held_item())


func test_ac2_ignores_other_players_action() -> void:
	var target: FakeInteractable = _target()
	var event: InputEventAction = InputEventAction.new()
	event.action = &"p2_interact"
	event.pressed = true
	_component._unhandled_input(event)
	assert_eq(target.interact_count, 0)


func test_ac2_target_changed_replaces_target() -> void:
	var first: FakeInteractable = _target()
	var second: FakeInteractable = _target()
	_detector.target_changed.emit(first, second)
	_press()
	assert_eq(first.interact_count, 0)
	assert_eq(second.interact_count, 1)


func test_ac2_target_cleared_by_detector() -> void:
	var target: FakeInteractable = _target()
	_detector.target_changed.emit(target, null)
	_press()
	assert_eq(target.interact_count, 0)


func test_ac2_freed_target_is_ignored_without_error() -> void:
	var target: FakeInteractable = _target()
	_hold()
	target.free()
	_press()
	assert_null(_holder.get_held_item())


# --- PUL-121 AC5: respuesta única (ADR-003 §11.4) -----------------------------------------------


func _hinted(hint: ActionHint) -> FakeHintedInteractable:
	var target: FakeHintedInteractable = add_child_autofree(FakeHintedInteractable.new())
	target.hint = hint
	_detector.target_changed.emit(null, target)
	return target


## Parámetros de la `index`-ésima emisión de una señal del bus.
func _bus(signal_name: String, index: int = 0) -> Array:
	return get_signal_parameters(EventBus, signal_name, index)


func test_ac5_none_hint_without_target_and_empty_hand_does_nothing() -> void:
	watch_signals(_component)
	assert_false(_component.interact_pressed())
	assert_signal_not_emitted(_component, "interaction_resolved")
	assert_signal_not_emitted(EventBus, "interaction_resolved")


func test_ac5_ok_target_gives_one_local_and_one_bus_response_with_primitives() -> void:
	var hint: ActionHint = ActionHint.ok(ActionVerb.PICK_UP)
	var target: FakeHintedInteractable = _hinted(hint)
	watch_signals(_component)
	assert_true(_component.interact_pressed())
	assert_eq(target.effect_count, 1)
	assert_signal_emit_count(_component, "interaction_resolved", 1)
	var params: Array = get_signal_parameters(_component, "interaction_resolved", 0)
	assert_eq(params[0], target)
	assert_true((params[1] as ActionHint).same_as(hint))
	assert_signal_emit_count(EventBus, "interaction_resolved", 1)
	assert_eq(_bus("interaction_resolved"), [1, &"pick_up", 1, &""])


func test_ac5_blocked_target_responds_without_changing_the_world() -> void:
	var hint: ActionHint = ActionHint.blocked(ActionVerb.CUT, ActionReason.NOT_COOKED)
	var target: FakeHintedInteractable = _hinted(hint)
	var item: FakePickable = _hold()
	assert_true(_component.interact_pressed())
	assert_eq(target.interact_count, 1, "el receptor decide su rama")
	assert_eq(target.effect_count, 0)
	assert_eq(_holder.get_held_item(), item, "la mano no cambia: no cae al suelo")
	assert_signal_emit_count(EventBus, "interaction_resolved", 1)
	assert_eq(_bus("interaction_resolved"), [1, &"cut", 2, &"not_cooked"])


func test_ac5_hint_is_recalculated_at_press_time() -> void:
	var target: FakeHintedInteractable = _hinted(ActionHint.ok(ActionVerb.PICK_UP))
	target.hint = ActionHint.blocked(ActionVerb.PICK_UP, ActionReason.BUSY)
	_component.interact_pressed()
	assert_eq(_bus("interaction_resolved"), [1, &"pick_up", 2, &"busy"])


func test_ac5_target_that_became_none_falls_to_the_floor_rule() -> void:
	var target: FakeHintedInteractable = _hinted(ActionHint.ok(ActionVerb.PICK_UP))
	target.hint = ActionHint.none()
	var item: FakePickable = _hold()
	assert_true(_component.interact_pressed())
	assert_eq(target.interact_count, 0)
	assert_false(item.is_held, "soltó al suelo")
	assert_eq(_bus("interaction_resolved"), [1, &"drop", 1, &""])


func test_ac5_free_floor_drops_and_responds_ok() -> void:
	var item: FakePickable = _hold()
	watch_signals(_component)
	assert_true(_component.interact_pressed())
	assert_false(item.is_held)
	assert_null(_holder.get_held_item())
	var params: Array = get_signal_parameters(_component, "interaction_resolved", 0)
	assert_null(params[0], "sin objetivo")
	assert_eq((params[1] as ActionHint).verb, ActionVerb.DROP)
	assert_eq((params[1] as ActionHint).state, ActionHint.State.OK)
	assert_eq(_bus("interaction_resolved"), [1, &"drop", 1, &""])


func test_ac5_blocked_floor_keeps_the_hand_and_responds_busy() -> void:
	var item: FakePickable = _hold()
	_holder.can_drop = false
	watch_signals(_component)
	assert_true(_component.interact_pressed())
	assert_true(item.is_held)
	assert_eq(_holder.get_held_item(), item)
	assert_signal_emit_count(_component, "interaction_resolved", 1)
	assert_signal_emit_count(EventBus, "interaction_resolved", 1)
	assert_eq(_bus("interaction_resolved"), [1, &"drop", 2, &"busy"])


func test_ac5_press_without_control_responds_locally_but_not_on_the_bus() -> void:
	var target: FakeHintedInteractable = _hinted(ActionHint.ok(ActionVerb.PICK_UP))
	_control.controlled_by = 0
	watch_signals(_component)
	assert_true(_component.interact_pressed())
	assert_eq(target.effect_count, 1)
	assert_signal_emit_count(_component, "interaction_resolved", 1)
	assert_signal_not_emitted(EventBus, "interaction_resolved")


func test_ac5_player_index_is_the_controlling_player_not_the_character() -> void:
	_control.player_index = 1
	_control.controlled_by = 2
	_hinted(ActionHint.ok(ActionVerb.PICK_UP))
	_component.interact_pressed()
	assert_eq(_bus("interaction_resolved")[0], 2)


func test_ac5_press_event_goes_through_the_same_path() -> void:
	var target: FakeHintedInteractable = _hinted(ActionHint.ok(ActionVerb.PICK_UP))
	_press()
	assert_eq(target.effect_count, 1)
	assert_signal_emit_count(EventBus, "interaction_resolved", 1)


func test_ac5_hint_changed_of_the_detector_goes_to_the_bus() -> void:
	var target: FakeInteractable = _target()
	var hint: ActionHint = ActionHint.blocked(ActionVerb.COOK, ActionReason.BUSY)
	_detector.hint_changed.emit(target, hint)
	assert_signal_emit_count(EventBus, "action_hint_changed", 1)
	assert_eq(_bus("action_hint_changed"), [1, &"cook", 2, &"busy"])


func test_ac5_hint_changed_is_not_forwarded_without_control() -> void:
	_control.controlled_by = 0
	var before: int = get_signal_emit_count(EventBus, "action_hint_changed")
	_detector.hint_changed.emit(null, ActionHint.ok(ActionVerb.DROP))
	assert_eq(get_signal_emit_count(EventBus, "action_hint_changed"), before)


func test_ac5_losing_control_announces_none_once_to_the_previous_player() -> void:
	_control.controlled_by = 0
	assert_signal_emit_count(EventBus, "action_hint_changed", 1)
	assert_eq(_bus("action_hint_changed"), [1, &"", 0, &""])


func test_ac5_gaining_control_announces_the_current_detector_hint_once() -> void:
	_control.controlled_by = 0
	_detector.hint = ActionHint.ok(ActionVerb.PICK_UP)
	_control.controlled_by = 1
	assert_signal_emit_count(EventBus, "action_hint_changed", 2)
	assert_eq(_bus("action_hint_changed", 1), [1, &"pick_up", 1, &""])


func test_ac5_character_switch_leaves_the_incoming_hint_as_the_last_fact() -> void:
	# CharacterSwitcher pone 0 al saliente y después 1 al entrante (ADR-004 §4).
	var incoming_control: ControlComponent = ControlComponent.new()
	incoming_control.controlled_by = 0
	add_child_autofree(incoming_control)
	var incoming_detector: FakeDetector = add_child_autofree(FakeDetector.new())
	incoming_detector.hint = ActionHint.blocked(ActionVerb.CUT, ActionReason.FULL)
	var incoming: InteractionComponent = InteractionComponent.new()
	incoming.control = incoming_control
	incoming.holder = add_child_autofree(FakeHolder.new())
	incoming.detector = incoming_detector
	add_child_autofree(incoming)
	_control.controlled_by = 0
	incoming_control.controlled_by = 1
	assert_signal_emit_count(EventBus, "action_hint_changed", 2)
	assert_eq(_bus("action_hint_changed", 0), [1, &"", 0, &""], "NONE del saliente")
	assert_eq(_bus("action_hint_changed", 1), [1, &"cut", 2, &"full"], "hint del entrante")


## PUL-131 (revisión de PUL-121): un receptor con verbo real cuyo `interact` devuelve `false`
## incumple §11.2 (`push_error`), pero la pulsación no queda muda: se responde con un rechazo.
func test_pul131_receiver_that_lies_gives_an_error_and_a_rejection_not_silence() -> void:
	var target: LyingTarget = add_child_autofree(LyingTarget.new())
	target.hint = ActionHint.ok(ActionVerb.COOK)
	_detector.target_changed.emit(null, target)
	var item: FakePickable = _hold()
	watch_signals(_component)
	assert_true(_component.interact_pressed())
	assert_push_error("interact() devolvió false")
	assert_signal_emit_count(_component, "interaction_resolved", 1)
	assert_signal_emit_count(EventBus, "interaction_resolved", 1)
	assert_eq(_bus("interaction_resolved"), [1, &"cook", 2, &"busy"])
	assert_eq(_holder.get_held_item(), item, "la mano no cambia")


## ADR-002 Enmienda 2: en cada instante hay como mucho un `InteractionComponent` controlado por
## cada jugador (es el emisor único del bus para ese `player_index`).
func _controlled_count(components: Array[InteractionComponent], player: int) -> int:
	var count: int = 0
	for component: InteractionComponent in components:
		if component.control.controlled_by == player:
			count += 1
	return count


func _team(mode: GameMode.Mode) -> Dictionary:
	var components: Array[InteractionComponent] = []
	var controls: Array[ControlComponent] = []
	for i: int in 2:
		var control: ControlComponent = ControlComponent.new()
		control.player_index = i + 1
		control.controlled_by = 0
		add_child_autofree(control)
		controls.append(control)
		var component: InteractionComponent = InteractionComponent.new()
		component.control = control
		component.holder = add_child_autofree(FakeHolder.new())
		component.detector = add_child_autofree(FakeDetector.new())
		add_child_autofree(component)
		components.append(component)
	var switcher: CharacterSwitcher = CharacterSwitcher.new()
	switcher.characters = controls
	switcher.set_mode(mode)
	add_child_autofree(switcher)
	EventBus.round_started.emit(60.0)
	return {"components": components, "switcher": switcher}


func test_pul131_single_after_several_switches_one_component_per_player() -> void:
	var team: Dictionary = _team(GameMode.Mode.SINGLE)
	var components: Array[InteractionComponent] = team["components"]
	var switcher: CharacterSwitcher = team["switcher"]
	for round_index: int in 7:
		assert_eq(_controlled_count(components, 1), 1, "tras %d cambios, J1" % round_index)
		assert_eq(_controlled_count(components, 2), 0, "tras %d cambios, J2" % round_index)
		switcher.advance(10.0)
		assert_true(switcher.switch_pressed())


func test_pul131_coop_each_player_has_exactly_one_component() -> void:
	var team: Dictionary = _team(GameMode.Mode.COOP_2P)
	var components: Array[InteractionComponent] = team["components"]
	assert_eq(_controlled_count(components, 1), 1)
	assert_eq(_controlled_count(components, 2), 1)
	assert_ne(components[0].control.controlled_by, components[1].control.controlled_by)


# --- PUL-121 AC6: mantener para cortar (ADR-003 §11.4) ------------------------------------------


func _cut_target() -> FakeHintedInteractable:
	var target: FakeHintedInteractable = _hinted(ActionHint.ok(ActionVerb.CUT, 0.0))
	Input.action_press(&"p1_interact")
	return target


func _advance(seconds: float, step: float = REPEAT_STEP) -> void:
	for _i: int in roundi(seconds / step):
		_component._physics_process(step)


func test_ac6_holding_cut_repeats_every_0_2_s_six_cuts_in_1_05_s() -> void:
	var target: FakeHintedInteractable = _cut_target()
	_press()
	assert_eq(target.effect_count, 1, "el primer corte es al pulsar")
	_advance(1.05)
	assert_eq(target.effect_count, 6)
	assert_signal_emit_count(EventBus, "interaction_resolved", 6)


func test_ac6_no_repeat_before_the_interval() -> void:
	var target: FakeHintedInteractable = _cut_target()
	_press()
	_advance(0.15)
	assert_eq(target.effect_count, 1)


func test_ac6_releasing_the_action_stops_the_repeat_without_a_press() -> void:
	var target: FakeHintedInteractable = _cut_target()
	_press()
	_advance(0.45)
	assert_eq(target.effect_count, 3)
	Input.action_release(&"p1_interact")
	_advance(1.0)
	assert_eq(target.effect_count, 3)


func test_ac6_a_tap_gives_one_cut() -> void:
	var target: FakeHintedInteractable = _hinted(ActionHint.ok(ActionVerb.CUT, 0.0))
	_press()  # sin mantener: la acción ya no está pulsada en el siguiente tick
	_advance(1.0)
	assert_eq(target.effect_count, 1)


func test_ac6_becoming_blocked_stops_the_repeat_without_a_rejection() -> void:
	var target: FakeHintedInteractable = _cut_target()
	_press()
	_advance(0.45)
	assert_eq(target.effect_count, 3)
	target.hint = ActionHint.blocked(ActionVerb.CUT, ActionReason.FULL)
	_advance(1.0)
	assert_eq(target.effect_count, 3)
	assert_eq(target.interact_count, 3, "ni siquiera se llama a interact: sin rechazo")
	assert_signal_emit_count(EventBus, "interaction_resolved", 3)


func test_ac6_changing_target_stops_the_repeat() -> void:
	var first: FakeHintedInteractable = _cut_target()
	_press()
	var second: FakeHintedInteractable = _hinted(ActionHint.ok(ActionVerb.CUT, 0.0))
	_advance(1.0)
	assert_eq(first.effect_count, 1)
	assert_eq(second.effect_count, 0)


func test_ac6_other_verbs_are_not_repeated() -> void:
	var target: FakeHintedInteractable = _hinted(ActionHint.ok(ActionVerb.PICK_UP))
	Input.action_press(&"p1_interact")
	_press()
	_advance(1.0)
	assert_eq(target.effect_count, 1)


func test_ac6_a_new_press_while_holding_still_counts() -> void:
	var target: FakeHintedInteractable = _cut_target()
	_press()
	_advance(0.1)
	_press()  # pulsar sigue valiendo (D13)
	assert_eq(target.effect_count, 2)


func test_ac6_losing_control_stops_the_repeat() -> void:
	var target: FakeHintedInteractable = _cut_target()
	_press()
	_control.controlled_by = 0
	_advance(1.0)
	assert_eq(target.effect_count, 1)


func test_ac6_repeat_freezes_with_the_pause() -> void:
	var target: FakeHintedInteractable = _cut_target()
	_press()
	await wait_physics_frames(6)
	GameState.set_paused(true)
	await wait_physics_frames(40)
	assert_eq(target.effect_count, 1, "en pausa el temporizador no avanza")
	GameState.set_paused(false)
	await wait_physics_frames(10)
	assert_eq(target.effect_count, 2, "al reanudar completa el intervalo")


func test_ac6_interval_comes_from_the_input_config() -> void:
	var config: InputConfig = InputConfig.new()
	config.cut_repeat_interval = 0.5
	var control: ControlComponent = ControlComponent.new()
	control.config = config
	add_child_autofree(control)
	var component: InteractionComponent = InteractionComponent.new()
	component.control = control
	component.holder = _holder
	component.detector = _detector
	add_child_autofree(component)
	var target: FakeHintedInteractable = add_child_autofree(FakeHintedInteractable.new())
	target.hint = ActionHint.ok(ActionVerb.CUT)
	_detector.target_changed.emit(null, target)
	Input.action_press(&"p1_interact")
	component.interact_pressed()
	for _i: int in 9:
		component._physics_process(0.05)
	assert_eq(target.effect_count, 1)
	component._physics_process(0.05)
	assert_eq(target.effect_count, 2)


## Doble de un receptor que miente: publica un verbo real pero `interact` no hace nada.
class LyingTarget:
	extends FakeHintedInteractable

	func interact(_actor: InteractionComponent) -> bool:
		return false
