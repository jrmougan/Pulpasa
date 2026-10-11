extends GutTest
## PUL-130 AC: seguimiento móvil del personaje activo, paneo al cambiar, límites del nivel y flecha
## de borde del inactivo (ADR-005 E5, `controles-tactiles.md`). La cámara se mide en un SubViewport
## de 2340 × 1080 con el perfil móvil.

const RIG_SCENE: PackedScene = preload("res://entities/camera/camera_rig.tscn")
const MOBILE: CameraProfile = preload("res://data/config/camera_mobile.tres")
const UI_MOBILE: UiProfile = preload("res://data/config/ui_profile_mobile.tres")
const EventBusScript: GDScript = preload("res://autoload/event_bus.gd")
const DT: float = 1.0 / 60.0
const CANVAS: Vector2i = Vector2i(2340, 1080)

var _viewport: SubViewport
var _rig: CameraRig
var _bus: Node
var _a: Node3D
var _b: Node3D


func before_each() -> void:
	_viewport = SubViewport.new()
	_viewport.size = CANVAS
	add_child_autofree(_viewport)
	_bus = autofree(EventBusScript.new())
	_rig = RIG_SCENE.instantiate()
	_rig.set_bus(_bus)
	_rig.ui_profile = UI_MOBILE
	_viewport.add_child(_rig)
	_a = _character(Vector3(0.0, 0.005, 0.0))
	_b = _character(Vector3(-4.3, 0.005, -2.0))
	_rig.characters = [_a, _b]
	_rig.set_profile(MOBILE)
	_run(0.1)


func _character(at: Vector3) -> Node3D:
	var node: Node3D = autofree(Node3D.new())
	_viewport.add_child(node)
	node.global_position = at
	return node


func _run(seconds: float) -> void:
	for i: int in int(seconds / DT):
		_rig.step(DT)


func _screen_fraction(node: Node3D) -> Vector2:
	var p: Vector2 = _rig.unproject_position(node.global_position + Vector3.UP * 0.8)
	return p / Vector2(CANVAS)


func _arrow_layer() -> CanvasLayer:
	return _rig.get_node(^"%OffscreenArrow") as CanvasLayer


func _arrow() -> TextureRect:
	return _rig.get_node(^"%Arrow") as TextureRect


func test_active_character_stays_in_central_sixty_percent() -> void:
	for at: Vector3 in [Vector3(0.0, 0.0, 0.0), Vector3(1.5, 0.0, 1.0), Vector3(-0.5, 0.0, -1.0)]:
		_a.global_position = at
		_run(1.5)
		var f: Vector2 = _screen_fraction(_a)
		assert_between(f.x, 0.2, 0.8, "x en el 60 %% central: %s" % at)
		assert_between(f.y, 0.2, 0.8, "y en el 60 %% central: %s" % at)


func test_no_oscillation_at_rest() -> void:
	_run(2.0)
	var start: Vector3 = _rig.global_position
	var worst: float = 0.0
	for i: int in 240:
		_rig.step(DT)
		worst = maxf(worst, _rig.global_position.distance_to(start))
	assert_lt(worst, 0.05, "quieto: la cámara no se mueve más de 0,05 m")


func test_follows_walking_character_smoothly() -> void:
	_run(1.0)
	var before: Vector3 = _rig.global_position
	var last_x: float = before.x
	for i: int in 60:
		_a.global_position.x += 5.0 * DT * 0.2
		_rig.step(DT)
		assert_gte(_rig.global_position.x, last_x - 0.0001, "no retrocede")
		last_x = _rig.global_position.x
	assert_gt(_rig.global_position.x, before.x, "la cámara avanza con el personaje")


func test_view_never_leaves_level_margin() -> void:
	var half: Vector2 = _rig.view_half_extents()
	for at: Vector3 in [
		Vector3(80.0, 0.0, 80.0), Vector3(-80.0, 0.0, -80.0), Vector3(9.4, 0.0, 6.6)
	]:
		_a.global_position = at
		_run(3.0)
		var f: Vector2 = _rig.get_focus()
		assert_gte(f.x - half.x, MOBILE.play_area_min.x - MOBILE.camera_margin_m - 0.01)
		assert_lte(f.x + half.x, MOBILE.play_area_max.x + MOBILE.camera_margin_m + 0.01)
		assert_gte(f.y - half.y, MOBILE.play_area_min.y - MOBILE.camera_margin_m - 0.01)
		assert_lte(f.y + half.y, MOBILE.play_area_max.y + MOBILE.camera_margin_m + 0.01)


func test_switch_pans_to_new_character_in_pan_time() -> void:
	_run(1.0)
	_bus.character_switched.emit(1, 2)
	assert_eq(_rig.get_active_index(), 1)
	var start: Vector2 = _rig.get_focus()
	_run(0.1)
	assert_lt(_rig.get_focus().distance_to(start), 4.0, "no salta de golpe")
	assert_gt(_rig.get_focus().distance_to(start), 0.1, "ya se mueve")
	_run(0.3)
	var target: Vector2 = CameraFollow.clamp_focus(
		Vector2(_b.global_position.x, _b.global_position.z),
		_rig.view_half_extents(),
		MOBILE.play_area_min,
		MOBILE.play_area_max,
		MOBILE.camera_margin_m
	)
	assert_lt(_rig.get_focus().distance_to(target), 0.05, "a los 0,4 s centrada en el nuevo activo")


func test_other_player_switch_is_ignored() -> void:
	_bus.character_switched.emit(2, 2)
	assert_eq(_rig.get_active_index(), 0)


func test_arrow_hidden_when_inactive_is_on_screen() -> void:
	_b.global_position = _a.global_position + Vector3(1.0, 0.0, 0.0)
	_run(0.5)
	assert_false(_arrow_layer().visible)


func test_arrow_points_to_offscreen_inactive_inside_safe_area() -> void:
	_rig.set_safe_margins(Vector4(132.0, 0.0, 132.0, 63.0))
	_a.global_position = Vector3(5.0, 0.0, 3.0)
	_b.global_position = Vector3(-6.5, 0.0, -4.0)
	_run(1.5)
	assert_true(_arrow_layer().visible, "inactivo fuera de cuadro: flecha")
	var arrow: TextureRect = _arrow()
	assert_almost_eq(arrow.size.x, 48.0, 0.01, "48 px a 1080 de alto")
	var center: Vector2 = arrow.position + arrow.size * 0.5
	assert_gte(center.x - 24.0, 132.0 - 0.01, "dentro de la safe area (izq)")
	assert_lte(center.x + 24.0, 2340.0 - 132.0 + 0.01, "dentro de la safe area (der)")
	assert_lte(center.y + 24.0, 1080.0 - 63.0 + 0.01, "dentro de la safe area (inf)")
	assert_lt(center.x, 600.0, "señala a la izquierda (el inactivo está al oeste)")
	assert_gt(absf(arrow.rotation), PI / 2.0, "el chevron apunta hacia la izquierda")


func test_arrow_keeps_16px_from_button_zone() -> void:
	_rig.set_safe_margins(Vector4(132.0, 0.0, 132.0, 63.0))
	_a.global_position = Vector3(-4.0, 0.0, -4.0)
	_b.global_position = Vector3(9.4, 0.0, 6.6)
	_run(1.5)
	assert_true(_arrow_layer().visible)
	var arrow: TextureRect = _arrow()
	var zone: Rect2 = Rect2(Vector2(2340.0 - 390.0, 600.0), Vector2(390.0, 480.0)).grow(16.0)
	assert_false(Rect2(arrow.position, arrow.size).intersects(zone), "a >= 16 px de los botones")


func test_arrow_follows_active_switch() -> void:
	_a.global_position = Vector3(9.0, 0.0, 6.0)
	_b.global_position = Vector3(-6.5, 0.0, -4.0)
	_run(1.5)
	assert_true(_arrow_layer().visible)
	_bus.character_switched.emit(1, 2)
	_run(1.5)
	var target: Vector2 = CameraFollow.clamp_focus(
		Vector2(_b.global_position.x, _b.global_position.z),
		_rig.view_half_extents(),
		MOBILE.play_area_min,
		MOBILE.play_area_max,
		MOBILE.camera_margin_m
	)
	assert_lt(_rig.get_focus().distance_to(target), 0.05, "la cámara sigue al nuevo activo")
	assert_true(_arrow_layer().visible, "el inactivo ahora es A, que sigue fuera de cuadro")
