# gdlint: disable=max-public-methods
extends GutTest
## PUL-057/114: reglas puras de condimento (condimentacion.md AC1–AC4 y AC7; estacion-condimentos.md
## AC4, D25): aplicar un aliño (sustituye al otro, repetir no hace nada), alternar cachelos, orden
## canónico y reposición del cuenco.

const SWEET: SeasoningData = preload("res://data/seasonings/sweet_dressing.tres")
const HOT: SeasoningData = preload("res://data/seasonings/hot_dressing.tres")
const CACHELOS: SeasoningData = preload("res://data/seasonings/cachelos.tres")


func _list(items: Array) -> Array[SeasoningData]:
	var result: Array[SeasoningData] = []
	result.assign(items)
	return result


func _dressing_count(seasonings: Array[SeasoningData]) -> int:
	var count: int = 0
	for seasoning: SeasoningData in seasonings:
		if seasoning.exclusivity_group == &"dressing":
			count += 1
	return count


func test_data_dressing_types_are_appended_to_the_enum() -> void:
	assert_eq(SeasoningData.SeasoningType.CACHELOS, 4, "cachelos.tres guarda type = 4")
	assert_eq(SeasoningData.SeasoningType.SWEET_DRESSING, 5)
	assert_eq(SeasoningData.SeasoningType.HOT_DRESSING, 6)
	assert_eq(SeasoningRules.Rejection.ALREADY_APPLIED, 8, "al final, sin renumerar")


func test_ac1_apply_adds_the_dressing_to_an_empty_box() -> void:
	var result: SeasoningRules.Toggle = SeasoningRules.apply(_list([]), SWEET, true)
	assert_eq(result.rejection, SeasoningRules.Rejection.NONE)
	assert_eq(result.added, SWEET)
	assert_null(result.removed, "no se quita nada")
	assert_eq(result.seasonings, _list([SWEET]), "solo el aliño, nada más")


func test_ac2_apply_the_other_dressing_replaces_it() -> void:
	var result: SeasoningRules.Toggle = SeasoningRules.apply(_list([SWEET]), HOT, true)
	assert_eq(result.rejection, SeasoningRules.Rejection.NONE)
	assert_eq(result.removed, SWEET)
	assert_eq(result.added, HOT)
	assert_eq(result.seasonings, _list([HOT]))
	assert_eq(_dressing_count(result.seasonings), 1, "nunca hay dos aliños")


func test_ac2_replacing_keeps_cachelos_and_puts_the_new_dressing_last() -> void:
	var result: SeasoningRules.Toggle = SeasoningRules.apply(_list([SWEET, CACHELOS]), HOT, true)
	assert_eq(result.seasonings, _list([CACHELOS, HOT]), "orden de aplicación")
	assert_eq(_dressing_count(result.seasonings), 1)


func test_ac3_apply_the_same_dressing_is_already_applied() -> void:
	var current: Array[SeasoningData] = _list([SWEET])
	var result: SeasoningRules.Toggle = SeasoningRules.apply(current, SWEET, true)
	assert_eq(result.rejection, SeasoningRules.Rejection.ALREADY_APPLIED)
	assert_null(result.added)
	assert_null(result.removed)
	assert_eq(result.seasonings, current, "applied no cambia")


func test_ac3_same_type_from_another_instance_is_already_applied() -> void:
	var result: SeasoningRules.Toggle = SeasoningRules.apply(_list([HOT]), HOT.duplicate(), true)
	assert_eq(result.rejection, SeasoningRules.Rejection.ALREADY_APPLIED)


func test_ac3_already_applied_has_priority_over_replacing() -> void:
	# La caja con aliño y cachelos: repetir el aliño no hace nada aunque haya más cosas.
	var result: SeasoningRules.Toggle = SeasoningRules.apply(_list([CACHELOS, HOT]), HOT, true)
	assert_eq(result.rejection, SeasoningRules.Rejection.ALREADY_APPLIED)
	assert_eq(result.seasonings, _list([CACHELOS, HOT]))


func test_ac4_box_not_full_is_rejected_for_any_seasoning() -> void:
	# Caja vacía o a medio llenar (fill 0,6): la regla solo ve is_full = false.
	for seasoning: SeasoningData in [SWEET, HOT, CACHELOS]:
		var applied: SeasoningRules.Toggle = SeasoningRules.apply(_list([]), seasoning, false)
		assert_eq(applied.rejection, SeasoningRules.Rejection.BOX_NOT_FULL, seasoning.display_name)
		assert_null(applied.added)
		assert_eq(applied.seasonings, _list([]))


func test_ac4_box_not_full_wins_over_already_applied() -> void:
	var result: SeasoningRules.Toggle = SeasoningRules.apply(_list([SWEET]), SWEET, false)
	assert_eq(result.rejection, SeasoningRules.Rejection.BOX_NOT_FULL)


func test_apply_null_seasoning_is_not_accepted() -> void:
	var result: SeasoningRules.Toggle = SeasoningRules.apply(_list([SWEET]), null, true)
	assert_eq(result.rejection, SeasoningRules.Rejection.NOT_ACCEPTED)
	assert_eq(result.seasonings, _list([SWEET]))


func test_apply_does_not_mutate_input() -> void:
	var current: Array[SeasoningData] = _list([SWEET, CACHELOS])
	SeasoningRules.apply(current, HOT, true)
	SeasoningRules.apply(current, SWEET, true)
	assert_eq(current, _list([SWEET, CACHELOS]))


## D26 (ADR-003 §11.7): el cuenco solo pone; `toggle` y `Box.toggle_seasoning` no existen.
func test_d26_no_toggle_in_the_rules() -> void:
	assert_false(SeasoningRules.new().has_method(&"toggle"))


func test_remove_returns_copy_without_seasoning() -> void:
	var current: Array[SeasoningData] = _list([SWEET, CACHELOS])
	assert_eq(SeasoningRules.remove(current, CACHELOS), _list([SWEET]))
	assert_eq(SeasoningRules.remove(current, HOT), _list([SWEET, CACHELOS]), "no lo lleva")
	assert_eq(current, _list([SWEET, CACHELOS]), "no muta")


func test_find_and_find_in_group() -> void:
	var current: Array[SeasoningData] = _list([HOT, CACHELOS])
	assert_eq(SeasoningRules.find(current, CACHELOS), CACHELOS)
	assert_null(SeasoningRules.find(current, SWEET))
	assert_null(SeasoningRules.find(current, null))
	assert_eq(SeasoningRules.find_in_group(current, &"dressing"), HOT)
	assert_null(SeasoningRules.find_in_group(current, &""))


func test_ac7_canonical_order_is_dressing_then_cachelos() -> void:
	var applied: Array[SeasoningData] = _list([CACHELOS, HOT])
	var ordered: Array[SeasoningData] = SeasoningRules.canonical_order(applied)
	assert_eq(ordered, _list([HOT, CACHELOS]))
	assert_eq(applied, _list([CACHELOS, HOT]), "no muta")
	assert_eq(SeasoningRules.canonical_order(_list([SWEET, CACHELOS])), _list([SWEET, CACHELOS]))


func test_ac7_canonical_order_is_compact_and_stable() -> void:
	assert_eq(
		SeasoningRules.canonical_order(_list([CACHELOS, null, SWEET])),
		_list([SWEET, CACHELOS]),
		"sin huecos"
	)
	assert_eq(SeasoningRules.canonical_order(_list([])), _list([]))
	# A igual sort_order se respeta el orden de entrada (estable).
	assert_eq(SeasoningRules.canonical_order(_list([HOT, SWEET])), _list([HOT, SWEET]))
	assert_eq(SeasoningRules.canonical_order(_list([SWEET, HOT])), _list([SWEET, HOT]))


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
