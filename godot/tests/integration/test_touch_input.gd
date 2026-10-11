extends GutTest
## PUL-128 AC6/AC7/AC20/AC21 (controles-tactiles AC6, AC7, AC20, AC21): los controles táctiles
## producen las mismas acciones que teclado y mando de J1 (sin eventos nuevos en el InputMap), el
## personaje reacciona igual (5 m/s), la latencia es de un frame y el mando oculta los controles.

const SCENE: PackedScene = preload("res://ui/touch/touch_controls.tscn")
const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const CAMERA_SCENE: PackedScene = preload("res://entities/camera/camera_rig.tscn")
const SWITCHER_SCENE: PackedScene = preload("res://entities/player/character_switcher.tscn")
const EventBusScript: GDScript = preload("res://autoload/event_bus.gd")
const SAFE: Rect2 = Rect2(132.0, 0.0, 2076.0, 1017.0)
const ACTION_PX: Vector2 = Vector2(2070.0, 879.0)
const SWITCH_PX: Vector2 = Vector2(2070.0, 705.0)
const PAUSE_PX: Vector2 = Vector2(2100.0, 108.0)
const STICK_PX: Vector2 = Vector2(300.0, 700.0)
const TICK: float = 1.0 / 60.0

var _original_size: Vector2i
var _controls: TouchControls
var _seen: Array[StringName] = []
var _bus: Node


class Probe:
	extends Node
	var seen: Array[StringName] = []

	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventAction and event.pressed:
			seen.append(event.action)


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


func after_each() -> void:
	_controls.release_all()
	Input.flush_buffered_events()
	get_window().size = _original_size
	GameState.set_platform(PlatformProfile.Kind.DESKTOP)
	GameState.mode = GameMode.Mode.SINGLE


func _scale() -> float:
	return get_viewport().get_final_transform().get_scale().y


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


func _joypad_button() -> InputEventJoypadButton:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_A
	event.pressed = true
	return event


func _stick_node() -> VirtualStick:
	return _controls.get_node(^"%MoveStick") as VirtualStick


func _action_button() -> ActionButton:
	return _controls.get_node(^"%ActionButton") as ActionButton


# --- AC6: mismas acciones ------------------------------------------------------------------------


func test_ac6_each_control_produces_the_player_one_action() -> void:
	var probe: Probe = add_child_autofree(Probe.new())
	_touch(0, ACTION_PX, true)
	_touch(0, ACTION_PX, false)
	_touch(1, SWITCH_PX, true)
	_touch(1, SWITCH_PX, false)
	_touch(2, PAUSE_PX, true)
	_touch(2, PAUSE_PX, false)
	assert_eq(probe.seen, [&"p1_interact", &"p1_switch", &"pause"] as Array[StringName])


func test_ac6_actions_exist_in_the_input_map_unchanged_by_touch() -> void:
	for action: StringName in [&"p1_interact", &"p1_switch", &"pause"] + TouchInput.MOVE_ACTIONS:
		assert_true(InputMap.has_action(action), action)
		for event: InputEvent in InputMap.action_get_events(action):
			assert_false(event is InputEventScreenTouch, action)
			assert_false(event is InputEventScreenDrag, action)


func test_ac6_stick_feeds_the_same_vector_player_input_reads() -> void:
	_touch(0, STICK_PX, true)
	_drag(0, STICK_PX + Vector2(150.0, 0.0))
	var reader: PlayerInput = PlayerInput.new(1, 0.2)
	assert_almost_eq(reader.get_move_vector().x, 1.0, 0.01)
	_drag(0, STICK_PX + Vector2(0.0, -150.0))
	assert_almost_eq(reader.get_move_vector().y, -1.0, 0.01)
	_touch(0, STICK_PX, false)
	assert_eq(reader.get_move_vector(), Vector2.ZERO)


func _build_level() -> Array:
	var level: Node3D = add_child_autofree(Node3D.new())
	_bus = autofree(EventBusScript.new())
	var camera: Camera3D = CAMERA_SCENE.instantiate()
	level.add_child(camera)
	var player: Player = PLAYER_SCENE.instantiate()
	player.set_bus(_bus)
	player.camera = camera
	level.add_child(player)
	(player.get_node(^"%Control") as ControlComponent).player_index = 1
	return [level, player]


func test_ac6_full_stick_moves_the_character_five_meters_in_one_second() -> void:
	var player: Player = _build_level()[1]
	_bus.round_started.emit(180.0)
	var start: Vector3 = player.global_position
	_touch(0, STICK_PX, true)
	_drag(0, STICK_PX + Vector2(150.0, 0.0))
	var first: int = Engine.get_physics_frames()
	await wait_physics_frames(60)
	var seconds: float = (Engine.get_physics_frames() - first) * TICK
	var moved: Vector3 = player.global_position - start
	moved.y = 0.0
	assert_almost_eq(moved.length(), 5.0 * seconds, 0.25, "5 m/s con magnitud 1,0")
	_touch(0, STICK_PX, false)


func test_ac6_a_touch_inside_the_deadzone_does_not_move_the_character() -> void:
	var player: Player = _build_level()[1]
	_bus.round_started.emit(180.0)
	var start: Vector3 = player.global_position
	_touch(0, STICK_PX, true)
	_drag(0, STICK_PX + Vector2(20.0, 0.0))
	await wait_physics_frames(30)
	_touch(0, STICK_PX, false)
	assert_almost_eq(player.global_position.distance_to(start), 0.0, 0.01)


func test_ac6_switch_button_changes_the_controlled_character() -> void:
	var built: Array = _build_level()
	var level: Node3D = built[0]
	var first: Player = built[1]
	var second: Player = PLAYER_SCENE.instantiate()
	second.set_bus(_bus)
	second.camera = first.camera
	second.position = Vector3(3.0, 0.0, 0.0)
	level.add_child(second)
	var first_control: ControlComponent = first.get_node(^"%Control") as ControlComponent
	var second_control: ControlComponent = second.get_node(^"%Control") as ControlComponent
	second_control.player_index = 2
	var switcher: CharacterSwitcher = SWITCHER_SCENE.instantiate()
	switcher.set_bus(_bus)
	switcher.set_mode(GameMode.Mode.SINGLE)
	switcher.characters = [first_control, second_control]
	level.add_child(switcher)
	_bus.round_started.emit(180.0)
	assert_eq(first_control.controlled_by, 1)
	_touch(0, SWITCH_PX, true)
	_touch(0, SWITCH_PX, false)
	assert_eq(first_control.controlled_by, 0)
	assert_eq(second_control.controlled_by, 1)


# --- AC7: latencia -------------------------------------------------------------------------------


func test_ac7_touch_on_the_action_button_emits_interact_in_the_same_frame() -> void:
	var probe: Probe = add_child_autofree(Probe.new())
	var frame: int = Engine.get_process_frames()
	_touch(0, ACTION_PX, true)
	assert_eq(Engine.get_process_frames(), frame, "sin esperar ningún frame")
	assert_eq(probe.seen, [&"p1_interact"] as Array[StringName])
	assert_true(Input.is_action_just_pressed(&"p1_interact"))
	_touch(0, ACTION_PX, false)


func test_ac7_the_icon_changes_within_the_same_frame_of_the_hint() -> void:
	var button: ActionButton = _action_button()
	EventBus.action_hint_changed.emit(1, ActionVerb.CUT, ActionHint.State.OK, ActionReason.NONE)
	assert_eq(button.get_verb(), ActionVerb.CUT, "<= 0,1 s: inmediato")
	EventBus.action_hint_changed.emit(1, ActionVerb.TRASH, ActionHint.State.OK, ActionReason.NONE)
	assert_eq(button.get_verb(), ActionVerb.TRASH)


func test_ac7_the_visual_icon_is_redrawn_within_a_frame() -> void:
	var button: ActionButton = _action_button()
	EventBus.action_hint_changed.emit(1, ActionVerb.COOK, ActionHint.State.OK, ActionReason.NONE)
	await wait_process_frames(1)
	assert_eq(button.get_icon_texture(), button.icons.verb_icons[ActionVerb.COOK])


# --- AC20: el mando oculta los controles -------------------------------------------------------


func test_ac20_controls_are_visible_at_start_on_mobile_single() -> void:
	assert_true(_controls.visible)


func test_ac20_gamepad_event_hides_the_controls_at_once() -> void:
	_deliver(_joypad_button())
	assert_false(_controls.visible)


func test_ac20_gamepad_stick_beyond_the_deadzone_hides_them_and_noise_does_not() -> void:
	var noise: InputEventJoypadMotion = InputEventJoypadMotion.new()
	noise.axis_value = 0.05
	_deliver(noise)
	assert_true(_controls.visible)
	var motion: InputEventJoypadMotion = InputEventJoypadMotion.new()
	motion.axis_value = 0.8
	_deliver(motion)
	assert_false(_controls.visible)


func test_ac20_a_touch_brings_them_back() -> void:
	_deliver(_joypad_button())
	_touch(0, Vector2(1500.0, 500.0), true)
	_touch(0, Vector2(1500.0, 500.0), false)
	assert_true(_controls.visible)


func test_ac20_keyboard_does_not_hide_them() -> void:
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_D
	key.pressed = true
	_deliver(key)
	assert_true(_controls.visible)


func test_ac20_mouse_and_injected_actions_do_not_change_the_source() -> void:
	_deliver(_joypad_button())
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	_deliver(click)
	var action: InputEventAction = InputEventAction.new()
	action.action = &"p1_interact"
	action.pressed = true
	_deliver(action)
	assert_false(_controls.visible)
	assert_eq(_controls.get_last_source(), TouchInput.Source.JOYPAD)


func test_ac20_hidden_controls_ignore_touches_on_their_buttons() -> void:
	_deliver(_joypad_button())
	var probe: Probe = add_child_autofree(Probe.new())
	_touch(0, ACTION_PX, true)
	assert_eq(probe.seen, [] as Array[StringName])
	assert_false(_action_button().is_pressed())


func test_ac20_the_gamepad_hides_the_controls_while_the_stick_is_held() -> void:
	_touch(0, STICK_PX, true)
	_drag(0, STICK_PX + Vector2(150.0, 0.0))
	_deliver(_joypad_button())
	assert_false(_stick_node().is_active())
	assert_eq(Input.get_action_strength(&"p1_move_right"), 0.0)


# --- AC21: perfiles ------------------------------------------------------------------------------


func test_ac21_local_two_player_mode_keeps_the_controls_hidden() -> void:
	GameState.mode = GameMode.Mode.COOP_2P
	_controls.set_last_source(TouchInput.Source.TOUCH)
	assert_false(_controls.visible)
	GameState.mode = GameMode.Mode.SINGLE
	_controls.set_last_source(TouchInput.Source.TOUCH)
	assert_true(_controls.visible)
