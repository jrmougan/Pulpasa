extends GutTest
## PUL-131 AC1, la puerta de D26 (diseño AC1, AC2, AC11 y AC20; ADR-003 §11.6): cada fila de
## `tests/fixtures/action_matrix.csv` se monta con las escenas reales (olla, estaciones, cajas,
## cubo, pasaplatos, puesto) y un jugador real con su detector real. Por fila se comprueba:
## - lo que se ve: objetivo, verbo, estado, motivo, «sustituye» y progreso publicados por el
##   detector, y el contorno del objetivo (ámbar si está bloqueado);
## - lo que pasa al pulsar: `OK` cambia el mundo y da exactamente 1 `interaction_resolved` de
##   éxito;
##   `BLOCKED` no cambia nada, da 1 `interaction_resolved` de rechazo y suena 1 `rejected` en el
##   jugador; `—` no es objetivo, no se resalta y no responde (con la mano llena, la pulsación es
##   la del suelo: SOLTAR);
## - el suelo (filas A8–A9): `OK:drop` con sitio y `B:busy` contra una pared;
## - el puesto (A7) y la zona de entrega (F): ni objetivo ni resaltado, y la zona entrega sola.
## Las columnas son las de `test_action_rules.gd`. Las cuentas son exactas y una fila mal formada
## falla.

const FIXTURE: String = "res://tests/fixtures/action_matrix.csv"
const COLUMNS: Array[String] = [
	"id",
	"receiver",
	"params",
	"hand",
	"reachable",
	"verb",
	"state",
	"reason",
	"replaces",
	"progress"
]
const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const KITCHEN_SCENE: PackedScene = preload("res://entities/stations/kitchen.tscn")
const SLOT_SCENE: PackedScene = preload("res://entities/stations/slot.tscn")
const TRASH_SCENE: PackedScene = preload("res://entities/stations/trash_bin.tscn")
const STATION_SCENE: PackedScene = preload("res://entities/stations/seasoning_station.tscn")
const STAND_SCENE: PackedScene = preload("res://entities/stations/order_stand.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const CACHELOS_SCENE: PackedScene = preload("res://entities/items/cachelos.tscn")
const SPAWNER_SCENES: Dictionary[String, PackedScene] = {
	"A1": preload("res://entities/stations/octopus_storage.tscn"),
	"A2": preload("res://entities/stations/cachelos_storage.tscn"),
	"A3": preload("res://entities/stations/box_shelf.tscn"),
}
const EventBusScript: GDScript = preload("res://autoload/event_bus.gd")
const OrderServiceScript: GDScript = preload("res://autoload/order_service.gd")
const BOX_DATA: BoxData = preload("res://data/boxes/box.tres")
const OCTOPUS: IngredientData = preload("res://data/ingredients/octopus.tres")
const A_FEIRA: OrderData = preload("res://data/orders/a_feira.tres")
const SWEET: SeasoningData = preload("res://data/seasonings/sweet_dressing.tres")
const HOT: SeasoningData = preload("res://data/seasonings/hot_dressing.tres")
const CACHELOS: SeasoningData = preload("res://data/seasonings/cachelos.tres")
const STATES: Dictionary[String, ActionHint.State] = {
	"NONE": ActionHint.State.NONE,
	"OK": ActionHint.State.OK,
	"BLOCKED": ActionHint.State.BLOCKED,
}
const HANDS: Array[String] = ["M0", "M1", "M2", "M3", "M4", "M5", "M6", "M7", "M8", "M9"]
## Filas del fixture por receptor (A1–A9, B, C, D, E y F del diseño). Suman 353.
const EXPECTED_ROWS: Dictionary[String, int] = {
	"spawner": 30,
	"loose_item": 10,
	"pass_slot": 10,
	"trash": 10,
	"order_stand": 10,
	"floor": 20,
	"box": 30,
	"pot": 60,
	"dispenser_season_sweet": 20,
	"dispenser_season_hot": 20,
	"bowl": 130,
	"delivery_zone": 3,
}
const TOTAL_ROWS: int = 353
## Ticks de física para que el detector vea el cambio (el área solapa un tick después).
const SETTLE_TICKS: int = 4
## Ticks que tarda el puesto en encender la zona (0,1 s a 60 Hz).
const LIGHT_TICKS: int = 8
const STEP: float = 0.1
## Distancia del jugador al receptor (m) y a los lados de la estación de condimentos.
const APPROACH: float = 1.2
const PASS_Z: float = -1.2
const OPERATOR_Z: float = 1.2
const SLOT_ID: int = 2

var _rows: Array[Dictionary] = []
var _malformed: Array[String] = []
var _level: Node3D
var _player: Player
var _hold: HoldComponent
var _actor: InteractionComponent
var _detector: InteractionDetector
var _kitchen: CookingStation
var _station: SeasoningStation
var _cues: Array[StringName] = []
var _use_octopus: bool = true
var _stand_bus: Node
var _stand_service: Node
## Entregas y rechazos que ha emitido el bus propio del puesto de la fila.
var _stand_completed: int = 0
var _stand_rejected: int = 0


func before_all() -> void:
	var file: FileAccess = FileAccess.open(FIXTURE, FileAccess.READ)
	assert_not_null(file, "no abre %s" % FIXTURE)
	if file == null:
		return
	var header: PackedStringArray = file.get_csv_line()
	assert_eq(Array(header), COLUMNS as Array, "cabecera del fixture")
	while not file.eof_reached():
		var cells: PackedStringArray = file.get_csv_line()
		if cells.size() == 1 and cells[0].is_empty():
			continue
		if cells.size() != header.size():
			_malformed.append(",".join(cells))
			continue
		var row: Dictionary = {}
		for i: int in header.size():
			row[header[i]] = cells[i]
		var problem: String = _validate(row)
		if problem != "":
			_malformed.append("%s: %s" % [row["id"], problem])
			continue
		_rows.append(row)


func before_each() -> void:
	watch_signals(EventBus)
	_fresh_level()


func after_each() -> void:
	if is_instance_valid(_level):
		_level.free()


## Motivo por el que una fila está mal formada, o `""`.
func _validate(row: Dictionary) -> String:
	if not EXPECTED_ROWS.has(row["receiver"]):
		return "receptor desconocido «%s»" % row["receiver"]
	if not STATES.has(row["state"]):
		return "estado desconocido «%s»" % row["state"]
	if not String(row["hand"]).trim_suffix("+C") in HANDS:
		return "mano desconocida «%s»" % row["hand"]
	if not row["reachable"] in ["0", "1"]:
		return "reachable debe ser 0 o 1"
	if row["replaces"] != "" and row["replaces"] != "1":
		return "replaces debe ser vacío o 1"
	return _validate_hint(row)


## Coherencia entre estado, verbo y motivo de una fila (invariantes de `ActionHint`).
func _validate_hint(row: Dictionary) -> String:
	var state: ActionHint.State = STATES[row["state"]]
	var verb: StringName = StringName(row["verb"])
	var reason: StringName = StringName(row["reason"])
	if state == ActionHint.State.NONE and (verb != &"" or reason != &""):
		return "NONE con verbo o motivo"
	if state == ActionHint.State.OK and (not ActionVerb.is_valid(verb) or reason != &""):
		return "OK con verbo inválido o con motivo"
	if state == ActionHint.State.BLOCKED:
		if not ActionVerb.is_valid(verb) or not ActionReason.is_valid(reason):
			return "BLOCKED con verbo o motivo inválidos"
	return ""


# --- Montaje ------------------------------------------------------------------------------------


## Nivel nuevo con un jugador real, para que cada fila parta de cero.
func _fresh_level() -> void:
	if is_instance_valid(_level):
		_level.free()
	_level = Node3D.new()
	add_child(_level)
	_player = PLAYER_SCENE.instantiate()
	_level.add_child(_player)
	_hold = _player.get_node("%HoldComponent")
	_hold.items_root = _level
	_actor = _player.get_node("%InteractionComponent")
	_detector = _player.get_node("%InteractionDetector")
	_kitchen = null
	_station = null
	_cues = []
	var feedback: FeedbackPlayer = _player.get_node("%Feedback")
	var cues: Array[StringName] = _cues
	feedback.played.connect(func(cue: StringName) -> void: cues.append(cue))


func _params(row: Dictionary) -> Dictionary:
	var params: Dictionary = {}
	for pair: String in String(row["params"]).split(";", false):
		var parts: PackedStringArray = pair.split("=")
		params[parts[0]] = parts[1]
	return params


func _put_raw_in_pot() -> void:
	var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
	_level.add_child(octopus)
	assert_true(_hold.pick_up(octopus))
	assert_true(_kitchen.interact(_actor))


func _advance(seconds: float) -> void:
	simulate(_kitchen, roundi(seconds / STEP), STEP)


## Olla con `cooked` cocidos listos, `burnt` quemados y `cooking` cociendo (en ese orden de tiempo).
func _build_pot(cooked: int, burnt: int, cooking: int) -> void:
	_kitchen = KITCHEN_SCENE.instantiate()
	_level.add_child(_kitchen)
	for _i: int in burnt:
		_put_raw_in_pot()
	if burnt > 0:
		_advance(OCTOPUS.cook_time + OCTOPUS.burn_time)
	for _i: int in cooked:
		_put_raw_in_pot()
	if cooked > 0:
		_advance(OCTOPUS.cook_time)
	for _i: int in cooking:
		_put_raw_in_pot()


## Monta el receptor de `row` con su estado. `null` para el suelo (sin receptor).
func _build_receiver(row: Dictionary) -> Node:
	var params: Dictionary = _params(row)
	var kind: String = row["receiver"]
	var node: Node = null
	match kind:
		"spawner":
			node = SPAWNER_SCENES[String(row["id"]).get_slice("-", 0)].instantiate()
			_level.add_child(node)
			if not node is ItemSpawner:
				node = node.find_children("*", "ItemSpawner", true, false)[0]
		"loose_item":
			node = OCTOPUS_SCENE.instantiate() if _use_octopus else CACHELOS_SCENE.instantiate()
			_level.add_child(node)
		"pass_slot":
			node = SLOT_SCENE.instantiate()
			_level.add_child(node)
		"trash":
			node = TRASH_SCENE.instantiate()
			_level.add_child(node)
		"box":
			var box: Box = BOX_SCENE.instantiate()
			box.data = BOX_DATA
			box.fill = float(params["fill"])
			_level.add_child(box)
			node = box
		"pot":
			var free: int = int(params["free"])
			var burnt: int = int(params["burnt"])
			var ready: int = int(params["ready"])
			# Plazas ocupadas que no están listas ni quemadas: cociendo.
			_build_pot(ready, burnt, 2 - free - burnt - ready)
			node = _kitchen
		"dispenser_season_sweet", "dispenser_season_hot", "bowl":
			_station = STATION_SCENE.instantiate()
			_level.add_child(_station)
			if kind == "bowl":
				var bowl: CachelosBowl = _station.get_node("CachelosBowl")
				bowl.stock = int(params["stock"])
				node = bowl
			elif kind == "dispenser_season_sweet":
				node = _station.get_node("Dispensers/SweetDressing")
			else:
				node = _station.get_node("Dispensers/HotDressing")
		"order_stand":
			node = _new_stand()
	return node


## Puesto con bus y servicio propios (y un catálogo de una sola comanda), sin tocar los autoloads.
func _new_stand() -> OrderStand:
	_stand_bus = EventBusScript.new()
	_level.add_child(_stand_bus)
	_stand_service = OrderServiceScript.new()
	_stand_service.set_bus(_stand_bus)
	_level.add_child(_stand_service)
	var catalog: OrderCatalog = OrderCatalog.new()
	catalog.orders = [A_FEIRA] as Array[OrderData]
	catalog.max_active_orders = 4
	_stand_service.setup(catalog, null, RoundConfig.new())
	var stand: OrderStand = STAND_SCENE.instantiate()
	stand.slot_id = SLOT_ID
	stand.set_bus(_stand_bus)
	stand.set_service(_stand_service)
	_level.add_child(stand)
	_stand_completed = 0
	_stand_rejected = 0
	_stand_bus.order_completed.connect(
		func(_order: ActiveOrder, _points: int) -> void: _stand_completed += 1
	)
	_stand_bus.delivery_rejected.connect(
		func(_slot: int, _order: int, _penalty: int) -> void: _stand_rejected += 1
	)
	return stand


func _new_box(hand: String) -> Box:
	var box: Box = BOX_SCENE.instantiate()
	box.data = BOX_DATA
	_level.add_child(box)
	box.fill = {"M5": 0.0, "M6": 0.5}.get(hand.trim_suffix("+C"), 1.0)
	match hand.trim_suffix("+C"):
		"M8":
			box.apply_seasoning(SWEET)
		"M9":
			box.apply_seasoning(HOT)
	if hand.ends_with("+C"):
		box.apply_seasoning(CACHELOS)
	return box


## Pone en la mano lo que dice `hand` (M0…M9, `+C` = la caja ya lleva cachelos). Devuelve
## el objeto.
func _equip(hand: String) -> Node:
	var item: Node = null
	match hand.trim_suffix("+C"):
		"M0":
			return null
		"M1", "M2":
			item = OCTOPUS_SCENE.instantiate()
			_level.add_child(item)
		"M3", "M4":
			item = CACHELOS_SCENE.instantiate()
			_level.add_child(item)
		_:
			item = _new_box(hand)
	if hand in ["M2", "M4"]:
		(item as Ingredient).set_cooked()
	assert_true(_hold.pick_up(item), "la mano coge %s" % hand)
	return item


## Coloca al jugador mirando al receptor desde el lado de `row` y deja que el detector lo vea.
func _place_player(row: Dictionary, receiver: Node) -> void:
	var params: Dictionary = _params(row)
	var at: Vector3 = Vector3.ZERO if receiver == null else (receiver as Node3D).global_position
	var yaw: float = 0.0
	var offset: float = APPROACH
	if params.has("side"):
		offset = OPERATOR_Z if params["side"] == "operator" else PASS_Z
		yaw = 0.0 if params["side"] == "operator" else PI
	var spot: Vector3 = Vector3(at.x, 0.0, at.z + offset)
	if receiver == null:
		spot = Vector3(0.0, 0.0, 6.0)
	_player.global_position = spot
	_player.rotation = Vector3(0.0, yaw, 0.0)
	if row["receiver"] == "floor" and params["can_drop"] == "0":
		_wall_at(_hold.get_drop_position())
	await wait_physics_frames(SETTLE_TICKS)


## Pared de la capa `world` en `point` (el punto de soltar queda bloqueado).
func _wall_at(point: Vector3) -> void:
	var wall: StaticBody3D = StaticBody3D.new()
	wall.collision_layer = 1
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(1.0, 1.0, 1.0)
	shape.shape = box
	wall.add_child(shape)
	_level.add_child(wall)
	wall.global_position = point


# --- Lectura del mundo --------------------------------------------------------------------------


## Estado del receptor, sin la mano: lo que una pulsación sin efecto no puede cambiar.
func _receiver_state(receiver: Node) -> String:
	if receiver is Box:
		return (
			"caja %.3f %d"
			% [(receiver as Box).fill, (receiver as Box).get_contents().seasonings.size()]
		)
	if receiver is Ingredient:
		var item: Ingredient = receiver
		return "ingrediente %d %.3f %s" % [item.state, item.remaining, item.is_held]
	if receiver is Slot:
		return "slot %s" % (receiver as Slot).has_item()
	if receiver is CookingStation:
		var pot: CookingStation = receiver
		return "olla %d %s %s" % [pot._free_places(), pot.has_burnt(), pot.is_cooking()]
	if receiver is CachelosBowl:
		return "cuenco %d" % (receiver as CachelosBowl).stock
	return ""


## Fotografía del mundo que puede cambiar con una pulsación (incluida la mano).
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
	if _kitchen != null:
		parts.append("olla=%d:%s" % [_kitchen._free_places(), _kitchen.has_burnt()])
	return ";".join(parts)


## Estado de lo que lleva la mano (caja o ingrediente), para ver que una pulsación sin efecto
## no lo toca.
func _held_state() -> String:
	var held: Node = _hold.get_held_item()
	return _content_state(held) if held != null else ""


## Contenido de una caja o ingrediente (sin dónde está ni si lo lleva alguien).
func _content_state(node: Node) -> String:
	if node is Box:
		return "caja %.3f %s" % [(node as Box).fill, _seasoning_ids(node as Box)]
	if node is Ingredient:
		return "ingrediente %d %.3f" % [(node as Ingredient).state, (node as Ingredient).remaining]
	return ""


func _seasoning_ids(box: Box) -> String:
	var ids: Array[String] = []
	for seasoning: SeasoningData in box.get_contents().seasonings:
		ids.append(str(seasoning.get_instance_id()))
	return ",".join(ids)


func _describe(hint: ActionHint) -> String:
	return (
		"%s/%s/%s%s" % [hint.verb, hint.state, hint.reason, "/sustituye" if hint.replaces else ""]
	)


func _expected_hint(row: Dictionary) -> ActionHint:
	var state: ActionHint.State = STATES[row["state"]]
	var verb: StringName = StringName(row["verb"])
	var hint: ActionHint = ActionHint.none()
	if state == ActionHint.State.OK:
		hint = ActionHint.ok(verb)
	elif state == ActionHint.State.BLOCKED:
		hint = ActionHint.blocked(verb, StringName(row["reason"]))
	hint.replaces = row["replaces"] == "1"
	return hint


## Cuántas veces ha sonado `cue` en el jugador.
func _cue_count(cue: StringName) -> int:
	return _cues.count(cue)


func _highlight_of(node: Node) -> Highlightable:
	return node.get_node_or_null(^"%Highlightable") as Highlightable


# --- Una fila -----------------------------------------------------------------------------------


## Monta, mira y pulsa una fila. Devuelve las discrepancias («id: qué»), vacío si coincide.
func _check_row(row: Dictionary) -> Array[String]:
	var found: Array[String] = []
	var where: String = String(row["id"])
	_fresh_level()
	var kind: String = row["receiver"]
	var receiver: Node = _build_receiver(row)
	var item: Node = _equip(String(row["hand"]))
	await _place_player(row, receiver)
	var expected: ActionHint = _expected_hint(row)
	var floor_row: bool = kind == "floor"
	var stand_row: bool = kind == "order_stand"
	var seen: bool = expected.is_target() and row["reachable"] == "1" and not floor_row
	# --- Lo que se ve ---
	var target: Node = _detector.get_target()
	var hint: ActionHint = _detector.get_hint()
	if seen:
		if target != receiver:
			found.append("%s: objetivo %s, esperado %s" % [where, target, receiver])
			return found
		if not hint.same_as(expected):
			found.append("%s: hint %s, esperado %s" % [where, _describe(hint), _describe(expected)])
		if row["progress"] != "" and not is_equal_approx(hint.progress, float(row["progress"])):
			found.append("%s: progreso %f" % [where, hint.progress])
		var highlight: Highlightable = _highlight_of(receiver)
		if highlight != null:
			if not highlight.is_highlighted():
				found.append("%s: el objetivo no se resalta" % where)
			if highlight.is_blocked() != (expected.state == ActionHint.State.BLOCKED):
				found.append("%s: contorno bloqueado=%s" % [where, highlight.is_blocked()])
	elif floor_row:
		if target != null:
			found.append("%s: en el suelo hay objetivo %s" % [where, target])
		if not hint.same_as(expected):
			found.append("%s: hint %s, esperado %s" % [where, _describe(hint), _describe(expected)])
	else:
		if target == receiver:
			found.append("%s: «—» es objetivo" % where)
		var dim: Highlightable = _highlight_of(receiver) if receiver != null else null
		if dim != null and dim.is_highlighted():
			found.append("%s: «—» tiene contorno" % where)
		if stand_row and receiver.is_in_group(InteractionContract.GROUP_INTERACTABLE):
			found.append("%s: el puesto es interactable" % where)
	# --- Lo que pasa al pulsar ---
	var resolved_before: int = get_signal_emit_count(EventBus, "interaction_resolved")
	var world_before: String = _snapshot()
	var receiver_before: String = _receiver_state(receiver) if receiver != null else ""
	var held_before: String = _held_state()
	_cues.clear()
	var pressed: bool = _actor.interact_pressed()
	var resolved: int = get_signal_emit_count(EventBus, "interaction_resolved")
	resolved -= resolved_before
	var args: Array = []
	if resolved >= 1:
		args = get_signal_parameters(EventBus, "interaction_resolved", resolved_before)
	var changed: bool = _snapshot() != world_before
	if seen or floor_row:
		found.append_array(_check_press(row, expected, pressed, resolved, args, changed))
	else:
		found.append_array(
			_check_idle_press(row, receiver, item, pressed, resolved, args, receiver_before)
		)
		if item != null and held_before != _content_state(item):
			found.append("%s: la pulsación tocó lo que lleva la mano" % where)
	return found


## Pulsación sobre un objetivo (o el suelo) con hint `OK` o `BLOCKED`, o sin nada con la mano vacía.
func _check_press(
	row: Dictionary, expected: ActionHint, pressed: bool, resolved: int, args: Array, changed: bool
) -> Array[String]:
	var found: Array[String] = []
	var where: String = String(row["id"])
	match expected.state:
		ActionHint.State.NONE:
			if pressed or resolved != 0 or changed:
				found.append("%s: «—» respondió (%s, %d, %s)" % [where, pressed, resolved, changed])
		ActionHint.State.OK:
			if not pressed or resolved != 1:
				found.append("%s: OK dio %d respuestas (pulsó %s)" % [where, resolved, pressed])
			elif args != [1, expected.verb, int(ActionHint.State.OK), &""]:
				found.append("%s: respuesta %s" % [where, args])
			if not changed:
				found.append("%s: OK no cambió el mundo" % where)
			if _cue_count(&"rejected") != 0:
				found.append("%s: OK sonó «rejected»" % where)
		ActionHint.State.BLOCKED:
			if not pressed or resolved != 1:
				found.append(
					"%s: BLOCKED dio %d respuestas (pulsó %s)" % [where, resolved, pressed]
				)
			elif args != [1, expected.verb, int(ActionHint.State.BLOCKED), expected.reason]:
				found.append("%s: respuesta %s" % [where, args])
			if changed:
				found.append("%s: BLOCKED cambió el mundo" % where)
			if _cues != ([&"rejected"] as Array[StringName]):
				found.append("%s: cues %s, esperado un solo «rejected»" % [where, _cues])
	return found


## Pulsación con un receptor que no es objetivo (`—` o fuera de alcance): no lo toca; con la mano
## llena es la pulsación del suelo (SOLTAR, con sitio o `busy` contra el receptor o la pared).
func _check_idle_press(
	row: Dictionary,
	receiver: Node,
	item: Node,
	pressed: bool,
	resolved: int,
	args: Array,
	receiver_before: String
) -> Array[String]:
	var found: Array[String] = []
	var where: String = String(row["id"])
	if receiver != null and receiver_before != _receiver_state(receiver):
		found.append("%s: la pulsación cambió el receptor" % where)
	if row["receiver"] == "order_stand" or row["receiver"] == "delivery_zone":
		if _stand_completed != 0:
			found.append("%s: la pulsación entregó" % where)
		if _stand_rejected != 0:
			found.append("%s: la pulsación rechazó una entrega" % where)
	if item == null:
		if pressed or resolved != 0:
			found.append("%s: mano vacía y sin objetivo respondió" % where)
		return found
	if resolved != 1 or not pressed:
		found.append("%s: mano llena sin objetivo dio %d respuestas" % [where, resolved])
	elif args[1] != ActionVerb.DROP:
		found.append("%s: sin objetivo respondió %s, esperado drop" % [where, args[1]])
	return found


func _check_receivers(receivers: Array[String]) -> void:
	var discrepancies: Array[String] = []
	var checked: int = 0
	for row: Dictionary in _rows:
		if not row["receiver"] in receivers:
			continue
		checked += 1
		if row["receiver"] == "delivery_zone":
			discrepancies.append_array(await _check_zone_row(row))
			continue
		_use_octopus = true
		discrepancies.append_array(await _check_row(row))
		if row["receiver"] == "loose_item":
			# A4 se comprueba con pulpo y con cachelos sueltos (misma regla).
			_use_octopus = false
			discrepancies.append_array(await _check_row(row))
	var expected: int = 0
	for receiver: String in receivers:
		expected += EXPECTED_ROWS[receiver]
	assert_eq(checked, expected, "filas de %s" % ", ".join(receivers))
	assert_eq(discrepancies, [] as Array[String], ", ".join(receivers))


# --- Zona de entrega (F) ------------------------------------------------------------------------


func _order_for(slot_id: int) -> ActiveOrder:
	for order: ActiveOrder in _stand_service.get_active_orders():
		if order.slot_id == slot_id:
			return order
	return null


## Caja llena con lo que pide `order` en la mano: cortes reales y condimentos con la API de
## la estación.
func _matching_box(order: ActiveOrder, actor: InteractionComponent) -> Box:
	var box: Box = BOX_SCENE.instantiate()
	box.data = BOX_DATA
	_level.add_child(box)
	var guard: int = 0
	while not box.is_full() and guard < 200:
		var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
		_level.add_child(octopus)
		octopus.set_cooked()
		assert_true(_hold.pick_up(octopus))
		while octopus.is_inside_tree() and not box.is_full() and guard < 200:
			assert_true(box.interact(actor))
			guard += 1
		if is_instance_valid(octopus):
			_hold.drop()
			octopus.free()
	for seasoning: SeasoningData in order.data.seasonings:
		assert_eq(box.apply_seasoning(seasoning), SeasoningRules.Rejection.NONE)
	assert_true(_hold.pick_up(box))
	return box


## F1: la zona del puesto se enciende solo con la caja que coincide y entrega al entrar; una caja
## que no encaja (o la mano vacía) la deja apagada y entrar no entrega ni rechaza. Ni el puesto ni
## la zona son objetivo desde ningún sitio.
func _check_zone_row(row: Dictionary) -> Array[String]:
	var found: Array[String] = []
	var where: String = String(row["id"])
	_fresh_level()
	var stand: OrderStand = _new_stand()
	_stand_service.board.fill_slots([1, 2, 3, 4] as Array[int])
	var zone: Node3D = stand.get_node("%DeliveryZone")
	var matches: bool = _params(row)["match"] == "1"
	var hand: String = String(row["hand"])
	var held: Node = null
	if hand == "M0":
		pass
	elif matches:
		held = _matching_box(_order_for(SLOT_ID), _actor)
	else:
		held = _equip(hand)
	var should_deliver: bool = held != null and matches
	# Cerca (≤ 2 m) pero fuera de la zona.
	_player.global_position = zone.global_position + Vector3(0.0, 0.0, 1.5)
	await wait_physics_frames(LIGHT_TICKS)
	if stand.is_zone_lit() != should_deliver:
		found.append("%s: zona encendida=%s" % [where, stand.is_zone_lit()])
	if _detector.get_target() == stand:
		found.append("%s: el puesto es objetivo desde fuera de la zona" % where)
	if _stand_completed != 0:
		found.append("%s: entregó sin entrar" % where)
	# Entra en la zona.
	_player.global_position = zone.global_position
	await wait_physics_frames(SETTLE_TICKS)
	if _detector.get_target() == stand:
		found.append("%s: el puesto es objetivo dentro de la zona" % where)
	var delivered: int = _stand_completed
	if delivered != (1 if should_deliver else 0):
		found.append("%s: %d entregas al entrar" % [where, delivered])
	if _stand_rejected != 0:
		found.append("%s: la zona rechazó" % where)
	if held != null and not matches and _hold.get_held_item() != held:
		found.append("%s: la caja que no encaja salió de la mano" % where)
	if should_deliver and is_instance_valid(held) and not held.is_queued_for_deletion():
		found.append("%s: la caja entregada no se liberó" % where)
	return found


# --- Tests --------------------------------------------------------------------------------------


func test_fixture_is_well_formed_and_the_counts_are_exact() -> void:
	assert_eq(_malformed, [] as Array[String], "filas mal formadas")
	assert_gte(_rows.size(), 250, "al menos 250 filas")
	assert_eq(_rows.size(), TOTAL_ROWS, "filas del fixture")
	var ids: Dictionary = {}
	var per_receiver: Dictionary = {}
	for row: Dictionary in _rows:
		assert_false(ids.has(row["id"]), "id duplicado %s" % row["id"])
		ids[row["id"]] = true
		per_receiver[row["receiver"]] = int(per_receiver.get(row["receiver"], 0)) + 1
	for receiver: String in EXPECTED_ROWS:
		assert_eq(per_receiver.get(receiver, 0), EXPECTED_ROWS[receiver], receiver)
	var total: int = 0
	for receiver: String in EXPECTED_ROWS:
		total += EXPECTED_ROWS[receiver]
	assert_eq(total, TOTAL_ROWS)


func test_validator_rejects_malformed_rows() -> void:
	var good: Dictionary = {
		"id": "X",
		"receiver": "spawner",
		"params": "",
		"hand": "M0",
		"reachable": "1",
		"verb": "pick_up",
		"state": "OK",
		"reason": "",
		"replaces": "",
		"progress": "",
	}
	assert_eq(_validate(good), "")
	for change: Dictionary in [
		{"receiver": "nevera"},
		{"state": "OKAY"},
		{"hand": "M10"},
		{"reachable": "2"},
		{"verb": "volar"},
		{"reason": "full"},
		{"replaces": "2"},
		{"state": "NONE"},
		{"state": "BLOCKED", "reason": "fuera"},
	]:
		var bad: Dictionary = good.duplicate()
		bad.merge(change, true)
		assert_ne(_validate(bad), "", "debía fallar: %s" % change)


func test_ac1_spawners_a1_a3() -> void:
	await _check_receivers(["spawner"] as Array[String])


func test_ac1_loose_items_a4() -> void:
	await _check_receivers(["loose_item"] as Array[String])


func test_ac1_empty_pass_slot_a5() -> void:
	await _check_receivers(["pass_slot"] as Array[String])


func test_ac1_trash_a6() -> void:
	await _check_receivers(["trash"] as Array[String])


func test_ac1_stand_is_never_a_target_a7() -> void:
	await _check_receivers(["order_stand"] as Array[String])


func test_ac1_free_floor_and_blocked_floor_a8_a9() -> void:
	await _check_receivers(["floor"] as Array[String])


func test_ac1_box_b1_b3() -> void:
	await _check_receivers(["box"] as Array[String])


func test_ac1_pot_c1_c5() -> void:
	await _check_receivers(["pot"] as Array[String])


func test_ac1_dispensers_d() -> void:
	await _check_receivers(["dispenser_season_sweet", "dispenser_season_hot"] as Array[String])


func test_ac1_bowl_e() -> void:
	await _check_receivers(["bowl"] as Array[String])


func test_ac1_delivery_zone_f() -> void:
	await _check_receivers(["delivery_zone"] as Array[String])
