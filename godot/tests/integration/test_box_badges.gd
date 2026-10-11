extends GutTest
## PUL-059/114 (estacion-condimentos AC14, D25): la fila de pegatinas de la caja sigue el orden
## canónico (aliño → cachelos), se rehace al aplicar o sustituir y marca el picante con la llama.

const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const SMALL: BoxData = preload("res://data/boxes/box.tres")
const SWEET: SeasoningData = preload("res://data/seasonings/sweet_dressing.tres")
const HOT: SeasoningData = preload("res://data/seasonings/hot_dressing.tres")
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


func _apply(seasoning: SeasoningData) -> void:
	assert_eq(_box.apply_seasoning(seasoning), SeasoningRules.Rejection.NONE)


func test_ac14_canonical_order_and_hot_mark_in_either_application_order() -> void:
	for applied: Array in [[HOT, CACHELOS], [CACHELOS, HOT]]:
		_box.remove_seasoning(HOT)
		_box.remove_seasoning(CACHELOS)
		for seasoning: SeasoningData in applied:
			_apply(seasoning)
		assert_eq(
			_types(_row.get_shown()),
			(
				[SeasoningData.SeasoningType.HOT_DRESSING, SeasoningData.SeasoningType.CACHELOS]
				as Array[int]
			)
		)
		assert_true(_row.visible)
		assert_eq(_row.get_child_count(), 2, "exactamente 2 iconos")
		assert_eq(_hot_marks(), 1, "solo el aliño picante lleva llama")


func test_sweet_dressing_has_no_hot_mark() -> void:
	_apply(SWEET)
	assert_eq(_row.get_child_count(), 1)
	assert_eq(_hot_marks(), 0)


func test_removing_cachelos_removes_badge_and_compacts() -> void:
	_apply(SWEET)
	_apply(CACHELOS)
	assert_eq(_row.get_child_count(), 2)
	assert_true(_box.remove_seasoning(CACHELOS), "D26: el cuenco no quita; la caja sí puede")
	assert_eq(_types(_row.get_shown()), [SeasoningData.SeasoningType.SWEET_DRESSING] as Array[int])
	_box.remove_seasoning(SWEET)
	assert_eq(_row.get_shown().size(), 0)
	assert_false(_row.visible)


func test_dressing_swap_replaces_badge() -> void:
	_apply(SWEET)
	_apply(HOT)
	assert_eq(_types(_row.get_shown()), [SeasoningData.SeasoningType.HOT_DRESSING] as Array[int])
	assert_eq(_row.get_child_count(), 1, "nunca dos aliños")
	assert_eq(_hot_marks(), 1)


func test_badges_use_style_size_and_seasoning_color() -> void:
	_apply(SWEET)
	var disc: Sprite3D = _row.get_child(0).get_child(0) as Sprite3D
	assert_eq(disc.modulate, SWEET.color)
	assert_true(disc.no_depth_test)
	assert_eq(disc.billboard, BaseMaterial3D.BILLBOARD_ENABLED)
	var side: float = disc.pixel_size * disc.texture.get_width()
	assert_almost_eq(side, 24.0 * 12.74 / 720.0, 0.001)


func _tilted_camera() -> Camera3D:
	var camera: Camera3D = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.74
	add_child_autofree(camera)
	camera.rotation_degrees = Vector3(-45, 45, 0)
	camera.position = camera.basis.z * 20.0
	camera.current = true
	return camera


func test_row_keeps_a_screen_gap_above_the_box() -> void:
	_tilted_camera()
	_apply(SWEET)
	for height: float in [0.0, 1.0]:
		_box.global_position = Vector3(0, height, 0)
		_row._follow()
		var gap: float = _box_top_y() - _row.get_bottom_screen_y()
		assert_gte(gap, 6.0, "hueco en pantalla con la caja a %s m" % height)


func test_row_rebuilds_when_camera_size_changes() -> void:
	var camera: Camera3D = _tilted_camera()
	_apply(SWEET)
	var disc: Sprite3D = _row.get_child(0).get_child(0) as Sprite3D
	var before: float = disc.pixel_size
	camera.size = 6.37
	_row._process(0.0)
	disc = _row.get_child(0).get_child(0) as Sprite3D
	assert_almost_eq(disc.pixel_size, before / 2.0, before * 0.01)


func _box_top_y() -> float:
	return _row.get_box_top_screen_y()


## PUL-126 AC5 (D26.7): la pegatina lleva el icono propio de cada aliño y la marca del picante es la
## guindilla del verbo, la misma que ve el dispensador y el ticket.
func test_pul126_badges_use_each_dressings_own_icon_and_the_hot_mark_is_the_chilli() -> void:
	var style: BoxBadgeStyle = load("res://data/config/box_badges.tres") as BoxBadgeStyle
	var dir: String = "res://assets/textures/ui/actions/"
	assert_eq(SWEET.icon.resource_path, dir + "icon_verb_season_sweet.svg")
	assert_eq(HOT.icon.resource_path, dir + "icon_verb_season_hot.svg")
	assert_eq(style.hot_mark.resource_path, dir + "icon_verb_season_hot.svg")
	_apply(HOT)
	var badge: Node = _row.get_child(0)
	var icon: Sprite3D = badge.get_child(1) as Sprite3D
	var mark: Sprite3D = badge.get_child(2) as Sprite3D
	assert_eq(icon.texture, HOT.icon, "la pegatina pinta el icono del aliño")
	assert_eq(mark.texture, style.hot_mark, "y el picante, su marca")
	_box.remove_seasoning(HOT)
	_apply(SWEET)
	assert_eq(_row.get_child(0).get_child(1).texture, SWEET.icon)
	assert_ne(_row.get_child(0).get_child(1).texture, HOT.icon, "dulce y picante distinguibles")
	assert_eq(_hot_marks(), 0)
