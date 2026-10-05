# gdlint: disable=max-public-methods
extends GutTest
## PUL-058: escena de la estación de condimentos (feature estacion-condimentos AC1, AC3–AC11;
## ADR-003 §8; scene-tree.md §3). Las pulsaciones se dan con `interact()` del objetivo (como hace
## `InteractionComponent`) y el antirrebote se prueba con el reloj inyectado, sin esperas reales.
## AC7 y AC9 (segunda caja) pasan por el detector real del jugador.

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


func before_each() -> void:
	_now = 100.0
	_rejections.clear()
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


func _error_audio() -> AudioStreamPlayer3D:
	return _station.get_node("%ErrorAudio") as AudioStreamPlayer3D


func _new_box(fill: float) -> Box:
	var box: Box = BOX_SCENE.instantiate()
	box.data = MEDIUM
	_level.add_child(box)
	box.position = Vector3(4.0, 0.5, 4.0)
	box.fill = fill
	return box


## Caja con `fill` en la bandeja, dejada por la ruta real; la mano queda vacía.
func _box_on_tray(fill: float = 1.0) -> Box:
	var box: Box = _new_box(fill)
	assert_true(_hold.pick_up(box))
	assert_true(_station.get_tray().interact(_actor))
	assert_eq(_station.get_box(), box)
	assert_null(_hold.get_held_item())
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
	assert_eq(_station.get_tray().accepted_group, &"box")
	assert_null(_station.get_tray().initial_item)
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
		assert_false(_station.get_tray().has_method(method), "la bandeja se usa por los dos lados")


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
	var box: Box = _box_on_tray()
	watch_signals(box)
	_press(_dispenser("Salt"))
	assert_true(box.has_seasoning(SALT))
	assert_signal_emit_count(box, "seasoned", 1)
	assert_signal_emitted_with_parameters(box, "seasoned", [SALT])
	assert_eq(box.get_contents().seasonings, [SALT] as Array[SeasoningData])
	assert_eq(_rejections, [] as Array[SeasoningRules.Rejection])
	assert_null(_hold.get_held_item(), "la mano sigue vacía")


func test_ac1_ac2_second_press_after_guard_removes_salt() -> void:
	var box: Box = _box_on_tray()
	_press(_dispenser("Salt"))
	watch_signals(box)
	_now += STATION_DATA.toggle_guard
	_press(_dispenser("Salt"))
	assert_false(box.has_seasoning(SALT))
	assert_signal_emit_count(box, "seasoning_removed", 1)
	assert_signal_emit_count(box, "seasoned", 0)


# --- AC3 ---


func test_ac3_second_press_within_guard_is_ignored_silently() -> void:
	var box: Box = _box_on_tray()
	var salt: SeasoningDispenser = _dispenser("Salt")
	assert_true(salt.interact(_actor))
	watch_signals(box)
	watch_signals(salt)
	_now += 0.1
	assert_true(salt.interact(_actor), "el antirrebote consume la pulsación")
	assert_true(box.has_seasoning(SALT), "la caja sigue con sal")
	assert_signal_not_emitted(box, "seasoning_removed")
	assert_signal_not_emitted(salt, "rejected")
	assert_false(_error_audio().playing, "sin sonido de error")


func test_ac3_guard_is_per_dispenser() -> void:
	var box: Box = _box_on_tray()
	assert_true(_dispenser("Salt").interact(_actor))
	_now += 0.1
	assert_true(_dispenser("Oil").interact(_actor))
	assert_true(box.has_seasoning(SALT))
	assert_true(box.has_seasoning(OIL))


func test_ac3_guard_reads_toggle_guard_from_data() -> void:
	var data: SeasoningStationData = STATION_DATA.duplicate()
	data.toggle_guard = 0.05
	_add_station(data)
	var box: Box = _box_on_tray()
	assert_true(_dispenser("Salt").interact(_actor))
	_now += 0.1
	assert_true(_dispenser("Salt").interact(_actor))
	assert_false(box.has_seasoning(SALT), "0,1 s > 0,05 s: se quita")


# --- AC4 / AC5 por la escena ---


func test_ac4_hot_dispenser_swaps_sweet_paprika() -> void:
	var box: Box = _box_on_tray()
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
	var box: Box = _box_on_tray()
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
		var box: Box = _box_on_tray(fill)
		watch_signals(box)
		_press(_dispenser("Salt"))
		assert_eq(box.get_contents().seasonings, [] as Array[SeasoningData], "fill %s" % fill)
		assert_signal_not_emitted(box, "seasoned")
		assert_eq(
			_rejections, [SeasoningRules.Rejection.BOX_NOT_FULL] as Array[SeasoningRules.Rejection]
		)
		assert_true(_error_audio().playing, "suena el error")
		assert_true(_station.get_tray().interact(_actor), "se recoge la caja")
		_hold.drop()
		box.queue_free()


# --- AC6 ---


func test_ac6_empty_tray_rejects_without_errors() -> void:
	for dispenser: SeasoningDispenser in _dispensers():
		_press(dispenser)
	assert_eq(_rejections.size(), 4)
	for reason: SeasoningRules.Rejection in _rejections:
		assert_eq(reason, SeasoningRules.Rejection.NO_BOX)
	assert_true(_error_audio().playing)
	assert_engine_error_count(0)


func test_ac6_rejection_shakes_emitter_and_returns_to_rest() -> void:
	var model: Node3D = _dispenser("Salt").get_node("Model")
	var rest: Vector3 = model.position
	_press(_dispenser("Salt"))
	var shake: Tween = _station.get_shake(_dispenser("Salt"))
	assert_not_null(shake)
	shake.pause()
	shake.custom_step(SeasoningStation.SHAKE_STEP_TIME / 2.0)
	assert_ne(model.position, rest, "se sacude")
	var total: float = SeasoningStation.SHAKE_STEP_TIME * (SeasoningStation.SHAKE_STEPS + 1)
	shake.custom_step(total)
	assert_true(model.position.is_equal_approx(rest), "vuelve a su sitio")
	assert_null(_station.get_shake(_dispenser("Salt")), "la sacudida terminó")


func test_ac6_repeated_rejection_restarts_shake_from_rest() -> void:
	var salt: SeasoningDispenser = _dispenser("Salt")
	var model: Node3D = salt.get_node("Model")
	var rest: Vector3 = model.position
	_press(salt)
	var first: Tween = _station.get_shake(salt)
	first.pause()
	first.custom_step(SeasoningStation.SHAKE_STEP_TIME / 2.0)
	_press(salt)
	assert_false(first.is_valid(), "la primera se cancela")
	var second: Tween = _station.get_shake(salt)
	second.pause()
	second.custom_step(SeasoningStation.SHAKE_STEP_TIME * (SeasoningStation.SHAKE_STEPS + 1))
	assert_true(model.position.is_equal_approx(rest), "reposo original, no el desplazado")


# --- AC7 ---


func test_ac7_dispenser_not_reachable_from_pass_side() -> void:
	for dispenser: SeasoningDispenser in _dispensers():
		var x: float = dispenser.global_position.x
		assert_false(dispenser.is_reachable_from(_floor(PASS_Z, x), _hold), dispenser.name)
		assert_true(dispenser.is_reachable_from(_floor(OPERATOR_Z, x), _hold), dispenser.name)


func test_ac7_from_pass_side_dispenser_is_neither_target_nor_highlighted() -> void:
	var box: Box = _box_on_tray()
	var sweet: SeasoningDispenser = _dispenser("SweetPaprika")
	_player.global_position = Vector3(sweet.global_position.x, 0.0, PASS_Z)
	_player.rotation = Vector3(0.0, PI, 0.0)
	await _settle()
	var detector: InteractionDetector = _player.get_node("%InteractionDetector")
	for dispenser: SeasoningDispenser in _dispensers():
		assert_ne(detector.get_target(), dispenser, dispenser.name)
		var highlight: Highlightable = dispenser.get_node("%Highlightable")
		assert_false(highlight.is_highlighted(), "%s sin resaltar" % dispenser.name)
	_actor.interact_pressed()
	assert_eq(box.get_contents().seasonings, [] as Array[SeasoningData], "la caja no cambia")


func test_ac7_from_operator_side_dispenser_is_target_and_highlighted() -> void:
	_box_on_tray()
	var sweet: SeasoningDispenser = _dispenser("SweetPaprika")
	_player.global_position = Vector3(sweet.global_position.x, 0.0, OPERATOR_Z)
	await _settle()
	var detector: InteractionDetector = _player.get_node("%InteractionDetector")
	assert_eq(detector.get_target(), sweet)
	assert_true((sweet.get_node("%Highlightable") as Highlightable).is_highlighted())


func test_ac7_operator_side_only_false_reaches_from_both_sides() -> void:
	var data: SeasoningStationData = STATION_DATA.duplicate()
	data.operator_side_only = false
	_add_station(data)
	for dispenser: SeasoningDispenser in _dispensers():
		assert_true(dispenser.is_reachable_from(_floor(PASS_Z), _hold), dispenser.name)


# --- AC8 ---


func test_ac8_busy_hand_dispensers_are_not_interactable_and_hand_unchanged() -> void:
	var box: Box = _box_on_tray()
	var cachelos: Ingredient = _held_cachelos(IngredientData.CookingState.COOKED)
	for dispenser: SeasoningDispenser in _dispensers():
		assert_false(dispenser.can_interact(_actor), "%s no es objetivo" % dispenser.name)
		assert_false(dispenser.interact(_actor), "%s no consume" % dispenser.name)
	assert_eq(_hold.get_held_item(), cachelos, "la mano no cambia")
	assert_eq(box.get_contents().seasonings, [] as Array[SeasoningData])
	assert_eq(_rejections.size(), 0, "sin rechazos: ya no hay HAND_BUSY")


func test_ac8_busy_hand_detector_does_not_pick_a_dispenser() -> void:
	_box_on_tray()
	var cachelos: Ingredient = _held_cachelos(IngredientData.CookingState.COOKED)
	var salt: SeasoningDispenser = _dispenser("Salt")
	_player.global_position = Vector3(salt.global_position.x, 0.0, OPERATOR_Z)
	await _settle()
	var target: Node = (
		(_player.get_node("%InteractionDetector") as InteractionDetector).get_target()
	)
	assert_false(target is SeasoningDispenser, "el detector no elige un dispensador")
	assert_eq(_hold.get_held_item(), cachelos)


# --- AC9 ---


func test_ac9_tray_pick_and_place_from_both_sides() -> void:
	var tray: Slot = _station.get_tray()
	for z: float in [PASS_Z, OPERATOR_Z]:
		_player.global_position = Vector3(tray.global_position.x, 0.0, z)
		var box: Box = _new_box(1.0)
		assert_true(_hold.pick_up(box))
		assert_true(tray.interact(_actor), "deja desde z=%s" % z)
		assert_eq(_station.get_box(), box)
		assert_true(box.interact(_actor), "coge desde z=%s" % z)
		assert_eq(_hold.get_held_item(), box)
		assert_null(_station.get_box())
		_hold.drop()
		box.queue_free()


func test_ac9_tray_rejects_non_box_without_dropping() -> void:
	var cachelos: Ingredient = _held_cachelos(IngredientData.CookingState.COOKED)
	assert_true(_station.get_tray().interact(_actor), "consume la pulsación")
	assert_eq(_hold.get_held_item(), cachelos)
	assert_null(_station.get_box())


func test_ac9_second_box_on_occupied_tray_is_rejected() -> void:
	var first: Box = _box_on_tray()
	var tray: Slot = _station.get_tray()
	_player.global_position = Vector3(tray.global_position.x, 0.0, PASS_Z)
	_player.rotation = Vector3(0.0, PI, 0.0)
	var second: Box = _new_box(1.0)
	assert_true(_hold.pick_up(second))
	await _settle()
	assert_eq((_player.get_node("%InteractionDetector") as InteractionDetector).get_target(), first)
	assert_true(_actor.interact_pressed())
	assert_eq(_hold.get_held_item(), second, "la segunda sigue en la mano")
	assert_eq(_station.get_box(), first)


# --- AC10 ---


func test_ac10_cooked_cachelos_restock_bowl_from_any_side() -> void:
	var bowl: CachelosBowl = _bowl()
	assert_eq(bowl.stock, 0)
	watch_signals(bowl)
	var cachelos: Ingredient = _held_cachelos(IngredientData.CookingState.COOKED)
	assert_true(bowl.is_reachable_from(_floor(PASS_Z), _hold), "con algo en la mano, desde el pase")
	_press(bowl)
	assert_eq(bowl.stock, 1)
	assert_null(_hold.get_held_item(), "la mano queda vacía")
	assert_true(cachelos.is_queued_for_deletion())
	assert_signal_emitted_with_parameters(bowl, "stock_changed", [1])


func test_ac10_raw_or_burnt_cachelos_are_rejected() -> void:
	var bowl: CachelosBowl = _bowl()
	for state: IngredientData.CookingState in [
		IngredientData.CookingState.RAW, IngredientData.CookingState.BURNT
	]:
		_rejections.clear()
		var cachelos: Ingredient = _held_cachelos(state)
		_press(bowl)
		assert_eq(bowl.stock, 0)
		assert_eq(_hold.get_held_item(), cachelos, "siguen en la mano")
		assert_eq(
			_rejections, [SeasoningRules.Rejection.NOT_ACCEPTED] as Array[SeasoningRules.Rejection]
		)
		_hold.drop()
		cachelos.queue_free()


func test_ac10_other_item_is_rejected() -> void:
	var box: Box = _new_box(1.0)
	assert_true(_hold.pick_up(box))
	_press(_bowl())
	assert_eq(_hold.get_held_item(), box)
	assert_eq(
		_rejections, [SeasoningRules.Rejection.NOT_ACCEPTED] as Array[SeasoningRules.Rejection]
	)


func test_ac10_full_bowl_rejects_restock() -> void:
	var bowl: CachelosBowl = _bowl()
	for i: int in STATION_DATA.cachelos_stock_max:
		_held_cachelos(IngredientData.CookingState.COOKED)
		_press(bowl)
	assert_eq(bowl.stock, 3)
	var extra: Ingredient = _held_cachelos(IngredientData.CookingState.COOKED)
	_press(bowl)
	assert_eq(bowl.stock, 3)
	assert_eq(_hold.get_held_item(), extra)
	assert_eq(_rejections, [SeasoningRules.Rejection.BOWL_FULL] as Array[SeasoningRules.Rejection])


func test_ac10_portions_visual_follows_stock() -> void:
	var portions: Node3D = _bowl().get_node("%Portions")
	_held_cachelos(IngredientData.CookingState.COOKED)
	_press(_bowl())
	var visible: int = 0
	for child: Node in portions.get_children():
		if (child as Node3D).visible:
			visible += 1
	assert_eq(visible, 1)


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
	var box: Box = _box_on_tray()
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
	var box: Box = _box_on_tray()
	_press(_bowl())
	assert_false(box.has_seasoning(CACHELOS))
	assert_eq(_bowl().stock, 0)
	assert_eq(_rejections, [SeasoningRules.Rejection.BOWL_EMPTY] as Array[SeasoningRules.Rejection])


func test_ac11_toggle_reachable_only_from_operator_side_with_empty_hand() -> void:
	assert_false(_bowl().is_reachable_from(_floor(PASS_Z), _hold))
	assert_true(_bowl().is_reachable_from(_floor(OPERATOR_Z), _hold))


func test_ac11_toggle_rejects_without_box_or_not_full() -> void:
	_station_with_stock(2)
	_press(_bowl())
	_box_on_tray(0.6)
	_press(_bowl())
	assert_eq(_bowl().stock, 2)
	assert_eq(
		_rejections,
		(
			[SeasoningRules.Rejection.NO_BOX, SeasoningRules.Rejection.BOX_NOT_FULL]
			as Array[SeasoningRules.Rejection]
		)
	)


func test_ac11_removing_cachelos_with_full_bowl_is_rejected() -> void:
	_station_with_stock(1)
	var bowl: CachelosBowl = _bowl()
	var box: Box = _box_on_tray()
	_press(bowl)
	assert_true(box.has_seasoning(CACHELOS))
	assert_eq(bowl.stock, 0)
	for i: int in STATION_DATA.cachelos_stock_max:
		_held_cachelos(IngredientData.CookingState.COOKED)
		_press(bowl)
	assert_eq(bowl.stock, STATION_DATA.cachelos_stock_max)
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
	assert_true(salt.interact(_actor), "bandeja vacía: rechazo")
	assert_eq(_rejections, [SeasoningRules.Rejection.NO_BOX] as Array[SeasoningRules.Rejection])
	var box: Box = _box_on_tray()
	_now += 0.1
	assert_true(salt.interact(_actor))
	assert_true(box.has_seasoning(SALT), "0,1 s tras un rechazo sí condimenta")


func test_ac11_bowl_rejection_does_not_arm_guard() -> void:
	_station_with_stock(1)
	assert_true(_bowl().interact(_actor), "bandeja vacía: rechazo")
	var box: Box = _box_on_tray()
	_now += 0.1
	assert_true(_bowl().interact(_actor))
	assert_true(box.has_seasoning(CACHELOS))
	assert_eq(_bowl().stock, 0)


func test_ac11_toggle_has_guard() -> void:
	_station_with_stock(2)
	var box: Box = _box_on_tray()
	assert_true(_bowl().interact(_actor))
	_now += 0.1
	assert_true(_bowl().interact(_actor))
	assert_true(box.has_seasoning(CACHELOS))
	assert_eq(_bowl().stock, 1)
