extends GutTest
## PUL-127 AC2/AC5 (D26.3, ADR-006 §4.1): el jugador da la respuesta sonora. Rechazo
## (`interaction_resolved` con `BLOCKED`): exactamente un cue `rejected`, sea cual sea el motivo,
## con `SHAKE` del objetivo (o del propio personaje sin objetivo). Éxito: el jugador no suma
## cue (suena el del efecto). Cambio de personaje en ronda: un `switch` en el que recibe el
## control; no al arrancar la ronda.

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const SWITCHER_SCENE: PackedScene = preload("res://entities/player/character_switcher.tscn")
const EventBusScript: GDScript = preload("res://autoload/event_bus.gd")

var _level: Node3D
var _bus: Node
var _player: Player
var _actor: InteractionComponent
var _target: HintedTarget
var _switcher: CharacterSwitcher
var _cues: Array[StringName] = []


class HintedTarget:
	extends Node3D
	## Objetivo 3D con consulta de acción: `interact` cuenta los efectos `OK`.

	var hint: ActionHint = ActionHint.none()
	var effect_count: int = 0

	func get_action_hint(_actor: InteractionComponent) -> ActionHint:
		return hint

	func can_interact(_actor: InteractionComponent) -> bool:
		return hint.is_target()

	func interact(_actor: InteractionComponent) -> bool:
		if hint.state == ActionHint.State.OK:
			effect_count += 1
		return hint.is_target()


func before_each() -> void:
	_cues.clear()
	_level = add_child_autofree(Node3D.new())
	_bus = autofree(EventBusScript.new())
	_player = _add_player(1, Vector3.ZERO)
	_actor = _player.get_node(^"%InteractionComponent") as InteractionComponent
	_target = HintedTarget.new()
	_target.position = Vector3(0.0, 0.0, -1.0)
	_level.add_child(_target)


func _add_player(index: int, at: Vector3) -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	player.set_bus(_bus)
	player.position = at
	_level.add_child(player)
	var control: ControlComponent = player.get_node(^"%Control") as ControlComponent
	control.player_index = index
	control.controlled_by = index
	_feedback_of(player).played.connect(_on_played)
	return player


func _feedback_of(player: Player) -> FeedbackPlayer:
	return player.get_node(^"%Feedback") as FeedbackPlayer


func _on_played(cue: StringName) -> void:
	_cues.append(cue)


func _count(cue: StringName) -> int:
	return _cues.count(cue)


func _blocked() -> ActionHint:
	return ActionHint.blocked(ActionVerb.CUT, ActionReason.FULL)


func test_blocked_press_plays_exactly_one_rejected() -> void:
	_actor.interaction_resolved.emit(_target, _blocked())
	assert_eq(_cues, [&"rejected"] as Array[StringName])


func test_any_reason_gives_the_same_single_cue() -> void:
	for reason: StringName in ActionReason.ALL:
		_cues.clear()
		_actor.interaction_resolved.emit(_target, ActionHint.blocked(ActionVerb.COOK, reason))
		assert_eq(_cues, [&"rejected"] as Array[StringName], "motivo %s" % reason)


func test_ok_press_adds_no_cue_from_the_player() -> void:
	_actor.interaction_resolved.emit(_target, ActionHint.ok(ActionVerb.PICK_UP))
	assert_eq(_cues.size(), 0)


func test_two_presses_100ms_apart_give_two_cues() -> void:
	_actor.interaction_resolved.emit(_target, _blocked())
	await get_tree().create_timer(0.1).timeout
	_actor.interaction_resolved.emit(_target, _blocked())
	assert_eq(_count(&"rejected"), 2)


func test_rejection_shakes_the_target() -> void:
	var feedback: FeedbackPlayer = _feedback_of(_player)
	_actor.interaction_resolved.emit(_target, _blocked())
	assert_not_null(feedback.get_visual_tween(_target), "SHAKE del objetivo")
	assert_null(feedback.get_visual_tween(_player))


func test_rejection_without_target_shakes_the_character() -> void:
	var feedback: FeedbackPlayer = _feedback_of(_player)
	_actor.interaction_resolved.emit(null, ActionHint.blocked(ActionVerb.DROP, ActionReason.BUSY))
	assert_eq(_cues, [&"rejected"] as Array[StringName])
	assert_not_null(feedback.get_visual_tween(_player), "SHAKE del propio personaje")


func test_real_press_on_a_blocked_target_plays_one_rejected_and_changes_nothing() -> void:
	_target.hint = ActionHint.blocked(ActionVerb.CUT, ActionReason.NOT_COOKED)
	var detector: InteractionDetector = _player.get_node(^"%InteractionDetector")
	detector.target_changed.emit(null, _target)
	assert_true(_actor.interact_pressed())
	assert_eq(_cues, [&"rejected"] as Array[StringName])
	assert_eq(_target.effect_count, 0, "BLOCKED no cambia nada")


func test_real_press_on_an_ok_target_has_no_rejected() -> void:
	_target.hint = ActionHint.ok(ActionVerb.PICK_UP)
	var detector: InteractionDetector = _player.get_node(^"%InteractionDetector")
	detector.target_changed.emit(null, _target)
	assert_true(_actor.interact_pressed())
	assert_eq(_count(&"rejected"), 0)
	assert_eq(_target.effect_count, 1)


func _start_two(mode: GameMode.Mode) -> Player:
	var second: Player = _add_player(2, Vector3(3.0, 0.0, 0.0))
	_switcher = SWITCHER_SCENE.instantiate()
	_switcher.set_bus(_bus)
	_switcher.set_mode(mode)
	_switcher.characters = [
		_player.get_node(^"%Control") as ControlComponent,
		second.get_node(^"%Control") as ControlComponent
	]
	_level.add_child(_switcher)
	_bus.round_started.emit(180.0)
	await wait_process_frames(2)
	return second


func test_switch_does_not_play_when_the_round_starts() -> void:
	await _start_two(GameMode.Mode.SINGLE)
	assert_eq(_count(&"switch"), 0)


func test_switch_does_not_play_for_both_players_at_coop_start() -> void:
	await _start_two(GameMode.Mode.COOP_2P)
	assert_eq(_count(&"switch"), 0)


func test_switch_plays_once_on_the_character_that_receives_control() -> void:
	var second: Player = await _start_two(GameMode.Mode.SINGLE)
	var played_on_second: Array[StringName] = []
	_feedback_of(second).played.connect(func(cue: StringName) -> void: played_on_second.append(cue))
	_cues.clear()
	assert_true(_switcher.switch_pressed())
	assert_eq(played_on_second, [&"switch"] as Array[StringName], "el entrante")
	assert_eq(_count(&"switch"), 1, "el saliente no suena: solo el entrante")
	assert_not_null(_feedback_of(second).get_visual_tween(second), "POP del personaje")


func test_switch_does_not_play_outside_the_round() -> void:
	var second: Player = await _start_two(GameMode.Mode.SINGLE)
	_bus.round_finished.emit(null)
	_cues.clear()
	_bus.character_switched.emit(1, (second.get_node(^"%Control") as ControlComponent).player_index)
	assert_eq(_count(&"switch"), 0)
