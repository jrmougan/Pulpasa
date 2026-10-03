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
