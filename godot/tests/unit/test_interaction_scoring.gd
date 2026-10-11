# gdlint: disable=max-public-methods
extends GutTest
## PUL-014 AC1: InteractionScoring elige el mismo objetivo que InteractionDetector.cs.
##
## La distancia es 3D desde el jugador + 0,8 m de altura (como Unity); `_cand` la calcula
## desde la posición del suelo salvo que el caso fije una explícita.

const CONE: float = 30.0
const NEAR: float = 0.7
const BONUS: float = 1.0
const EYE_HEIGHT: float = 0.8

# Mirando a +x desde el origen.
const FWD: Vector2 = Vector2.RIGHT
# PUL-121: margen de la histéresis y dos puntos rectos al frente (dot = 1: puntuación `2 + 1/dist`).
const MARGIN: float = 0.2
const AHEAD_A: Vector2 = Vector2(1.0, 0.0)
const AHEAD_B: Vector2 = Vector2(2.0, 0.0)


func _cand(
	pos: Vector2,
	pickable: bool = false,
	interactable: bool = true,
	kitchen: bool = false,
	dist: float = -1.0
) -> InteractionScoring.Candidate:
	if dist < 0.0:
		dist = Vector3(pos.x, EYE_HEIGHT, pos.y).length()
	return InteractionScoring.Candidate.new(pos, dist, pickable, interactable, kitchen)


func _pick(cands: Array[InteractionScoring.Candidate], holding: bool = false) -> int:
	return InteractionScoring.pick_best(Vector2.ZERO, FWD, cands, holding, CONE, NEAR, BONUS)


func test_ac1_no_candidates_returns_minus_one() -> void:
	assert_eq(_pick([]), -1)


func test_ac1_front_beats_behind() -> void:
	var cands: Array[InteractionScoring.Candidate] = [
		_cand(Vector2(-1.0, 0.0)),
		_cand(Vector2(1.0, 0.0)),
	]
	assert_eq(_pick(cands), 1)


func test_ac1_only_behind_is_discarded() -> void:
	var cands: Array[InteractionScoring.Candidate] = [_cand(Vector2(-1.0, 0.0))]
	assert_eq(_pick(cands), -1)


func test_ac1_closer_beats_farther_same_direction() -> void:
	var cands: Array[InteractionScoring.Candidate] = [
		_cand(Vector2(2.0, 0.0)),
		_cand(Vector2(1.0, 0.0)),
	]
	assert_eq(_pick(cands), 1)


func test_ac1_outside_cone_but_within_min_distance_is_valid() -> void:
	# Lateral a 0,3 m del suelo: distancia 3D 0,854 > 0,7 -> en Unity se descarta.
	# Para quedar dentro hace falta distancia 3D <= 0,7.
	var cands: Array[InteractionScoring.Candidate] = [
		_cand(Vector2(0.0, 0.3), false, true, false, 0.6)
	]
	assert_eq(_pick(cands), 0)


func test_ac1_lateral_half_metre_on_ground_is_rejected_by_3d_distance() -> void:
	# Distancia 3D = sqrt(0,5² + 0,8²) = 0,943 > 0,7 y fuera del cono: Unity lo rechaza.
	var cands: Array[InteractionScoring.Candidate] = [_cand(Vector2(0.0, 0.5))]
	assert_almost_eq(cands[0].distance, 0.943, 0.001)
	assert_eq(_pick(cands), -1)


func test_ac1_min_distance_boundary_is_inclusive() -> void:
	# `dist > 0.7` descarta: exactamente 0,7 sigue valiendo; 0,7001 no.
	var lateral: Vector2 = Vector2(0.0, 0.5)
	assert_eq(
		_pick([_cand(lateral, false, true, false, 0.7)] as Array[InteractionScoring.Candidate]), 0
	)
	assert_eq(
		_pick([_cand(lateral, false, true, false, 0.7001)] as Array[InteractionScoring.Candidate]),
		-1
	)


func test_ac1_cone_boundary_just_inside_and_just_outside() -> void:
	var inside: Vector2 = Vector2.from_angle(deg_to_rad(29.99))
	var outside: Vector2 = Vector2.from_angle(deg_to_rad(30.01))
	assert_eq(
		_pick([_cand(inside, false, true, false, 2.0)] as Array[InteractionScoring.Candidate]), 0
	)
	assert_eq(
		_pick([_cand(outside, false, true, false, 2.0)] as Array[InteractionScoring.Candidate]), -1
	)


func test_ac1_cone_is_symmetric() -> void:
	var left: Vector2 = Vector2.from_angle(deg_to_rad(-29.99))
	assert_eq(
		_pick([_cand(left, false, true, false, 2.0)] as Array[InteractionScoring.Candidate]), 0
	)


func test_ac1_pickable_only_is_not_returned() -> void:
	# Unity :99 `bestPickable as IInteractable ?? bestInteractable`: un cogible que no es
	# interactuable no se devuelve.
	var cands: Array[InteractionScoring.Candidate] = [_cand(Vector2(1.0, 0.0), true, false)]
	assert_eq(_pick(cands, false), -1)


func test_ac1_pickable_only_falls_back_to_best_interactable() -> void:
	var cands: Array[InteractionScoring.Candidate] = [
		_cand(Vector2(0.5, 0.0), true, false),
		_cand(Vector2(1.5, 0.0)),
	]
	assert_eq(_pick(cands, false), 1)


func test_ac1_double_pickable_interactable_beats_better_scored_interactable() -> void:
	var cands: Array[InteractionScoring.Candidate] = [
		_cand(Vector2(0.5, 0.0)),
		_cand(Vector2(1.5, 0.0), true, true),
	]
	assert_eq(_pick(cands, false), 1)


func test_ac1_best_pickable_is_chosen_among_pickables_before_conversion() -> void:
	# El mejor cogible (por puntuación) es solo cogible: gana el bucket de cogibles y,
	# al no ser interactuable, se cae al mejor interactuable aunque otro cogible doble exista.
	var cands: Array[InteractionScoring.Candidate] = [
		_cand(Vector2(0.5, 0.0), true, false),
		_cand(Vector2(1.5, 0.0), true, true),
		_cand(Vector2(1.0, 0.0)),
	]
	assert_eq(_pick(cands, false), 2)


func test_ac1_tie_between_pickable_and_interactable_prefers_pickable() -> void:
	var cands: Array[InteractionScoring.Candidate] = [
		_cand(Vector2(1.0, 0.0)),
		_cand(Vector2(1.0, 0.0), true, true),
	]
	assert_eq(_pick(cands, false), 1)


func test_ac1_tie_between_equal_interactables_keeps_first() -> void:
	var cands: Array[InteractionScoring.Candidate] = [
		_cand(Vector2(1.0, 0.0)),
		_cand(Vector2(1.0, 0.0)),
	]
	assert_eq(_pick(cands), 0)


func test_ac1_full_hand_ignores_pickable_only_candidates() -> void:
	var cands: Array[InteractionScoring.Candidate] = [
		_cand(Vector2(0.5, 0.0), true, false),
		_cand(Vector2(1.5, 0.0)),
	]
	assert_eq(_pick(cands, true), 1)


func test_ac1_full_hand_only_pickable_returns_minus_one() -> void:
	var cands: Array[InteractionScoring.Candidate] = [_cand(Vector2(0.5, 0.0), true, false)]
	assert_eq(_pick(cands, true), -1)


func test_ac1_double_candidate_with_full_hand_competes_as_interactable() -> void:
	var cands: Array[InteractionScoring.Candidate] = [
		_cand(Vector2(0.5, 0.0)),
		_cand(Vector2(1.5, 0.0), true, true),
	]
	assert_eq(_pick(cands, true), 0)


func test_ac1_kitchen_bonus_applies_with_empty_hand() -> void:
	# Distancias 3D: 1,0 m -> 1,281 (2 + 0,781 = 2,781); 1,6 m -> 1,789 (2 + 0,559 + 1 = 3,559).
	var cands: Array[InteractionScoring.Candidate] = [
		_cand(Vector2(1.0, 0.0)),
		_cand(Vector2(1.6, 0.0), false, true, true),
	]
	assert_eq(_pick(cands, false), 1)


func test_ac1_kitchen_bonus_not_applied_with_full_hand() -> void:
	var cands: Array[InteractionScoring.Candidate] = [
		_cand(Vector2(1.0, 0.0)),
		_cand(Vector2(1.6, 0.0), false, true, true),
	]
	assert_eq(_pick(cands, true), 0)


func test_ac1_non_interactable_non_pickable_is_ignored() -> void:
	var cands: Array[InteractionScoring.Candidate] = [_cand(Vector2(1.0, 0.0), false, false)]
	assert_eq(_pick(cands), -1)


func test_ac1_candidate_on_top_of_player_uses_zero_direction() -> void:
	# Dirección nula -> dot 0 (fuera del cono): solo vale si la distancia 3D es <= 0,7.
	var near: Array[InteractionScoring.Candidate] = [_cand(Vector2.ZERO, false, true, false, 0.5)]
	assert_eq(_pick(near), 0)
	var at_eye_height: Array[InteractionScoring.Candidate] = [_cand(Vector2.ZERO)]
	assert_eq(_pick(at_eye_height), -1)


func test_ac1_score_formula() -> void:
	assert_almost_eq(InteractionScoring.score(1.0, 2.0), 2.5, 0.0001)
	assert_almost_eq(InteractionScoring.score(1.0, 0.0), 12.0, 0.0001)


# --- PUL-063: objetos guardados en un slot -------------------------------------------------------


func _stored(pos: Vector2) -> InteractionScoring.Candidate:
	var cand: InteractionScoring.Candidate = _cand(pos, true, true)
	cand.in_slot = true
	return cand


func test_pul063_candidate_defaults_to_not_in_slot() -> void:
	assert_false(_cand(Vector2(1.0, 0.0), true, true).in_slot)
	var stored: InteractionScoring.Candidate = InteractionScoring.Candidate.new(
		Vector2.ZERO, 1.0, true, true, false, true
	)
	assert_true(stored.in_slot)


func test_pul063_stored_item_loses_to_better_scored_interactable_with_empty_hand() -> void:
	# Mismo caso que el de prioridad de cogible, pero el cogible está en un slot.
	var cands: Array[InteractionScoring.Candidate] = [
		_cand(Vector2(0.5, 0.0)),
		_stored(Vector2(1.5, 0.0)),
	]
	assert_eq(_pick(cands, false), 0)


func test_pul063_stored_item_wins_when_better_scored_with_empty_hand() -> void:
	var cands: Array[InteractionScoring.Candidate] = [
		_cand(Vector2(1.5, 0.0)),
		_stored(Vector2(0.5, 0.0)),
	]
	assert_eq(_pick(cands, false), 1)


func test_pul063_loose_pickable_keeps_priority_over_stored_and_interactable() -> void:
	var cands: Array[InteractionScoring.Candidate] = [
		_cand(Vector2(0.5, 0.0)),
		_stored(Vector2(0.6, 0.0)),
		_cand(Vector2(1.8, 0.0), true, true),
	]
	assert_eq(_pick(cands, false), 2)


func test_pul063_stored_item_with_full_hand_is_unchanged() -> void:
	# Con la mano llena ya competía como interactuable: el campo no cambia nada.
	var cands: Array[InteractionScoring.Candidate] = [
		_cand(Vector2(0.5, 0.0)),
		_stored(Vector2(1.5, 0.0)),
	]
	assert_eq(_pick(cands, true), 0)
	cands[1].in_slot = false
	assert_eq(_pick(cands, true), 0)
	var swapped: Array[InteractionScoring.Candidate] = [
		_cand(Vector2(1.5, 0.0)),
		_stored(Vector2(0.5, 0.0)),
	]
	assert_eq(_pick(swapped, true), 1)


func test_pul063_kitchen_bonus_counts_against_stored_item() -> void:
	var cands: Array[InteractionScoring.Candidate] = [
		_stored(Vector2(1.0, 0.0)),
		_cand(Vector2(1.0, 0.0), false, true, true),
	]
	assert_eq(_pick(cands, false), 1)


# --- PUL-121 AC3: histéresis (D26.4, lenguaje-acciones AC9) -------------------------------------


## Candidato recto al frente con una distancia que da exactamente `target_score`.
func _scored(
	pos: Vector2, target_score: float, kitchen: bool = false
) -> InteractionScoring.Candidate:
	var dist: float = 1.0 / (target_score - 2.0)
	return _cand(pos, false, true, kitchen, dist)


func _pick_h(
	cands: Array[InteractionScoring.Candidate],
	current: int,
	margin: float = MARGIN,
	holding: bool = false
) -> int:
	return InteractionScoring.pick_best(
		Vector2.ZERO, FWD, cands, holding, CONE, NEAR, BONUS, current, margin
	)


func test_ac3_candidate_at_119_percent_does_not_replace_current() -> void:
	var cands: Array[InteractionScoring.Candidate] = [
		_scored(AHEAD_A, 3.0),
		_scored(AHEAD_B, 3.0 * 1.19),
	]
	assert_eq(_pick_h(cands, 0), 0, "sigue el actual")


func test_ac3_candidate_at_121_percent_replaces_current() -> void:
	var cands: Array[InteractionScoring.Candidate] = [
		_scored(AHEAD_A, 3.0),
		_scored(AHEAD_B, 3.0 * 1.21),
	]
	assert_eq(_pick_h(cands, 0), 1)


func test_ac3_current_can_be_any_index() -> void:
	var cands: Array[InteractionScoring.Candidate] = [
		_scored(AHEAD_B, 3.0 * 1.19),
		_scored(AHEAD_A, 3.0),
	]
	assert_eq(_pick_h(cands, 1), 1)
	assert_eq(_pick_h(cands, -1), 0, "sin actual, gana el mejor")


func test_ac3_invalid_current_changes_even_below_the_margin() -> void:
	# El actual salió del cono (a la espalda y lejos): el mejor lo sustituye aunque puntúe poco más.
	var behind: InteractionScoring.Candidate = _cand(Vector2(-1.0, 0.0), false, true, false, 1.0)
	var cands: Array[InteractionScoring.Candidate] = [behind, _scored(AHEAD_B, 2.4)]
	assert_eq(_pick_h(cands, 0), 1)


func test_ac3_current_that_is_not_interactable_is_invalid() -> void:
	var inert: InteractionScoring.Candidate = _cand(AHEAD_A, false, false, false, 1.0)
	var cands: Array[InteractionScoring.Candidate] = [inert, _scored(AHEAD_B, 2.5)]
	assert_eq(_pick_h(cands, 0), 1)


func test_ac3_current_index_out_of_range_is_ignored() -> void:
	var cands: Array[InteractionScoring.Candidate] = [_scored(AHEAD_A, 3.0)]
	assert_eq(_pick_h(cands, 5), 0)


func test_ac3_zero_margin_is_the_previous_behaviour() -> void:
	var cands: Array[InteractionScoring.Candidate] = [
		_scored(AHEAD_A, 3.0),
		_scored(AHEAD_B, 3.0 * 1.01),
	]
	assert_eq(_pick_h(cands, 0, 0.0), 1)
	assert_eq(_pick(cands), 1, "la firma antigua no cambia")
	var tie: Array[InteractionScoring.Candidate] = [_scored(AHEAD_A, 3.0), _scored(AHEAD_B, 3.0)]
	assert_eq(
		_pick_h(tie, 1, 0.0),
		InteractionScoring.pick_best(Vector2.ZERO, FWD, tie, false, CONE, NEAR, BONUS)
	)


func test_ac3_kitchen_bonus_counts_in_both_scores() -> void:
	# Actual de cocina: 3 + 1 de bonus = 4. El otro necesita más de 4 × 1,2 = 4,8.
	var stays: Array[InteractionScoring.Candidate] = [
		_scored(AHEAD_A, 3.0, true),
		_scored(AHEAD_B, 4.7),
	]
	assert_eq(_pick_h(stays, 0), 0)
	var changes: Array[InteractionScoring.Candidate] = [
		_scored(AHEAD_A, 3.0, true),
		_scored(AHEAD_B, 4.9),
	]
	assert_eq(_pick_h(changes, 0), 1)


func test_ac3_negative_score_uses_the_absolute_value() -> void:
	# Cerca y a la espalda (dentro de la distancia mínima): dot = -1, puntuación negativa.
	var behind: Vector2 = Vector2(-0.5, 0.0)
	var current: InteractionScoring.Candidate = _cand(behind, false, true, false, 0.6)
	assert_almost_eq(InteractionScoring.score(-1.0, 0.6), -0.3333, 0.001)
	# Umbral: -0,3333 + 0,2 × 0,3333 = -0,2667.
	var below: InteractionScoring.Candidate = _cand(behind, false, true, false, 1.0 / 1.70)
	var above: InteractionScoring.Candidate = _cand(behind, false, true, false, 1.0 / 1.80)
	assert_eq(_pick_h([current, below], 0), 0, "-0,30 no supera el umbral")
	assert_eq(_pick_h([current, above], 0), 1, "-0,20 sí")


func test_ac3_pickable_priority_beats_hysteresis_with_empty_hand() -> void:
	# Regla categórica de PUL-063: un cogible suelto gana aunque no supere el margen.
	var pickable: InteractionScoring.Candidate = _cand(AHEAD_B, true, true, false, 1.0 / 0.95)
	var cands: Array[InteractionScoring.Candidate] = [_scored(AHEAD_A, 3.0), pickable]
	assert_lt(InteractionScoring.score(1.0, 1.0 / 0.95), 3.0 * 1.2)
	assert_eq(_pick_h(cands, 0), 1)


func test_ac3_pickable_current_is_kept_against_a_slightly_better_interactable() -> void:
	var pickable: InteractionScoring.Candidate = _cand(AHEAD_A, true, true, false, 1.0)
	var cands: Array[InteractionScoring.Candidate] = [pickable, _scored(AHEAD_B, 3.5)]
	assert_eq(_pick_h(cands, 0), 0, "el cogible sigue siendo el mejor por prioridad")


func test_ac3_two_pickables_use_the_margin() -> void:
	var first: InteractionScoring.Candidate = _cand(AHEAD_A, true, true, false, 1.0)
	var near_tie: InteractionScoring.Candidate = _cand(AHEAD_B, true, true, false, 1.0 / 1.1)
	assert_eq(_pick_h([first, near_tie], 0), 0, "3,0 contra 3,1: sigue el actual")
	var clear_win: InteractionScoring.Candidate = _cand(AHEAD_B, true, true, false, 1.0 / 1.7)
	assert_eq(_pick_h([first, clear_win], 0), 1, "3,0 contra 3,7: cambia")


func test_ac3_holding_ignores_pickable_priority() -> void:
	var pickable: InteractionScoring.Candidate = _cand(AHEAD_B, true, true, false, 1.0 / 0.95)
	var cands: Array[InteractionScoring.Candidate] = [_scored(AHEAD_A, 3.0), pickable]
	assert_eq(_pick_h(cands, 0, MARGIN, true), 0)
