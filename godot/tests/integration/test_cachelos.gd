extends GutTest

const KITCHEN_SCENE: PackedScene = preload("res://entities/stations/kitchen.tscn")
const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const CACHELOS_SCENE: PackedScene = preload("res://entities/items/cachelos.tscn")
const STATION_SCENE: PackedScene = preload("res://entities/stations/seasoning_station.tscn")
const SMALL_BOX: Resource = preload("res://data/boxes/box.tres")
const CACHELOS_DATA: SeasoningData = preload("res://data/seasonings/cachelos.tres")
const SWEET_DATA: SeasoningData = preload("res://data/seasonings/sweet_dressing.tres")

const STEP: float = 0.1
const INTERACTABLE_LAYER: int = 1 << 2

var _level: Node3D
var _hold: HoldComponent
var _actor: InteractionComponent
var _kitchen: CookingStation
var _rejections: Array[SeasoningRules.Rejection] = []


func before_each() -> void:
	_level = add_child_autofree(Node3D.new())
	var player: Player = PLAYER_SCENE.instantiate()
	_level.add_child(player)
	_hold = player.get_node("%HoldComponent")
	_hold.items_root = _level
	_actor = player.get_node("%InteractionComponent")
	_kitchen = KITCHEN_SCENE.instantiate()
	_level.add_child(_kitchen)


func after_each() -> void:
	get_tree().paused = false


func _cook_for(seconds: float) -> void:
	simulate(_kitchen, roundi(seconds / STEP), STEP)


func test_ac2_cachelo_raw_to_pot_to_cooked() -> void:
	var cachelo: Ingredient = CACHELOS_SCENE.instantiate()
	_level.add_child(cachelo)
	_hold.pick_up(cachelo)

	_kitchen.interact(_actor)
	assert_true(_kitchen.is_cooking())
	assert_null(_hold.get_held_item())

	_cook_for(5.0)
	assert_true(cachelo.is_cooked())


## PUL-061 (AC12 de la estación): los cachelos cocidos ya no se echan sobre la caja; van al cuenco
## de la estación. La caja llena consume la pulsación sin cambiar y los cachelos siguen en la mano.
func test_ac2_cachelo_cooked_no_longer_seasons_a_full_box() -> void:
	var cachelo: Ingredient = CACHELOS_SCENE.instantiate()
	_level.add_child(cachelo)
	cachelo.set_cooked()
	_hold.pick_up(cachelo)

	var box: Box = BOX_SCENE.instantiate()
	_level.add_child(box)
	box.data = SMALL_BOX
	box.fill = 1.0  # full

	assert_false(box.can_interact(_actor))
	assert_false(box.interact(_actor))

	assert_eq(box.get_contents().seasonings.size(), 0)
	assert_eq(_hold.get_held_item(), cachelo)
	assert_true(is_instance_valid(cachelo) and not cachelo.is_queued_for_deletion())


func test_ac2_cachelo_raw_rejected_by_box() -> void:
	var cachelo: Ingredient = CACHELOS_SCENE.instantiate()
	_level.add_child(cachelo)
	_hold.pick_up(cachelo)

	var box: Box = BOX_SCENE.instantiate()
	_level.add_child(box)
	box.data = SMALL_BOX
	box.fill = 1.0  # full

	box.interact(_actor)

	var contents := box.get_contents()
	assert_eq(contents.seasonings.size(), 0)
	assert_eq(_hold.get_held_item(), cachelo)


## Aliño y cachelos caben a la vez con la API de la estación (`apply_seasoning`, D26: el cuenco ya
## no usa `toggle_seasoning`).
func test_ac3_dressing_and_cachelos() -> void:
	var box: Box = BOX_SCENE.instantiate()
	_level.add_child(box)
	box.data = SMALL_BOX
	box.fill = 1.0  # full
	var dressing: SeasoningData = SWEET_DATA
	var cachelos: SeasoningData = CACHELOS_DATA
	assert_eq(box.apply_seasoning(dressing), SeasoningRules.Rejection.NONE)
	assert_eq(box.apply_seasoning(cachelos), SeasoningRules.Rejection.NONE)

	var contents := box.get_contents()
	assert_eq(contents.seasonings.size(), 2)


## PUL-046: una malla por estado (cachelos_raw / cachelos_cooked) con los colores de la paleta
## (art-bible §3.3); sustituye a la prueba de cambio de material del placeholder (PUL-033).
func test_pul046_state_meshes_and_palette() -> void:
	var cachelo: Ingredient = CACHELOS_SCENE.instantiate()
	_level.add_child(cachelo)
	var raw: MeshInstance3D = cachelo.get_node("Model").find_child("cachelos_raw") as MeshInstance3D
	var cooked: MeshInstance3D = (
		cachelo.get_node("Model").find_child("cachelos_cooked") as MeshInstance3D
	)
	assert_not_null(raw)
	assert_not_null(cooked)
	assert_true(raw.visible, "en crudo se ve la patata entera")
	assert_false(cooked.visible)
	cachelo.set_cooked()
	assert_false(raw.visible)
	assert_true(cooked.visible, "al cocerse se ven los trozos")
	assert_has(_material_names(raw), "mat_potato_raw")
	assert_has(_material_names(cooked), "mat_cachelos_cooked")
	assert_does_not_have(_material_names(cooked), "mat_potato_raw")
	var raw_color: Color = _albedo(raw, "mat_potato_raw")
	var cooked_color: Color = _albedo(cooked, "mat_cachelos_cooked")
	assert_gt(cooked_color.get_luminance() - raw_color.get_luminance(), 0.3, "luminosidad")


func _material_names(mesh: MeshInstance3D) -> Array[String]:
	var names: Array[String] = []
	for i: int in mesh.get_surface_override_material_count():
		names.append(mesh.get_active_material(i).resource_name)
	return names


func _albedo(mesh: MeshInstance3D, material_name: String) -> Color:
	for i: int in mesh.get_surface_override_material_count():
		var material: BaseMaterial3D = mesh.get_active_material(i) as BaseMaterial3D
		if material != null and material.resource_name == material_name:
			return material.albedo_color
	return Color.BLACK


## PUL-097 (R6): los cachelos cocidos en la olla van al cuenco de la estación: 2 raciones cada uno.
func test_pul097_cooked_cachelo_from_the_pot_gives_two_portions_to_the_bowl() -> void:
	var station: SeasoningStation = STATION_SCENE.instantiate()
	station.position = Vector3(0.0, 0.0, 10.0)
	_level.add_child(station)
	var bowl: CachelosBowl = station.get_node("CachelosBowl")
	var cachelo: Ingredient = CACHELOS_SCENE.instantiate()
	_level.add_child(cachelo)
	_hold.pick_up(cachelo)
	_kitchen.interact(_actor)
	_cook_for(5.0)
	assert_true(cachelo.is_cooked())
	_kitchen.interact(_actor)
	assert_eq(_hold.get_held_item(), cachelo, "cachelo cocido en la mano")

	assert_true(bowl.interact(_actor))
	assert_eq(bowl.stock, 2)
	assert_null(_hold.get_held_item())


# --- PUL-126 AC2 (D26): el cuenco solo pone ---


func _bowl_with(stock: int) -> CachelosBowl:
	var station: SeasoningStation = STATION_SCENE.instantiate()
	station.position = Vector3(0.0, 0.0, 10.0)
	_level.add_child(station)
	var bowl: CachelosBowl = station.get_node("CachelosBowl")
	bowl.stock = stock
	_rejections.clear()
	bowl.rejected.connect(
		func(reason: SeasoningRules.Rejection) -> void: _rejections.append(reason)
	)
	return bowl


func _hold_box(fill: float, with_cachelos: bool = false) -> Box:
	var box: Box = BOX_SCENE.instantiate()
	_level.add_child(box)
	box.data = SMALL_BOX
	box.fill = fill
	if with_cachelos:
		assert_eq(box.apply_seasoning(CACHELOS_DATA), SeasoningRules.Rejection.NONE)
	assert_true(_hold.pick_up(box))
	return box


func _assert_hint(
	bowl: CachelosBowl, state: ActionHint.State, reason: StringName, message: String
) -> void:
	var hint: ActionHint = bowl.get_action_hint(_actor)
	assert_eq(hint.state, state, "%s: estado" % message)
	assert_eq(hint.reason, reason, "%s: motivo" % message)
	if state != ActionHint.State.NONE:
		assert_eq(hint.verb, ActionVerb.CACHELOS, "%s: verbo" % message)


func test_pul126_ac2_bowl_puts_cachelos_on_a_full_box_and_spends_a_portion() -> void:
	var bowl: CachelosBowl = _bowl_with(2)
	var box: Box = _hold_box(1.0)
	_assert_hint(bowl, ActionHint.State.OK, ActionReason.NONE, "pone")
	assert_true(bowl.interact(_actor))
	assert_true(box.has_seasoning(CACHELOS_DATA))
	assert_eq(bowl.stock, 1, "stock - 1")
	assert_eq(_rejections.size(), 0)
	assert_eq(_hold.get_held_item(), box, "la caja no se suelta")


func test_pul126_ac2_box_that_already_has_cachelos_is_already_applied_even_with_stock_zero(
) -> void:
	for stock: int in [0, 2, 4]:
		var bowl: CachelosBowl = _bowl_with(stock)
		var box: Box = _hold_box(1.0, true)
		_assert_hint(
			bowl, ActionHint.State.BLOCKED, ActionReason.ALREADY_APPLIED, "stock %d" % stock
		)
		assert_true(bowl.interact(_actor), "consume")
		assert_true(box.has_seasoning(CACHELOS_DATA), "stock %d: no quita" % stock)
		assert_eq(bowl.stock, stock, "stock %d: sin cambios" % stock)
		assert_eq(
			_rejections,
			[SeasoningRules.Rejection.ALREADY_APPLIED] as Array[SeasoningRules.Rejection]
		)
		_hold.drop()
		box.queue_free()


func test_pul126_ac2_empty_bowl_blocks_with_empty() -> void:
	var bowl: CachelosBowl = _bowl_with(0)
	var box: Box = _hold_box(1.0)
	box.apply_seasoning(SWEET_DATA)
	_assert_hint(bowl, ActionHint.State.BLOCKED, ActionReason.EMPTY, "vacío")
	assert_true(bowl.interact(_actor))
	assert_false(box.has_seasoning(CACHELOS_DATA))
	assert_eq(_rejections, [SeasoningRules.Rejection.BOWL_EMPTY] as Array[SeasoningRules.Rejection])


func test_pul126_ac2_box_not_full_blocks_with_box_not_full() -> void:
	var bowl: CachelosBowl = _bowl_with(2)
	for fill: float in [0.0, 0.6]:
		_rejections.clear()
		var box: Box = _hold_box(fill)
		_assert_hint(bowl, ActionHint.State.BLOCKED, ActionReason.BOX_NOT_FULL, "fill %s" % fill)
		assert_true(bowl.interact(_actor))
		assert_false(box.has_seasoning(CACHELOS_DATA))
		assert_eq(bowl.stock, 2)
		assert_eq(
			_rejections, [SeasoningRules.Rejection.BOX_NOT_FULL] as Array[SeasoningRules.Rejection]
		)
		_hold.drop()
		box.queue_free()


func test_pul126_ac2_restock_with_three_or_four_portions_blocks_with_full() -> void:
	for stock: int in [3, 4]:
		var bowl: CachelosBowl = _bowl_with(stock)
		var cachelo: Ingredient = CACHELOS_SCENE.instantiate()
		_level.add_child(cachelo)
		cachelo.set_cooked()
		assert_true(_hold.pick_up(cachelo))
		_assert_hint(bowl, ActionHint.State.BLOCKED, ActionReason.FULL, "stock %d" % stock)
		assert_true(bowl.interact(_actor))
		assert_eq(bowl.stock, stock, "stock %d: sin cambios" % stock)
		assert_eq(_hold.get_held_item(), cachelo, "el cachelo sigue en la mano")
		assert_eq(
			_rejections, [SeasoningRules.Rejection.BOWL_FULL] as Array[SeasoningRules.Rejection]
		)
		_hold.drop()
		cachelo.queue_free()


func test_pul126_ac2_restock_with_stock_two_gives_four_and_the_bowl_never_takes_back() -> void:
	var bowl: CachelosBowl = _bowl_with(2)
	var cachelo: Ingredient = CACHELOS_SCENE.instantiate()
	_level.add_child(cachelo)
	cachelo.set_cooked()
	assert_true(_hold.pick_up(cachelo))
	_assert_hint(bowl, ActionHint.State.OK, ActionReason.NONE, "repone")
	assert_true(bowl.interact(_actor))
	assert_eq(bowl.stock, 4)
	var box: Box = _hold_box(1.0, true)
	for i: int in 3:
		assert_true(bowl.interact(_actor), "pulsar con la caja que ya lleva cachelos")
	assert_true(box.has_seasoning(CACHELOS_DATA), "no hay quitar")
	assert_eq(bowl.stock, 4, "ni devolver raciones")
	assert_false(bowl.has_method("_toggle"), "sin rama de quitar")


func test_pul126_ac2_empty_hand_or_other_items_are_not_a_target() -> void:
	var bowl: CachelosBowl = _bowl_with(2)
	_assert_hint(bowl, ActionHint.State.NONE, ActionReason.NONE, "mano vacía")
	assert_false(bowl.interact(_actor))
	var raw: Ingredient = CACHELOS_SCENE.instantiate()
	_level.add_child(raw)
	assert_true(_hold.pick_up(raw))
	_assert_hint(bowl, ActionHint.State.NONE, ActionReason.NONE, "cachelos crudos")
	assert_eq(_rejections.size(), 0)
