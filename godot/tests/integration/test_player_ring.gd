extends GutTest
## PUL-127 AC5 (D26.6, diseño `jugadores-y-cambio.md` AC5'): el aro del personaje activo es sólido
## (>= 8 px a 1080) del color de su jugador y lleva un ▼ (>= 24 px); el inactivo, un aro gris
## discontinuo de <= 3 px sin ▼; en escala de grises el contraste entre ambos es >= 3:1.

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const CAMERA_SCENE: PackedScene = preload("res://entities/camera/camera_rig.tscn")
const EventBusScript: GDScript = preload("res://autoload/event_bus.gd")

var _level: Node3D
var _bus: Node
var _player: Player
var _control: ControlComponent
var _camera_size: float


func before_each() -> void:
	_level = add_child_autofree(Node3D.new())
	_bus = autofree(EventBusScript.new())
	var camera: Camera3D = CAMERA_SCENE.instantiate()
	_level.add_child(camera)
	_camera_size = camera.size
	_player = PLAYER_SCENE.instantiate()
	_player.set_bus(_bus)
	_player.camera = camera
	_level.add_child(_player)
	_control = _player.get_node(^"%Control") as ControlComponent
	_control.player_index = 1


func _active() -> MeshInstance3D:
	return _player.get_node(^"%ActiveIndicator") as MeshInstance3D


func _inactive() -> MeshInstance3D:
	return _player.get_node(^"%InactiveIndicator") as MeshInstance3D


func _marker() -> Sprite3D:
	return _player.get_node(^"%ActiveMarker") as Sprite3D


## Grosor de un toro en px de pantalla a 1080 de alto (diámetro del tubo, en el suelo).
func _thickness_px(ring: MeshInstance3D) -> float:
	var torus: TorusMesh = ring.mesh as TorusMesh
	return (torus.outer_radius - torus.inner_radius) * 1080.0 / _camera_size


func _luminance(color: Color) -> float:
	var channels: Array[float] = []
	for channel: float in [color.r, color.g, color.b]:
		channels.append(
			channel / 12.92 if channel <= 0.04045 else pow((channel + 0.055) / 1.055, 2.4)
		)
	return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]


func _contrast(a: Color, b: Color) -> float:
	var la: float = _luminance(a)
	var lb: float = _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _inactive_color() -> Color:
	return (_player.inactive_material as ShaderMaterial).get_shader_parameter(&"ring_color")


func test_active_ring_is_solid_and_at_least_8px() -> void:
	_control.controlled_by = 1
	assert_true(_active().visible)
	assert_gte(_thickness_px(_active()), 8.0)
	assert_true(_active().material_override is StandardMaterial3D, "color sólido, sin huecos")


func test_inactive_ring_is_dashed_gray_and_at_most_3px() -> void:
	_control.controlled_by = 0
	assert_true(_inactive().visible)
	assert_false(_active().visible)
	assert_lte(_thickness_px(_inactive()), 3.0)
	var material: ShaderMaterial = _inactive().material_override as ShaderMaterial
	assert_eq(material, _player.inactive_material)
	assert_gt(float(material.get_shader_parameter(&"dashes")), 1.0, "discontinuo")
	assert_lt(float(material.get_shader_parameter(&"duty")), 1.0)
	var gray: Color = _inactive_color()
	assert_almost_eq(gray.r, gray.g, 0.02)
	assert_almost_eq(gray.g, gray.b, 0.02)


## PUL-133 AC3 (H-02): el trazo no depende del zoom: con la cámara de escritorio y con la
## móvil el activo mide >= 8 px y el inactivo <= 3 px a 1080.
func test_ac3_ring_thickness_is_the_same_with_desktop_and_mobile_cameras() -> void:
	var profiles: Array[CameraProfile] = [
		preload("res://data/config/camera_desktop.tres"),
		preload("res://data/config/camera_mobile.tres"),
	]
	for profile: CameraProfile in profiles:
		_player.camera.size = profile.ortho_size
		await wait_process_frames(2)
		_camera_size = profile.ortho_size
		assert_gte(_thickness_px(_active()), 8.0, "activo con zoom %s" % profile.ortho_size)
		assert_lte(_thickness_px(_inactive()), 3.0, "inactivo con zoom %s" % profile.ortho_size)
		assert_gt(_thickness_px(_inactive()), 0.5, "no desaparece")


func test_ac3_each_player_owns_its_ring_meshes() -> void:
	var other: Player = PLAYER_SCENE.instantiate()
	other.set_bus(_bus)
	other.camera = _player.camera
	_level.add_child(other)
	assert_ne(_active().mesh, (other.get_node(^"%ActiveIndicator") as MeshInstance3D).mesh)
	assert_ne(_inactive().mesh, (other.get_node(^"%InactiveIndicator") as MeshInstance3D).mesh)


func test_marker_only_on_the_active_character() -> void:
	_control.controlled_by = 1
	assert_true(_marker().visible)
	_control.controlled_by = 0
	assert_false(_marker().visible)
	assert_ne(_inactive().visible, _active().visible, "exactamente un aro visible")


func test_marker_is_at_least_24px_and_above_the_head() -> void:
	_control.controlled_by = 1
	await wait_process_frames(2)
	var marker: Sprite3D = _marker()
	var mpp: float = ActionPrompt.meters_per_pixel_of(_player)
	var side: float = marker.pixel_size * float(marker.texture.get_width()) / mpp
	assert_gte(side, 24.0 - 0.01)
	assert_gt(marker.position.y, 1.6, "sobre la cabeza (cápsula de 1,54 m)")
	assert_true(marker.no_depth_test, "el modelo no lo tapa")
	assert_eq(marker.billboard, BaseMaterial3D.BILLBOARD_ENABLED)
	assert_gte(_player.marker_px_1080, 24.0)


func test_marker_and_ring_use_the_player_colour() -> void:
	for slot: int in 2:
		_control.controlled_by = slot + 1
		var ring: StandardMaterial3D = _active().material_override as StandardMaterial3D
		assert_eq(ring, _player.indicator_materials[slot])
		assert_eq(_marker().modulate, ring.albedo_color)
	var first: StandardMaterial3D = _player.indicator_materials[0] as StandardMaterial3D
	var second: StandardMaterial3D = _player.indicator_materials[1] as StandardMaterial3D
	assert_ne(first.albedo_color, second.albedo_color)


func test_ring_colours_are_not_yellow_or_amber() -> void:
	for material: Material in _player.indicator_materials:
		var color: Color = (material as StandardMaterial3D).albedo_color
		var yellowish: bool = color.r > 0.8 and color.g > 0.55 and color.b < 0.4
		assert_false(yellowish, "choca con el gorro de J2 y el ámbar de BLOQUEADO")


func test_gray_contrast_between_active_and_inactive_is_at_least_3() -> void:
	for material: Material in _player.indicator_materials:
		var color: Color = (material as StandardMaterial3D).albedo_color
		assert_gte(_contrast(color, _inactive_color()), 3.0, "anillo %s" % color)


func test_switching_swaps_the_two_rings() -> void:
	_control.controlled_by = 1
	_control.controlled_by = 0
	assert_true(_inactive().visible)
	assert_false(_marker().visible)
	_control.controlled_by = 2
	assert_true(_active().visible)
	assert_false(_inactive().visible)
	assert_true(_marker().visible)
