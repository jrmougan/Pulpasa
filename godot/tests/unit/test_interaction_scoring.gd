extends GutTest
## PUL-014 AC1: InteractionScoring elige el mismo objetivo que InteractionDetector.cs.

const CONE: float = 30.0
const NEAR: float = 0.7
const BONUS: float = 1.0

# Mirando a +x desde el origen.
const FWD: Vector2 = Vector2.RIGHT


func _cand(
	pos: Vector2, pickable: bool = false, interactable: bool = true, kitchen: bool = false
) -> InteractionScoring.Candidate:
	return InteractionScoring.Candidate.new(pos, pickable, interactable, kitchen)


func _pick(cands: Array[InteractionScoring.Candidate], holding: bool = false) -> int:
	return InteractionScoring.pick_best(Vector2.ZERO, FWD, cands, holding, CONE, NEAR, BONUS)


func test_ac1_no_candidates_returns_minus_one() -> void:
	assert_eq(_pick([]), -1)


func test_ac1_front_beats_behind() -> void:
	# Detrás queda fuera del cono y a > 0,7 m: descartado.
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


func test_ac1_outside_cone_but_nearer_than_min_distance_is_valid() -> void:
	var cands: Array[InteractionScoring.Candidate] = [_cand(Vector2(0.0, 0.5))]
	assert_eq(_pick(cands), 0)


func test_ac1_outside_cone_beyond_min_distance_is_discarded() -> void:
	var cands: Array[InteractionScoring.Candidate] = [_cand(Vector2(0.0, 0.8))]
	assert_eq(_pick(cands), -1)


func test_ac1_cone_boundary_29_in_31_out() -> void:
	var inside: Vector2 = Vector2.from_angle(deg_to_rad(29.0)) * 1.0
	var outside: Vector2 = Vector2.from_angle(deg_to_rad(31.0)) * 1.0
	assert_eq(_pick([_cand(inside)] as Array[InteractionScoring.Candidate]), 0)
	assert_eq(_pick([_cand(outside)] as Array[InteractionScoring.Candidate]), -1)


func test_ac1_empty_hand_pickable_beats_better_scored_interactable() -> void:
	var cands: Array[InteractionScoring.Candidate] = [
		_cand(Vector2(0.5, 0.0)),
		_cand(Vector2(1.5, 0.0), true, false),
	]
	assert_eq(_pick(cands, false), 1)


func test_ac1_full_hand_ignores_pickable_only_candidates() -> void:
	var cands: Array[InteractionScoring.Candidate] = [
		_cand(Vector2(0.5, 0.0), true, false),
		_cand(Vector2(1.5, 0.0)),
	]
	assert_eq(_pick(cands, true), 1)


func test_ac1_full_hand_only_pickable_returns_minus_one() -> void:
	var cands: Array[InteractionScoring.Candidate] = [_cand(Vector2(0.5, 0.0), true, false)]
	assert_eq(_pick(cands, true), -1)


func test_ac1_pickable_that_is_also_interactable_counts_as_pickable_with_empty_hand() -> void:
	var cands: Array[InteractionScoring.Candidate] = [
		_cand(Vector2(0.5, 0.0)),
		_cand(Vector2(1.5, 0.0), true, true),
	]
	assert_eq(_pick(cands, false), 1)
	# Con la mano llena cae a la rama de interactuables, y gana el más cercano.
	assert_eq(_pick(cands, true), 0)


func test_ac1_kitchen_bonus_applies_with_empty_hand() -> void:
	# A 1,0 m: 2 + 1 = 3; a 1,6 m: 2 + 0,625 = 2,625 (+1 cocina = 3,625).
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


func test_ac1_candidate_on_top_of_player_is_valid() -> void:
	var cands: Array[InteractionScoring.Candidate] = [_cand(Vector2.ZERO)]
	assert_eq(_pick(cands), 0)


func test_ac1_non_interactable_non_pickable_is_ignored() -> void:
	var cands: Array[InteractionScoring.Candidate] = [_cand(Vector2(1.0, 0.0), false, false)]
	assert_eq(_pick(cands), -1)


func test_ac1_score_formula() -> void:
	# dot = 1, dist = 2 -> 2 + 0,5
	assert_almost_eq(InteractionScoring.score(1.0, 2.0), 2.5, 0.0001)
	# distancia mínima 0,1 para no dividir por cero
	assert_almost_eq(InteractionScoring.score(1.0, 0.0), 12.0, 0.0001)
