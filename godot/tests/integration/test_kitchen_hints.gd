extends GutTest
## PUL-125 AC1 (diseño AC2, ADR-003 §11.2): en las escenas reales de cocina y objetos (nevera y
## demás spawners, pulpo y cachelos sueltos, pasaplatos vacío, cubo, caja y olla) el hint publicado
## por `get_action_hint` coincide celda a celda con `tests/fixtures/action_matrix.csv` y con el
## efecto de `interact`: `OK` cambia el mundo, `BLOCKED` no lo cambia y `NONE` no es objetivo
## (`interact` devuelve `false`; con hint distinto de `NONE` devuelve `true`).
## `can_interact` es exactamente `get_action_hint(...).is_target()`.
## Quedan fuera los receptores de PUL-126 (dispensadores y cuenco) y el suelo (detector, PUL-121).

const FIXTURE: String = "res://tests/fixtures/action_matrix.csv"
const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const KITCHEN_SCENE: PackedScene = preload("res://entities/stations/kitchen.tscn")
const SLOT_SCENE: PackedScene = preload("res://entities/stations/slot.tscn")
const TRASH_SCENE: PackedScene = preload("res://entities/stations/trash_bin.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const CACHELOS_SCENE: PackedScene = preload("res://entities/items/cachelos.tscn")
const OCTOPUS: IngredientData = preload("res://data/ingredients/octopus.tres")
const SWEET: SeasoningData = preload("res://data/seasonings/sweet_dressing.tres")
const HOT: SeasoningData = preload("res://data/seasonings/hot_dressing.tres")
const STATES: Dictionary[String, ActionHint.State] = {
	"NONE": ActionHint.State.NONE,
	"OK": ActionHint.State.OK,
	"BLOCKED": ActionHint.State.BLOCKED,
}
const RECEIVERS: Array[String] = ["spawner", "loose_item", "pass_slot", "trash", "box", "pot"]
const STEP: float = 0.1

var _rows: Array[Dictionary] = []
var _level: Node3D
var _hold: HoldComponent
var _actor: InteractionComponent
var _kitchen: CookingStation


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
		_rows.append(row)


func before_each() -> void:
	_level = add_child_autofree(Node3D.new())
	var player: Player = PLAYER_SCENE.instantiate()
	_level.add_child(player)
	_hold = player.get_node("%HoldComponent")
	_hold.items_root = _level
	_actor = player.get_node("%InteractionComponent")
	_kitchen = null


func _params(row: Dictionary) -> Dictionary:
	var params: Dictionary = {}
	for pair: String in String(row["params"]).split(";", false):
		var parts: PackedStringArray = pair.split("=")
		params[parts[0]] = parts[1]
	return params


## Vacía el nivel y deja uno nuevo con el jugador, para que cada fila parta de cero.
func _fresh_level() -> void:
	_level.free()
	before_each()


## Pone en la mano lo que dice la columna `hand` (M0…M9 del diseño).
func _equip(hand: String) -> void:
	var item: Node = null
	match hand:
		"M1", "M2":
			var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
			_level.add_child(octopus)
			if hand == "M2":
				octopus.set_cooked()
			item = octopus
		"M3", "M4":
			var cachelos: Ingredient = CACHELOS_SCENE.instantiate()
			_level.add_child(cachelos)
			if hand == "M4":
				cachelos.set_cooked()
			item = cachelos
		"M5", "M6", "M7", "M8", "M9":
			var box: Box = BOX_SCENE.instantiate()
			_level.add_child(box)
			if hand == "M6":
				box.fill = 0.5
			elif hand != "M5":
				box.fill = 1.0
			if hand == "M8":
				box.apply_seasoning(SWEET)
			elif hand == "M9":
				box.apply_seasoning(HOT)
			item = box
	if item != null:
		assert_true(_hold.pick_up(item), "la mano coge %s" % hand)


## Fotografía del mundo que puede cambiar con una pulsación.
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
			parts.append(
				"b%d:%.3f:%s" % [box.get_instance_id(), box.fill, box.get_parent().get_path()]
			)
		elif node is Slot:
			var stored: Node3D = (node as Slot).get_item()
			parts.append(
				"s%d:%d" % [node.get_instance_id(), stored.get_instance_id() if stored else 0]
			)
	if _kitchen != null:
		parts.append("olla=%d:%s" % [_kitchen._free_places(), _kitchen.has_burnt()])
	return ";".join(parts)


func _advance(seconds: float) -> void:
	simulate(_kitchen, roundi(seconds / STEP), STEP)


func _put_raw_in_pot() -> void:
	var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
	_level.add_child(octopus)
	assert_true(_hold.pick_up(octopus))
	assert_true(_kitchen.interact(_actor))


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


## Monta el receptor de `row` con su estado y lo devuelve.
func _build_receiver(row: Dictionary) -> Node:
	var params: Dictionary = _params(row)
	var node: Node = null
	match String(row["receiver"]):
		"spawner":
			var spawner: ItemSpawner = ItemSpawner.new()
			spawner.scene = OCTOPUS_SCENE
			node = spawner
		"loose_item":
			node = OCTOPUS_SCENE.instantiate()
		"pass_slot":
			node = SLOT_SCENE.instantiate()
		"trash":
			node = TRASH_SCENE.instantiate()
		"box":
			var box: Box = BOX_SCENE.instantiate()
			box.fill = float(params["fill"])
			node = box
		"pot":
			var free: int = int(params["free"])
			var burnt: int = int(params["burnt"])
			var ready: int = int(params["ready"])
			# Plazas ocupadas que no están listas ni quemadas: cociendo.
			_build_pot(ready, burnt, 2 - free - burnt - ready)
			node = _kitchen
	if node != null and node.get_parent() == null:
		_level.add_child(node)
	return node


## Compara una fila: hint, `can_interact` y efecto de `interact`. Devuelve las discrepancias.
func _check_row(row: Dictionary) -> Array[String]:
	var found: Array[String] = []
	var where: String = String(row["id"])
	_fresh_level()
	var receiver: Node = _build_receiver(row)
	_equip(String(row["hand"]))
	var hint: ActionHint = receiver.call(&"get_action_hint", _actor)
	var expected_state: ActionHint.State = STATES[String(row["state"])]
	if hint.state != expected_state:
		found.append("%s: estado %d, esperado %s" % [where, hint.state, row["state"]])
		return found
	if hint.verb != StringName(row["verb"]) or hint.reason != StringName(row["reason"]):
		found.append(
			(
				"%s: %s/%s, esperado %s/%s"
				% [where, hint.verb, hint.reason, row["verb"], row["reason"]]
			)
		)
	if String(row["progress"]) != "" and not is_equal_approx(hint.progress, float(row["progress"])):
		found.append("%s: progreso %f" % [where, hint.progress])
	if bool(receiver.call(&"can_interact", _actor)) != hint.is_target():
		found.append("%s: can_interact no coincide con el hint" % where)
	var before: String = _snapshot()
	var consumed: bool = bool(receiver.call(&"interact", _actor))
	var changed: bool = _snapshot() != before
	if consumed != hint.is_target():
		found.append("%s: interact=%s con hint %d" % [where, consumed, hint.state])
	if (hint.state == ActionHint.State.OK) != changed:
		found.append(
			(
				"%s: el mundo %s con hint %d"
				% [where, "cambió" if changed else "no cambió", hint.state]
			)
		)
	return found


func _check_receiver(receiver: String) -> void:
	var discrepancies: Array[String] = []
	var checked: int = 0
	for row: Dictionary in _rows:
		if row["receiver"] != receiver or row["reachable"] != "1":
			continue
		checked += 1
		discrepancies.append_array(_check_row(row))
	assert_gt(checked, 0, "filas de %s" % receiver)
	assert_eq(discrepancies, [] as Array[String], receiver)


func test_ac1_fixture_has_rows_for_every_receiver_of_this_ticket() -> void:
	for receiver: String in RECEIVERS:
		var count: int = 0
		for row: Dictionary in _rows:
			if row["receiver"] == receiver:
				count += 1
		assert_gt(count, 0, receiver)


func test_ac1_spawners_a1_a3() -> void:
	_check_receiver("spawner")


func test_ac1_loose_items_a4() -> void:
	_check_receiver("loose_item")


func test_ac1_empty_pass_slot_a5() -> void:
	_check_receiver("pass_slot")


func test_ac1_trash_a6() -> void:
	_check_receiver("trash")


func test_ac1_box_b1_b3() -> void:
	_check_receiver("box")


func test_ac1_pot_c1_c5() -> void:
	_check_receiver("pot")


# --- Variantes que la matriz no cubre -----------------------------------------------------------


func test_ac1_slot_with_item_and_empty_hand_gives_it_back() -> void:
	var slot: Slot = SLOT_SCENE.instantiate()
	_level.add_child(slot)
	var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
	_level.add_child(octopus)
	assert_true(_hold.pick_up(octopus))
	assert_true(slot.interact(_actor))
	assert_true(slot.has_item())
	var hint: ActionHint = slot.get_action_hint(_actor)
	assert_eq(hint.verb, ActionVerb.PICK_UP)
	assert_eq(hint.state, ActionHint.State.OK)
	assert_true(slot.interact(_actor))
	assert_eq(_hold.get_held_item(), octopus)


func test_ac1_slot_with_item_and_full_hand_is_not_a_target() -> void:
	var slot: Slot = SLOT_SCENE.instantiate()
	_level.add_child(slot)
	var stored: Ingredient = OCTOPUS_SCENE.instantiate()
	_level.add_child(stored)
	assert_true(_hold.pick_up(stored))
	assert_true(slot.interact(_actor))
	_equip("M1")
	assert_eq(slot.get_action_hint(_actor).state, ActionHint.State.NONE)
	assert_false(slot.can_interact(_actor))
	assert_false(slot.interact(_actor))
	assert_true(slot.has_item(), "no cambia")


func test_ac1_tray_rejects_what_is_not_a_box_without_being_a_target() -> void:
	var slot: Slot = SLOT_SCENE.instantiate()
	slot.accepted_group = &"box"
	_level.add_child(slot)
	_equip("M1")
	assert_eq(slot.get_action_hint(_actor).state, ActionHint.State.NONE)
	assert_false(slot.interact(_actor))
	_hold.drop().queue_free()
	_equip("M5")
	assert_eq(slot.get_action_hint(_actor).verb, ActionVerb.DROP)
	assert_true(slot.interact(_actor))
	assert_true(slot.has_item())


func test_ac1_without_actor_every_receiver_is_none() -> void:
	var box: Box = BOX_SCENE.instantiate()
	var loose: Ingredient = OCTOPUS_SCENE.instantiate()
	var bin: TrashBin = TRASH_SCENE.instantiate()
	var slot: Slot = SLOT_SCENE.instantiate()
	var spawner: ItemSpawner = ItemSpawner.new()
	spawner.scene = OCTOPUS_SCENE
	for node: Node in [box, loose, bin, slot, spawner]:
		_level.add_child(node)
		assert_eq(node.call(&"get_action_hint", null).state, ActionHint.State.NONE, str(node))
	_kitchen = KITCHEN_SCENE.instantiate()
	_level.add_child(_kitchen)
	assert_eq(_kitchen.get_action_hint(null).state, ActionHint.State.NONE)


func test_ac1_box_held_by_someone_is_not_a_target() -> void:
	var box: Box = BOX_SCENE.instantiate()
	_level.add_child(box)
	assert_true(_hold.pick_up(box))
	assert_eq(box.get_action_hint(_actor).state, ActionHint.State.NONE)
	assert_false(box.can_interact(_actor))


func test_ac1_pot_does_not_take_what_it_cannot_cook() -> void:
	_build_pot(0, 0, 0)
	var data: IngredientData = OCTOPUS.duplicate()
	data.is_cookable = false
	var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
	octopus.data = data
	_level.add_child(octopus)
	assert_true(_hold.pick_up(octopus))
	assert_eq(_kitchen.get_action_hint(_actor).state, ActionHint.State.NONE)
	assert_false(_kitchen.interact(_actor))
