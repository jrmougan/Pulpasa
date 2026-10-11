class_name CameraRig
extends Camera3D
## Cámara ortográfica con perfil por plataforma (ADR-005 E5). Escritorio: fija como en D14. Móvil:
## sigue al personaje activo de J1 (`character_switched`), con paneo al cambiar, límites del nivel y
## una flecha de borde para el personaje inactivo fuera de cuadro. Solo lee posiciones.

## Mínimo de un eje de cámara proyectado al suelo (evita dividir por cero).
const MIN_AXIS: float = 0.0001
## Separación mínima entre la flecha y la zona de botones, px a 1080 de alto.
const ARROW_GAP_PX: float = 16.0
## Altura (m) a la que se proyecta un personaje para saber si está en cuadro.
const CHARACTER_CENTER_HEIGHT: float = 0.8

@export var desktop_profile: CameraProfile = preload("res://data/config/camera_desktop.tres")
@export var mobile_profile: CameraProfile = preload("res://data/config/camera_mobile.tres")
## Personajes del nivel; índice = `character_index − 1`.
@export var characters: Array[Node3D] = []
## Perfil de UI para las zonas reservadas; null = el de `GameState`.
var ui_profile: UiProfile
var profile: CameraProfile

var _bus: Node
var _follow: CameraFollow = CameraFollow.new()
var _rest_position: Vector3 = Vector3.ZERO
var _rest_focus: Vector2 = Vector2.ZERO
var _active: int = 0
var _needs_snap: bool = true
var _safe_override: Vector4 = Vector4.ZERO
var _has_safe_override: bool = false

@onready var _arrow_layer: CanvasLayer = get_node_or_null(^"%OffscreenArrow") as CanvasLayer
@onready var _arrow: TextureRect = get_node_or_null(^"%Arrow") as TextureRect


func _ready() -> void:
	_rest_position = global_position
	_rest_focus = _ground_focus()
	if _bus == null:
		_bus = EventBus
	_bus.character_switched.connect(_on_character_switched)
	if profile == null:
		set_profile(
			mobile_profile if GameState.platform == PlatformProfile.Kind.MOBILE else desktop_profile
		)


func _process(delta: float) -> void:
	step(delta)


func set_bus(bus: Node) -> void:
	_bus = bus


## Fija el perfil (tests y `_ready`): aplica el zoom y recoloca la cámara.
func set_profile(new_profile: CameraProfile) -> void:
	profile = new_profile
	size = profile.ortho_size
	_needs_snap = true
	if not profile.follow:
		global_position = _rest_position
	_set_arrow_visible(false)


## Inyecta los márgenes de la safe area (izq, arriba, der, abajo) en unidades de lienzo (tests).
func set_safe_margins(margins: Vector4) -> void:
	_safe_override = margins
	_has_safe_override = true


## Índice (0 = J1) del personaje seguido.
func get_active_index() -> int:
	return _active


## Foco actual (punto del suelo al que mira la cámara).
func get_focus() -> Vector2:
	return _ground_focus()


## Avanza el seguimiento `delta` s (lo llama `_process`; los tests lo llaman directamente).
func step(delta: float) -> void:
	if profile == null or not profile.follow or _active >= characters.size():
		_set_arrow_visible(false)
		return
	var target: Vector2 = _target_focus()
	if _needs_snap:
		_needs_snap = false
		_follow.snap_to(target)
	else:
		_follow.follow(target, profile.follow_time, delta)
	var focus: Vector2 = _follow.position
	global_position = (
		_rest_position + Vector3(focus.x - _rest_focus.x, 0.0, focus.y - _rest_focus.y)
	)
	_update_arrow()


## Medias dimensiones de la vista sobre el suelo (m): (x, z).
func view_half_extents() -> Vector2:
	var canvas: Vector2 = get_viewport().get_visible_rect().size
	var aspect: float = canvas.x / maxf(canvas.y, 1.0)
	var half_h: float = size * 0.5
	var ground_x: float = maxf(absf(global_basis.x.x), MIN_AXIS)
	var ground_z: float = maxf(absf(global_basis.y.z), MIN_AXIS)
	return Vector2(half_h * aspect / ground_x, half_h / ground_z)


func _target_focus() -> Vector2:
	var pos: Vector3 = characters[_active].global_position
	return CameraFollow.clamp_focus(
		Vector2(pos.x, pos.z),
		view_half_extents(),
		profile.play_area_min,
		profile.play_area_max,
		profile.camera_margin_m
	)


## Corte del eje de la cámara con el suelo (y = 0).
func _ground_focus() -> Vector2:
	var forward: Vector3 = -global_basis.z
	if forward.y > -MIN_AXIS:
		return Vector2(global_position.x, global_position.z)
	var dist: float = -global_position.y / forward.y
	var hit: Vector3 = global_position + forward * dist
	return Vector2(hit.x, hit.z)


func _on_character_switched(player_index: int, character_index: int) -> void:
	var idx: int = character_index - 1
	if player_index != 1 or idx < 0 or idx == _active:
		return
	_active = idx
	if profile != null and profile.follow and idx < characters.size() and not _needs_snap:
		_follow.pan_to(_target_focus(), profile.switch_pan_time)


func _update_arrow() -> void:
	if _arrow_layer == null or _arrow == null:
		return
	var canvas: Vector2 = get_viewport().get_visible_rect().size
	var screen: Rect2 = Rect2(Vector2.ZERO, canvas)
	for i: int in characters.size():
		if i == _active or characters[i] == null:
			continue
		var pos: Vector3 = characters[i].global_position + Vector3.UP * CHARACTER_CENTER_HEIGHT
		var projected: Vector2 = unproject_position(pos)
		if screen.has_point(projected):
			continue
		_place_arrow(projected, canvas)
		return
	_set_arrow_visible(false)


func _place_arrow(projected: Vector2, canvas: Vector2) -> void:
	var side: float = UiScale.px_to_units(profile.offscreen_arrow_px, canvas.y)
	var margins: Vector4 = _safe_override if _has_safe_override else _current_safe_margins(canvas)
	var inner: Rect2 = Rect2(
		Vector2(margins.x, margins.y),
		Vector2(canvas.x - margins.x - margins.z, canvas.y - margins.y - margins.w)
	)
	var bounds: Rect2 = inner.grow(-side * 0.5)
	var avoid: Rect2 = _button_zone(canvas)
	var gap: float = UiScale.px_to_units(ARROW_GAP_PX, canvas.y)
	var point: Vector2 = CameraFollow.edge_point(projected, bounds, avoid, Vector2(side, side), gap)
	_arrow.size = Vector2(side, side)
	_arrow.pivot_offset = _arrow.size * 0.5
	_arrow.position = point - _arrow.size * 0.5
	_arrow.rotation = (projected - canvas * 0.5).angle()
	_set_arrow_visible(true)


func _button_zone(canvas: Vector2) -> Rect2:
	var ui: UiProfile = ui_profile if ui_profile != null else GameState.ui_profile
	var width: float = UiScale.px_to_units(ui.button_zone_width_px, canvas.y)
	var top: float = UiScale.px_to_units(ui.button_zone_top_px, canvas.y)
	return Rect2(Vector2(canvas.x - width, top), Vector2(width, canvas.y - top))


func _current_safe_margins(canvas: Vector2) -> Vector4:
	return UiScale.safe_margins(
		Vector2(DisplayServer.window_get_size()),
		Rect2(DisplayServer.get_display_safe_area()),
		canvas
	)


func _set_arrow_visible(on: bool) -> void:
	if _arrow_layer != null:
		_arrow_layer.visible = on
