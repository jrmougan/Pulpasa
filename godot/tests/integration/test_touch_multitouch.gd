extends GutTest
## PUL-128 AC5 (controles-tactiles AC5): multitáctil por `event.index`. Tres contactos a la vez
## (stick, acción, cambiar) sin interferirse; un contacto pertenece al control donde empezó.

const SCENE: PackedScene = preload("res://ui/touch/touch_controls.tscn")
const SAFE: Rect2 = Rect2(132.0, 0.0, 2076.0, 1017.0)
const ACTION_PX: Vector2 = Vector2(2070.0, 879.0)
## Cambiar en fila a la izquierda de acción (D27.1): acción + (−(90 + 24 + 60), 90 − 60).
const SWITCH_PX: Vector2 = Vector2(1896.0, 909.0)
const PAUSE_PX: Vector2 = Vector2(2100.0, 108.0)
const STICK_PX: Vector2 = Vector2(300.0, 700.0)

var _original_size: Vector2i
var _controls: TouchControls
var _probe: Probe


## Cuenta las pulsaciones de acción que llegan a `_unhandled_input`, como el juego.
class Probe:
	extends Node
	var presses: Dictionary[StringName, int] = {}
	var releases: Dictionary[StringName, int] = {}

	func _unhandled_input(event: InputEvent) -> void:
		var action: InputEventAction = event as InputEventAction
		if action == null:
			return
		var counts: Dictionary[StringName, int] = presses if action.pressed else releases
		counts[action.action] = counts.get(action.action, 0) + 1

	func pressed(action: StringName) -> int:
		return presses.get(action, 0)

	func released(action: StringName) -> int:
		return releases.get(action, 0)


func before_each() -> void:
	_original_size = get_window().size
	GameState.set_platform(PlatformProfile.Kind.MOBILE)
	GameState.mode = GameMode.Mode.SINGLE
	get_window().size = Vector2i(2340, 1080)
	await wait_process_frames(3)
	_controls = SCENE.instantiate()
	add_child_autofree(_controls)
	_probe = add_child_autofree(Probe.new())
	await wait_process_frames(2)
	_controls.apply_safe_rect(SAFE, Vector2(2340.0, 1080.0))
	await wait_process_frames(2)


func after_each() -> void:
	_controls.release_all()
	get_window().size = _original_size
	GameState.set_platform(PlatformProfile.Kind.DESKTOP)


func _scale() -> float:
	return get_viewport().get_final_transform().get_scale().y


## Entrega el evento y vacía el búfer de `Input` (el `parse_input_event` de los controles se
## procesa en el mismo vaciado, que en el juego ocurre en el mismo frame).
func _deliver(event: InputEvent) -> void:
	get_viewport().push_input(event, true)
	Input.flush_buffered_events()


func _touch(index: int, px: Vector2, pressed: bool) -> void:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = index
	event.position = px / _scale()
	event.pressed = pressed
	_deliver(event)


func _drag(index: int, px: Vector2) -> void:
	var event: InputEventScreenDrag = InputEventScreenDrag.new()
	event.index = index
	event.position = px / _scale()
	_deliver(event)


func _stick() -> VirtualStick:
	return _controls.get_node(^"%MoveStick") as VirtualStick


func _action() -> ActionButton:
	return _controls.get_node(^"%ActionButton") as ActionButton


func _switch() -> TouchButton:
	return _controls.get_node(^"%SwitchButton") as TouchButton


func test_ac5_three_simultaneous_contacts_do_not_interfere() -> void:
	_touch(0, STICK_PX, true)
	_drag(0, STICK_PX + Vector2(75.0, 0.0))
	_touch(1, ACTION_PX, true)
	_touch(2, SWITCH_PX, true)
	assert_almost_eq(Input.get_action_strength(&"p1_move_right"), 0.5, 0.02, "stick")
	assert_eq(_probe.pressed(&"p1_interact"), 1)
	assert_eq(_probe.pressed(&"p1_switch"), 1)
	assert_true(Input.is_action_pressed(&"p1_interact"))
	assert_true(Input.is_action_pressed(&"p1_switch"))
	_touch(1, ACTION_PX, false)
	assert_almost_eq(Input.get_action_strength(&"p1_move_right"), 0.5, 0.02, "el stick sigue")
	assert_true(Input.is_action_pressed(&"p1_switch"), "cambiar sigue")
	assert_false(Input.is_action_pressed(&"p1_interact"))
	_touch(2, SWITCH_PX, false)
	_touch(0, STICK_PX, false)
	assert_eq(_probe.pressed(&"p1_interact"), 1)
	assert_eq(_probe.pressed(&"p1_switch"), 1)
	assert_eq(_probe.released(&"p1_interact"), 1)
	assert_eq(_probe.released(&"p1_switch"), 1)
	assert_eq(Input.get_action_strength(&"p1_move_right"), 0.0)


func test_ac5_stick_finger_sliding_over_the_action_button_does_not_press_it() -> void:
	_touch(0, STICK_PX, true)
	_drag(0, Vector2(1000.0, 800.0))
	_drag(0, ACTION_PX)
	_drag(0, ACTION_PX + Vector2(5.0, 5.0))
	assert_false(_action().is_pressed())
	assert_eq(_probe.pressed(&"p1_interact"), 0)
	assert_true(_stick().is_active(), "el stick conserva su contacto")
	_touch(0, ACTION_PX, false)
	assert_eq(_probe.pressed(&"p1_interact"), 0)
	assert_false(_stick().is_active())


func test_ac5_button_finger_leaving_the_button_keeps_the_press_until_lifted() -> void:
	_touch(1, ACTION_PX, true)
	_drag(1, Vector2(1500.0, 500.0))
	_drag(1, Vector2(600.0, 600.0))
	assert_true(_action().is_pressed())
	assert_true(Input.is_action_pressed(&"p1_interact"))
	assert_false(_stick().is_active(), "ese dedo no inicia el stick al pasar por su zona")
	assert_eq(_probe.released(&"p1_interact"), 0)
	_touch(1, Vector2(600.0, 600.0), false)
	assert_false(_action().is_pressed())
	assert_eq(_probe.released(&"p1_interact"), 1)
	assert_false(Input.is_action_pressed(&"p1_interact"))


func test_ac5_finger_dragged_onto_a_button_does_not_press_it() -> void:
	_touch(3, Vector2(1500.0, 500.0), true)
	_drag(3, SWITCH_PX)
	_touch(3, SWITCH_PX, false)
	assert_eq(_probe.pressed(&"p1_switch"), 0)
	assert_false(Input.is_action_pressed(&"p1_switch"))


func test_ac5_second_finger_on_a_pressed_button_is_ignored() -> void:
	_touch(1, ACTION_PX, true)
	_touch(2, ACTION_PX + Vector2(10.0, 0.0), true)
	assert_eq(_probe.pressed(&"p1_interact"), 1)
	_touch(2, ACTION_PX, false)
	assert_true(_action().is_pressed(), "soltar el dedo ajeno no suelta el botón")
	assert_eq(_action().get_touch_index(), 1)
	_touch(1, ACTION_PX, false)
	assert_false(_action().is_pressed())


func test_ac5_each_press_is_one_interact_even_with_repeated_taps() -> void:
	for _i: int in 3:
		_touch(1, ACTION_PX, true)
		_touch(1, ACTION_PX, false)
	assert_eq(_probe.pressed(&"p1_interact"), 3)
	assert_eq(_probe.released(&"p1_interact"), 3)


func test_ac5_the_touch_slop_extends_the_action_button_hit_zone() -> void:
	_touch(1, ACTION_PX + Vector2(97.0, 0.0), true)
	assert_true(_action().is_pressed(), "a 97 px del centro: dentro de 90 + 12")
	_touch(1, ACTION_PX, false)
	_touch(1, ACTION_PX + Vector2(105.0, 0.0), true)
	assert_false(_action().is_pressed(), "a 105 px: fuera")


func test_ac5_pause_button_sends_pause_and_releases_on_lift() -> void:
	_touch(0, PAUSE_PX, true)
	assert_eq(_probe.pressed(&"pause"), 1)
	_touch(0, PAUSE_PX, false)
	assert_eq(_probe.released(&"pause"), 1)


func test_ac5_hiding_the_controls_releases_every_pressed_action() -> void:
	_touch(1, ACTION_PX, true)
	_touch(2, SWITCH_PX, true)
	_controls.set_last_source(TouchInput.Source.JOYPAD)
	Input.flush_buffered_events()
	assert_false(Input.is_action_pressed(&"p1_interact"))
	assert_false(Input.is_action_pressed(&"p1_switch"))
	assert_eq(_probe.released(&"p1_interact"), 1)
	assert_eq(_probe.released(&"p1_switch"), 1)


func test_ac5_leaving_the_tree_releases_the_actions() -> void:
	_touch(1, ACTION_PX, true)
	assert_true(Input.is_action_pressed(&"p1_interact"))
	_controls.get_parent().remove_child(_controls)
	Input.flush_buffered_events()
	assert_false(Input.is_action_pressed(&"p1_interact"))
	add_child_autofree(_controls)
