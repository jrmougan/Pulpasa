extends GutTest
## PUL-014 AC2: InteractionComponent despacha la pulsación de interactuar.

var _control: ControlComponent
var _holder: FakeHolder
var _detector: FakeDetector
var _component: InteractionComponent


func before_each() -> void:
	_control = add_child_autofree(ControlComponent.new())
	_holder = add_child_autofree(FakeHolder.new())
	_detector = add_child_autofree(FakeDetector.new())
	_component = InteractionComponent.new()
	_component.control = _control
	_component.holder = _holder
	_component.detector = _detector
	add_child_autofree(_component)


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
