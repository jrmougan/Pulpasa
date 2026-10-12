extends GutTest
## PUL-128 AC2/AC3 (controles-tactiles AC2, AC3, AC17, AC21) y PUL-138 B-AC1 (D27.1): maquetación
## de los controles táctiles con la safe area simulada, sin safe area y en el perfil de escritorio.
## Las medidas son px de pantalla: unidades de lienzo por la escala final del viewport.

const SCENE: PackedScene = preload("res://ui/touch/touch_controls.tscn")
const SAFE_2340: Rect2 = Rect2(132.0, 0.0, 2076.0, 1017.0)

var _original_size: Vector2i
var _controls: TouchControls


func before_each() -> void:
	_original_size = get_window().size
	GameState.set_platform(PlatformProfile.Kind.MOBILE)
	GameState.mode = GameMode.Mode.SINGLE


func after_each() -> void:
	get_window().size = _original_size
	GameState.set_platform(PlatformProfile.Kind.DESKTOP)


func _open(resolution: Vector2i, safe: Rect2 = Rect2()) -> void:
	get_window().size = resolution
	await wait_process_frames(3)
	_controls = SCENE.instantiate()
	add_child_autofree(_controls)
	await wait_process_frames(2)
	_controls.apply_safe_rect(safe, Vector2(resolution))
	await wait_process_frames(2)


func _scale() -> float:
	return get_viewport().get_final_transform().get_scale().y


## Centro del control en px de pantalla.
func _center(button: Control) -> Vector2:
	return (button.global_position + button.size / 2.0) * _scale()


func _diameter(button: Control) -> float:
	return button.size.x * _scale()


func _action() -> ActionButton:
	return _controls.get_node(^"%ActionButton") as ActionButton


func _switch() -> TouchButton:
	return _controls.get_node(^"%SwitchButton") as TouchButton


func _pause() -> TouchButton:
	return _controls.get_node(^"%PauseButton") as TouchButton


func test_ac2_action_button_size_and_position_with_safe_area() -> void:
	await _open(Vector2i(2340, 1080), SAFE_2340)
	var button: ActionButton = _action()
	assert_almost_eq(_diameter(button), 180.0, 2.0)
	assert_gte(button.get_hit_radius() * 2.0 * _scale(), 204.0 - 2.0, "zona táctil >= 204 px")
	var center: Vector2 = _center(button)
	assert_almost_eq(center.x, 2070.0, 2.0)
	assert_almost_eq(center.y, 879.0, 2.0)


func test_ac2_action_button_keeps_48_px_to_the_safe_area_edges() -> void:
	await _open(Vector2i(2340, 1080), SAFE_2340)
	var center: Vector2 = _center(_action())
	var radius: float = 90.0
	assert_gte(SAFE_2340.end.x - (center.x + radius), 48.0 - 2.0)
	assert_gte(SAFE_2340.end.y - (center.y + radius), 48.0 - 2.0)


func test_ac2_action_button_without_safe_area_at_1920() -> void:
	await _open(Vector2i(1920, 1080))
	var center: Vector2 = _center(_action())
	assert_almost_eq(center.x, 1782.0, 2.0)
	assert_almost_eq(center.y, 942.0, 2.0)


## B-AC1 (D27.1): cambiar a la izquierda de acción, bordes inferiores alineados, 24 px de hueco.
func test_bac1_switch_button_sits_left_of_the_action_button_in_a_row() -> void:
	await _open(Vector2i(2340, 1080))
	assert_almost_eq(_diameter(_switch()), 120.0, 2.0)
	var center: Vector2 = _center(_switch())
	assert_almost_eq(center.x, 2028.0, 2.0)
	assert_almost_eq(center.y, 972.0, 2.0)
	assert_almost_eq(center.y + 60.0, _center(_action()).y + 90.0, 2.0, "bordes inferiores")
	var switch_right: float = center.x + 60.0
	var action_left: float = _center(_action()).x - 90.0
	assert_almost_eq(action_left - switch_right, 24.0, 2.0)


func test_bac1_switch_button_row_with_the_design_safe_area() -> void:
	await _open(Vector2i(2340, 1080), SAFE_2340)
	var center: Vector2 = _center(_switch())
	assert_almost_eq(center.x, 1896.0, 2.0)
	assert_almost_eq(center.y, 909.0, 2.0)


func test_ac3_pause_button_is_120_px_in_the_top_right_corner() -> void:
	await _open(Vector2i(2340, 1080), SAFE_2340)
	assert_almost_eq(_diameter(_pause()), 120.0, 2.0)
	var center: Vector2 = _center(_pause())
	assert_almost_eq(center.x, 2100.0, 2.0)
	assert_almost_eq(center.y, 108.0, 2.0)


func test_ac3_no_two_touch_zones_overlap() -> void:
	await _open(Vector2i(2340, 1080), SAFE_2340)
	var buttons: Array[TouchButton] = [_action(), _switch(), _pause()]
	for i: int in buttons.size():
		for j: int in range(i + 1, buttons.size()):
			var distance: float = buttons[i].get_center().distance_to(buttons[j].get_center())
			var reach: float = buttons[i].get_hit_radius() + buttons[j].get_hit_radius()
			assert_gt(distance, reach, "%s y %s" % [buttons[i].name, buttons[j].name])


func test_ac17_no_button_enters_the_excluded_margins() -> void:
	await _open(Vector2i(2340, 1080), SAFE_2340)
	for button: TouchButton in [_action(), _switch(), _pause()]:
		var center: Vector2 = _center(button)
		var radius: float = _diameter(button) / 2.0
		assert_gte(center.x - radius - SAFE_2340.position.x, 48.0 - 2.0, button.name)
		assert_gte(SAFE_2340.end.x - (center.x + radius), 48.0 - 2.0, button.name)
		assert_gte(center.y - radius - SAFE_2340.position.y, 48.0 - 2.0, button.name)
		assert_gte(SAFE_2340.end.y - (center.y + radius), 0.0, button.name)


func test_ac17_null_safe_area_anchors_to_the_edges_with_48_px() -> void:
	await _open(Vector2i(1920, 1080))
	assert_almost_eq(1920.0 - (_center(_action()).x + 90.0), 48.0, 2.0)
	assert_almost_eq(1920.0 - (_center(_pause()).x + 60.0), 48.0, 2.0)
	assert_almost_eq(_center(_pause()).y - 60.0, 48.0, 2.0)


func test_layout_scales_with_the_height_at_720() -> void:
	await _open(Vector2i(1600, 720))
	assert_almost_eq(_diameter(_action()), 120.0, 2.0)
	assert_almost_eq(_diameter(_switch()), 80.0, 2.0)
	var switch_right: float = _center(_switch()).x + 40.0
	assert_almost_eq(_center(_action()).x - 60.0 - switch_right, 16.0, 2.0)
	assert_almost_eq(_center(_switch()).y + 40.0, _center(_action()).y + 60.0, 2.0)


func test_stick_zone_is_the_left_half_below_the_top_band() -> void:
	await _open(Vector2i(2340, 1080), SAFE_2340)
	var zone: Rect2 = _controls.get_stick_zone()
	assert_almost_eq(zone.position.y * _scale(), 200.0, 1.0)
	assert_almost_eq(zone.end.x * _scale(), 1170.0, 1.0)
	assert_almost_eq(zone.end.y * _scale(), 1080.0, 1.0)


func test_layout_follows_a_window_resize() -> void:
	await _open(Vector2i(2340, 1080), SAFE_2340)
	get_window().size = Vector2i(1920, 1080)
	await wait_process_frames(3)
	_controls.apply_safe_rect(Rect2(), Vector2(1920.0, 1080.0))
	await wait_process_frames(2)
	assert_almost_eq(_center(_action()).x, 1782.0, 2.0)


func test_ac21_desktop_profile_frees_the_controls() -> void:
	GameState.set_platform(PlatformProfile.Kind.DESKTOP)
	_controls = SCENE.instantiate()
	add_child_autofree(_controls)
	await wait_process_frames(2)
	assert_false(is_instance_valid(_controls) and not _controls.is_queued_for_deletion())


func test_ac21_desktop_profile_leaves_no_touch_nodes_in_the_tree() -> void:
	GameState.set_platform(PlatformProfile.Kind.DESKTOP)
	_controls = SCENE.instantiate()
	add_child_autofree(_controls)
	await wait_process_frames(3)
	assert_eq(get_tree().root.find_children("*", "TouchControls", true, false).size(), 0)


## Zona de botones anclada a la esquina inferior derecha de la safe area (D27.2), en px a 1080.
func _assert_touch_rects_in_button_zone(screen: Vector2, safe: Rect2) -> void:
	var profile: UiProfile = GameState.ui_profile
	var scale: float = _scale()
	var right: float = 0.0 if safe.size == Vector2.ZERO else screen.x - safe.end.x
	var bottom: float = 0.0 if safe.size == Vector2.ZERO else screen.y - safe.end.y
	var left: float = screen.x - right - profile.button_zone_width_px
	var top: float = screen.y - bottom - profile.button_zone_height_px
	for button: TouchButton in [_action(), _switch()]:
		var center: Vector2 = _center(button)
		var reach: float = button.get_hit_radius() * scale
		assert_gte(center.x - reach, left - 1.0, button.name)
		assert_gte(center.y - reach, top - 1.0, button.name)
		assert_lte(center.x + reach, screen.x + 1.0, button.name)
		assert_lte(center.y + reach, screen.y + 1.0, button.name)


func test_touch_rects_stay_inside_the_ui_profile_button_zone_at_2340() -> void:
	await _open(Vector2i(2340, 1080), SAFE_2340)
	_assert_touch_rects_in_button_zone(Vector2(2340.0, 1080.0), SAFE_2340)


func test_touch_rects_stay_inside_the_ui_profile_button_zone_at_2340_null_safe() -> void:
	await _open(Vector2i(2340, 1080))
	_assert_touch_rects_in_button_zone(Vector2(2340.0, 1080.0), Rect2())


func test_touch_rects_stay_inside_the_ui_profile_button_zone_at_1920() -> void:
	await _open(Vector2i(1920, 1080))
	_assert_touch_rects_in_button_zone(Vector2(1920.0, 1080.0), Rect2())


func test_content_node_is_top_level_in_the_scene() -> void:
	await _open(Vector2i(2340, 1080), SAFE_2340)
	assert_true((_controls.get_node(^"%Content") as Control).top_level)
