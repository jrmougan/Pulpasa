# gdlint: disable=max-public-methods
extends GutTest
## PUL-057: reglas puras de condimento (estacion-condimentos.md AC2–AC5 y AC13, lógica).

const SALT: SeasoningData = preload("res://data/seasonings/salt.tres")
const PAPRIKA: SeasoningData = preload("res://data/seasonings/paprika.tres")
const HOT_PAPRIKA: SeasoningData = preload("res://data/seasonings/hot_paprika.tres")
const OIL: SeasoningData = preload("res://data/seasonings/oil.tres")
const CACHELOS: SeasoningData = preload("res://data/seasonings/cachelos.tres")


func _list(items: Array) -> Array[SeasoningData]:
	var result: Array[SeasoningData] = []
	result.assign(items)
	return result


func _paprika_count(seasonings: Array[SeasoningData]) -> int:
	var count: int = 0
	for seasoning: SeasoningData in seasonings:
		if seasoning.exclusivity_group == &"paprika":
			count += 1
	return count


func test_feature_ac1_toggle_adds_missing_seasoning() -> void:
	var result: SeasoningRules.Toggle = SeasoningRules.toggle(_list([]), SALT, true, true)
	assert_eq(result.rejection, SeasoningRules.Rejection.NONE)
	assert_eq(result.added, SALT)
	assert_null(result.removed)
	assert_eq(result.seasonings, _list([SALT]))


func test_feature_ac2_toggle_again_removes_seasoning() -> void:
	var result: SeasoningRules.Toggle = SeasoningRules.toggle(_list([SALT]), SALT, true, true)
	assert_eq(result.rejection, SeasoningRules.Rejection.NONE)
	assert_eq(result.removed, SALT)
	assert_null(result.added)
	assert_eq(result.seasonings, _list([]))


func test_feature_ac2_removing_keeps_the_others() -> void:
	var result: SeasoningRules.Toggle = SeasoningRules.toggle(
		_list([PAPRIKA, SALT, OIL]), SALT, true, true
	)
	assert_eq(result.seasonings, _list([PAPRIKA, OIL]))


func test_feature_ac2_same_type_from_another_instance_counts_as_same() -> void:
	var copy: SeasoningData = SALT.duplicate()
	var result: SeasoningRules.Toggle = SeasoningRules.toggle(_list([SALT]), copy, true, true)
	assert_eq(result.removed, SALT, "sale el que lleva la caja")
	assert_eq(result.seasonings, _list([]))


func test_feature_ac3_toggle_twice_returns_to_start() -> void:
	# El antirrebote temporal (toggle_guard) es del dispensador (PUL-058); la regla sola alterna.
	var first: SeasoningRules.Toggle = SeasoningRules.toggle(_list([SALT]), SALT, true, true)
	var second: SeasoningRules.Toggle = SeasoningRules.toggle(first.seasonings, SALT, true, true)
	assert_eq(second.seasonings, _list([SALT]))


func test_feature_ac4_paprika_swap_replaces_sweet_with_hot() -> void:
	var result: SeasoningRules.Toggle = SeasoningRules.toggle(
		_list([PAPRIKA, SALT]), HOT_PAPRIKA, true, true
	)
	assert_eq(result.rejection, SeasoningRules.Rejection.NONE)
	assert_eq(result.removed, PAPRIKA)
	assert_eq(result.added, HOT_PAPRIKA)
	assert_eq(result.seasonings, _list([SALT, HOT_PAPRIKA]))
	assert_eq(_paprika_count(result.seasonings), 1, "exactamente 1 del grupo paprika")


func test_feature_ac4_paprika_swap_replaces_hot_with_sweet() -> void:
	var result: SeasoningRules.Toggle = SeasoningRules.toggle(
		_list([HOT_PAPRIKA]), PAPRIKA, true, true
	)
	assert_eq(result.removed, HOT_PAPRIKA)
	assert_eq(result.added, PAPRIKA)
	assert_eq(result.seasonings, _list([PAPRIKA]))


func test_feature_ac4_pressing_the_paprika_it_has_removes_it() -> void:
	var result: SeasoningRules.Toggle = SeasoningRules.toggle(
		_list([HOT_PAPRIKA, OIL]), HOT_PAPRIKA, true, true
	)
	assert_eq(result.removed, HOT_PAPRIKA)
	assert_null(result.added)
	assert_eq(_paprika_count(result.seasonings), 0, "sin pimentón")


func test_feature_ac4_without_swap_exclusive_is_rejected() -> void:
	var current: Array[SeasoningData] = _list([PAPRIKA])
	var result: SeasoningRules.Toggle = SeasoningRules.toggle(current, HOT_PAPRIKA, true, false)
	assert_eq(result.rejection, SeasoningRules.Rejection.EXCLUSIVE_TAKEN)
	assert_null(result.removed)
	assert_null(result.added)
	assert_eq(result.seasonings, _list([PAPRIKA]))


func test_feature_ac4_without_swap_the_same_paprika_still_toggles() -> void:
	var result: SeasoningRules.Toggle = SeasoningRules.toggle(
		_list([PAPRIKA]), PAPRIKA, true, false
	)
	assert_eq(result.rejection, SeasoningRules.Rejection.NONE)
	assert_eq(result.removed, PAPRIKA)


func test_feature_ac4_non_exclusive_seasonings_coexist() -> void:
	var result: SeasoningRules.Toggle = SeasoningRules.toggle(
		_list([PAPRIKA, SALT]), OIL, true, false
	)
	assert_eq(result.rejection, SeasoningRules.Rejection.NONE)
	assert_null(result.removed)
	assert_eq(result.seasonings, _list([PAPRIKA, SALT, OIL]))


func test_feature_ac5_box_not_full_is_rejected() -> void:
	# Caja vacía o a medio llenar (fill 0,6): la regla solo ve is_full = false.
	for seasoning: SeasoningData in [SALT, PAPRIKA, HOT_PAPRIKA, OIL, CACHELOS]:
		var result: SeasoningRules.Toggle = SeasoningRules.toggle(_list([]), seasoning, false, true)
		assert_eq(result.rejection, SeasoningRules.Rejection.BOX_NOT_FULL, seasoning.display_name)
		assert_null(result.added)
		assert_null(result.removed)
		assert_eq(result.seasonings, _list([]))


func test_feature_ac5_null_seasoning_is_not_accepted() -> void:
	var result: SeasoningRules.Toggle = SeasoningRules.toggle(_list([SALT]), null, true, true)
	assert_eq(result.rejection, SeasoningRules.Rejection.NOT_ACCEPTED)
	assert_eq(result.seasonings, _list([SALT]))


func test_toggle_does_not_mutate_input() -> void:
	var current: Array[SeasoningData] = _list([PAPRIKA, SALT])
	SeasoningRules.toggle(current, SALT, true, true)
	SeasoningRules.toggle(current, HOT_PAPRIKA, true, true)
	SeasoningRules.toggle(current, OIL, true, true)
	assert_eq(current, _list([PAPRIKA, SALT]))


func test_remove_returns_copy_without_seasoning() -> void:
	var current: Array[SeasoningData] = _list([SALT, OIL])
	assert_eq(SeasoningRules.remove(current, SALT), _list([OIL]))
	assert_eq(SeasoningRules.remove(current, PAPRIKA), _list([SALT, OIL]), "no lo lleva")
	assert_eq(current, _list([SALT, OIL]), "no muta")


func test_find_and_find_in_group() -> void:
	var current: Array[SeasoningData] = _list([HOT_PAPRIKA, SALT])
	assert_eq(SeasoningRules.find(current, SALT), SALT)
	assert_null(SeasoningRules.find(current, OIL))
	assert_null(SeasoningRules.find(current, null))
	assert_eq(SeasoningRules.find_in_group(current, &"paprika"), HOT_PAPRIKA)
	assert_null(SeasoningRules.find_in_group(current, &""))


func test_feature_ac13_canonical_order_hot_salt_oil_cachelos() -> void:
	var applied: Array[SeasoningData] = _list([CACHELOS, OIL, SALT, HOT_PAPRIKA])
	var ordered: Array[SeasoningData] = SeasoningRules.canonical_order(applied)
	assert_eq(ordered, _list([HOT_PAPRIKA, SALT, OIL, CACHELOS]))
	assert_eq(applied, _list([CACHELOS, OIL, SALT, HOT_PAPRIKA]), "no muta")


func test_feature_ac13_canonical_order_is_compact_and_stable() -> void:
	assert_eq(SeasoningRules.canonical_order(_list([OIL, PAPRIKA])), _list([PAPRIKA, OIL]))
	assert_eq(
		SeasoningRules.canonical_order(_list([OIL, null, SALT])), _list([SALT, OIL]), "sin huecos"
	)
	assert_eq(SeasoningRules.canonical_order(_list([])), _list([]))
	# A igual sort_order se respeta el orden de entrada (estable).
	assert_eq(
		SeasoningRules.canonical_order(_list([SALT, HOT_PAPRIKA, PAPRIKA])),
		_list([HOT_PAPRIKA, PAPRIKA, SALT])
	)
	assert_eq(
		SeasoningRules.canonical_order(_list([PAPRIKA, SALT, HOT_PAPRIKA])),
		_list([PAPRIKA, HOT_PAPRIKA, SALT])
	)


## PUL-097 (R6): el cuenco suma 2 raciones por cachelo, con máximo 4 y recorte.
func test_pul097_restocked_adds_two_portions_up_to_four() -> void:
	assert_eq(SeasoningRules.restocked(0, 2, 4), 2)
	assert_eq(SeasoningRules.restocked(2, 2, 4), 4)


func test_pul097_restocked_clips_to_max() -> void:
	assert_eq(SeasoningRules.restocked(3, 2, 4), 4, "con 3 queda en 4")


func test_pul097_full_bowl_rejects_restock() -> void:
	assert_true(SeasoningRules.can_restock(3, 4))
	assert_false(SeasoningRules.can_restock(4, 4))
	assert_eq(SeasoningRules.restocked(4, 2, 4), 4)
