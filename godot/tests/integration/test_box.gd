# gdlint: disable=max-public-methods
extends GutTest
## PUL-016 AC1/AC2: la caja decide (ADR-003 §4) si el objeto en la mano la llena (pulpo cocido,
## corte por pulsación D1/D13) o la condimenta (una vez por tipo, con la caja llena).
## PUL-057: API de la estación de condimentos (`toggle_seasoning`/`remove_seasoning`, D18).

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const SEASONING_SCENE: PackedScene = preload("res://entities/items/seasoning.tscn")
const SMALL: BoxData = preload("res://data/boxes/small.tres")
const MEDIUM: BoxData = preload("res://data/boxes/medium.tres")
const LARGE: BoxData = preload("res://data/boxes/large.tres")
const SALT: SeasoningData = preload("res://data/seasonings/salt.tres")
const PAPRIKA: SeasoningData = preload("res://data/seasonings/paprika.tres")
const HOT_PAPRIKA: SeasoningData = preload("res://data/seasonings/hot_paprika.tres")
const OIL: SeasoningData = preload("res://data/seasonings/oil.tres")

var _level: Node3D
var _hold: HoldComponent
var _actor: InteractionComponent


func before_each() -> void:
	_level = add_child_autofree(Node3D.new())
	var player: Player = PLAYER_SCENE.instantiate()
	_level.add_child(player)
	_hold = player.get_node("%HoldComponent")
	_hold.items_root = _level
	_actor = player.get_node("%InteractionComponent")


func _box(data: BoxData) -> Box:
	var box: Box = BOX_SCENE.instantiate()
	box.data = data
	_level.add_child(box)
	box.position = Vector3(1, 0, 0)
	return box


func _octopus_in_hand(cooked: bool) -> Ingredient:
	var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
	_level.add_child(octopus)
	if cooked:
		octopus.set_cooked()
	assert_true(_hold.pick_up(octopus))
	return octopus


func _seasoning_in_hand(data: SeasoningData) -> SeasoningItem:
	var item: SeasoningItem = SEASONING_SCENE.instantiate()
	item.data = data
	_level.add_child(item)
	assert_true(_hold.pick_up(item))
	return item


## Corta hasta llenar; devuelve el número de pulsaciones.
func _fill(box: Box) -> int:
	var presses: int = 0
	while not box.is_full() and box.can_interact(_actor) and presses < 100:
		assert_true(box.interact(_actor))
		presses += 1
	return presses


func _assert_presses_to_fill(data: BoxData, expected: int) -> void:
	var box: Box = _box(data)
	var octopus: Ingredient = _octopus_in_hand(true)
	for i: int in expected - 1:
		assert_true(box.interact(_actor), "%s pulsación %d" % [data.display_name, i + 1])
	assert_false(box.is_full(), "%s no llena antes de %d" % [data.display_name, expected])
	assert_true(box.interact(_actor))
	assert_true(box.is_full(), "%s llena en %d" % [data.display_name, expected])
	assert_true(box.interact(_actor), "llena: consume la pulsación (paridad Unity)...")
	assert_eq(box.fill, 1.0, "...sin cortar más")
	assert_almost_eq(octopus.remaining, 100.0 - 50.0, 0.001, "gasta medio pulpo")
	var contents: BoxContents = box.get_contents()
	assert_eq(contents.box, data)
	assert_eq(contents.ingredient, octopus.data)
	assert_eq(contents.ingredient_state, IngredientData.CookingState.COOKED)
	assert_eq(contents.fill, 1.0)


func test_ac1_small_box_fills_in_5_presses() -> void:
	_assert_presses_to_fill(SMALL, 5)


func test_ac1_medium_box_fills_in_10_presses() -> void:
	_assert_presses_to_fill(MEDIUM, 10)


func test_ac1_large_box_fills_in_20_presses() -> void:
	_assert_presses_to_fill(LARGE, 20)


func test_ac1_each_press_spends_octopus_and_emits_fill_changed() -> void:
	var box: Box = _box(SMALL)
	var octopus: Ingredient = _octopus_in_hand(true)
	watch_signals(box)
	assert_true(box.interact(_actor))
	assert_almost_eq(box.fill, 0.2, 0.0001)
	assert_almost_eq(octopus.remaining, 90.0, 0.0001)
	assert_signal_emitted_with_parameters(box, "fill_changed", [box.fill])
	assert_null(box.get_contents().ingredient, "sin llenar no cuenta como ingrediente")


func test_ac1_raw_octopus_does_nothing() -> void:
	var box: Box = _box(SMALL)
	var octopus: Ingredient = _octopus_in_hand(false)
	# Paridad Unity: la caja consume la pulsación (no se suelta el pulpo) pero no corta.
	assert_true(box.can_interact(_actor))
	assert_true(box.interact(_actor))
	assert_eq(box.fill, 0.0)
	assert_eq(octopus.remaining, 100.0)
	assert_eq(_hold.get_held_item(), octopus)


func test_ac1_one_octopus_fills_two_boxes_then_is_freed() -> void:
	var first: Box = _box(MEDIUM)
	var octopus: Ingredient = _octopus_in_hand(true)
	assert_eq(_fill(first), 10)
	var second: Box = _box(MEDIUM)
	assert_eq(_fill(second), 10)
	assert_true(second.is_full())
	assert_true(octopus.is_queued_for_deletion(), "agotado se libera")
	assert_null(_hold.get_held_item(), "la mano queda libre")


func test_ac1_empty_hand_picks_up_the_box() -> void:
	var box: Box = _box(SMALL)
	assert_true(box.can_interact(_actor))
	assert_true(box.interact(_actor))
	assert_eq(_hold.get_held_item(), box)
	assert_true(box.is_held)


func test_ac2_full_box_receives_each_seasoning_once() -> void:
	var box: Box = _box(SMALL)
	var octopus: Ingredient = _octopus_in_hand(true)
	_fill(box)
	_hold.drop()
	octopus.queue_free()
	var salt: SeasoningItem = _seasoning_in_hand(SALT)
	watch_signals(box)
	assert_true(box.can_interact(_actor))
	assert_true(box.interact(_actor))
	assert_true(box.interact(_actor), "repetir consume la pulsación sin efecto")
	assert_eq(box.get_contents().seasonings, [SALT] as Array[SeasoningData])
	assert_signal_emit_count(box, "seasoned", 1)
	_hold.drop()
	salt.queue_free()
	_seasoning_in_hand(PAPRIKA)
	assert_true(box.interact(_actor))
	assert_eq(box.get_contents().seasonings, [SALT, PAPRIKA] as Array[SeasoningData])
	assert_signal_emit_count(box, "seasoned", 2)


func test_ac2_seasoning_not_applied_to_unfilled_box() -> void:
	var box: Box = _box(SMALL)
	var octopus: Ingredient = _octopus_in_hand(true)
	box.interact(_actor)
	_hold.drop()
	octopus.queue_free()
	_seasoning_in_hand(SALT)
	# Consume la pulsación sin aplicar (paridad Unity).
	assert_true(box.interact(_actor))
	assert_eq(box.get_contents().seasonings.size(), 0)


func test_ac2_contents_are_a_copy() -> void:
	var box: Box = _box(SMALL)
	box.get_contents().seasonings.append(SALT)
	assert_eq(box.get_contents().seasonings.size(), 0)


func test_ac1_condimentacion_ac1_sweet_paprika_applied_once() -> void:
	var box: Box = _box(SMALL)
	var octopus: Ingredient = _octopus_in_hand(true)
	_fill(box)
	_hold.drop()
	octopus.queue_free()
	_seasoning_in_hand(PAPRIKA)
	watch_signals(box)
	assert_true(box.interact(_actor))
	assert_eq(box.get_contents().seasonings, [PAPRIKA] as Array[SeasoningData])
	assert_signal_emit_count(box, "seasoned", 1)


func test_ac1_condimentacion_ac2_paprika_exclusivity_rejects_hot_paprika() -> void:
	var box: Box = _box(SMALL)
	var octopus: Ingredient = _octopus_in_hand(true)
	_fill(box)
	_hold.drop()
	octopus.queue_free()
	var paprika: SeasoningItem = _seasoning_in_hand(PAPRIKA)
	assert_true(box.interact(_actor))
	assert_eq(box.get_contents().seasonings, [PAPRIKA] as Array[SeasoningData])
	_hold.drop()
	paprika.queue_free()
	_seasoning_in_hand(HOT_PAPRIKA)
	watch_signals(box)
	assert_true(box.interact(_actor), "consume pulsación")
	assert_eq(box.get_contents().seasonings, [PAPRIKA] as Array[SeasoningData], "no cambia")
	assert_signal_emit_count(box, "seasoned", 0, "no emite seasoned")


func test_ac1_condimentacion_ac2_hot_paprika_exclusivity_rejects_sweet_paprika() -> void:
	var box: Box = _box(SMALL)
	var octopus: Ingredient = _octopus_in_hand(true)
	_fill(box)
	_hold.drop()
	octopus.queue_free()
	var hot: SeasoningItem = _seasoning_in_hand(HOT_PAPRIKA)
	assert_true(box.interact(_actor))
	assert_eq(box.get_contents().seasonings, [HOT_PAPRIKA] as Array[SeasoningData])
	_hold.drop()
	hot.queue_free()
	_seasoning_in_hand(PAPRIKA)
	watch_signals(box)
	assert_true(box.interact(_actor))
	assert_eq(box.get_contents().seasonings, [HOT_PAPRIKA] as Array[SeasoningData])
	assert_signal_emit_count(box, "seasoned", 0)


func test_ac1_condimentacion_ac3_salt_is_idempotent() -> void:
	var box: Box = _box(SMALL)
	var octopus: Ingredient = _octopus_in_hand(true)
	_fill(box)
	_hold.drop()
	octopus.queue_free()
	_seasoning_in_hand(SALT)
	watch_signals(box)
	assert_true(box.interact(_actor))
	assert_eq(box.get_contents().seasonings, [SALT] as Array[SeasoningData])
	assert_signal_emit_count(box, "seasoned", 1)
	assert_true(box.interact(_actor))
	assert_eq(box.get_contents().seasonings, [SALT] as Array[SeasoningData])
	assert_signal_emit_count(box, "seasoned", 1)


func test_ac1_condimentacion_ac4_empty_box_rejects_seasoning() -> void:
	var box: Box = _box(SMALL)
	_seasoning_in_hand(SALT)
	watch_signals(box)
	assert_true(box.interact(_actor))
	assert_eq(box.get_contents().seasonings.size(), 0)
	assert_signal_emit_count(box, "seasoned", 0)


func test_ac1_condimentacion_ac4_half_filled_box_rejects_seasoning() -> void:
	var box: Box = _box(SMALL)
	var octopus: Ingredient = _octopus_in_hand(true)
	assert_true(box.interact(_actor))
	_hold.drop()
	octopus.queue_free()
	_seasoning_in_hand(SALT)
	watch_signals(box)
	assert_true(box.interact(_actor))
	assert_eq(box.get_contents().seasonings.size(), 0)
	assert_signal_emit_count(box, "seasoned", 0)


func test_ac1_full_box_can_receive_oil() -> void:
	var box: Box = _box(SMALL)
	var octopus: Ingredient = _octopus_in_hand(true)
	_fill(box)
	_hold.drop()
	octopus.queue_free()
	_seasoning_in_hand(OIL)
	watch_signals(box)
	assert_true(box.interact(_actor))
	assert_eq(box.get_contents().seasonings, [OIL] as Array[SeasoningData])
	assert_signal_emit_count(box, "seasoned", 1)


func test_ac1_oil_and_paprika_can_coexist() -> void:
	var box: Box = _box(SMALL)
	var octopus: Ingredient = _octopus_in_hand(true)
	_fill(box)
	_hold.drop()
	octopus.queue_free()
	var paprika: SeasoningItem = _seasoning_in_hand(PAPRIKA)
	assert_true(box.interact(_actor))
	assert_eq(box.get_contents().seasonings, [PAPRIKA] as Array[SeasoningData])
	_hold.drop()
	paprika.queue_free()
	_seasoning_in_hand(OIL)
	watch_signals(box)
	assert_true(box.interact(_actor))
	assert_eq(box.get_contents().seasonings, [PAPRIKA, OIL] as Array[SeasoningData])
	assert_signal_emit_count(box, "seasoned", 1)


func test_box_without_fill_bar_does_not_crash() -> void:
	# B8: la barra es opcional y se comprueba.
	var box: Box = BOX_SCENE.instantiate()
	box.data = SMALL
	box.get_node("%FillBar").free()
	_level.add_child(box)
	_octopus_in_hand(true)
	assert_eq(_fill(box), 5)
	assert_true(box.is_full())


func test_box_open_close_animations_exist() -> void:
	var box: Box = _box(SMALL)
	var player: AnimationPlayer = box.get_node("%AnimationPlayer")
	assert_true(player.has_animation(&"box_open"))
	assert_true(player.has_animation(&"box_close"))


## Caja pequeña llena y mano vacía.
func _full_box() -> Box:
	var box: Box = _box(SMALL)
	var octopus: Ingredient = _octopus_in_hand(true)
	_fill(box)
	_hold.drop()
	octopus.queue_free()
	return box


func test_pul057_box_is_in_box_group() -> void:
	assert_true(_box(SMALL).is_in_group(&"box"), "la bandeja acepta el grupo box")


func test_pul057_ac2_toggle_adds_then_removes_with_signals() -> void:
	var box: Box = _full_box()
	watch_signals(box)
	assert_eq(box.toggle_seasoning(SALT, true), SeasoningRules.Rejection.NONE)
	assert_true(box.has_seasoning(SALT))
	assert_signal_emit_count(box, "seasoned", 1)
	assert_signal_emitted_with_parameters(box, "seasoned", [SALT])
	assert_signal_emit_count(box, "seasoning_removed", 0)
	assert_eq(box.toggle_seasoning(SALT, true), SeasoningRules.Rejection.NONE)
	assert_false(box.has_seasoning(SALT))
	assert_eq(box.get_contents().seasonings.size(), 0)
	assert_signal_emit_count(box, "seasoned", 1)
	assert_signal_emit_count(box, "seasoning_removed", 1)
	assert_signal_emitted_with_parameters(box, "seasoning_removed", [SALT])


func test_pul057_ac2_paprika_swap_emits_removed_before_seasoned() -> void:
	var box: Box = _full_box()
	assert_eq(box.toggle_seasoning(PAPRIKA, true), SeasoningRules.Rejection.NONE)
	var order: Array[String] = []
	box.seasoning_removed.connect(
		func(s: SeasoningData) -> void: order.append("removed:%s" % s.translation_key)
	)
	box.seasoned.connect(
		func(s: SeasoningData) -> void: order.append("seasoned:%s" % s.translation_key)
	)
	watch_signals(box)
	assert_eq(box.toggle_seasoning(HOT_PAPRIKA, true), SeasoningRules.Rejection.NONE)
	assert_eq(box.get_contents().seasonings, [HOT_PAPRIKA] as Array[SeasoningData])
	assert_signal_emit_count(box, "seasoning_removed", 1)
	assert_signal_emit_count(box, "seasoned", 1)
	assert_eq(
		order, ["removed:SEASONING_PAPRIKA", "seasoned:SEASONING_HOT_PAPRIKA"] as Array[String]
	)


func test_pul057_ac2_paprika_without_swap_is_rejected_silently() -> void:
	var box: Box = _full_box()
	box.toggle_seasoning(PAPRIKA, true)
	watch_signals(box)
	assert_eq(box.toggle_seasoning(HOT_PAPRIKA, false), SeasoningRules.Rejection.EXCLUSIVE_TAKEN)
	assert_eq(box.get_contents().seasonings, [PAPRIKA] as Array[SeasoningData])
	assert_signal_emit_count(box, "seasoned", 0)
	assert_signal_emit_count(box, "seasoning_removed", 0)


func test_pul057_ac2_toggle_on_unfilled_box_is_rejected() -> void:
	var empty: Box = _box(SMALL)
	watch_signals(empty)
	assert_eq(empty.toggle_seasoning(SALT, true), SeasoningRules.Rejection.BOX_NOT_FULL)
	assert_signal_emit_count(empty, "seasoned", 0)
	var half: Box = _box(MEDIUM)
	_octopus_in_hand(true)
	for i: int in 6:
		half.interact(_actor)
	assert_almost_eq(half.fill, 0.6, 0.0001)
	watch_signals(half)
	assert_eq(half.toggle_seasoning(OIL, true), SeasoningRules.Rejection.BOX_NOT_FULL)
	assert_eq(half.get_contents().seasonings.size(), 0)
	assert_signal_emit_count(half, "seasoned", 0)


func test_pul057_ac2_remove_seasoning() -> void:
	var box: Box = _full_box()
	box.toggle_seasoning(SALT, true)
	box.toggle_seasoning(OIL, true)
	watch_signals(box)
	assert_true(box.remove_seasoning(SALT))
	assert_eq(box.get_contents().seasonings, [OIL] as Array[SeasoningData])
	assert_signal_emitted_with_parameters(box, "seasoning_removed", [SALT])
	assert_false(box.remove_seasoning(SALT), "ya no la lleva")
	assert_false(box.remove_seasoning(null))
	assert_signal_emit_count(box, "seasoning_removed", 1)
	assert_signal_emit_count(box, "seasoned", 0)
