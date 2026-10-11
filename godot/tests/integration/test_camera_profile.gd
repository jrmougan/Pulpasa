extends GutTest
## PUL-130 AC: perfiles de cámara por datos (ADR-005 E5). Escritorio idéntico a hoy (12,74, fija,
## 66,8 px/m); móvil con zoom 7,0 y >= 120 px/m a 1080 de alto, medido proyectando pies y cabeza.

const RIG_SCENE: PackedScene = preload("res://entities/camera/camera_rig.tscn")
const DESKTOP: CameraProfile = preload("res://data/config/camera_desktop.tres")
const MOBILE: CameraProfile = preload("res://data/config/camera_mobile.tres")
const EventBusScript: GDScript = preload("res://autoload/event_bus.gd")
const CHARACTER_HEIGHT: float = 1.6
## Posición de reposo de `camera_rig.tscn` (D14), valores del prototipo.
const REST_POSITION: Vector3 = Vector3(0.7, 7.49, 5.86)

var _viewport: SubViewport
var _rig: CameraRig


func _make_rig(size: Vector2i, profile: CameraProfile) -> void:
	_viewport = SubViewport.new()
	_viewport.size = size
	add_child_autofree(_viewport)
	_rig = RIG_SCENE.instantiate()
	_rig.set_bus(autofree(EventBusScript.new()))
	_viewport.add_child(_rig)
	_rig.set_profile(profile)


func _px_per_meter_1080(at: Vector3) -> float:
	var feet: Vector2 = _rig.unproject_position(at)
	var head: Vector2 = _rig.unproject_position(at + Vector3.UP * CHARACTER_HEIGHT)
	var px: float = absf(feet.y - head.y) / CHARACTER_HEIGHT
	return px * 1080.0 / float(_viewport.size.y)


func test_profiles_have_contract_values() -> void:
	assert_eq(DESKTOP.ortho_size, 12.74)
	assert_false(DESKTOP.follow)
	assert_eq(MOBILE.ortho_size, 7.0)
	assert_true(MOBILE.follow)
	assert_eq(MOBILE.follow_time, 0.2)
	assert_eq(MOBILE.switch_pan_time, 0.35)
	assert_eq(MOBILE.camera_margin_m, 1.0)
	assert_eq(MOBILE.px_per_meter_min, 120.0)
	assert_eq(MOBILE.offscreen_arrow_px, 48.0)


func test_scene_defaults_point_to_the_profiles() -> void:
	var rig: CameraRig = autofree(RIG_SCENE.instantiate())
	assert_eq(rig.desktop_profile.ortho_size, 12.74)
	assert_eq(rig.mobile_profile.ortho_size, 7.0)
	assert_almost_eq(rig.size, 12.74, 0.0001, "la escena sigue en 12,74 (D14)")


func test_desktop_projection_is_unchanged() -> void:
	_make_rig(Vector2i(1920, 1080), DESKTOP)
	assert_almost_eq(_rig.size, 12.74, 0.0001)
	assert_eq(_rig.global_position, REST_POSITION)
	var ppm: float = _px_per_meter_1080(Vector3(4.7, 0.0, 3.0))
	assert_almost_eq(ppm, 66.8, 0.5, "66,8 px/m como hoy")


func test_desktop_is_fixed_even_with_characters() -> void:
	_make_rig(Vector2i(1920, 1080), DESKTOP)
	var a: Node3D = autofree(Node3D.new())
	_viewport.add_child(a)
	a.global_position = Vector3(8.0, 0.0, 5.0)
	_rig.characters = [a]
	for i: int in 120:
		_rig.step(1.0 / 60.0)
	assert_eq(_rig.global_position, REST_POSITION, "no se mueve")
	assert_false((_rig.get_node(^"%OffscreenArrow") as CanvasLayer).visible)


func test_mobile_meets_pixels_per_meter_at_1080() -> void:
	for canvas: Vector2i in [Vector2i(2340, 1080), Vector2i(1920, 1080), Vector2i(2400, 1000)]:
		_make_rig(canvas, MOBILE)
		assert_eq(_rig.size, 7.0)
		var ppm: float = _px_per_meter_1080(Vector3(0.7, 0.0, -3.7))
		assert_gte(ppm, MOBILE.px_per_meter_min, "px/m a 1080 de alto en %s: %f" % [canvas, ppm])
		assert_gte(ppm * CHARACTER_HEIGHT, 192.0, "personaje >= 192 px")
		_viewport.free()


func test_platform_picks_profile_on_ready() -> void:
	var previous: PlatformProfile.Kind = GameState.platform
	GameState.set_platform(PlatformProfile.Kind.MOBILE)
	var rig: CameraRig = RIG_SCENE.instantiate()
	rig.set_bus(autofree(EventBusScript.new()))
	add_child_autofree(rig)
	assert_eq(rig.size, 7.0, "MOBILE usa el perfil móvil")
	GameState.set_platform(PlatformProfile.Kind.DESKTOP)
	var rig2: CameraRig = RIG_SCENE.instantiate()
	rig2.set_bus(autofree(EventBusScript.new()))
	add_child_autofree(rig2)
	assert_almost_eq(rig2.size, 12.74, 0.0001, "DESKTOP usa el de escritorio")
	GameState.set_platform(previous)
