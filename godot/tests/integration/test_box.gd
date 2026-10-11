# gdlint: disable=max-public-methods
extends GutTest
## PUL-016 AC1: la caja decide (ADR-003 §4) si el objeto en la mano la llena (pulpo cocido,
## corte por pulsación D1/D13) o se coge con la mano vacía.
## PUL-057/114: API de la estación de condimentos (`apply_seasoning` de los aliños, D25;
## cachelos del cuenco con la misma API, D26, y `remove_seasoning`).
## PUL-061: fuera de la estación ya no se condimenta (feature estacion-condimentos AC12).

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const CACHELOS_SCENE: PackedScene = preload("res://entities/items/cachelos.tscn")
const BOX: BoxData = preload("res://data/boxes/box.tres")
const SWEET: SeasoningData = preload("res://data/seasonings/sweet_dressing.tres")
const HOT: SeasoningData = preload("res://data/seasonings/hot_dressing.tres")
const CACHELOS: SeasoningData = preload("res://data/seasonings/cachelos.tres")

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
	assert_eq(box.get_action_hint(_actor).reason, ActionReason.FULL)
	assert_true(box.interact(_actor), "llena: rechazo con motivo `full`...")
	assert_eq(box.fill, 1.0, "...sin cortar más")
	assert_almost_eq(octopus.remaining, 100.0 - 50.0, 0.001, "gasta medio pulpo")
	var contents: BoxContents = box.get_contents()
	assert_eq(contents.box, data)
	assert_eq(contents.ingredient, octopus.data)
	assert_eq(contents.ingredient_state, IngredientData.CookingState.COOKED)
	assert_eq(contents.fill, 1.0)


func test_pul113_ac5_single_box_fills_in_6_presses() -> void:
	_assert_presses_to_fill(BOX, 6)


func test_ac1_each_press_spends_octopus_and_emits_fill_changed() -> void:
	var box: Box = _box(BOX)
	var octopus: Ingredient = _octopus_in_hand(true)
	watch_signals(box)
	assert_true(box.interact(_actor))
	assert_almost_eq(box.fill, 1.0 / 6.0, 0.0001)
	assert_almost_eq(octopus.remaining, 100.0 - 50.0 / 6.0, 0.0001)
	assert_signal_emitted_with_parameters(box, "fill_changed", [box.fill])
	assert_null(box.get_contents().ingredient, "sin llenar no cuenta como ingrediente")


func test_ac1_raw_octopus_does_nothing() -> void:
	var box: Box = _box(BOX)
	var octopus: Ingredient = _octopus_in_hand(false)
	# D26: el pulpo crudo se rechaza con motivo (`BLOCKED not_cooked`): no corta ni se suelta.
	var hint: ActionHint = box.get_action_hint(_actor)
	assert_eq(
		[hint.state, hint.verb, hint.reason], [ActionHint.State.BLOCKED, &"cut", &"not_cooked"]
	)
	assert_true(box.can_interact(_actor))
	assert_true(box.interact(_actor))
	assert_eq(box.fill, 0.0)
	assert_eq(octopus.remaining, 100.0)
	assert_eq(_hold.get_held_item(), octopus)


func test_ac1_one_octopus_fills_two_boxes_then_is_freed() -> void:
	var first: Box = _box(BOX)
	var octopus: Ingredient = _octopus_in_hand(true)
	assert_eq(_fill(first), 6)
	var second: Box = _box(BOX)
	assert_eq(_fill(second), 6)
	assert_true(second.is_full())
	assert_true(octopus.is_queued_for_deletion(), "agotado se libera")
	assert_null(_hold.get_held_item(), "la mano queda libre")


func test_ac1_empty_hand_picks_up_the_box() -> void:
	var box: Box = _box(BOX)
	assert_true(box.can_interact(_actor))
	assert_true(box.interact(_actor))
	assert_eq(_hold.get_held_item(), box)
	assert_true(box.is_held)


## AC12: con cachelos cocidos en la mano, la caja llena no se condimenta: no es objetivo (D26) y los
## cachelos siguen en la mano (solo la estación condimenta).
func test_pul061_ac12_cooked_cachelos_do_not_season_a_full_box() -> void:
	var box: Box = _box(BOX)
	var octopus: Ingredient = _octopus_in_hand(true)
	_fill(box)
	_hold.drop()
	octopus.queue_free()
	var cachelos: Ingredient = CACHELOS_SCENE.instantiate()
	_level.add_child(cachelos)
	cachelos.set_cooked()
	assert_true(_hold.pick_up(cachelos))
	watch_signals(box)
	assert_false(box.can_interact(_actor), "D26: la caja llena no es objetivo de unos cachelos")
	assert_eq(box.get_action_hint(_actor).state, ActionHint.State.NONE)
	assert_false(box.interact(_actor), "no consume la pulsación")
	assert_eq(box.get_contents().seasonings.size(), 0, "la caja no cambia")
	assert_signal_emit_count(box, "seasoned", 0)
	assert_eq(_hold.get_held_item(), cachelos, "los cachelos siguen en la mano")


## AC12: la caja en la mano tampoco cambia por pulsar sobre ella con otra cosa (no condimenta ni
## se suelta): cualquier objeto que no corta solo consume la pulsación.
func test_pul061_ac12_other_items_only_consume_the_press() -> void:
	var box: Box = _box(BOX)
	var octopus: Ingredient = _octopus_in_hand(true)
	_fill(box)
	_hold.drop()
	octopus.queue_free()
	var raw: Ingredient = _octopus_in_hand(false)
	watch_signals(box)
	assert_true(box.interact(_actor))
	assert_eq(_hold.get_held_item(), raw)
	assert_signal_emit_count(box, "seasoned", 0)
	assert_false(box.has_method(&"can_season"), "sin ruta de condimento en la caja")


func test_ac2_contents_are_a_copy() -> void:
	var box: Box = _box(BOX)
	box.get_contents().seasonings.append(SWEET)
	assert_eq(box.get_contents().seasonings.size(), 0)


func test_box_without_cut_counter_does_not_crash() -> void:
	# B8: el contador es opcional y se comprueba. D26: ya no hay `%FillBar`.
	var box: Box = BOX_SCENE.instantiate()
	box.data = BOX
	assert_null(box.get_node_or_null("%FillBar"), "la barra de llenado se retiró")
	box.get_node("%CutCounter").free()
	_level.add_child(box)
	_octopus_in_hand(true)
	assert_eq(_fill(box), 6)
	assert_true(box.is_full())


func test_box_open_close_animations_exist() -> void:
	var box: Box = _box(BOX)
	var player: AnimationPlayer = box.get_node("%AnimationPlayer")
	assert_true(player.has_animation(&"box_open"))
	assert_true(player.has_animation(&"box_close"))


## Caja llena y mano vacía.
func _full_box() -> Box:
	var box: Box = _box(BOX)
	var octopus: Ingredient = _octopus_in_hand(true)
	_fill(box)
	_hold.drop()
	octopus.queue_free()
	return box


func test_pul057_box_is_in_box_group() -> void:
	assert_true(_box(BOX).is_in_group(&"box"), "la bandeja acepta el grupo box")


func test_pul114_ac1_apply_adds_the_dressing_with_one_seasoned() -> void:
	var box: Box = _full_box()
	watch_signals(box)
	assert_eq(box.apply_seasoning(SWEET), SeasoningRules.Rejection.NONE)
	assert_true(box.has_seasoning(SWEET))
	assert_eq(box.get_contents().seasonings, [SWEET] as Array[SeasoningData], "solo el aliño")
	assert_signal_emit_count(box, "seasoned", 1)
	assert_signal_emitted_with_parameters(box, "seasoned", [SWEET])
	assert_signal_emit_count(box, "seasoning_removed", 0)


func test_pul114_ac2_replacing_emits_removed_before_seasoned() -> void:
	var box: Box = _full_box()
	assert_eq(box.apply_seasoning(SWEET), SeasoningRules.Rejection.NONE)
	var order: Array[String] = []
	box.seasoning_removed.connect(
		func(s: SeasoningData) -> void: order.append("removed:%s" % s.translation_key)
	)
	box.seasoned.connect(
		func(s: SeasoningData) -> void: order.append("seasoned:%s" % s.translation_key)
	)
	watch_signals(box)
	assert_eq(box.apply_seasoning(HOT), SeasoningRules.Rejection.NONE)
	assert_eq(box.get_contents().seasonings, [HOT] as Array[SeasoningData])
	assert_false(box.has_seasoning(SWEET))
	assert_signal_emit_count(box, "seasoning_removed", 1)
	assert_signal_emit_count(box, "seasoned", 1)
	assert_eq(
		order,
		["removed:SEASONING_SWEET_DRESSING", "seasoned:SEASONING_HOT_DRESSING"] as Array[String]
	)


func test_pul114_ac3_same_dressing_is_silent_already_applied() -> void:
	var box: Box = _full_box()
	box.apply_seasoning(SWEET)
	watch_signals(box)
	assert_eq(box.apply_seasoning(SWEET), SeasoningRules.Rejection.ALREADY_APPLIED)
	assert_eq(box.get_contents().seasonings, [SWEET] as Array[SeasoningData])
	assert_signal_emit_count(box, "seasoned", 0)
	assert_signal_emit_count(box, "seasoning_removed", 0)


func test_pul114_ac4_apply_on_unfilled_box_is_rejected() -> void:
	var empty: Box = _box(BOX)
	watch_signals(empty)
	assert_eq(empty.apply_seasoning(SWEET), SeasoningRules.Rejection.BOX_NOT_FULL)
	assert_signal_emit_count(empty, "seasoned", 0)
	var half: Box = _box(BOX)
	_octopus_in_hand(true)
	for i: int in 3:
		half.interact(_actor)
	assert_almost_eq(half.fill, 0.5, 0.0001)
	watch_signals(half)
	assert_eq(half.apply_seasoning(HOT), SeasoningRules.Rejection.BOX_NOT_FULL)
	assert_eq(half.apply_seasoning(CACHELOS), SeasoningRules.Rejection.BOX_NOT_FULL)
	assert_eq(half.get_contents().seasonings.size(), 0)
	assert_signal_emit_count(half, "seasoned", 0)


func test_pul114_cachelos_apply_adds_once_and_remove_takes_it_out() -> void:
	var box: Box = _full_box()
	watch_signals(box)
	assert_eq(box.apply_seasoning(CACHELOS), SeasoningRules.Rejection.NONE)
	assert_true(box.has_seasoning(CACHELOS))
	assert_signal_emit_count(box, "seasoned", 1)
	assert_eq(
		box.apply_seasoning(CACHELOS), SeasoningRules.Rejection.ALREADY_APPLIED, "no se quita"
	)
	assert_true(box.has_seasoning(CACHELOS))
	assert_signal_emit_count(box, "seasoned", 1)
	assert_signal_emit_count(box, "seasoning_removed", 0)
	assert_true(box.remove_seasoning(CACHELOS))
	assert_false(box.has_seasoning(CACHELOS))
	assert_signal_emitted_with_parameters(box, "seasoning_removed", [CACHELOS])
	assert_false(box.has_method(&"toggle_seasoning"), "D26: el cuenco solo pone")


func test_pul114_ac5_contents_have_at_most_two_entries() -> void:
	var box: Box = _full_box()
	assert_eq(box.get_contents().seasonings.size(), 0, "sin nada, 0")
	box.apply_seasoning(HOT)
	assert_eq(box.get_contents().seasonings.size(), 1, "solo aliño, 1")
	box.apply_seasoning(CACHELOS)
	box.apply_seasoning(SWEET)
	box.apply_seasoning(HOT)
	var seasonings: Array[SeasoningData] = box.get_contents().seasonings
	assert_eq(seasonings.size(), 2, "aliño y cachelos, 2")
	assert_eq(seasonings.count(CACHELOS), 1)
	for seasoning: SeasoningData in seasonings:
		assert_true(
			seasoning.same_as(CACHELOS) or seasoning.exclusivity_group == &"dressing",
			"nunca sal, aceite ni pimentón sueltos"
		)


func test_pul057_ac2_remove_seasoning() -> void:
	var box: Box = _full_box()
	box.apply_seasoning(SWEET)
	box.apply_seasoning(CACHELOS)
	watch_signals(box)
	assert_true(box.remove_seasoning(SWEET))
	assert_eq(box.get_contents().seasonings, [CACHELOS] as Array[SeasoningData])
	assert_signal_emitted_with_parameters(box, "seasoning_removed", [SWEET])
	assert_false(box.remove_seasoning(SWEET), "ya no la lleva")
	assert_false(box.remove_seasoning(null))
	assert_signal_emit_count(box, "seasoning_removed", 1)
	assert_signal_emit_count(box, "seasoned", 0)


## PUL-104 AC2: dos cajas gastan exactamente un pulpo (sin residuo) y lo liberan.
func test_pul104_ac2_two_boxes_spend_exactly_one_octopus() -> void:
	var octopus: Ingredient = _octopus_in_hand(true)
	var spent: float = 0.0
	for i: int in 2:
		var box: Box = _box(BOX)
		var before: float = octopus.remaining
		_fill(box)
		spent += before - octopus.remaining
	assert_almost_eq(spent, 100.0, 0.00001, "gasto total exacto")
	assert_true(octopus.is_queued_for_deletion())


## PUL-104: si cambia `data` a mitad de llenado, la caja sigue llenando sin pasarse y el gasto
## total es el de una caja.
func test_pul104_resync_presses_when_data_changes() -> void:
	var box: Box = _box(BOX)
	var longer: BoxData = BoxData.new()
	longer.presses_to_fill = 10
	var octopus: Ingredient = _octopus_in_hand(true)
	assert_true(box.interact(_actor))
	box.data = longer
	var presses: int = 1
	while not box.is_full() and presses < 20:
		assert_true(box.interact(_actor))
		presses += 1
	assert_true(box.is_full())
	assert_eq(box.fill, 1.0)
	assert_eq(presses, 10, "no repite lo ya llenado")
	assert_almost_eq(octopus.remaining, 50.0, 0.001, "gasta una caja entera")
