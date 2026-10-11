class_name ActionButton
extends TouchButton
## Botón de acción táctil (ADR-004 §6.2): muestra el icono del verbo del objetivo activo de J1, el
## mismo que el prompt del mundo (`ActionIconSet`). Estados: sin objetivo = placa gris con COGER
## atenuado; OK = aro blanco y verbo blanco; BLOQUEADO = aro ámbar, verbo ámbar, aspa y motivo.
## Pulsar es `p1_interact`; mantener lo repite `InteractionComponent` solo con CORTAR (§6.4).

## Jugador cuyo hint muestra el botón.
const PLAYER: int = 1
## Llamada de vibración (duración en ms). `Input.vibrate_handheld` no hace nada en escritorio.
var vibrate: Callable = Input.vibrate_handheld

var _verb: StringName = ActionVerb.NONE
var _state: ActionHint.State = ActionHint.State.NONE
var _reason: StringName = ActionReason.NONE
## Fases visuales de la respuesta: desplazamiento (unidades), escala del icono y opacidad del aspa.
var _offset: Vector2 = Vector2.ZERO
var _icon_scale: float = 1.0
var _cross_alpha: float = 1.0
var _response_tween: Tween


func _ready() -> void:
	action = &"p1_interact"
	super._ready()
	EventBus.action_hint_changed.connect(_on_action_hint_changed)
	EventBus.interaction_resolved.connect(_on_interaction_resolved)


## Pinta el hint dado (el cambio es inmediato, cumple el ≤ 0,1 s del diseño).
func show_hint(verb: StringName, state: int, reason: StringName) -> void:
	_verb = verb
	_state = state as ActionHint.State
	_reason = reason
	queue_redraw()


func get_state() -> ActionHint.State:
	return _state


func get_verb() -> StringName:
	return _verb


func get_reason() -> StringName:
	return _reason


## Icono del verbo que se dibuja: sin objetivo, COGER atenuado.
func get_icon_texture() -> Texture2D:
	if icons == null:
		return null
	if _state == ActionHint.State.NONE:
		return icons.verb_icons.get(ActionVerb.PICK_UP)
	return icons.verb_icons.get(_verb)


func get_icon_color() -> Color:
	var color: Color = icons.ok_color
	match _state:
		ActionHint.State.NONE:
			color.a = icons.idle_alpha
		ActionHint.State.BLOCKED:
			color = icons.blocked_color
	return color


## Aro del estado: blanco (OK), ámbar (BLOQUEADO), sin aro (alfa 0) sin objetivo.
func get_ring_color() -> Color:
	match _state:
		ActionHint.State.OK:
			return icons.ok_color
		ActionHint.State.BLOCKED:
			return icons.blocked_color
	return Color(0.0, 0.0, 0.0, 0.0)


func get_plate_color() -> Color:
	return _plate_color()


func shows_cross() -> bool:
	return _state == ActionHint.State.BLOCKED


## Icono del motivo del bloqueo (`null` fuera de BLOQUEADO).
func get_reason_texture() -> Texture2D:
	if icons == null or _state != ActionHint.State.BLOCKED:
		return null
	return icons.reason_icons.get(_reason)


## Respuesta de una pulsación: salto del icono (OK) o sacudida con parpadeo del aspa (BLOQUEADO),
## y la vibración si está activada.
func play_response(state: int) -> void:
	if icons == null:
		return
	if _response_tween != null and _response_tween.is_valid():
		_response_tween.kill()
	_response_tween = create_tween()
	var is_blocked: bool = state == ActionHint.State.BLOCKED
	_response_tween.tween_method(
		_apply_response.bind(is_blocked), 0.0, 1.0, icons.response_duration
	)
	_response_tween.finished.connect(_clear_response)
	_vibrate(is_blocked)


func _on_action_hint_changed(
	player_index: int, verb: StringName, state: int, reason: StringName
) -> void:
	if player_index == PLAYER:
		show_hint(verb, state, reason)


func _on_interaction_resolved(
	player_index: int, _verb_id: StringName, state: int, _reason_id: StringName
) -> void:
	if player_index == PLAYER:
		play_response(state)


func _apply_response(progress: float, is_blocked: bool) -> void:
	var unit: float = UiScale.px_to_units(1.0, _canvas_height())
	if is_blocked:
		var shake: float = sin(progress * config.shake_cycles * TAU) * icons.reject_shake_px * unit
		_offset = Vector2(shake, 0.0)
		_icon_scale = 1.0
		_cross_alpha = 0.5 + 0.5 * cos(progress * TAU)
	else:
		var arc: float = sin(progress * PI)
		_offset = Vector2(0.0, -config.jump_px_1080 * unit * arc)
		_icon_scale = 1.0 + config.jump_scale * arc
		_cross_alpha = 1.0
	queue_redraw()


func _clear_response() -> void:
	_offset = Vector2.ZERO
	_icon_scale = 1.0
	_cross_alpha = 1.0
	queue_redraw()


func _vibrate(is_blocked: bool) -> void:
	if config == null or not config.haptics_enabled or not vibrate.is_valid():
		return
	if not is_blocked:
		vibrate.call(config.haptic_ok_ms)
		return
	vibrate.call(config.haptic_reject_ms)
	# Doble vibración: la segunda tras un hueco del mismo largo.
	var gap: float = 2.0 * config.haptic_reject_ms / 1000.0
	get_tree().create_timer(gap, true, false, true).timeout.connect(
		vibrate.bind(config.haptic_reject_ms)
	)


func _plate_color() -> Color:
	if icons == null:
		return Color.TRANSPARENT
	if _state == ActionHint.State.NONE:
		return icons.idle_color
	var color: Color = icons.plate_color
	color.a = 1.0
	return color


func _ring_color() -> Color:
	return get_ring_color()


func _draw_content(center: Vector2, radius: float) -> void:
	var height: float = _canvas_height()
	var icon_side: float = UiScale.px_to_units(config.action_icon_px_1080, height)
	var texture: Texture2D = get_icon_texture()
	var tint: Color = get_icon_color()
	if texture != null:
		var half: Vector2 = Vector2.ONE * icon_side * _icon_scale / 2.0
		draw_texture_rect(texture, Rect2(center + _offset - half, half * 2.0), false, tint)
	if _state != ActionHint.State.BLOCKED:
		return
	var mark: Color = icons.blocked_color
	var cross_side: float = UiScale.px_to_units(icons.cross_px_1080, height)
	var cross_center: Vector2 = center + _offset + Vector2(radius * 0.5, -radius * 0.5)
	mark.a = _cross_alpha
	if icons.cross != null:
		var cross_half: Vector2 = Vector2.ONE * cross_side / 2.0
		draw_texture_rect(
			icons.cross, Rect2(cross_center - cross_half, cross_half * 2.0), false, mark
		)
	var reason_texture: Texture2D = get_reason_texture()
	if reason_texture != null:
		var reason_side: float = UiScale.px_to_units(icons.reason_icon_px_1080, height)
		var reason_center: Vector2 = center + _offset + Vector2(radius * 0.5, radius * 0.5)
		var reason_half: Vector2 = Vector2.ONE * reason_side / 2.0
		draw_texture_rect(
			reason_texture, Rect2(reason_center - reason_half, reason_half * 2.0), false, mark
		)
