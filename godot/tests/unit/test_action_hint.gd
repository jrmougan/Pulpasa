extends GutTest
## PUL-121 AC2: ActionVerb, ActionReason y ActionHint cumplen las invariantes de ADR-003 §11.1.


func _no_empty_nor_duplicates(values: Array[StringName]) -> void:
	var seen: Dictionary = {}
	for value: StringName in values:
		assert_ne(value, &"", "valor vacío")
		assert_false(seen.has(value), "duplicado: %s" % value)
		seen[value] = true


func test_ac2_verbs_are_the_eight_of_the_contract_in_order() -> void:
	var expected: Array[StringName] = [
		&"pick_up", &"drop", &"cook", &"cut", &"season_sweet", &"season_hot", &"cachelos", &"trash"
	]
	assert_eq(ActionVerb.ALL, expected)
	_no_empty_nor_duplicates(ActionVerb.ALL)


func test_ac2_reasons_are_the_six_of_the_contract() -> void:
	var expected: Array[StringName] = [
		&"box_not_full", &"busy", &"empty", &"full", &"already_applied", &"not_cooked"
	]
	assert_eq(ActionReason.ALL, expected)
	_no_empty_nor_duplicates(ActionReason.ALL)


func test_ac2_is_valid_accepts_members_only() -> void:
	for verb: StringName in ActionVerb.ALL:
		assert_true(ActionVerb.is_valid(verb), verb)
	assert_false(ActionVerb.is_valid(ActionVerb.NONE))
	assert_false(ActionVerb.is_valid(&"deliver"))
	for reason: StringName in ActionReason.ALL:
		assert_true(ActionReason.is_valid(reason), reason)
	assert_false(ActionReason.is_valid(ActionReason.NONE))
	assert_false(ActionReason.is_valid(&"other"))


func test_ac2_repeatable_is_only_cut() -> void:
	var expected: Array[StringName] = [ActionVerb.CUT]
	assert_eq(ActionVerb.REPEATABLE, expected)


func test_ac2_state_values_are_fixed_for_the_bus() -> void:
	assert_eq(int(ActionHint.State.NONE), 0)
	assert_eq(int(ActionHint.State.OK), 1)
	assert_eq(int(ActionHint.State.BLOCKED), 2)


func test_ac2_none_invariants() -> void:
	var hint: ActionHint = ActionHint.none()
	assert_eq(hint.state, ActionHint.State.NONE)
	assert_eq(hint.verb, &"")
	assert_eq(hint.reason, &"")
	assert_false(hint.is_target())
	assert_false(hint.replaces)
	assert_eq(hint.progress, -1.0)


func test_ac2_ok_invariants_for_every_verb() -> void:
	for verb: StringName in ActionVerb.ALL:
		var hint: ActionHint = ActionHint.ok(verb)
		assert_eq(hint.state, ActionHint.State.OK)
		assert_true(ActionVerb.is_valid(hint.verb))
		assert_eq(hint.reason, &"")
		assert_true(hint.is_target())


func test_ac2_ok_keeps_progress() -> void:
	assert_eq(ActionHint.ok(ActionVerb.CUT, 0.5).progress, 0.5)
	assert_eq(ActionHint.ok(ActionVerb.CUT).progress, -1.0)


func test_ac2_blocked_invariants_for_every_verb_and_reason() -> void:
	for verb: StringName in ActionVerb.ALL:
		for reason: StringName in ActionReason.ALL:
			var hint: ActionHint = ActionHint.blocked(verb, reason)
			assert_eq(hint.state, ActionHint.State.BLOCKED)
			assert_true(ActionVerb.is_valid(hint.verb))
			assert_true(ActionReason.is_valid(hint.reason))
			assert_true(hint.is_target())


func test_ac2_legacy_ok_with_empty_verb_is_the_only_exception() -> void:
	var hint: ActionHint = ActionHint.ok(ActionVerb.NONE)
	assert_eq(hint.state, ActionHint.State.OK)
	assert_eq(hint.verb, &"")
	assert_true(hint.is_target())


func test_ac2_same_as_ignores_progress() -> void:
	assert_true(ActionHint.ok(ActionVerb.CUT, 0.1).same_as(ActionHint.ok(ActionVerb.CUT, 0.9)))
	assert_true(ActionHint.none().same_as(ActionHint.none()))


func test_ac2_same_as_compares_verb_state_reason_and_replaces() -> void:
	var base: ActionHint = ActionHint.ok(ActionVerb.SEASON_SWEET)
	assert_false(base.same_as(ActionHint.ok(ActionVerb.SEASON_HOT)))
	assert_false(base.same_as(ActionHint.blocked(ActionVerb.SEASON_SWEET, ActionReason.BUSY)))
	var other: ActionHint = ActionHint.ok(ActionVerb.SEASON_SWEET)
	other.replaces = true
	assert_false(base.same_as(other), "replaces cuenta")
	var full: ActionHint = ActionHint.blocked(ActionVerb.CUT, ActionReason.FULL)
	assert_false(full.same_as(ActionHint.blocked(ActionVerb.CUT, ActionReason.NOT_COOKED)))
	assert_false(base.same_as(ActionHint.none()))
	assert_false(base.same_as(null))
