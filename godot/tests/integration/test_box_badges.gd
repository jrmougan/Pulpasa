extends GutTest
## PUL-059 (estacion-condimentos AC13): la fila de pegatinas de la caja sigue el orden canónico,
## se rehace al alternar condimentos y marca el picante con la llama.

const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const SMALL: BoxData = preload("res://data/boxes/small.tres")
const SALT: SeasoningData = preload("res://data/seasonings/salt.tres")
const PAPRIKA: SeasoningData = preload("res://data/seasonings/paprika.tres")
const HOT_PAPRIKA: SeasoningData = preload("res://data/seasonings/hot_paprika.tres")
const OIL: SeasoningData = preload("res://data/seasonings/oil.tres")
const CACHELOS: SeasoningData = preload("res://data/seasonings/cachelos.tres")

var _box: Box
var _row: BadgeRow


func before_each() -> void:
	_box = BOX_SCENE.instantiate()
	_box.data = SMALL
	add_child_autofree(_box)
	_box.fill = 1.0
	_row = _box.get_node("%BadgeRow") as BadgeRow


func _types(list: Array[SeasoningData]) -> Array[int]:
	var types: Array[int] = []
	for seasoning: SeasoningData in list:
		types.append(seasoning.type)
	return types


func _hot_marks() -> int:
	var count: int = 0
	for badge: Node in _row.get_children():
		count += badge.get_child_count() - 2
	return count


func test_no_seasonings_hides_the_row() -> void:
	assert_eq(_row.get_shown().size(), 0)
	assert_false(_row.visible)


func test_ac13_canonical_order_and_hot_mark() -> void:
	for seasoning: SeasoningData in [CACHELOS, OIL, SALT, HOT_PAPRIKA]:
		assert_eq(_box.toggle_seasoning(seasoning, true), SeasoningRules.Rejection.NONE)
	assert_eq(
		_types(_row.get_shown()),
		(
			[
				SeasoningData.SeasoningType.HOT_PAPRIKA,
				SeasoningData.SeasoningType.SALT,
				SeasoningData.SeasoningType.OIL,
				SeasoningData.SeasoningType.CACHELOS,
			]
			as Array[int]
		)
	)
	assert_true(_row.visible)
	assert_eq(_row.get_child_count(), 4)
	assert_eq(_hot_marks(), 1, "solo el picante lleva llama")


func test_sweet_paprika_has_no_hot_mark() -> void:
	_box.toggle_seasoning(PAPRIKA, true)
	assert_eq(_row.get_child_count(), 1)
	assert_eq(_hot_marks(), 0)


func test_toggle_off_removes_badge_and_compacts() -> void:
	_box.toggle_seasoning(SALT, true)
	_box.toggle_seasoning(OIL, true)
	_box.toggle_seasoning(SALT, true)
	assert_eq(_types(_row.get_shown()), [SeasoningData.SeasoningType.OIL] as Array[int])
	_box.remove_seasoning(OIL)
	assert_eq(_row.get_shown().size(), 0)
	assert_false(_row.visible)


func test_paprika_swap_replaces_badge() -> void:
	_box.toggle_seasoning(PAPRIKA, true)
	_box.toggle_seasoning(HOT_PAPRIKA, true)
	assert_eq(_types(_row.get_shown()), [SeasoningData.SeasoningType.HOT_PAPRIKA] as Array[int])
	assert_eq(_hot_marks(), 1)


func test_badges_use_style_size_and_seasoning_color() -> void:
	_box.toggle_seasoning(SALT, true)
	var disc: Sprite3D = _row.get_child(0).get_child(0) as Sprite3D
	assert_eq(disc.modulate, SALT.color)
	assert_true(disc.no_depth_test)
	assert_eq(disc.billboard, BaseMaterial3D.BILLBOARD_ENABLED)
	var side: float = disc.pixel_size * disc.texture.get_width()
	assert_almost_eq(side, 24.0 * 12.74 / 720.0, 0.001)
