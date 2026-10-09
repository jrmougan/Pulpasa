# gdlint: disable=max-public-methods
extends GutTest
## PUL-058/097: escena de la estación de condimentos al paso (D23, R1–R8; ADR-003 §8; scene-tree.md
## §3). Sin bandeja: dispensadores y cuenco actúan sobre la caja que lleva el actor en la mano. Las
## pulsaciones se dan con `interact()` del objetivo (como hace `InteractionComponent`) y el
## antirrebote se prueba con el reloj de juego inyectado, sin esperas reales. Los tests de lado y de
## mapa de objetivos pasan por el detector real del jugador.
## PUL-071: el sonido de error y la sacudida salen de `%Feedback` (cue `season_error`, ADR-006 §4).

const STATION_SCENE: PackedScene = preload("res://entities/stations/seasoning_station.tscn")
const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const CACHELOS_SCENE: PackedScene = preload("res://entities/items/cachelos.tscn")
const MEDIUM: BoxData = preload("res://data/boxes/medium.tres")
const SWEET: SeasoningData = preload("res://data/seasonings/paprika.tres")
const HOT: SeasoningData = preload("res://data/seasonings/hot_paprika.tres")
const SALT: SeasoningData = preload("res://data/seasonings/salt.tres")
const OIL: SeasoningData = preload("res://data/seasonings/oil.tres")
const CACHELOS: SeasoningData = preload("res://data/seasonings/cachelos.tres")
const STATION_DATA: SeasoningStationData = preload("res://data/config/seasoning_station.tres")
const SETTLE_FRAMES: int = 3
## Carácter del mapa de objetivos (como el de PUL-090): dulce, picante, sal, aceite, cuenco.
const MAP_CHARS: Dictionary = {
	"-": ".", "SweetPaprika": "d", "HotPaprika": "p", "Salt": "s", "Oil": "a", "CachelosBowl": "c"
}
## Posiciones del jugador en el suelo, en el pasillo de cada lado (la estación está en el origen).
const PASS_Z: float = -1.2
const OPERATOR_Z: float = 1.2

var _level: Node3D
var _station: SeasoningStation
var _player: Player
var _hold: HoldComponent
var _actor: InteractionComponent
var _now: float = 100.0
var _rejections: Array[SeasoningRules.Rejection] = []
## Cues que ha reproducido el `%Feedback` de la estación.
var _cues: Array[StringName] = []


func before_each() -> void:
	_now = 100.0
	_rejections.clear()
	_cues.clear()
	_level = add_child_autofree(Node3D.new())
	_add_station(STATION_DATA)
	_player = PLAYER_SCENE.instantiate()
	_player.position = Vector3(0.0, 0.0, OPERATOR_Z)
	_level.add_child(_player)
	_hold = _player.get_node("%HoldComponent")
	_hold.items_root = _level
	_actor = _player.get_node("%InteractionComponent")


func _add_station(data: SeasoningStationData) -> void:
	if _station != null:
		_level.remove_child(_station)
		_station.queue_free()
	_station = STATION_SCENE.instantiate()
	_station.data = data
	_level.add_child(_station)
	var clock: Callable = func() -> float: return _now
	for dispenser: SeasoningDispenser in _dispensers():
		dispenser.clock = clock
		dispenser.rejected.connect(_on_rejected)
	_bowl().clock = clock
	_bowl().rejected.connect(_on_rejected)
	var feedback: FeedbackPlayer = _station.get_node("%Feedback") as FeedbackPlayer
	feedback.played.connect(func(cue: StringName) -> void: _cues.append(cue))


## Duración de la sacudida de rechazo (dato de la cue `season_error`).
func _shake_time() -> float:
	var feedback: FeedbackPlayer = _station.get_node("%Feedback") as FeedbackPlayer
	return feedback.map.get_cue(&"season_error").visual_time


func _on_rejected(reason: SeasoningRules.Rejection) -> void:
	_rejections.append(reason)


func _dispensers() -> Array[SeasoningDispenser]:
	var found: Array[SeasoningDispenser] = []
	for child: Node in _station.get_node("Dispensers").get_children():
		found.append(child as SeasoningDispenser)
	return found


func _dispenser(node_name: String) -> SeasoningDispenser:
	return _station.get_node("Dispensers/" + node_name) as SeasoningDispenser


func _bowl() -> CachelosBowl:
	return _station.get_node("CachelosBowl") as CachelosBowl


## Veces que ha sonado el error de la estación.
func _error_sounds() -> int:
	return _cues.count(&"season_error")


func _new_box(fill: float) -> Box:
	var box: Box = BOX_SCENE.instantiate()
	box.data = MEDIUM
	_level.add_child(box)
	box.position = Vector3(4.0, 0.5, 4.0)
	box.fill = fill
	return box


## Caja con `fill` en la mano del actor (por la ruta real de coger).
func _held_box(fill: float = 1.0) -> Box:
	var box: Box = _new_box(fill)
	assert_true(_hold.pick_up(box))
	assert_eq(_hold.get_held_item(), box)
	return box


func _held_cachelos(state: IngredientData.CookingState) -> Ingredient:
	var cachelos: Ingredient = CACHELOS_SCENE.instantiate()
	_level.add_child(cachelos)
	cachelos.position = Vector3(-4.0, 0.5, 4.0)
	cachelos.state = state
	assert_true(_hold.pick_up(cachelos))
	return cachelos


func _press(target: Node) -> void:
	assert_true(target.call(&"can_interact", _actor), "%s acepta la pulsación" % target.name)
	assert_true(target.call(&"interact", _actor), "%s consume la pulsación" % target.name)
	_now += 1.0


func _floor(z: float, x: float = 0.0) -> Vector2:
	return Vector2(x, z)


func _settle() -> void:
	await wait_physics_frames(SETTLE_FRAMES)


# --- Contrato de la escena (scene-tree.md §3) ---


func test_scene_contract_nodes_and_data() -> void:
	assert_eq(_station.collision_layer, 1, "mostrador en la capa world")
	assert_false(_station.is_in_group(&"interactable"), "la estación no es objetivo")
	assert_null(_station.get_node_or_null("Tray"), "R7: sin bandeja")
	assert_false(_station.has_method("get_tray"))
	var expected: Dictionary = {"SweetPaprika": SWEET, "HotPaprika": HOT, "Salt": SALT, "Oil": OIL}
	assert_eq(_dispensers().size(), 4)
	for node_name: String in expected:
		var dispenser: SeasoningDispenser = _dispenser(node_name)
		assert_eq(dispenser.seasoning, expected[node_name], node_name)
		assert_eq(dispenser.station, _station, node_name)
		assert_true(dispenser.get_node("%Highlightable") is Highlightable, node_name)
	assert_eq(_bowl().station, _station)
	assert_eq(_bowl().seasoning, CACHELOS)
	assert_true(_bowl().get_node("%Highlightable") is Highlightable)
	assert_eq(InteractionContract.scan_tree(_station), [])


func test_scene_contract_dispensers_and_bowl_implement_reachability() -> void:
	for method: String in InteractionContract.INTERACTABLE_OPTIONAL_METHODS:
		for dispenser: SeasoningDispenser in _dispensers():
			assert_true(dispenser.has_method(method), "%s.%s" % [dispenser.name, method])
		assert_true(_bowl().has_method(method), "CachelosBowl.%s" % method)


func test_scene_contract_dispensers_at_least_09_m_apart() -> void:
	var dispensers: Array[SeasoningDispenser] = _dispensers()
	for i: int in dispensers.size():
		for j: int in range(i + 1, dispensers.size()):
			var a: Vector3 = dispensers[i].global_position
			var b: Vector3 = dispensers[j].global_position
			assert_gte(Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z)), 0.9 - 0.0001)


func test_side_of_uses_markers_pass_toward_minus_z() -> void:
	assert_eq(_station.side_of(_floor(PASS_Z)), StationSide.Side.PASS)
	assert_eq(_station.side_of(_floor(OPERATOR_Z)), StationSide.Side.OPERATOR)


func test_side_of_follows_station_rotation() -> void:
	_station.rotation = Vector3(0.0, PI, 0.0)
	assert_eq(_station.side_of(_floor(PASS_Z)), StationSide.Side.OPERATOR)
	assert_eq(_station.side_of(_floor(OPERATOR_Z)), StationSide.Side.PASS)


func test_station_data_comes_from_tres() -> void:
	var fresh: SeasoningStation = STATION_SCENE.instantiate()
	assert_eq(fresh.data, STATION_DATA)
	fresh.free()


# --- AC1 ---


func test_ac1_salt_dispenser_seasons_full_box_once() -> void:
	var box: Box = _held_box()
	watch_signals(box)
	_press(_dispenser("Salt"))
	assert_true(box.has_seasoning(SALT))
	assert_signal_emit_count(box, "seasoned", 1)
	assert_signal_emitted_with_parameters(box, "seasoned", [SALT])
	assert_eq(box.get_contents().seasonings, [SALT] as Array[SeasoningData])
	assert_eq(_rejections, [] as Array[SeasoningRules.Rejection])
	assert_eq(_hold.get_held_item(), box, "la caja sigue en la mano")


func test_ac1_ac2_second_press_after_guard_removes_salt() -> void:
	var box: Box = _held_box()
	_press(_dispenser("Salt"))
	watch_signals(box)
	_now += STATION_DATA.toggle_guard
	_press(_dispenser("Salt"))
	assert_false(box.has_seasoning(SALT))
	assert_signal_emit_count(box, "seasoning_removed", 1)
	assert_signal_emit_count(box, "seasoned", 0)


# --- AC3 ---


func test_ac3_second_press_within_guard_is_ignored_silently() -> void:
	var box: Box = _held_box()
	var salt: SeasoningDispenser = _dispenser("Salt")
	assert_true(salt.interact(_actor))
	watch_signals(box)
	watch_signals(salt)
	_now += 0.1
	assert_true(salt.interact(_actor), "el antirrebote consume la pulsación")
	assert_true(box.has_seasoning(SALT), "la caja sigue con sal")
	assert_signal_not_emitted(box, "seasoning_removed")
	assert_signal_not_emitted(salt, "rejected")
	assert_eq(_error_sounds(), 0, "sin sonido de error")


func test_ac3_guard_is_per_dispenser() -> void:
	var box: Box = _held_box()
	assert_true(_dispenser("Salt").interact(_actor))
	_now += 0.1
	assert_true(_dispenser("Oil").interact(_actor))
	assert_true(box.has_seasoning(SALT))
	assert_true(box.has_seasoning(OIL))


func test_ac3_guard_reads_toggle_guard_from_data() -> void:
	var data: SeasoningStationData = STATION_DATA.duplicate()
	data.toggle_guard = 0.05
	_add_station(data)
	var box: Box = _held_box()
	assert_true(_dispenser("Salt").interact(_actor))
	_now += 0.1
	assert_true(_dispenser("Salt").interact(_actor))
	assert_false(box.has_seasoning(SALT), "0,1 s > 0,05 s: se quita")


# --- AC4 / AC5 por la escena ---


func test_ac4_hot_dispenser_swaps_sweet_paprika() -> void:
	var box: Box = _held_box()
	_press(_dispenser("SweetPaprika"))
	watch_signals(box)
	_press(_dispenser("HotPaprika"))
	assert_true(box.has_seasoning(HOT))
	assert_false(box.has_seasoning(SWEET))
	assert_signal_emit_count(box, "seasoning_removed", 1)
	assert_signal_emitted_with_parameters(box, "seasoning_removed", [SWEET])
	assert_signal_emit_count(box, "seasoned", 1)
	assert_signal_emitted_with_parameters(box, "seasoned", [HOT])


func test_ac4_without_paprika_swap_other_paprika_is_rejected() -> void:
	var data: SeasoningStationData = STATION_DATA.duplicate()
	data.paprika_swap = false
	_add_station(data)
	var box: Box = _held_box()
	_press(_dispenser("SweetPaprika"))
	_press(_dispenser("HotPaprika"))
	assert_true(box.has_seasoning(SWEET))
	assert_false(box.has_seasoning(HOT))
	assert_eq(
		_rejections, [SeasoningRules.Rejection.EXCLUSIVE_TAKEN] as Array[SeasoningRules.Rejection]
	)


func test_ac5_box_not_full_is_rejected_with_error_sound() -> void:
	for fill: float in [0.0, 0.6]:
		_rejections.clear()
		_cues.clear()
		var box: Box = _held_box(fill)
		watch_signals(box)
		_press(_dispenser("Salt"))
		assert_eq(box.get_contents().seasonings, [] as Array[SeasoningData], "fill %s" % fill)
		assert_signal_not_emitted(box, "seasoned")
		assert_eq(
			_rejections, [SeasoningRules.Rejection.BOX_NOT_FULL] as Array[SeasoningRules.Rejection]
		)
		assert_eq(_cues, [&"season_error"] as Array[StringName], "suena el error una vez")
		_hold.drop()
		box.queue_free()


# --- AC6 ---


func test_ac6_unfilled_box_rejects_every_dispenser_with_error_sound() -> void:
	var box: Box = _held_box(0.6)
	for dispenser: SeasoningDispenser in _dispensers():
		_press(dispenser)
	assert_eq(_rejections.size(), 4)
	for reason: SeasoningRules.Rejection in _rejections:
		assert_eq(reason, SeasoningRules.Rejection.BOX_NOT_FULL)
	assert_eq(_error_sounds(), 4, "un error por pulsación")
	assert_eq(box.get_contents().seasonings, [] as Array[SeasoningData])
	assert_engine_error_count(0)


func test_ac6_rejection_shakes_emitter_and_returns_to_rest() -> void:
	var model: Node3D = _dispenser("Salt").get_node("Model")
	var rest: Vector3 = model.position
	_held_box(0.6)
	_press(_dispenser("Salt"))
	var shake: Tween = _station.get_shake(_dispenser("Salt"))
	assert_not_null(shake)
	shake.pause()
	shake.custom_step(_shake_time() / 10.0)
	assert_ne(model.position, rest, "se sacude")
	shake.custom_step(_shake_time())
	assert_true(model.position.is_equal_approx(rest), "vuelve a su sitio")
	assert_null(_station.get_shake(_dispenser("Salt")), "la sacudida terminó")


func test_ac6_repeated_rejection_restarts_shake_from_rest() -> void:
	var salt: SeasoningDispenser = _dispenser("Salt")
	var model: Node3D = salt.get_node("Model")
	var rest: Vector3 = model.position
	_held_box(0.6)
	_press(salt)
	var first: Tween = _station.get_shake(salt)
	first.pause()
	first.custom_step(_shake_time() / 10.0)
	_press(salt)
	assert_false(first.is_valid(), "la primera se cancela")
	var second: Tween = _station.get_shake(salt)
	second.pause()
	second.custom_step(_shake_time())
	assert_true(model.position.is_equal_approx(rest), "reposo original, no el desplazado")


# --- AC7 / R4: lado de condimentar y mano ---


func _detector() -> InteractionDetector:
	return _player.get_node("%InteractionDetector") as InteractionDetector


## Pone al jugador en el suelo a `(x, z)` mirando a la barra y espera al detector.
func _stand_at(x: float, z: float) -> void:
	_player.global_position = Vector3(x, 0.0, z)
	_player.rotation = Vector3(0.0, 0.0 if z > 0.0 else PI, 0.0)
	await _settle()


func test_ac7_dispenser_not_reachable_from_pass_side() -> void:
	_held_box()
	for dispenser: SeasoningDispenser in _dispensers():
		var x: float = dispenser.global_position.x
		assert_false(dispenser.is_reachable_from(_floor(PASS_Z, x), _hold), dispenser.name)
		assert_true(dispenser.is_reachable_from(_floor(OPERATOR_Z, x), _hold), dispenser.name)


func test_ac7_from_pass_side_dispenser_is_neither_target_nor_highlighted() -> void:
	var box: Box = _held_box()
	var sweet: SeasoningDispenser = _dispenser("SweetPaprika")
	await _stand_at(sweet.global_position.x, PASS_Z)
	for dispenser: SeasoningDispenser in _dispensers():
		assert_ne(_detector().get_target(), dispenser, dispenser.name)
		var highlight: Highlightable = dispenser.get_node("%Highlightable")
		assert_false(highlight.is_highlighted(), "%s sin resaltar" % dispenser.name)
	_actor.interact_pressed()
	assert_eq(box.get_contents().seasonings, [] as Array[SeasoningData], "la caja no cambia")


func test_r1_from_operator_side_dispenser_is_target_and_highlighted() -> void:
	_held_box()
	var sweet: SeasoningDispenser = _dispenser("SweetPaprika")
	await _stand_at(sweet.global_position.x, OPERATOR_Z)
	assert_eq(_detector().get_target(), sweet)
	assert_true((sweet.get_node("%Highlightable") as Highlightable).is_highlighted())


func test_ac7_operator_side_only_false_reaches_from_both_sides() -> void:
	var data: SeasoningStationData = STATION_DATA.duplicate()
	data.operator_side_only = false
	_add_station(data)
	_held_box()
	for dispenser: SeasoningDispenser in _dispensers():
		assert_true(dispenser.is_reachable_from(_floor(PASS_Z), _hold), dispenser.name)


# --- R4 / AC8: mano vacía u otro objeto, sin objetivo ---


func test_r4_empty_hand_dispensers_are_not_interactable_nor_targets() -> void:
	for dispenser: SeasoningDispenser in _dispensers():
		assert_false(dispenser.can_interact(_actor), "%s no es objetivo" % dispenser.name)
		assert_false(dispenser.interact(_actor), "%s no consume" % dispenser.name)
		assert_false(dispenser.is_reachable_from(_floor(OPERATOR_Z), _hold), dispenser.name)
	assert_eq(_rejections.size(), 0)
	assert_eq(_error_sounds(), 0)


func test_r4_empty_hand_detector_picks_no_dispenser_or_bowl() -> void:
	for dispenser: SeasoningDispenser in _dispensers():
		await _stand_at(dispenser.global_position.x, OPERATOR_Z)
		var target: Node = _detector().get_target()
		assert_null(target, "mano vacía frente a %s" % dispenser.name)
		var highlight: Highlightable = dispenser.get_node("%Highlightable")
		assert_false(highlight.is_highlighted(), "%s sin resaltar" % dispenser.name)


func test_ac8_other_item_dispensers_are_not_interactable_and_hand_unchanged() -> void:
	var cachelos: Ingredient = _held_cachelos(IngredientData.CookingState.COOKED)
	for dispenser: SeasoningDispenser in _dispensers():
		assert_false(dispenser.can_interact(_actor), "%s no es objetivo" % dispenser.name)
		assert_false(dispenser.interact(_actor), "%s no consume" % dispenser.name)
	assert_eq(_hold.get_held_item(), cachelos, "la mano no cambia")
	assert_eq(_rejections.size(), 0, "sin rechazos: ya no hay HAND_BUSY")


func test_ac8_other_item_detector_does_not_pick_a_dispenser() -> void:
	var cachelos: Ingredient = _held_cachelos(IngredientData.CookingState.COOKED)
	var salt: SeasoningDispenser = _dispenser("Salt")
	await _stand_at(salt.global_position.x, OPERATOR_Z)
	assert_false(_detector().get_target() is SeasoningDispenser, "el detector no elige uno")
	assert_eq(_hold.get_held_item(), cachelos)


# --- Reloj de juego (ADR-003 §9.2) ---


func test_default_clock_is_game_time_and_freezes_while_paused() -> void:
	var extra: SeasoningStation = STATION_SCENE.instantiate()
	extra.position = Vector3(30.0, 0.0, 0.0)
	_level.add_child(extra)
	var oil: SeasoningDispenser = extra.get_node("Dispensers/Oil")
	var box: Box = _held_box()
	assert_true(oil.interact(_actor))
	assert_true(box.has_seasoning(OIL))
	get_tree().paused = true
	var frozen: float = oil.get("_game_time")
	await wait_physics_frames(60)
	assert_eq(float(oil.get("_game_time")), frozen, "congelado en pausa")
	assert_true(oil.interact(_actor), "consume la pulsación")
	assert_true(box.has_seasoning(OIL), "la guarda no vence en pausa: no se quita")
	get_tree().paused = false
	await wait_physics_frames(30)
	assert_gt(float(oil.get("_game_time")), frozen, "avanza con el árbol en marcha")
	assert_true(oil.interact(_actor), "pasada la guarda, alterna")
	assert_false(box.has_seasoning(OIL))


# --- R7 / R8: sin bandeja y franjas continuas ---


func test_r7_station_has_no_tray_and_counter_collision_covers_5_2_m() -> void:
	assert_null(_station.get_node_or_null("Tray"))
	assert_null(_station.find_child("Tray*", true, false))
	var shape: BoxShape3D = (_station.get_node("CollisionShape3D") as CollisionShape3D).shape
	assert_almost_eq(shape.size.x, 5.2, 0.0001)


## Los modelos están en los anclajes de PUL-094; el origen de cada objetivo queda 0,45 / 0,25 m
## hacia el pase para que las franjas del detector (cono de 30°) sean continuas (R8).
func test_selection_shapes_stay_inside_the_counter_collision() -> void:
	var counter: BoxShape3D = (_station.get_node("CollisionShape3D") as CollisionShape3D).shape
	var half: Vector3 = counter.size / 2.0
	var parts: Array[Node3D] = [_bowl()]
	for dispenser: SeasoningDispenser in _dispensers():
		parts.append(dispenser)
	for part: Node3D in parts:
		var body: CollisionShape3D = part.get_node("CollisionShape3D")
		var extents: Vector3 = Vector3.ZERO
		if body.shape is BoxShape3D:
			extents = (body.shape as BoxShape3D).size / 2.0
		elif body.shape is CylinderShape3D:
			var cylinder: CylinderShape3D = body.shape as CylinderShape3D
			extents = Vector3(cylinder.radius, cylinder.height / 2.0, cylinder.radius)
		var center: Vector3 = _station.to_local(body.global_position)
		assert_lte(absf(center.x) + extents.x, half.x + 0.0001, "%s en x" % part.name)
		assert_lte(absf(center.z) + extents.z, half.z + 0.0001, "%s no sobresale en z" % part.name)


func test_r7_anchors_place_dispensers_and_bowl_one_meter_apart() -> void:
	var expected: Dictionary = {"SweetPaprika": -2.0, "HotPaprika": -1.0, "Salt": 0.0, "Oil": 1.0}
	for node_name: String in expected:
		var model: Vector3 = (_dispenser(node_name).get_node("Model") as Node3D).global_position
		assert_almost_eq(model.x, expected[node_name], 0.0001, node_name)
		assert_almost_eq(model.z, 0.35, 0.0001, node_name)
		assert_almost_eq(model.y, 1.1, 0.0001, node_name)
	var bowl: Vector3 = (_bowl().get_node("Model") as Node3D).global_position
	assert_almost_eq(bowl.x, 2.0, 0.0001)
	assert_almost_eq(bowl.z, 0.15, 0.0001)


## Objetivo del detector con la caja llena en la mano a `(x, OPERATOR_Z - 0.2)`: 1,0 m del eje.
func _target_name_at(x: float) -> String:
	_player.global_position = Vector3(x, 0.0, 1.0)
	_player.rotation = Vector3.ZERO
	_detector().refresh()
	var target: Node = _detector().get_target()
	return "-" if target == null else String(target.name)


func test_r8_target_strips_are_continuous_and_at_least_06_m() -> void:
	_held_box()
	var line: String = ""
	var runs: Array[Array] = []
	var step: float = 0.05
	var x: float = -2.6
	while x <= 2.6001:
		_player.global_position = Vector3(x, 0.0, 1.0)
		await _settle()
		var name_at: String = _target_name_at(x)
		line += MAP_CHARS.get(name_at, "?")
		if runs.is_empty() or runs[runs.size() - 1][0] != name_at:
			runs.append([name_at, 0.0])
		runs[runs.size() - 1][1] += step
		x += step
	gut.p("mapa de objetivos (x -2,6..2,6; 0,05 m por carácter): " + line)
	var names: Array[String] = []
	for run: Array in runs:
		names.append(String(run[0]))
	var first: int = names.find("SweetPaprika")
	var last: int = names.find("CachelosBowl")
	assert_gte(first, 0, "el primer dispensador es objetivo")
	assert_gte(last, first, "el cuenco es objetivo")
	for index: int in range(first, last + 1):
		assert_ne(names[index], "-", "sin huecos entre el primero y el último")
	for expected: String in ["SweetPaprika", "HotPaprika", "Salt", "Oil"]:
		var index: int = names.find(expected)
		assert_gte(index, 0, expected)
		assert_gte(runs[index][1], 0.6 - 0.0001, "franja de %s" % expected)
		assert_eq(names.count(expected), 1, "%s: una sola franja continua" % expected)


# --- AC10 / R5 / R6: cuenco ---


func _visible_portions() -> Array[String]:
	var shown: Array[String] = []
	for child: Node in _bowl().find_children("Portions*", "MeshInstance3D", true, false):
		if (child as MeshInstance3D).visible:
			shown.append(String(child.name))
	return shown


func test_r6_cooked_cachelos_restock_bowl_with_two_portions_from_any_side() -> void:
	var bowl: CachelosBowl = _bowl()
	assert_eq(bowl.stock, 0)
	watch_signals(bowl)
	var cachelos: Ingredient = _held_cachelos(IngredientData.CookingState.COOKED)
	assert_true(bowl.is_reachable_from(_floor(PASS_Z), _hold), "con cachelos, desde el pase")
	assert_true(bowl.is_reachable_from(_floor(OPERATOR_Z), _hold), "y desde el lado de condimentar")
	_press(bowl)
	assert_eq(bowl.stock, 2)
	assert_null(_hold.get_held_item(), "la mano queda vacía")
	assert_true(cachelos.is_queued_for_deletion())
	assert_signal_emitted_with_parameters(bowl, "stock_changed", [2])


func test_r6_restock_clips_to_max_and_full_bowl_rejects() -> void:
	var bowl: CachelosBowl = _bowl()
	assert_eq(STATION_DATA.cachelos_stock_max, 4)
	assert_eq(STATION_DATA.cachelos_portions_per_item, 2)
	_held_cachelos(IngredientData.CookingState.COOKED)
	_press(bowl)
	_held_cachelos(IngredientData.CookingState.COOKED)
	_press(bowl)
	assert_eq(bowl.stock, 4)
	var extra: Ingredient = _held_cachelos(IngredientData.CookingState.COOKED)
	_press(bowl)
	assert_eq(bowl.stock, 4)
	assert_eq(_hold.get_held_item(), extra, "el cachelo rechazado sigue en la mano")
	assert_eq(_rejections, [SeasoningRules.Rejection.BOWL_FULL] as Array[SeasoningRules.Rejection])


func test_r6_restock_with_three_portions_is_accepted_and_clipped_to_four() -> void:
	_station_with_stock(3)
	var cachelos: Ingredient = _held_cachelos(IngredientData.CookingState.COOKED)
	_press(_bowl())
	assert_eq(_bowl().stock, 4)
	assert_true(cachelos.is_queued_for_deletion(), "se consume")
	assert_eq(_rejections.size(), 0)


func test_r5_raw_or_burnt_cachelos_are_not_target() -> void:
	var bowl: CachelosBowl = _bowl()
	for state: IngredientData.CookingState in [
		IngredientData.CookingState.RAW, IngredientData.CookingState.BURNT
	]:
		var cachelos: Ingredient = _held_cachelos(state)
		assert_false(bowl.can_interact(_actor))
		assert_false(bowl.is_reachable_from(_floor(OPERATOR_Z), _hold))
		assert_false(bowl.interact(_actor))
		assert_eq(bowl.stock, 0)
		assert_eq(_hold.get_held_item(), cachelos, "siguen en la mano")
		_hold.drop()
		cachelos.queue_free()
	assert_eq(_rejections.size(), 0)


func test_r5_empty_hand_or_octopus_bowl_is_not_target() -> void:
	var bowl: CachelosBowl = _bowl()
	assert_false(bowl.can_interact(_actor), "mano vacía")
	assert_false(bowl.is_reachable_from(_floor(OPERATOR_Z), _hold))
	var octopus: Ingredient = (
		preload("res://entities/items/octopus.tscn").instantiate() as Ingredient
	)
	_level.add_child(octopus)
	octopus.set_cooked()
	assert_true(_hold.pick_up(octopus))
	for z: float in [PASS_Z, OPERATOR_Z]:
		assert_false(bowl.is_reachable_from(_floor(z), _hold), "pulpo, z=%s" % z)
	assert_false(bowl.interact(_actor))
	assert_eq(_hold.get_held_item(), octopus)


func test_r5_box_in_hand_bowl_is_not_target_from_pass_side_within_1_5_m() -> void:
	_held_box()
	var bowl: CachelosBowl = _bowl()
	var start: float = bowl.global_position.x - 1.5
	for step: int in 7:
		var x: float = start + 0.5 * step
		await _stand_at(x, PASS_Z)
		assert_ne(_detector().get_target(), bowl, "desde el pase, x=%s" % x)
	assert_false(bowl.is_reachable_from(_floor(PASS_Z), _hold))
	assert_true(bowl.is_reachable_from(_floor(OPERATOR_Z), _hold), "con caja, desde condimentar")


func test_r5_with_cooked_cachelos_bowl_is_target_from_both_sides() -> void:
	_held_cachelos(IngredientData.CookingState.COOKED)
	var bowl: CachelosBowl = _bowl()
	for z: float in [PASS_Z, OPERATOR_Z]:
		await _stand_at(bowl.global_position.x, z)
		assert_eq(_detector().get_target(), bowl, "z=%s" % z)


func test_ac10_portions_model_shows_exactly_one_state_for_each_stock() -> void:
	assert_eq(_visible_portions(), ["Portions0"] as Array[String], "vacío al arrancar")
	_held_cachelos(IngredientData.CookingState.COOKED)
	_press(_bowl())
	assert_eq(_visible_portions(), ["Portions2"] as Array[String], "2 raciones")
	_held_cachelos(IngredientData.CookingState.COOKED)
	_press(_bowl())
	assert_eq(_visible_portions(), ["Portions4"] as Array[String], "4 raciones")
	assert_eq(_bowl().find_children("Portions*", "MeshInstance3D", true, false).size(), 5)


func test_ac10_portions_model_one_state_visible_in_the_bare_scene() -> void:
	var bare: CachelosBowl = (
		load("res://entities/stations/cachelos_bowl.tscn").instantiate() as CachelosBowl
	)
	var shown: int = 0
	for node: Node in bare.find_children("Portions*", "MeshInstance3D", true, false):
		if (node as MeshInstance3D).visible:
			shown += 1
	assert_eq(shown, 1, "la escena sola ya muestra un único estado")
	bare.free()


# --- AC11 ---


func _station_with_stock(stock: int) -> void:
	var data: SeasoningStationData = STATION_DATA.duplicate()
	data.cachelos_initial_stock = stock
	_add_station(data)


func test_ac11_initial_stock_from_data() -> void:
	_station_with_stock(2)
	assert_eq(_bowl().stock, 2)


func test_ac11_toggle_cachelos_spends_and_returns_portion() -> void:
	_station_with_stock(2)
	var bowl: CachelosBowl = _bowl()
	var box: Box = _held_box()
	watch_signals(box)
	watch_signals(bowl)
	_press(bowl)
	assert_true(box.has_seasoning(CACHELOS))
	assert_eq(bowl.stock, 1)
	assert_signal_emitted_with_parameters(box, "seasoned", [CACHELOS])
	_press(bowl)
	assert_false(box.has_seasoning(CACHELOS))
	assert_eq(bowl.stock, 2)
	assert_signal_emitted_with_parameters(box, "seasoning_removed", [CACHELOS])
	assert_signal_emit_count(bowl, "stock_changed", 2)


func test_ac11_empty_bowl_rejects_putting_cachelos() -> void:
	var box: Box = _held_box()
	_press(_bowl())
	assert_false(box.has_seasoning(CACHELOS))
	assert_eq(_bowl().stock, 0)
	assert_eq(_rejections, [SeasoningRules.Rejection.BOWL_EMPTY] as Array[SeasoningRules.Rejection])


func test_ac11_toggle_reachable_only_from_operator_side_with_box_in_hand() -> void:
	_held_box()
	assert_false(_bowl().is_reachable_from(_floor(PASS_Z), _hold))
	assert_true(_bowl().is_reachable_from(_floor(OPERATOR_Z), _hold))


func test_ac11_toggle_rejects_a_box_not_full_and_empty_hand_is_not_target() -> void:
	_station_with_stock(2)
	assert_false(_bowl().interact(_actor), "mano vacía: no es objetivo")
	var box: Box = _held_box(0.6)
	_press(_bowl())
	assert_eq(_bowl().stock, 2)
	assert_eq(box.get_contents().seasonings, [] as Array[SeasoningData])
	assert_eq(
		_rejections, [SeasoningRules.Rejection.BOX_NOT_FULL] as Array[SeasoningRules.Rejection]
	)


func test_ac11_removing_cachelos_with_full_bowl_is_rejected() -> void:
	_station_with_stock(1)
	var bowl: CachelosBowl = _bowl()
	var box: Box = _held_box()
	_press(bowl)
	assert_true(box.has_seasoning(CACHELOS))
	assert_eq(bowl.stock, 0)
	_hold.drop()
	for i: int in STATION_DATA.cachelos_stock_max / STATION_DATA.cachelos_portions_per_item:
		_held_cachelos(IngredientData.CookingState.COOKED)
		_press(bowl)
	assert_eq(bowl.stock, STATION_DATA.cachelos_stock_max)
	assert_true(_hold.pick_up(box))
	_rejections.clear()
	watch_signals(box)
	watch_signals(bowl)
	_press(bowl)
	assert_true(box.has_seasoning(CACHELOS), "la caja sigue con cachelos")
	assert_eq(bowl.stock, STATION_DATA.cachelos_stock_max)
	assert_eq(_rejections, [SeasoningRules.Rejection.BOWL_FULL] as Array[SeasoningRules.Rejection])
	assert_signal_not_emitted(box, "seasoning_removed")
	assert_signal_not_emitted(bowl, "stock_changed")


func test_ac3_rejection_does_not_arm_guard() -> void:
	var salt: SeasoningDispenser = _dispenser("Salt")
	var box: Box = _held_box(0.6)
	assert_true(salt.interact(_actor), "caja a medio cortar: rechazo")
	assert_eq(
		_rejections, [SeasoningRules.Rejection.BOX_NOT_FULL] as Array[SeasoningRules.Rejection]
	)
	box.fill = 1.0
	_now += 0.1
	assert_true(salt.interact(_actor))
	assert_true(box.has_seasoning(SALT), "0,1 s tras un rechazo sí condimenta")


func test_ac11_bowl_rejection_does_not_arm_guard() -> void:
	_station_with_stock(1)
	var box: Box = _held_box(0.6)
	assert_true(_bowl().interact(_actor), "caja a medio cortar: rechazo")
	box.fill = 1.0
	_now += 0.1
	assert_true(_bowl().interact(_actor))
	assert_true(box.has_seasoning(CACHELOS))
	assert_eq(_bowl().stock, 0)


func test_ac11_toggle_has_guard() -> void:
	_station_with_stock(2)
	var box: Box = _held_box()
	assert_true(_bowl().interact(_actor))
	_now += 0.1
	assert_true(_bowl().interact(_actor))
	assert_true(box.has_seasoning(CACHELOS))
	assert_eq(_bowl().stock, 1)
