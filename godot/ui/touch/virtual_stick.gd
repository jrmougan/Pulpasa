class_name VirtualStick
extends Control
## Stick flotante de movimiento (ADR-004 §6.1–§6.2). Un toque nuevo en su zona hace aparecer la base
## centrada en el contacto (recortada para quedar entera en la safe area); el vector alimenta
## `p1_move_*` con `Input.action_press(acción, fuerza)`, sin eventos nuevos en el InputMap. Si el
## dedo pasa del radio, la base lo sigue. El control ocupa la zona del stick (su propio rectángulo).

const BASE_FILL: Color = Color(1.0, 1.0, 1.0, 0.16)
const BASE_RING: Color = Color(1.0, 1.0, 1.0, 0.5)
const THUMB_FILL: Color = Color(1.0, 1.0, 1.0, 0.55)
## Diámetro del pulgar respecto a la base (150 px frente a 300 px).
const THUMB_RATIO: float = 0.5

var config: TouchConfig
## Safe area en coordenadas globales: la base queda entera dentro.
var safe_rect: Rect2 = Rect2()
## Controles sobre los que un toque no inicia el stick (botones; el HUD queda fuera de la zona).
var blockers: Array[TouchButton] = []

var _index: int = -1
var _center: Vector2 = Vector2.ZERO
var _finger: Vector2 = Vector2.ZERO
var _vector: Vector2 = Vector2.ZERO
var _alpha: float = 0.0
var _fade_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _exit_tree() -> void:
	release_all()


func setup(new_config: TouchConfig) -> void:
	config = new_config


func is_active() -> bool:
	return _index != -1


## Vector actual del stick (x a la derecha, y hacia abajo), longitud 0–1.
func get_vector() -> Vector2:
	return _vector


## Centro de la base en coordenadas globales.
func get_base_center() -> Vector2:
	return _center


func get_finger_position() -> Vector2:
	return _finger


## Opacidad de la base (1 al tocar, desvanece a 0 en `stick_fade_s` al soltar).
func get_base_alpha() -> float:
	return _alpha


func get_touch_index() -> int:
	return _index


## Diámetro de la base en unidades de lienzo.
func get_base_diameter() -> float:
	return UiScale.dp_to_units(config.stick_base_dp, config.px_per_dp_at_1080, _canvas_height())


## Radio de recorrido del pulgar en unidades de lienzo.
func get_travel_radius() -> float:
	return UiScale.dp_to_units(config.stick_radius_dp, config.px_per_dp_at_1080, _canvas_height())


## Suelta el contacto, pone el vector a cero y libera las acciones (se oculta, pausa o sale).
func release_all() -> void:
	if _index != -1:
		_end()


func _input(event: InputEvent) -> void:
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	if touch != null:
		if touch.pressed:
			if _index == -1 and _can_start(touch.position):
				_begin(touch.index, touch.position)
				get_viewport().set_input_as_handled()
		elif touch.index == _index:
			_end()
			get_viewport().set_input_as_handled()
		return
	var drag: InputEventScreenDrag = event as InputEventScreenDrag
	if drag != null and drag.index == _index:
		_move(drag.position)
		get_viewport().set_input_as_handled()


func _can_start(point: Vector2) -> bool:
	if config == null or not is_visible_in_tree():
		return false
	if not get_global_rect().has_point(point):
		return false
	for blocker: TouchButton in blockers:
		if blocker.is_visible_in_tree() and blocker.hit_test(point):
			return false
	return true


func _begin(touch_index: int, point: Vector2) -> void:
	_index = touch_index
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_alpha = 1.0
	_center = _clamped(point)
	_move(point)


func _move(point: Vector2) -> void:
	_finger = point
	var radius: float = get_travel_radius()
	_center = _clamped(TouchInput.follow_center(_center, point, radius))
	_apply(TouchInput.stick_vector(_center, point, radius, config.stick_deadzone))
	queue_redraw()


func _end() -> void:
	_index = -1
	_apply(Vector2.ZERO)
	_fade_tween = create_tween()
	_fade_tween.tween_method(_set_alpha, _alpha, 0.0, config.stick_fade_s)


func _clamped(point: Vector2) -> Vector2:
	if safe_rect.size == Vector2.ZERO:
		return point
	return TouchInput.clamp_center(point, get_base_diameter() / 2.0, safe_rect)


func _set_alpha(value: float) -> void:
	_alpha = value
	queue_redraw()


## Guarda el vector y pone las cuatro acciones de movimiento a su fuerza (0 = suelta).
func _apply(vector: Vector2) -> void:
	_vector = vector
	var strengths: Dictionary[StringName, float] = TouchInput.axis_strengths(vector)
	for action: StringName in TouchInput.MOVE_ACTIONS:
		var strength: float = strengths[action]
		if strength > 0.0:
			Input.action_press(action, strength)
		else:
			Input.action_release(action)


func _canvas_height() -> float:
	return get_viewport().get_visible_rect().size.y


func _draw() -> void:
	if _alpha <= 0.0 or config == null:
		return
	var center: Vector2 = _center - global_position
	var radius: float = get_base_diameter() / 2.0
	var travel: float = get_travel_radius()
	var offset: Vector2 = (_finger - _center).limit_length(travel)
	var fill: Color = BASE_FILL
	var ring: Color = BASE_RING
	var thumb: Color = THUMB_FILL
	fill.a *= _alpha
	ring.a *= _alpha
	thumb.a *= _alpha
	draw_circle(center, radius, fill)
	draw_arc(center, radius, 0.0, TAU, 64, ring, 3.0, true)
	draw_circle(center + offset, radius * THUMB_RATIO, thumb)
