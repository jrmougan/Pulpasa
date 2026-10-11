extends GutTest
## PUL-132 AC1 (D26, lenguaje-acciones AC2 y AC7): ninguna pulsación con objetivo queda muda, sobre
## el `level_01.tscn` real (sus ollas, pasaplatos, cubos, dispensadores, cuenco, estantería, puesto
## y barra), no sobre escenas sueltas como `test_action_matrix.gd`.
## Cada caso toma su esperado de una fila de `tests/fixtures/action_matrix.csv` (la tabla del
## diseño) y la coloca en un receptor del nivel: monta la mano y el estado del receptor, pone a J1
## de cara al receptor y pulsa `E` con el teclado, con el detector real. Por pulsación:
## - con objetivo (o mano llena sin objetivo) hay exactamente UNA `interaction_resolved`;
## - `OK` cambia el mundo y no suena `rejected`; `BLOCKED` no cambia nada, trae su motivo y suena
##   exactamente un `rejected`;
## - una celda `—` no es objetivo ni se resalta; con la mano vacía no responde y con la mano llena
##   suelta al suelo (verbo `drop`).
## Además: los 6 cortes y el 7.º (rechazo `full`), dos rechazos seguidos a ~0,1 s (se cuentan
## los dos)
## y una caja que no encaja dentro de la zona de entrega.
## La colocación del jugador es directa (posición y giro); la pulsación, el detector y las
## estaciones son los reales. Caminar de verdad se cubre en `test_m2b_flow.gd` y
## `test_d26_touch_flow.gd`.

const LEVEL: PackedScene = preload("res://scenes/levels/level_01.tscn")
const Walker: GDScript = preload("res://tests/integration/level_walker.gd")
const FIXTURE: String = "res://tests/fixtures/action_matrix.csv"
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const CACHELOS_SCENE: PackedScene = preload("res://entities/items/cachelos.tscn")
const BOX_DATA: BoxData = preload("res://data/boxes/box.tres")
const OCTOPUS: IngredientData = preload("res://data/ingredients/octopus.tres")
const SWEET: SeasoningData = preload("res://data/seasonings/sweet_dressing.tres")
const HOT: SeasoningData = preload("res://data/seasonings/hot_dressing.tres")
const CACHELOS: SeasoningData = preload("res://data/seasonings/cachelos.tres")
const STATES: Dictionary[String, ActionHint.State] = {
	"NONE": ActionHint.State.NONE,
	"OK": ActionHint.State.OK,
	"BLOCKED": ActionHint.State.BLOCKED,
}
## Casos «fila@receptor». La fila sale del CSV del diseño; el receptor, de `_spot()`.
const POT_CASES: Array[String] = [
	"C1-M1@pot1",
	"C2-M0@pot1",
	"C2-M1@pot1",
	"C2-M2@pot1",
	"C3-M0@pot1",
	"C3-M0@pot2",
	"C3-M1@pot1",
	"C3b-M0@pot1",
	"C3b-M1@pot1",
	"C4-M1@pot2",
	"C5-M0@pot1",
	"C5-M1@pot1",
]
const SIMPLE_CASES: Array[String] = [
	"A1-M0@nevera",
	"A1-M1@nevera",
	"A2-M0@cachelera",
	"A3-M0@rack",
	"A3-M7@rack",
	"A4-M0@loose",
	"A4-M5@loose",
	"A5-M0@slot",
	"A5-M2@slot",
	"A5-M5@slot",
	"A6-M1@trash_kitchen",
	"A6-M7@trash_service",
	"A6-M9@trash_kitchen",
	"A7-M7@stand",
	"A8-M2@floor",
	"A8-M7@floor",
	"A9-M1@wall",
	"A9-M6@wall",
]
const BOX_CASES: Array[String] = [
	"B1-M0@box",
	"B1-M1@box",
	"B1-M2@box",
	"B1-M6@box",
	"B2-M2@box",
	"B3-M0@box",
	"B3-M1@box",
	"B3-M2@box",
]
const DISPENSER_CASES: Array[String] = [
	"D1-M5@sweet",
	"D1-M6@sweet",
	"D1-M7@sweet",
	"D1-M8@sweet",
	"D1-M9@sweet",
	"D1p-M7@sweet",
	"D2-M6@hot",
	"D2-M7@hot",
	"D2-M8@hot",
	"D2-M9@hot",
]
const BOWL_CASES: Array[String] = [
	"E1s0-M4@bowl",
	"E1s0-M6@bowl",
	"E1s0-M7@bowl",
	"E1s0-M7+C@bowl",
	"E2s1-M7@bowl",
	"E2s1-M7+C@bowl",
	"E2s2-M4@bowl",
	"E3s3-M4@bowl",
	"E3s3-M7@bowl",
	"E4s0-M4@bowl",
]
## Ticks de física para que el detector vea el cambio.
const SETTLE_TICKS: int = 4
const STEP: float = 0.1
## Distancia de uso al frente de una estación del mostrador trasero y de la estantería (m).
const BACK_ACCESS: float = 0.9
const SHELF_ACCESS: float = 0.9
## Distancia al receptor de una caja o ingrediente suelto (m).
const LOOSE_GAP: float = 1.2
const LOOSE_AT: Vector2 = Vector2(-1.5, 2.0)
## Punto con sitio delante (suelo libre del servicio) y punto contra la barra (sin sitio).
const FLOOR_AT: Vector2 = Vector2(4.7, 3.0)
const WALL_STAND: Vector2 = Vector2(-1.5, 1.0)
const WALL_AIM: Vector2 = Vector2(-1.5, 0.0)

var _rows: Dictionary[String, Dictionary] = {}
var _level: Node3D
var _player: Player
var _hold: HoldComponent
var _actor: InteractionComponent
var _detector: InteractionDetector
var _walker: RefCounted
var _cues: Array[StringName] = []
## Reproductores de cues del nivel que ya se escuchan (instance id → true).
var _listening: Dictionary[int, bool] = {}
## Número de casos que se han ejecutado (los tests comprueban que no se salta ninguno).
var _ran: int = 0


func before_all() -> void:
	var file: FileAccess = FileAccess.open(FIXTURE, FileAccess.READ)
	assert_not_null(file, "no abre %s" % FIXTURE)
	if file == null:
		return
	var header: PackedStringArray = file.get_csv_line()
	while not file.eof_reached():
		var cells: PackedStringArray = file.get_csv_line()
		if cells.size() != header.size():
			continue
		var row: Dictionary = {}
		for i: int in header.size():
			row[header[i]] = cells[i]
		_rows[String(row["id"])] = row


func before_each() -> void:
	PhaselessConfig.disable()
	GameState.set_paused(false)
	watch_signals(EventBus)
	_ran = 0


func after_each() -> void:
	if is_instance_valid(_level):
		_level.queue_free()
		await get_tree().process_frame
	for keycode: Key in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_E, KEY_Q]:
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = keycode
		Input.parse_input_event(event)
	Input.flush_buffered_events()
	GameState.set_paused(false)
	GameState.reset_input()
	PhaselessConfig.restore()


# --- Montaje ------------------------------------------------------------------------------------


## `level_01` real nuevo, con J1 controlando a `Player1` en Individual.
func _fresh_level() -> void:
	if is_instance_valid(_level):
		_level.queue_free()
		await get_tree().process_frame
	_level = LEVEL.instantiate()
	add_child(_level)
	await wait_physics_frames(2)
	_player = _level.get_node("Characters/Player1") as Player
	_hold = _player.get_node("%HoldComponent")
	_actor = _player.get_node("%InteractionComponent")
	_detector = _player.get_node("%InteractionDetector")
	_walker = Walker.new(get_tree(), _player, 1)
	_cues = []
	_listening.clear()


func _stations(path: String) -> Node3D:
	return _level.get_node("Stations/" + path) as Node3D


func _station() -> SeasoningStation:
	return _stations("SeasoningStation") as SeasoningStation


func _params(row: Dictionary) -> Dictionary:
	var params: Dictionary = {}
	for pair: String in String(row["params"]).split(";", false):
		var parts: PackedStringArray = pair.split("=")
		params[parts[0]] = parts[1]
	return params


func _xz(node: Node3D) -> Vector2:
	return Vector2(node.global_position.x, node.global_position.z)


## Receptor del nivel y desde dónde se usa: {node, stand, aim}. `node` es `null` para suelo/pared.
func _spot(place: String, row: Dictionary) -> Dictionary:
	var params: Dictionary = _params(row)
	var node: Node3D = null
	var aim: Vector2 = Vector2.ZERO
	var stand: Vector2 = Vector2.ZERO
	match place:
		"pot1", "pot2":
			node = _stations("Kitchen" if place == "pot1" else "Kitchen2")
			aim = _xz(node)
			stand = aim + Vector2(0.0, BACK_ACCESS)
		"nevera", "cachelera":
			node = _stations("OctopusStorage" if place == "nevera" else "CachelosStorage")
			aim = _xz(node)
			stand = aim + Vector2(0.0, BACK_ACCESS)
		"rack":
			for child: Node in _stations("BoxShelf").get_children():
				if child is ItemSpawner and (child as ItemSpawner).data == BOX_DATA:
					node = child as Node3D
			aim = _xz(node)
			stand = aim + Vector2(SHELF_ACCESS, 0.0)
		"slot":
			node = _stations("PassSlot05")
			aim = _xz(node)
			stand = Walker.station_stand(aim, _station().global_position.z, -1.0)
		"trash_kitchen":
			node = _stations("TrashBinKitchen")
			aim = _xz(node)
			stand = aim + Vector2(0.0, BACK_ACCESS)
		"trash_service":
			node = _stations("TrashBinService")
			aim = _xz(node)
			stand = aim + Vector2(0.0, -BACK_ACCESS)
		"stand":
			node = _stations("OrderStand2")
			aim = _xz(node)
			stand = aim + Vector2(0.0, -LOOSE_GAP)
		"sweet", "hot", "bowl":
			var part: String = "Dispensers/SweetDressing"
			if place == "hot":
				part = "Dispensers/HotDressing"
			elif place == "bowl":
				part = "CachelosBowl"
			node = _station().get_node(part) as Node3D
			aim = _xz(node)
			var side: float = -1.0 if params.get("side", "operator") == "pass" else 1.0
			stand = Walker.station_stand(aim, _station().global_position.z, side)
		"box", "loose":
			aim = LOOSE_AT
			stand = LOOSE_AT + Vector2(0.0, LOOSE_GAP)
		"floor":
			stand = FLOOR_AT
			aim = FLOOR_AT + Vector2(0.0, 1.0)
		"wall":
			stand = WALL_STAND
			aim = WALL_AIM
	return {"node": node, "stand": stand, "aim": aim}


func _put_raw_in_pot(pot: CookingStation) -> void:
	var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
	_level.get_node("Items").add_child(octopus)
	assert_true(_hold.pick_up(octopus))
	assert_true(pot.interact(_actor))


func _advance(pot: CookingStation, seconds: float) -> void:
	simulate(pot, roundi(seconds / STEP), STEP)


## Olla del nivel con `cooked` cocidos listos, `burnt` quemados y `cooking` cociendo.
func _build_pot(pot: CookingStation, cooked: int, burnt: int, cooking: int) -> void:
	for _i: int in burnt:
		_put_raw_in_pot(pot)
	if burnt > 0:
		_advance(pot, OCTOPUS.cook_time + OCTOPUS.burn_time)
	for _i: int in cooked:
		_put_raw_in_pot(pot)
	if cooked > 0:
		_advance(pot, OCTOPUS.cook_time)
	for _i: int in cooking:
		_put_raw_in_pot(pot)


func _new_box(hand: String) -> Box:
	var box: Box = BOX_SCENE.instantiate()
	box.data = BOX_DATA
	_level.get_node("Items").add_child(box)
	box.fill = {"M5": 0.0, "M6": 0.5}.get(hand.trim_suffix("+C"), 1.0)
	match hand.trim_suffix("+C"):
		"M8":
			box.apply_seasoning(SWEET)
		"M9":
			box.apply_seasoning(HOT)
	if hand.ends_with("+C"):
		box.apply_seasoning(CACHELOS)
	return box


## Pone en la mano lo que dice `hand` (M0…M9; `+C` = la caja ya lleva cachelos).
func _equip(hand: String) -> Node:
	var item: Node = null
	match hand.trim_suffix("+C"):
		"M0":
			return null
		"M1", "M2":
			item = OCTOPUS_SCENE.instantiate()
			_level.get_node("Items").add_child(item)
		"M3", "M4":
			item = CACHELOS_SCENE.instantiate()
			_level.get_node("Items").add_child(item)
		_:
			item = _new_box(hand)
	if hand in ["M2", "M4"]:
		(item as Ingredient).set_cooked()
	assert_true(_hold.pick_up(item), "la mano coge %s" % hand)
	return item


## Monta el receptor del caso (estado de la fila) antes de equipar la mano.
func _build(place: String, row: Dictionary, spot: Dictionary) -> Node:
	var params: Dictionary = _params(row)
	var node: Node = spot["node"]
	match place:
		"pot1", "pot2":
			var free: int = int(params["free"])
			var burnt: int = int(params["burnt"])
			var ready: int = int(params["ready"])
			_build_pot(node as CookingStation, ready, burnt, 2 - free - burnt - ready)
		"bowl":
			(node as CachelosBowl).stock = int(params["stock"])
		"box":
			var box: Box = BOX_SCENE.instantiate()
			box.data = BOX_DATA
			box.fill = float(params["fill"])
			_level.get_node("Items").add_child(box)
			box.global_position = Vector3(LOOSE_AT.x, 0.0, LOOSE_AT.y)
			node = box
		"loose":
			var item: Node3D = OCTOPUS_SCENE.instantiate()
			_level.get_node("Items").add_child(item)
			item.global_position = Vector3(LOOSE_AT.x, 0.0, LOOSE_AT.y)
			node = item
	return node


## Yaw de un personaje que mira de `from` a `to` (su frente es −Z).
func _yaw(from: Vector2, to: Vector2) -> float:
	var direction: Vector2 = to - from
	return atan2(-direction.x, -direction.y)


func _place_player(stand: Vector2, aim: Vector2) -> void:
	_player.global_position = Vector3(stand.x, 0.005, stand.y)
	_player.velocity = Vector3.ZERO
	_player.rotation = Vector3(0.0, _yaw(stand, aim), 0.0)
	await wait_physics_frames(SETTLE_TICKS)


# --- Lectura del mundo --------------------------------------------------------------------------


## Fotografía de lo que una pulsación puede cambiar en el nivel (mano incluida).
func _snapshot() -> String:
	var parts: Array[String] = []
	var held: Node = _hold.get_held_item()
	parts.append("mano=%d" % (held.get_instance_id() if held != null else 0))
	for node: Node in _level.find_children("*", "", true, false):
		if node is Ingredient:
			var ingredient: Ingredient = node
			(
				parts
				. append(
					(
						"i%d:%d:%.3f:%s:%s"
						% [
							ingredient.get_instance_id(),
							ingredient.state,
							ingredient.remaining,
							ingredient.get_parent().get_path(),
							ingredient.is_queued_for_deletion(),
						]
					)
				)
			)
		elif node is Box:
			var box: Box = node
			(
				parts
				. append(
					(
						"b%d:%.3f:%s:%s:%s"
						% [
							box.get_instance_id(),
							box.fill,
							_seasoning_ids(box),
							box.get_parent().get_path(),
							box.is_queued_for_deletion(),
						]
					)
				)
			)
		elif node is Slot:
			var stored: Node3D = (node as Slot).get_item()
			parts.append(
				"s%d:%d" % [node.get_instance_id(), stored.get_instance_id() if stored else 0]
			)
		elif node is CachelosBowl:
			parts.append("c%d" % (node as CachelosBowl).stock)
		elif node is CookingStation:
			var pot: CookingStation = node
			parts.append("o%d:%d:%s" % [pot.get_instance_id(), pot._free_places(), pot.has_burnt()])
	return ";".join(parts)


func _seasoning_ids(box: Box) -> String:
	var ids: Array[String] = []
	for seasoning: SeasoningData in box.get_contents().seasonings:
		ids.append(str(seasoning.get_instance_id()))
	return ",".join(ids)


func _describe(hint: ActionHint) -> String:
	return "%s/%s/%s" % [hint.verb, hint.state, hint.reason]


func _expected(row: Dictionary) -> ActionHint:
	var state: ActionHint.State = STATES[row["state"]]
	var verb: StringName = StringName(row["verb"])
	if state == ActionHint.State.OK:
		return ActionHint.ok(verb)
	if state == ActionHint.State.BLOCKED:
		return ActionHint.blocked(verb, StringName(row["reason"]))
	return ActionHint.none()


## Pulsa `E` con el teclado y devuelve lo que se observó: {count, args, cues, changed, pressed}.
func _press() -> Dictionary:
	var before: int = get_signal_emit_count(EventBus, "interaction_resolved")
	var world: String = _snapshot()
	_listen_to_cues()
	_cues.clear()
	await (_walker as Object).call("tap_interact")
	var count: int = get_signal_emit_count(EventBus, "interaction_resolved") - before
	var args: Array = []
	if count >= 1:
		args = get_signal_parameters(EventBus, "interaction_resolved", before)
	return {
		"count": count, "args": args, "cues": _cues.duplicate(), "changed": _snapshot() != world
	}


## Escucha las cues de todos los `FeedbackPlayer` del nivel (jugador, estaciones, cajas, puestos).
func _listen_to_cues() -> void:
	for node: Node in _level.find_children("*", "FeedbackPlayer", true, false):
		if _listening.has(node.get_instance_id()):
			continue
		_listening[node.get_instance_id()] = true
		(node as FeedbackPlayer).played.connect(_on_cue)


func _on_cue(cue: StringName) -> void:
	_cues.append(cue)


# --- Un caso ------------------------------------------------------------------------------------


## Monta, mira y pulsa un caso. Devuelve las discrepancias («id@lugar: qué»), vacío si cumple.
func _check_case(case_id: String) -> Array[String]:
	var found: Array[String] = []
	var id: String = case_id.get_slice("@", 0)
	var place: String = case_id.get_slice("@", 1)
	assert_true(_rows.has(id), "fila %s en el CSV" % id)
	if not _rows.has(id):
		return ["%s: no está en el CSV" % case_id]
	var row: Dictionary = _rows[id]
	await _fresh_level()
	var spot: Dictionary = _spot(place, row)
	var receiver: Node = _build(place, row, spot)
	var item: Node = _equip(String(row["hand"]))
	await _place_player(spot["stand"], spot["aim"])
	var expected: ActionHint = _expected(row)
	var floor_case: bool = place in ["floor", "wall"]
	var seen: bool = expected.is_target() and row["reachable"] == "1" and not floor_case
	var where: String = case_id
	var target: Node = _detector.get_target()
	var hint: ActionHint = _detector.get_hint()
	if seen:
		if target != receiver:
			return ["%s: objetivo %s, esperado %s" % [where, target, receiver]]
		if (
			hint.verb != expected.verb
			or hint.state != expected.state
			or hint.reason != expected.reason
		):
			found.append("%s: hint %s, esperado %s" % [where, _describe(hint), _describe(expected)])
	elif floor_case:
		if target != null:
			found.append("%s: en el suelo hay objetivo %s" % [where, target])
		if (
			hint.verb != expected.verb
			or hint.state != expected.state
			or hint.reason != expected.reason
		):
			found.append("%s: hint %s, esperado %s" % [where, _describe(hint), _describe(expected)])
	elif receiver != null:
		if target == receiver:
			found.append("%s: «—» es objetivo" % where)
		var outline: Highlightable = receiver.get_node_or_null(^"%Highlightable") as Highlightable
		if outline != null and outline.is_highlighted():
			found.append("%s: «—» tiene contorno" % where)
	var result: Dictionary = await _press()
	_ran += 1
	found.append_array(_judge(where, row, expected, seen or floor_case, item != null, result))
	return found


## Compara la respuesta con lo esperado. `has_target` = objetivo o suelo con el hint de `expected`.
func _judge(
	where: String,
	row: Dictionary,
	expected: ActionHint,
	has_target: bool,
	holding: bool,
	result: Dictionary
) -> Array[String]:
	var found: Array[String] = []
	var count: int = result["count"]
	var args: Array = result["args"]
	var cues: Array = result["cues"]
	if has_target and expected.state == ActionHint.State.OK:
		if count != 1:
			found.append("%s: OK dio %d respuestas" % [where, count])
		elif args != [1, expected.verb, int(ActionHint.State.OK), &""]:
			found.append("%s: respuesta %s" % [where, args])
		if not result["changed"]:
			found.append("%s: OK no cambió el mundo" % where)
		if &"rejected" in cues:
			found.append("%s: OK sonó «rejected»" % where)
		if cues.is_empty():
			found.append("%s: OK sin ningún cue" % where)
	elif has_target and expected.state == ActionHint.State.BLOCKED:
		if count != 1:
			found.append("%s: BLOQUEADO dio %d respuestas" % [where, count])
		elif args != [1, expected.verb, int(ActionHint.State.BLOCKED), expected.reason]:
			found.append("%s: respuesta %s" % [where, args])
		if result["changed"]:
			found.append("%s: BLOQUEADO cambió el mundo" % where)
		if cues != [&"rejected"]:
			found.append("%s: cues %s, esperado un solo «rejected»" % [where, cues])
	elif holding:
		# «—» con la mano llena: la pulsación es la del suelo (SOLTAR, con sitio o `busy`).
		if count != 1:
			found.append("%s: mano llena sin objetivo dio %d respuestas" % [where, count])
		elif args[1] != ActionVerb.DROP:
			found.append("%s: sin objetivo respondió %s, esperado drop" % [where, args[1]])
	else:
		if count != 0:
			found.append("%s: mano vacía y sin objetivo respondió %d veces" % [where, count])
		if result["changed"]:
			found.append("%s: mano vacía y sin objetivo cambió el mundo" % where)
	assert_true(row != null)
	return found


func _run(cases: Array[String]) -> void:
	var discrepancies: Array[String] = []
	for case_id: String in cases:
		discrepancies.append_array(await _check_case(case_id))
	assert_eq(_ran, cases.size(), "casos ejecutados")
	assert_eq(discrepancies, [] as Array[String], "pulsaciones mudas o incoherentes")


# --- Tests --------------------------------------------------------------------------------------


func test_cases_cover_at_least_40_combinations_with_the_study_cases() -> void:
	var all: Array[String] = []
	for group: Array[String] in [POT_CASES, SIMPLE_CASES, BOX_CASES, DISPENSER_CASES, BOWL_CASES]:
		all.append_array(group)
	assert_gte(all.size(), 40, "combinaciones mano × objetivo")
	assert_eq(all.size(), 58, "total declarado")
	# Del estudio de PUL-119: cortar crudo, 7.º corte, mismo aliño, caja a medias en dispensador y
	# cuenco, olla con quemado (y la caja errónea en la zona y los 7 cortes, en sus tests).
	for needed: String in [
		"B1-M1@box",
		"B3-M2@box",
		"D1-M8@sweet",
		"D2-M9@hot",
		"D1-M6@sweet",
		"D2-M6@hot",
		"E1s0-M6@bowl",
		"C3-M0@pot1",
	]:
		assert_true(needed in all, "caso del estudio %s" % needed)
	for case_id: String in all:
		assert_true(_rows.has(case_id.get_slice("@", 0)), "fila %s" % case_id)


func test_ac1_pots_on_level_01() -> void:
	await _run(POT_CASES)


func test_ac1_simple_stations_slots_bins_stand_and_floor_on_level_01() -> void:
	await _run(SIMPLE_CASES)


func test_ac1_loose_boxes_on_level_01() -> void:
	await _run(BOX_CASES)


func test_ac1_dispensers_on_level_01() -> void:
	await _run(DISPENSER_CASES)


func test_ac1_cachelos_bowl_on_level_01() -> void:
	await _run(BOWL_CASES)


## Seis cortes con la mano (cada uno da un `cut` OK) y el 7.º sobre la caja llena da un solo
## rechazo `full`; el pulpo no se toca.
func test_ac1_six_cuts_then_the_seventh_is_one_rejection() -> void:
	await _fresh_level()
	var box: Box = _new_box("M5")
	box.global_position = Vector3(LOOSE_AT.x, 0.0, LOOSE_AT.y)
	var octopus: Ingredient = _equip("M2") as Ingredient
	await _place_player(LOOSE_AT + Vector2(0.0, LOOSE_GAP), LOOSE_AT)
	assert_eq(_detector.get_target(), box, "de cara a la caja")
	for cut: int in 6:
		var result: Dictionary = await _press()
		assert_eq(result["count"], 1, "corte %d: una respuesta" % (cut + 1))
		assert_eq(
			result["args"],
			[1, ActionVerb.CUT, int(ActionHint.State.OK), &""] as Array,
			"corte %d" % (cut + 1)
		)
		assert_true(result["changed"], "corte %d cambia la caja" % (cut + 1))
		assert_false(&"rejected" in result["cues"], "corte %d no se rechaza" % (cut + 1))
	assert_true(box.is_full(), "6 cortes llenan la caja")
	var remaining: float = octopus.remaining
	var seventh: Dictionary = await _press()
	assert_eq(seventh["count"], 1, "7.º corte: una respuesta")
	assert_eq(
		seventh["args"],
		[1, ActionVerb.CUT, int(ActionHint.State.BLOCKED), ActionReason.FULL] as Array,
		"7.º corte rechazado con «full»"
	)
	assert_eq(seventh["cues"], [&"rejected"] as Array, "un solo rechazo")
	assert_false(seventh["changed"], "el 7.º corte no cambia nada")
	assert_almost_eq(octopus.remaining, remaining, 0.0001, "el pulpo no se gasta")


## Dos rechazos a ~0,1 s no se pierden ni se apilan: 2 respuestas y 2 cues.
func test_ac1_two_quick_rejections_give_two_responses() -> void:
	await _fresh_level()
	var box: Box = _new_box("M5")
	box.global_position = Vector3(LOOSE_AT.x, 0.0, LOOSE_AT.y)
	_equip("M1")
	await _place_player(LOOSE_AT + Vector2(0.0, LOOSE_GAP), LOOSE_AT)
	var before: int = get_signal_emit_count(EventBus, "interaction_resolved")
	_listen_to_cues()
	_cues.clear()
	await (_walker as Object).call("tap_interact")
	await (_walker as Object).call("tap_interact")
	assert_eq(get_signal_emit_count(EventBus, "interaction_resolved") - before, 2, "dos respuestas")
	assert_eq(_cues, [&"rejected", &"rejected"] as Array[StringName], "dos rechazos")


## Una caja que no encaja con la comanda del puesto, dentro de su zona: la zona sigue apagada,
## entrar no entrega ni penaliza, y pulsar `E` da una sola respuesta (la del suelo, SOLTAR)
## sin entregar.
func test_ac1_wrong_box_in_the_delivery_zone_is_not_silent_and_does_not_deliver() -> void:
	await _fresh_level()
	var config: RoundConfig = _level.get("round_config")
	RoundManager.round_state.advance(config.first_order_delay)
	var stand: OrderStand = _stations("OrderStand2") as OrderStand
	var box: Box = _equip("M6") as Box
	await (_walker as Object).call("walk_into_zone", stand)
	assert_false(stand.is_zone_lit(), "la zona sigue apagada con una caja a medias")
	assert_ne(_detector.get_target(), stand, "el puesto no es objetivo dentro de la zona")
	assert_signal_not_emitted(EventBus, "order_completed")
	assert_signal_not_emitted(EventBus, "delivery_rejected")
	assert_eq(_hold.get_held_item(), box, "la caja sigue en la mano tras entrar")
	var result: Dictionary = await _press()
	assert_eq(result["count"], 1, "una sola respuesta")
	assert_eq(result["args"][1], ActionVerb.DROP, "suelta al suelo")
	assert_signal_not_emitted(EventBus, "order_completed")
	assert_signal_not_emitted(EventBus, "delivery_rejected")
