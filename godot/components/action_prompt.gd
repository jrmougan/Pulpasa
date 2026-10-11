class_name ActionPrompt
extends Node3D
## Prompt de acción sobre el objetivo del jugador (ADR-003 §11.5, D26; capa específica: sprites
## billboard sin test de profundidad). Pinta el verbo de la pulsación sobre una placa oscura
## (blanco = `OK`; ámbar + aspa + icono de motivo = `BLOCKED`) y responde a cada pulsación:
## `OK` -> el icono salta (sube 12 px y escala 1,25); `BLOCKED` -> aspa y motivo parpadean y el
## prompt se sacude. Obtiene el hint **localmente** de su detector (`hint_changed`) y la pulsación
## de `actor.interaction_resolved`; no usa el bus.
##
## Las medidas son de pantalla (px a 1080 de alto, escaladas por `alto / 1080`). Con la cámara
## ortográfica, metros = px × `size` / alto. El diseño de los sprites se calcula en px y se lleva a
## metros sobre los ejes de la cámara, así que es independiente de la perspectiva del billboard.
## Dos prompts sobre el mismo objetivo (Local 2P) se reparten lado a lado (registro estático).

## Hueco entre las placas de dos prompts sobre el mismo objetivo, en px.
const GAP_PX: float = 8.0
## Alto de referencia de las medidas (px).
const REFERENCE_HEIGHT: float = 1080.0
## Marcador de jugador y insignia «sustituye», en px a 1080.
const MARKER_PX_1080: float = 16.0
const REPLACE_PX_1080: float = 16.0
## Subida del icono al responder `OK` (px a 1080) y escala máxima.
const LIFT_PX_1080: float = 12.0
const POP_SCALE: float = 1.25
## Ciclos de la sacudida de rechazo.
const SHAKE_CYCLES: int = 3
## Tramo de la respuesta de rechazo (0–1) en que aspa y motivo se apagan: un parpadeo.
const BLINK_FROM: float = 0.25
const BLINK_TO: float = 0.5
## Cámara por defecto si no hay ortográfica: `size` de `camera_rig.tscn` y 1080 de alto.
const FALLBACK_CAMERA_SIZE: float = 12.74
const RENDER_PRIORITY: int = 100

## Objetivo -> prompts visibles sobre él (Local 2P). Registro de la clase, sin buscar en la escena.
static var _registry: Dictionary = {}

@export var detector: InteractionDetector
@export var actor: InteractionComponent
## Mano del personaje: el hint de suelo se coloca en su punto de soltar.
@export var hold: HoldComponent
@export var icons: ActionIconSet = preload("res://data/config/action_icons.tres")

var _target: Node
var _hint: ActionHint = ActionHint.none()
var _shown: bool = false
## Medidas de vista inyectadas (tests): alto en px y `size` de la cámara.
var _view_height: float = 0.0
var _view_size: float = 0.0
var _mode: GameMode.Mode = GameMode.Mode.SINGLE
var _mode_set: bool = false
## Respuesta en curso: tiempo transcurrido (−1 = ninguna) y estado con que se pulsó.
var _elapsed: float = -1.0
var _response_state: ActionHint.State = ActionHint.State.NONE
var _responses: int = 0
var _lift_px: float = 0.0
var _scale: float = 1.0
var _shake_px: float = 0.0
var _blink_hidden: bool = false
var _registered_target_id: int = 0

@onready var _plate: Sprite3D = %Plate
@onready var _verb: Sprite3D = %VerbIcon
@onready var _reason: Sprite3D = %ReasonIcon
@onready var _cross: Sprite3D = %Cross
@onready var _replace: Sprite3D = %ReplaceBadge
@onready var _marker: Sprite3D = %PlayerMarker


## Metros por píxel de pantalla de `node` (cámara ortográfica del viewport). Lo usa también el
## marcador del personaje activo.
static func meters_per_pixel_of(node: Node3D) -> float:
	var viewport: Viewport = node.get_viewport() if node.is_inside_tree() else null
	var camera: Camera3D = viewport.get_camera_3d() if viewport != null else null
	var height: float = viewport.get_visible_rect().size.y if viewport != null else 0.0
	if camera == null or camera.projection != Camera3D.PROJECTION_ORTHOGONAL or height <= 0.0:
		return FALLBACK_CAMERA_SIZE / REFERENCE_HEIGHT
	if camera.keep_aspect == Camera3D.KEEP_WIDTH:
		return camera.size / viewport.get_visible_rect().size.x
	return camera.size / height


## Vacía el registro de la clase (tests).
static func clear_registry() -> void:
	_registry.clear()


func _ready() -> void:
	top_level = true
	for sprite: Sprite3D in [_plate, _verb, _reason, _cross, _replace, _marker]:
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.no_depth_test = true
		sprite.shaded = false
		sprite.double_sided = true
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_plate.render_priority = RENDER_PRIORITY
	_verb.render_priority = RENDER_PRIORITY + 1
	for sprite: Sprite3D in [_reason, _cross, _replace, _marker]:
		sprite.render_priority = RENDER_PRIORITY + 2
	_plate.texture = icons.plate
	_cross.texture = icons.cross
	_replace.texture = icons.replace
	if detector != null:
		detector.hint_changed.connect(_on_hint_changed)
		_target = detector.get_target()
		_hint = detector.get_hint()
	if actor != null:
		actor.interaction_resolved.connect(_on_interaction_resolved)
		if actor.control != null:
			actor.control.control_changed.connect(_on_control_changed)
	_refresh()


func _exit_tree() -> void:
	_unregister()


func _process(delta: float) -> void:
	advance(delta)
	_layout()


## Inyecta la vista (tests): alto de la ventana en px y `size` de la cámara ortográfica.
func set_view(height_px: float, camera_size: float) -> void:
	_view_height = height_px
	_view_size = camera_size


## Fija el modo (tests); por defecto se lee `GameState.mode`.
func set_mode(mode: GameMode.Mode) -> void:
	_mode = mode
	_mode_set = true


## Avanza la respuesta `delta` s (lo llama `_process`; los tests, a mano). En pausa no corre.
func advance(delta: float) -> void:
	if _elapsed < 0.0:
		return
	_elapsed += delta
	var duration: float = icons.response_duration
	if _elapsed >= duration:
		_elapsed = -1.0
		_reset_response()
		return
	var u: float = _elapsed / duration
	if _response_state == ActionHint.State.BLOCKED:
		_shake_px = float(icons.reject_shake_px) * sin(TAU * float(SHAKE_CYCLES) * u)
		_blink_hidden = u >= BLINK_FROM and u < BLINK_TO
	else:
		var bump: float = sin(PI * u)
		_lift_px = LIFT_PX_1080 * bump
		_scale = 1.0 + (POP_SCALE - 1.0) * bump


## Muestra y anima la respuesta a una pulsación; cada una reinicia la anterior.
func play_response(hint: ActionHint) -> void:
	_responses += 1
	_reset_response()
	_response_state = hint.state
	_elapsed = 0.0


func is_responding() -> bool:
	return _elapsed >= 0.0


## Pulsaciones con respuesta recibidas.
func get_response_count() -> int:
	return _responses


## Subida del icono en px a 1080 y escala en este instante de la respuesta.
func get_icon_lift_px() -> float:
	return _lift_px


func get_icon_scale() -> float:
	return _scale


## Desplazamiento horizontal de la sacudida de rechazo, en px.
func get_shake_px() -> float:
	return _shake_px


## `true` mientras el parpadeo del rechazo tiene apagados el aspa y el motivo.
func is_blink_hidden() -> bool:
	return _blink_hidden


func get_hint() -> ActionHint:
	return _hint


func get_target() -> Node:
	return _target if is_instance_valid(_target) else null


## `true` si el prompt se ve: hint `OK`/`BLOCKED` con verbo y personaje controlado.
func is_shown() -> bool:
	return _shown


## Lado del icono de verbo en px de pantalla (escala con el alto, con mínimo absoluto).
func icon_px() -> float:
	var ratio: float = _view_height_px() / REFERENCE_HEIGHT
	return maxf(float(icons.prompt_icon_px_1080) * ratio, float(icons.prompt_min_px))


## Lado de la placa en px de pantalla (misma proporción que el icono).
func plate_px() -> float:
	return icon_px() * float(icons.prompt_plate_px_1080) / float(icons.prompt_icon_px_1080)


## Metros por píxel de pantalla de la vista actual.
func meters_per_pixel() -> float:
	if _view_height > 0.0:
		return _view_size / _view_height
	return meters_per_pixel_of(self)


## Posición de pantalla (px, x derecha, y arriba) del centro de `sprite` respecto al ancla.
func offset_px_of(sprite: Sprite3D) -> Vector2:
	var axes: Array[Vector3] = _camera_axes()
	var local: Vector3 = sprite.global_position - global_position
	var mpp: float = meters_per_pixel()
	return Vector2(local.dot(axes[0]), local.dot(axes[1])) / mpp


## Lado en px de pantalla que ocupa `sprite`.
func size_px_of(sprite: Sprite3D) -> float:
	if sprite.texture == null:
		return 0.0
	return sprite.pixel_size * float(sprite.texture.get_width()) / meters_per_pixel()


## Inyecta un hint y objetivo como si los publicara el detector (tests y capturas).
func show_hint(target: Node, hint: ActionHint) -> void:
	_target = target
	_hint = hint
	_refresh()


func _on_hint_changed(target: Node, hint: ActionHint) -> void:
	show_hint(target, hint)


func _on_interaction_resolved(_target_node: Node, hint: ActionHint) -> void:
	play_response(hint)


func _on_control_changed(_controlled_by: int) -> void:
	_refresh()


func _is_controlled() -> bool:
	return actor != null and actor.control != null and actor.control.controlled_by > 0


func _is_coop() -> bool:
	return (_mode if _mode_set else GameState.mode) == GameMode.Mode.COOP_2P


func _player_number() -> int:
	return actor.control.controlled_by if _is_controlled() else 0


func _refresh() -> void:
	_shown = _is_controlled() and _hint.is_target() and _hint.verb != ActionVerb.NONE
	visible = _shown
	_unregister()
	if not _shown:
		return
	if icons.verb_icons.has(_hint.verb):
		_verb.texture = icons.verb_icons[_hint.verb]
	var blocked: bool = _hint.state == ActionHint.State.BLOCKED
	_verb.modulate = icons.blocked_color if blocked else icons.ok_color
	_plate.modulate = icons.plate_color
	_reason.texture = icons.reason_icons.get(_hint.reason) if blocked else null
	_replace.visible = _hint.replaces
	_cross.visible = blocked
	_reason.visible = blocked and _reason.texture != null
	var slot: int = _player_number() - 1
	_marker.texture = (
		icons.player_markers[slot] if slot >= 0 and slot < icons.player_markers.size() else null
	)
	_marker.visible = _is_coop() and _marker.texture != null
	_register()
	_layout()


func _register() -> void:
	var target: Node = get_target()
	if target == null:
		return
	_registered_target_id = target.get_instance_id()
	var list: Array = _registry.get(_registered_target_id, [])
	if not self in list:
		list.append(self)
	_registry[_registered_target_id] = list


func _unregister() -> void:
	if _registered_target_id == 0:
		return
	var list: Array = _registry.get(_registered_target_id, [])
	list.erase(self)
	if list.is_empty():
		_registry.erase(_registered_target_id)
	_registered_target_id = 0


func _reset_response() -> void:
	_lift_px = 0.0
	_scale = 1.0
	_shake_px = 0.0
	_blink_hidden = false


func _view_height_px() -> float:
	if _view_height > 0.0:
		return _view_height
	var viewport: Viewport = get_viewport() if is_inside_tree() else null
	return viewport.get_visible_rect().size.y if viewport != null else REFERENCE_HEIGHT


## `[derecha, arriba]` de la cámara en el mundo.
func _camera_axes() -> Array[Vector3]:
	var viewport: Viewport = get_viewport() if is_inside_tree() else null
	var camera: Camera3D = viewport.get_camera_3d() if viewport != null else null
	if camera == null:
		return [Vector3.RIGHT, Vector3.UP]
	return [camera.global_basis.x, camera.global_basis.y]


## Recoloca el prompt sobre el objetivo y reparte los sprites en px de pantalla.
func _layout() -> void:
	if not _shown or not is_inside_tree():
		return
	global_position = _anchor_position()
	var mpp: float = meters_per_pixel()
	var axes: Array[Vector3] = _camera_axes()
	var ratio: float = icon_px() / float(icons.prompt_icon_px_1080)
	var plate: float = plate_px()
	var lateral: float = _lateral_px(plate) + _shake_px
	var reason_px: float = float(icons.reason_icon_px_1080) * ratio
	var cross_px: float = float(icons.cross_px_1080) * ratio
	var badge_px: float = REPLACE_PX_1080 * ratio
	var half: float = plate * 0.5
	_place(_plate, plate, Vector2(lateral, 0.0), mpp, axes)
	_place(_verb, icon_px() * _scale, Vector2(lateral, _lift_px * ratio), mpp, axes)
	_place(
		_reason,
		reason_px,
		Vector2(lateral + half - reason_px * 0.5, -half + reason_px * 0.5),
		mpp,
		axes
	)
	_place(
		_cross,
		cross_px,
		Vector2(lateral + half - cross_px * 0.25, half - cross_px * 0.25),
		mpp,
		axes
	)
	_place(
		_replace,
		badge_px,
		Vector2(lateral - half + badge_px * 0.25, half - badge_px * 0.25),
		mpp,
		axes
	)
	_place(
		_marker,
		MARKER_PX_1080 * ratio,
		Vector2(lateral - half + badge_px * 0.25, -half + badge_px * 0.25),
		mpp,
		axes
	)
	var blocked: bool = _hint.state == ActionHint.State.BLOCKED
	_cross.visible = blocked and not _blink_hidden
	_reason.visible = blocked and _reason.texture != null and not _blink_hidden


## Pone `sprite` con `size` px de lado centrado en `center` px (derecha, arriba) del ancla.
func _place(
	sprite: Sprite3D, size: float, center: Vector2, mpp: float, axes: Array[Vector3]
) -> void:
	if sprite.texture == null:
		return
	sprite.pixel_size = size * mpp / float(sprite.texture.get_width())
	sprite.position = axes[0] * (center.x * mpp) + axes[1] * (center.y * mpp)


## Desplazamiento horizontal (px) de este prompt entre los que comparten objetivo, por jugador.
func _lateral_px(plate: float) -> float:
	var list: Array = _registry.get(_registered_target_id, [])
	if list.size() < 2:
		return 0.0
	var peers: Array[ActionPrompt] = []
	for peer: Variant in list:
		peers.append(peer as ActionPrompt)
	peers.sort_custom(
		func(a: ActionPrompt, b: ActionPrompt) -> bool:
			return a._player_number() < b._player_number()
	)
	var index: int = peers.find(self)
	return (float(index) - float(peers.size() - 1) * 0.5) * (plate + GAP_PX)


## Dónde se ancla: `%PromptAnchor` del objetivo, o la parte alta de su `Highlightable` más
## `prompt_offset`; sin objetivo, sobre el punto de soltar de la mano.
func _anchor_position() -> Vector3:
	var target: Node3D = get_target() as Node3D
	if target == null:
		if hold != null:
			return hold.get_drop_position() + Vector3.UP * icons.prompt_offset
		return global_position
	var anchor: Node3D = target.get_node_or_null(^"%PromptAnchor") as Node3D
	if anchor == null:
		anchor = target.find_child("PromptAnchor", false, false) as Node3D
	if anchor != null:
		return anchor.global_position
	var bounds: AABB = _highlight_bounds(target)
	if bounds.size == Vector3.ZERO:
		return target.global_position + Vector3.UP * icons.prompt_offset
	var center: Vector3 = bounds.get_center()
	return Vector3(center.x, bounds.end.y + icons.prompt_offset, center.z)


## AABB global de las mallas del `Highlightable` de `target` (sin otras entidades colgadas).
func _highlight_bounds(target: Node3D) -> AABB:
	var root: Node3D = target
	for child: Node in target.get_children():
		if child is Highlightable and (child as Highlightable).root != null:
			root = (child as Highlightable).root
			break
	var bounds: AABB = AABB()
	var found: bool = false
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node != root and _is_entity(node):
			continue
		if node is MeshInstance3D:
			var mesh: MeshInstance3D = node as MeshInstance3D
			var box: AABB = mesh.global_transform * mesh.get_aabb()
			bounds = box if not found else bounds.merge(box)
			found = true
		stack.append_array(node.get_children())
	return bounds if found else AABB()


func _is_entity(node: Node) -> bool:
	return (
		node.is_in_group(InteractionContract.GROUP_INTERACTABLE)
		or node.is_in_group(InteractionContract.GROUP_PICKABLE)
	)
