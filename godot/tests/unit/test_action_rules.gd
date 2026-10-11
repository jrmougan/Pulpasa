extends GutTest
## PUL-121 AC1: `ActionRules` reproduce la tabla A–F de `lenguaje-acciones.md` (ADR-003 §11.6).
## El fixture `tests/fixtures/action_matrix.csv` es la transcripción celda a celda del diseño
## (una fila por combinación mano × receptor × estado). Aquí se evalúan las reglas puras; la
## puerta de D26 con escenas reales es `test_action_matrix.gd` (ficha de montaje).
## Columnas: id, receiver, params (k=v;k=v), hand (M0…M9, `+C` = la caja ya lleva cachelos),
## reachable (0 = el receptor no es candidato: lo filtra `is_reachable_from`, no la regla),
## verb, state (NONE/OK/BLOCKED), reason, replaces (1) y progress.
## Fuera de la regla: A7 (el puesto no es `interactable`) y F (la zona no usa el hint).

const FIXTURE: String = "res://tests/fixtures/action_matrix.csv"
const MIN_ROWS: int = 250
const STATES: Dictionary[String, ActionHint.State] = {
	"NONE": ActionHint.State.NONE,
	"OK": ActionHint.State.OK,
	"BLOCKED": ActionHint.State.BLOCKED,
}
const HELD: Dictionary[String, ActionRules.Held] = {
	"M0": ActionRules.Held.NOTHING,
	"M1": ActionRules.Held.OCTOPUS_RAW,
	"M2": ActionRules.Held.OCTOPUS_COOKED,
	"M3": ActionRules.Held.CACHELOS_RAW,
	"M4": ActionRules.Held.CACHELOS_COOKED,
	"M5": ActionRules.Held.BOX_EMPTY,
	"M6": ActionRules.Held.BOX_PARTIAL,
	"M7": ActionRules.Held.BOX_FULL,
	"M8": ActionRules.Held.BOX_FULL,
	"M9": ActionRules.Held.BOX_FULL,
}
## Verbo de acción de cada receptor con estado BLOCKED.
const ACTION_VERB: Dictionary[String, String] = {
	"box": "cut",
	"pot": "cook",
	"bowl": "cachelos",
	"floor": "drop",
	"dispenser_season_sweet": "season_sweet",
	"dispenser_season_hot": "season_hot",
}
const STOCK_MAX: int = 4
const PORTIONS: int = 2

var _rows: Array[Dictionary] = []


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


func _params(row: Dictionary) -> Dictionary:
	var params: Dictionary = {}
	for pair: String in String(row["params"]).split(";", false):
		var parts: PackedStringArray = pair.split("=")
		params[parts[0]] = parts[1]
	return params


func _hand_of(row: Dictionary) -> String:
	return String(row["hand"]).trim_suffix("+C")


## Evalúa la regla del receptor de `row`; `null` si no hay regla (A7, F).
func _evaluate(row: Dictionary) -> ActionHint:
	var hand_id: String = _hand_of(row)
	var held: ActionRules.Held = HELD[hand_id]
	var params: Dictionary = _params(row)
	var receiver: String = row["receiver"]
	var hint: ActionHint = null
	match receiver:
		"spawner":
			hint = ActionRules.for_spawner(held)
		"loose_item":
			hint = ActionRules.for_loose_item(held, params["can_hold"] == "1")
		"pass_slot":
			hint = ActionRules.for_pass_slot(held, params["accepts"] == "1")
		"trash":
			hint = ActionRules.for_trash(held, params["can_trash"] == "1")
		"floor":
			hint = ActionRules.for_floor(held, params["can_drop"] == "1")
		"box":
			hint = ActionRules.for_box(held, params["full"] == "1", float(params["fill"]))
		"pot":
			hint = ActionRules.for_pot(
				held, int(params["free"]), params["burnt"] == "1", params["ready"] == "1"
			)
		"dispenser_season_sweet", "dispenser_season_hot":
			var verb: StringName = StringName(receiver.trim_prefix("dispenser_"))
			var mine: String = "M8" if verb == ActionVerb.SEASON_SWEET else "M9"
			var other: String = "M9" if verb == ActionVerb.SEASON_SWEET else "M8"
			hint = ActionRules.for_dispenser(held, verb, hand_id == mine, hand_id == other)
		"bowl":
			var has_cachelos: bool = String(row["hand"]).ends_with("+C")
			hint = ActionRules.for_bowl(
				held, int(params["stock"]), STOCK_MAX, PORTIONS, has_cachelos
			)
	return hint


func test_ac1_fixture_has_at_least_250_unique_rows() -> void:
	assert_gte(_rows.size(), MIN_ROWS)
	var ids: Dictionary = {}
	for row: Dictionary in _rows:
		assert_false(ids.has(row["id"]), "id duplicado %s" % row["id"])
		ids[row["id"]] = true


func test_ac1_every_row_is_well_formed() -> void:
	for row: Dictionary in _rows:
		var where: String = "fila %s" % row["id"]
		assert_true(STATES.has(row["state"]), where)
		assert_true(HELD.has(_hand_of(row)), where)
		match row["state"]:
			"NONE":
				assert_eq(row["verb"], "", where)
				assert_eq(row["reason"], "", where)
			"OK":
				assert_true(ActionVerb.is_valid(StringName(row["verb"])), where)
				assert_eq(row["reason"], "", where)
			"BLOCKED":
				assert_true(ActionVerb.is_valid(StringName(row["verb"])), where)
				assert_true(ActionReason.is_valid(StringName(row["reason"])), where)


func test_ac1_rules_match_the_table_with_zero_discrepancies() -> void:
	var discrepancies: Array[String] = []
	var evaluated: int = 0
	for row: Dictionary in _rows:
		if row["reachable"] != "1":
			continue
		var hint: ActionHint = _evaluate(row)
		if hint == null:
			continue
		evaluated += 1
		var got: String = "%s/%s/%s/%s" % [hint.verb, hint.state, hint.reason, hint.replaces]
		var expected: String = (
			"%s/%s/%s/%s"
			% [row["verb"], STATES[row["state"]], row["reason"], row["replaces"] == "1"]
		)
		if got != expected:
			discrepancies.append("%s: esperado %s, obtenido %s" % [row["id"], expected, got])
		elif row["progress"] != "" and not is_equal_approx(hint.progress, float(row["progress"])):
			discrepancies.append("%s: progreso %f" % [row["id"], hint.progress])
	assert_eq(discrepancies, [] as Array[String])
	assert_gte(evaluated, MIN_ROWS, "se evalúan al menos 250 filas con regla")


func test_ac1_unreachable_and_ruleless_rows_are_all_none() -> void:
	# A7 (puesto), lado de pase de dispensadores y cuenco con caja: no son candidatos.
	var checked: int = 0
	for row: Dictionary in _rows:
		if row["reachable"] == "1" and _evaluate(row) != null:
			continue
		checked += 1
		assert_eq(row["state"], "NONE", "fila %s" % row["id"])
	assert_gt(checked, 0)


func test_ac1_block_rows_name_the_action_verb_of_their_receiver() -> void:
	for row: Dictionary in _rows:
		if row["state"] == "BLOCKED":
			assert_eq(row["verb"], ACTION_VERB[row["receiver"]], "fila %s" % row["id"])


func test_ac1_cut_progress_is_the_fill() -> void:
	var hint: ActionHint = ActionRules.for_box(ActionRules.Held.OCTOPUS_COOKED, false, 0.5)
	assert_eq(hint.progress, 0.5)


func test_ac1_fill_row_e1_already_applied_beats_empty() -> void:
	var hint: ActionHint = ActionRules.for_bowl(ActionRules.Held.BOX_FULL, 0, 4, 2, true)
	assert_eq(hint.reason, ActionReason.ALREADY_APPLIED)


func test_ac1_other_hand_is_only_dropped_or_trashed() -> void:
	var other: ActionRules.Held = ActionRules.Held.OTHER
	var none: ActionHint.State = ActionHint.State.NONE
	assert_eq(ActionRules.for_spawner(other).state, none)
	assert_eq(ActionRules.for_loose_item(other, true).state, none)
	assert_eq(ActionRules.for_box(other, false, 0.0).state, none)
	assert_eq(ActionRules.for_pot(other, 2, false, false).state, none)
	assert_eq(ActionRules.for_bowl(other, 2, 4, 2, false).state, none)
	assert_eq(ActionRules.for_dispenser(other, ActionVerb.SEASON_HOT, false, false).state, none)
	assert_eq(ActionRules.for_pass_slot(other, true).verb, ActionVerb.DROP)
	assert_eq(ActionRules.for_trash(other, true).verb, ActionVerb.TRASH)
	assert_eq(ActionRules.for_floor(other, true).verb, ActionVerb.DROP)


func test_ac1_loose_item_that_cannot_be_held_is_none() -> void:
	var hint: ActionHint = ActionRules.for_loose_item(ActionRules.Held.NOTHING, false)
	assert_eq(hint.state, ActionHint.State.NONE)
