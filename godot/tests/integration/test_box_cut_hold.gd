extends GutTest
## PUL-125 AC2 (diseño AC13, ADR-003 §11.4): mantener la acción sobre una caja con pulpo cocido
## corta cada `cut_repeat_interval` (0,2 s): 1,05 s mantenido son 6 cortes y medio pulpo gastado,
## sin rechazo mientras sigue pulsada; soltar y pulsar sobre la caja llena da 1 rechazo `full`;
## un toque de menos de 0,2 s da 1 corte. Jugador, caja y pulpo reales; el reloj se inyecta con
## `_physics_process(delta)` del componente.

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const ACTION: StringName = &"p1_interact"
const STEP: float = 0.05

var _level: Node3D
var _hold: HoldComponent
var _actor: InteractionComponent
var _box: Box
var _octopus: Ingredient


func before_each() -> void:
	_level = add_child_autofree(Node3D.new())
	var player: Player = PLAYER_SCENE.instantiate()
	_level.add_child(player)
	_hold = player.get_node("%HoldComponent")
	_hold.items_root = _level
	_actor = player.get_node("%InteractionComponent")
	_box = _new_box()
	_octopus = OCTOPUS_SCENE.instantiate()
	_level.add_child(_octopus)
	_octopus.set_cooked()
	assert_true(_hold.pick_up(_octopus))


func after_each() -> void:
	Input.action_release(ACTION)


func _new_box() -> Box:
	var box: Box = BOX_SCENE.instantiate()
	_level.add_child(box)
	box.position = Vector3(1.0, 0.0, 0.0)
	_actor.detector.target_changed.emit(null, box)
	return box


func _advance(seconds: float) -> void:
	for _i: int in roundi(seconds / STEP):
		_actor._physics_process(STEP)


func _resolved(state: ActionHint.State) -> int:
	var count: int = 0
	for index: int in get_signal_emit_count(_actor, "interaction_resolved"):
		var params: Array = get_signal_parameters(_actor, "interaction_resolved", index)
		if (params[1] as ActionHint).state == state:
			count += 1
	return count


func test_ac2_holding_1_05_s_gives_6_cuts_and_half_an_octopus_without_rejection() -> void:
	watch_signals(_actor)
	Input.action_press(ACTION)
	assert_true(_actor.interact_pressed())
	assert_eq(_box.get_presses(), 1, "el primer corte es al pulsar")
	_advance(1.05)
	assert_eq(_box.get_presses(), 6, "6 cortes en 1,05 s")
	assert_true(_box.is_full())
	assert_almost_eq(_octopus.remaining, 50.0, 0.001, "la mitad del pulpo")
	assert_eq(_resolved(ActionHint.State.OK), 6)
	assert_eq(
		_resolved(ActionHint.State.BLOCKED), 0, "sin 7.º corte ni rechazo mientras se mantiene"
	)
	_advance(1.0)
	assert_eq(_resolved(ActionHint.State.BLOCKED), 0, "tampoco al seguir pulsada")


func test_ac2_release_and_press_on_the_full_box_gives_one_full_rejection() -> void:
	Input.action_press(ACTION)
	_actor.interact_pressed()
	_advance(1.05)
	Input.action_release(ACTION)
	_advance(0.2)
	watch_signals(_actor)
	Input.action_press(ACTION)
	assert_true(_actor.interact_pressed())
	assert_eq(_resolved(ActionHint.State.BLOCKED), 1)
	var hint: ActionHint = get_signal_parameters(_actor, "interaction_resolved", 0)[1]
	assert_eq([hint.verb, hint.reason], [ActionVerb.CUT, ActionReason.FULL])
	assert_eq(_box.get_presses(), 6, "no hay 7.º corte")
	assert_almost_eq(_octopus.remaining, 50.0, 0.001, "el pulpo no se gasta")


func test_ac2_a_tap_under_0_2_s_gives_one_cut() -> void:
	Input.action_press(ACTION)
	assert_true(_actor.interact_pressed())
	_advance(0.1)
	Input.action_release(ACTION)
	_advance(1.0)
	assert_eq(_box.get_presses(), 1)


func test_ac2_changing_the_target_stops_the_repeat() -> void:
	Input.action_press(ACTION)
	_actor.interact_pressed()
	_advance(0.45)
	assert_eq(_box.get_presses(), 3, "primer corte y dos repeticiones")
	var other: Box = _new_box()
	_advance(1.0)
	assert_eq(_box.get_presses(), 3, "ya no corta la anterior")
	assert_eq(other.get_presses(), 0, "ni corta la nueva sin pulsar")


func test_ac2_an_exhausted_octopus_stops_the_repeat() -> void:
	_octopus.remaining = 10.0
	Input.action_press(ACTION)
	_actor.interact_pressed()
	_advance(1.05)
	assert_lt(_box.get_presses(), 6, "el pulpo se agota antes de llenar")
	assert_true(_octopus.is_queued_for_deletion())
	assert_null(_hold.get_held_item())
