class_name CameraRig
extends Camera3D
## Cámara ortográfica con perfil por plataforma (ADR-005 E5). Escritorio: fija como en D14. Móvil:
## sigue al personaje activo de J1 (`character_switched`), con paneo al cambiar, límites del nivel y
## una flecha de borde para el personaje inactivo fuera de cuadro. Solo lee posiciones.

## Mínimo de un eje de cámara proyectado al suelo (evita dividir por cero).
const MIN_AXIS: float = 0.0001
## Separación mínima entre la flecha y la zona de botones, px a 1080 de alto.
const ARROW_GAP_PX: float = 16.0
## Media anchura (m) del personaje que debe quedar fuera de la zona de botones.
const CHARACTER_HALF_WIDTH_M: float = 0.5
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
	if profile == null or not profile.follow:
		_set_arrow_visible(false)
		return
	if _active >= characters.size() or characters[_active] == null:
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
	var ground: Vector2 = Vector2(pos.x, pos.z)
	var half: Vector2 = view_half_extents()
	if not profile.respect_top_band:
		return CameraFollow.clamp_focus(
			ground, half, profile.play_area_min, profile.play_area_max, profile.camera_margin_m
		)
	var cover: float = top_cover_m()
	var focus: Vector2 = CameraFollow.clamp_focus_covered(
		CameraFollow.covered_focus(ground, cover),
		half,
		profile.play_area_min,
		profile.play_area_max,
		profile.camera_margin_m,
		cover,
		top_reach_m()
	)
	if not _in_button_strip(ground.y, focus.y, half.y):
		return focus
	var canvas: Vector2 = get_viewport().get_visible_rect().size
	var pad: float = (
		CHARACTER_HALF_WIDTH_M + _canvas_to_ground_x(UiScale.px_to_units(ARROW_GAP_PX, canvas.y))
	)
	return CameraFollow.clear_east_cover(
		focus,
		ground.x,
		half.x,
		profile.play_area_max.x,
		profile.camera_margin_m,
		_canvas_to_ground_x(_button_zone(canvas).size.x),
		pad
	)


## Si los pies (`ground_z`) quedan, con el foco en `focus_z`, en la franja de la zona de botones.
func _in_button_strip(ground_z: float, focus_z: float, half_z: float) -> bool:
	var canvas: Vector2 = get_viewport().get_visible_rect().size
	var feet_y: float = canvas.y * (0.5 + (ground_z - focus_z) / maxf(half_z * 2.0, MIN_AXIS))
	return feet_y > _button_zone(canvas).position.y


## Ancho en unidades de lienzo → metros de suelo en x.
func _canvas_to_ground_x(units: float) -> float:
	var canvas: Vector2 = get_viewport().get_visible_rect().size
	return units / maxf(canvas.x, 1.0) * view_half_extents().x * 2.0


## Alto (m sobre el suelo) de la zona tapada arriba: safe area superior + banda de HUD y tickets
## (`UiProfile.top_band_max_px`), de unidades de lienzo a metros por la fracción del alto de vista.
func top_cover_m() -> float:
	var canvas: Vector2 = get_viewport().get_visible_rect().size
	return _top_cover_units(canvas) / maxf(canvas.y, 1.0) * view_half_extents().y * 2.0


## Alto (unidades de lienzo) tapado arriba: safe area superior + `UiProfile.top_band_max_px`; 0 sin
## `respect_top_band`.
func _top_cover_units(canvas: Vector2) -> float:
	if profile == null or not profile.respect_top_band:
		return 0.0
	var ui: UiProfile = ui_profile if ui_profile != null else GameState.ui_profile
	return _safe_margins(canvas).y + UiScale.px_to_units(ui.top_band_max_px, canvas.y)


## `top_reach_height_m` (altura sobre el suelo) como metros equivalentes hacia el norte del suelo.
func top_reach_m() -> float:
	var ground_z: float = maxf(absf(global_basis.y.z), MIN_AXIS)
	return profile.top_reach_height_m * absf(global_basis.y.y) / ground_z


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
	# Bajo la banda superior tapada el inactivo no se ve: cuenta como fuera de cuadro.
	var top: float = _top_cover_units(canvas)
	var screen: Rect2 = Rect2(Vector2(0.0, top), Vector2(canvas.x, canvas.y - top))
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
	var margins: Vector4 = _safe_margins(canvas)
	var top: float = maxf(margins.y, _top_cover_units(canvas))
	var inner: Rect2 = Rect2(
		Vector2(margins.x, top),
		Vector2(canvas.x - margins.x - margins.z, canvas.y - top - margins.w)
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


## Zona de botones anclada a la esquina inferior derecha de la safe area (ADR-005 E4, D27.2),
## hasta el borde del lienzo (incluye las safe areas derecha e inferior).
func _button_zone(canvas: Vector2) -> Rect2:
	var ui: UiProfile = ui_profile if ui_profile != null else GameState.ui_profile
	var m: Vector4 = _safe_margins(canvas)
	var left: float = canvas.x - m.z - UiScale.px_to_units(ui.button_zone_width_px, canvas.y)
	var top: float = canvas.y - m.w - UiScale.px_to_units(ui.button_zone_height_px, canvas.y)
	return Rect2(left, top, canvas.x - left, canvas.y - top)


func _safe_margins(canvas: Vector2) -> Vector4:
	return _safe_override if _has_safe_override else _current_safe_margins(canvas)


func _current_safe_margins(canvas: Vector2) -> Vector4:
	return UiScale.safe_margins(
		Vector2(DisplayServer.window_get_size()),
		Rect2(DisplayServer.get_display_safe_area()),
		canvas
	)


func _set_arrow_visible(on: bool) -> void:
	if _arrow_layer != null:
		_arrow_layer.visible = on
