extends GutTest
## PUL-126 AC1 (diseño AC2, ADR-003 §11.2): filas D (dispensadores) y E (cuenco) del mapa mano ×
## objetivo con las escenas reales. Cada fila de `tests/fixtures/action_matrix.csv` se contrasta
## con `is_reachable_from` (filtro de lado), `get_action_hint` (lo que se ve) e `interact` (lo que
## pasa):
## las dos últimas salen de la misma `_resolve`, así que el efecto es el publicado. Las columnas
## son las de `test_action_rules.gd`; aquí solo se evalúan los receptores `dispenser_*` y `bowl`.

const FIXTURE: String = "res://tests/fixtures/action_matrix.csv"
const STATION_SCENE: PackedScene = preload("res://entities/stations/seasoning_station.tscn")
const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const CACHELOS_SCENE: PackedScene = preload("res://entities/items/cachelos.tscn")
const BOX_DATA: BoxData = preload("res://data/boxes/box.tres")
const SWEET: SeasoningData = preload("res://data/seasonings/sweet_dressing.tres")
const HOT: SeasoningData = preload("res://data/seasonings/hot_dressing.tres")
const CACHELOS: SeasoningData = preload("res://data/seasonings/cachelos.tres")
const PASS_Z: float = -1.2
const OPERATOR_Z: float = 1.2
const STATES: Dictionary[String, ActionHint.State] = {
	"NONE": ActionHint.State.NONE,
	"OK": ActionHint.State.OK,
	"BLOCKED": ActionHint.State.BLOCKED,
}

var _rows: Array[Dictionary] = []
var _level: Node3D
var _station: SeasoningStation
var _player: Player
var _hold: HoldComponent
var _actor: InteractionComponent
var _rejections: Array[SeasoningRules.Rejection] = []


func before_all() -> void:
	var file: FileAccess = FileAccess.open(FIXTURE, FileAccess.READ)
	assert_not_null(file, "no abre %s" % FIXTURE)
	if file == null:
		return
	var header: PackedStringArray = file.get_csv_line()
	while not file.eof_reached():
		var cells: PackedStringArray = file.get_csv_line()
		if cells.size() == 1 and cells[0].is_empty():
			continue  # línea en blanco final
		assert_eq(cells.size(), header.size(), "fila mal formada: %s" % ",".join(cells))
		if cells.size() != header.size():
			continue
		var row: Dictionary = {}
		for i: int in header.size():
			row[header[i]] = cells[i]
		if String(row["receiver"]).begins_with("dispenser_") or row["receiver"] == "bowl":
			_rows.append(row)


func before_each() -> void:
	_rejections.clear()
	_level = add_child_autofree(Node3D.new())
	_station = STATION_SCENE.instantiate()
	_level.add_child(_station)
	_player = PLAYER_SCENE.instantiate()
	_level.add_child(_player)
	_hold = _player.get_node("%HoldComponent")
	_hold.items_root = _level
	_actor = _player.get_node("%InteractionComponent")
	for dispenser: SeasoningDispenser in _dispensers():
		dispenser.rejected.connect(_on_rejected)
	_bowl().rejected.connect(_on_rejected)


func _on_rejected(reason: SeasoningRules.Rejection) -> void:
	_rejections.append(reason)


func _dispensers() -> Array[SeasoningDispenser]:
	var found: Array[SeasoningDispenser] = []
	for child: Node in _station.get_node("Dispensers").get_children():
		found.append(child as SeasoningDispenser)
	return found


func _bowl() -> CachelosBowl:
	return _station.get_node("CachelosBowl") as CachelosBowl


func _receiver(row: Dictionary) -> Node:
	match String(row["receiver"]):
		"dispenser_season_sweet":
			return _station.get_node("Dispensers/SweetDressing")
		"dispenser_season_hot":
			return _station.get_node("Dispensers/HotDressing")
	return _bowl()


func _params(row: Dictionary) -> Dictionary:
	var params: Dictionary = {}
	for pair: String in String(row["params"]).split(";", false):
		var parts: PackedStringArray = pair.split("=")
		params[parts[0]] = parts[1]
	return params


## Pone en la mano lo que dice `hand` (M0…M9, `+C` = la caja ya lleva cachelos). Devuelve el objeto.
func _equip(hand: String) -> Node:
	var item: Node = null
	match hand.trim_suffix("+C"):
		"M0":
			return null
		"M1", "M2":
			item = OCTOPUS_SCENE.instantiate()
		"M3", "M4":
			item = CACHELOS_SCENE.instantiate()
		_:
			item = _new_box(hand)
	if item.get_parent() == null:
		_level.add_child(item)
	if hand in ["M2", "M4"]:
		(item as Ingredient).set_cooked()
	assert_true(_hold.pick_up(item), "coge %s" % hand)
	return item


func _new_box(hand: String) -> Box:
	var box: Box = BOX_SCENE.instantiate()
	box.data = BOX_DATA
	_level.add_child(box)
	box.fill = {"M5": 0.0, "M6": 0.6}.get(hand.trim_suffix("+C"), 1.0)
	match hand.trim_suffix("+C"):
		"M8":
			box.apply_seasoning(SWEET)
		"M9":
			box.apply_seasoning(HOT)
	if hand.ends_with("+C"):
		box.apply_seasoning(CACHELOS)
	return box


func _drop_hand() -> void:
	var held: Node = _hold.drop()
	if held != null:
		held.queue_free()


func _seasonings_of(item: Node) -> Array[SeasoningData]:
	var box: Box = item as Box
	if box == null:
		var none: Array[SeasoningData] = []
		return none
	return box.get_contents().seasonings


func _describe(hint: ActionHint) -> String:
	return (
		"%s/%s/%s%s" % [hint.verb, hint.state, hint.reason, "/sustituye" if hint.replaces else ""]
	)


# --- AC1: la tabla D y E, celda a celda ---


func test_fixture_has_the_station_rows() -> void:
	var dispensers: int = 0
	var bowls: int = 0
	for row: Dictionary in _rows:
		if row["receiver"] == "bowl":
			bowls += 1
		else:
			dispensers += 1
	assert_eq(dispensers, 40, "D: 2 dispensadores × 2 lados × 10 manos")
	assert_eq(bowls, 130, "E: 10 casos de lado y stock × 13 manos")


func test_ac1_hint_matches_the_matrix_for_every_dispenser_and_bowl_row() -> void:
	for row: Dictionary in _rows:
		var id: String = row["id"]
		var params: Dictionary = _params(row)
		var receiver: Node = _receiver(row)
		if row["receiver"] == "bowl":
			_bowl().stock = int(params["stock"])
		var item: Node = _equip(row["hand"])
		var floor_position: Vector2 = Vector2(
			(receiver as Node3D).global_position.x,
			OPERATOR_Z if params["side"] == "operator" else PASS_Z
		)

		var reachable: bool = receiver.call(&"is_reachable_from", floor_position, _hold)
		assert_eq(reachable, row["reachable"] == "1", "%s: is_reachable_from" % id)
		if reachable:
			var hint: ActionHint = receiver.call(&"get_action_hint", _actor)
			assert_eq(hint.verb, StringName(row["verb"]), "%s: verbo (%s)" % [id, _describe(hint)])
			assert_eq(hint.state, STATES[row["state"]], "%s: estado (%s)" % [id, _describe(hint)])
			assert_eq(hint.reason, StringName(row["reason"]), "%s: motivo" % id)
			assert_eq(hint.replaces, row["replaces"] == "1", "%s: sustituye" % id)
			assert_eq(
				receiver.call(&"can_interact", _actor), hint.is_target(), "%s: can_interact" % id
			)
			if hint.state == ActionHint.State.NONE:
				assert_false(hint.is_target(), id)
		_drop_hand()
		if item != null:
			item.queue_free()


## Lo que dice la tabla es lo que pasa: `interact` ejecuta la rama del hint publicado.
func test_ac1_interact_follows_the_published_hint_for_every_reachable_row() -> void:
	for row: Dictionary in _rows:
		if row["reachable"] != "1":
			continue
		var id: String = row["id"]
		var params: Dictionary = _params(row)
		var receiver: Node = _receiver(row)
		var bowl: CachelosBowl = _bowl()
		if row["receiver"] == "bowl":
			bowl.stock = int(params["stock"])
		var item: Node = _equip(row["hand"])
		var before_stock: int = bowl.stock
		var before_seasonings: Array[SeasoningData] = _seasonings_of(item).duplicate()
		_rejections.clear()

		var pressed: bool = receiver.call(&"interact", _actor)

		match row["state"]:
			"NONE":
				assert_false(pressed, "%s: sin objetivo no consume" % id)
				assert_eq(_rejections.size(), 0, "%s: sin rechazo" % id)
				assert_eq(_hold.get_held_item(), item, "%s: la mano no cambia" % id)
				assert_eq(bowl.stock, before_stock, "%s: stock" % id)
			"BLOCKED":
				assert_true(pressed, "%s: el rechazo consume la pulsación" % id)
				assert_eq(_rejections.size(), 1, "%s: un `rejected`" % id)
				assert_eq(_hold.get_held_item(), item, "%s: la mano no cambia" % id)
				assert_eq(bowl.stock, before_stock, "%s: stock" % id)
				assert_eq(_seasonings_of(item), before_seasonings, "%s: la caja no cambia" % id)
			"OK":
				assert_true(pressed, "%s: consume" % id)
				assert_eq(_rejections.size(), 0, "%s: sin rechazo" % id)
				_assert_effect(row, receiver, item, before_stock)
		_drop_hand()
		if is_instance_valid(item):
			item.queue_free()


func _assert_effect(row: Dictionary, receiver: Node, item: Node, before_stock: int) -> void:
	var id: String = row["id"]
	if row["receiver"] == "bowl":
		if item is Box:
			assert_true((item as Box).has_seasoning(CACHELOS), "%s: pone cachelos" % id)
			assert_eq(_bowl().stock, before_stock - 1, "%s: gasta una ración" % id)
			assert_eq(_hold.get_held_item(), item, "%s: la caja sigue en la mano" % id)
		else:
			assert_eq(_bowl().stock, before_stock + 2, "%s: repone 2 raciones" % id)
			assert_null(_hold.get_held_item(), "%s: el cachelo se consume" % id)
	else:
		var seasoning: SeasoningData = (receiver as SeasoningDispenser).seasoning
		var box: Box = item as Box
		assert_true(box.has_seasoning(seasoning), "%s: aplica su aliño" % id)
		assert_eq(box.get_contents().seasonings.size(), 1, "%s: nunca dos aliños" % id)
		assert_eq(_hold.get_held_item(), box, "%s: la caja sigue en la mano" % id)


# --- Casos que la tabla no ejercita por separado ---


func test_ac1_dispensers_declare_the_seasoning_verb() -> void:
	var sweet: SeasoningDispenser = _station.get_node("Dispensers/SweetDressing")
	var hot: SeasoningDispenser = _station.get_node("Dispensers/HotDressing")
	var box: Box = _new_box("M7")
	assert_true(_hold.pick_up(box))
	assert_eq(sweet.get_action_hint(_actor).verb, ActionVerb.SEASON_SWEET)
	assert_eq(hot.get_action_hint(_actor).verb, ActionVerb.SEASON_HOT)
	assert_eq(sweet.get_action_hint(_actor).verb, SWEET.verb, "el verbo sale de los datos")


func test_ac1_hint_is_a_pure_query() -> void:
	var box: Box = _new_box("M7")
	assert_true(_hold.pick_up(box))
	watch_signals(box)
	for receiver: Node in [_dispensers()[0], _bowl()]:
		for i: int in 3:
			receiver.call(&"get_action_hint", _actor)
	assert_signal_not_emitted(box, "seasoned")
	assert_eq(box.get_contents().seasonings.size(), 0)
	assert_eq(_bowl().stock, 0)
	assert_eq(_rejections.size(), 0)


func test_ac1_without_actor_or_holder_there_is_no_target() -> void:
	for receiver: Node in [_dispensers()[0], _bowl()]:
		assert_false((receiver.call(&"get_action_hint", null) as ActionHint).is_target())
		assert_false(receiver.call(&"can_interact", null))
		assert_false(receiver.call(&"interact", null))


func test_ac1_stations_satisfy_the_hint_contract() -> void:
	for receiver: Node in [_dispensers()[0], _dispensers()[1], _bowl()]:
		assert_true(receiver.has_method(InteractionContract.HINT_METHOD), receiver.name)
		assert_true(receiver.is_in_group(InteractionContract.GROUP_INTERACTABLE), receiver.name)
	assert_eq(InteractionContract.scan_tree(_station), [])


## Desde el lado de pase, con una caja (llena o no), el cuenco no es candidato del detector real.
func test_ac1_detector_skips_the_bowl_with_a_box_from_the_pass_side() -> void:
	var box: Box = _new_box("M7")
	assert_true(_hold.pick_up(box))
	_bowl().stock = 2
	var detector: InteractionDetector = _player.get_node("%InteractionDetector")
	_player.global_position = Vector3(_bowl().global_position.x, 0.0, PASS_Z)
	_player.rotation = Vector3(0.0, PI, 0.0)
	await wait_physics_frames(3)
	assert_ne(detector.get_target(), _bowl(), "pase + caja: no es objetivo")
	_player.global_position = Vector3(_bowl().global_position.x, 0.0, OPERATOR_Z)
	_player.rotation = Vector3.ZERO
	await wait_physics_frames(3)
	assert_eq(detector.get_target(), _bowl(), "lado de aliñar + caja llena: sí")
	assert_eq(detector.get_hint().verb, ActionVerb.CACHELOS)
	assert_eq(detector.get_hint().state, ActionHint.State.OK)
