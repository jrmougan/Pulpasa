class_name TouchButton
extends Control
## Botón circular táctil (ADR-004 §6.2). Cambiar y pausa lo usan tal cual; el de acción lo
## extiende. Pulsa una acción de entrada con `InputEventAction` al tocar y la suelta al levantar el
## dedo. Un contacto pertenece al botón donde empezó hasta que se levanta (multitáctil): arrastrarlo
## fuera no cancela, y un dedo que llega arrastrado desde otro control no lo pulsa.

## Se emite al empezar y al terminar el contacto que posee el botón.
signal pressed_changed(is_pressed: bool)

enum Icon { NONE, SWITCH, PAUSE }

## Acción de entrada que pulsa (`p1_switch`, `pause`, `p1_interact`).
@export var action: StringName = &""
@export var icon_kind: Icon = Icon.NONE

var config: TouchConfig
var icons: ActionIconSet
## Margen añadido al radio de la zona táctil, en unidades de lienzo.
var hit_slop: float = 0.0
## Puerta de entrada que pone `TouchControls`: recibe el evento y dice si los controles lo aceptan.
## Sin ella vale `is_visible_in_tree()`.
var gate: Callable = Callable()

var _index: int = -1
var _press_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_on_resized)
	_on_resized()


func _exit_tree() -> void:
	release_all()


## Datos compartidos; los inyecta `TouchControls`.
func setup(new_config: TouchConfig, new_icons: ActionIconSet) -> void:
	config = new_config
	icons = new_icons
	queue_redraw()


## Centro del botón en coordenadas globales (de lienzo).
func get_center() -> Vector2:
	return global_position + size / 2.0


## Radio visible en unidades de lienzo.
func get_radius() -> float:
	return size.x / 2.0


## Radio de la zona táctil (visible + margen).
func get_hit_radius() -> float:
	return get_radius() + hit_slop


## `true` si `point` (global) cae en la zona táctil.
func hit_test(point: Vector2) -> bool:
	return get_center().distance_to(point) <= get_hit_radius()


func is_pressed() -> bool:
	return _index != -1


## Índice del contacto que posee el botón (-1 = ninguno).
func get_touch_index() -> int:
	return _index


## Suelta lo que haya pulsado (se oculta, pausa o sale del árbol).
func release_all() -> void:
	if _index != -1:
		_end()


func _input(event: InputEvent) -> void:
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	if touch != null:
		if touch.pressed:
			if _index == -1 and _is_open(touch) and hit_test(touch.position):
				_begin(touch.index)
				get_viewport().set_input_as_handled()
		elif touch.index == _index:
			_end()
			get_viewport().set_input_as_handled()
		return
	var drag: InputEventScreenDrag = event as InputEventScreenDrag
	if drag != null and drag.index == _index:
		get_viewport().set_input_as_handled()


func _is_open(event: InputEvent) -> bool:
	if gate.is_valid():
		return gate.call(event)
	return is_visible_in_tree()


func _begin(touch_index: int) -> void:
	_index = touch_index
	_send(true)
	_tween_scale(config.press_scale if config != null else 1.0)
	pressed_changed.emit(true)
	queue_redraw()


func _end() -> void:
	_index = -1
	_send(false)
	_tween_scale(1.0)
	pressed_changed.emit(false)
	queue_redraw()


func _send(is_down: bool) -> void:
	if action == &"":
		return
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = is_down
	event.strength = 1.0 if is_down else 0.0
	Input.parse_input_event(event)


func _tween_scale(target: float) -> void:
	if _press_tween != null and _press_tween.is_valid():
		_press_tween.kill()
	var time: float = config.press_time if config != null else 0.1
	_press_tween = create_tween()
	_press_tween.tween_property(self, "scale", Vector2.ONE * target, time)


func _on_resized() -> void:
	pivot_offset = size / 2.0
	queue_redraw()


func _draw() -> void:
	if icons == null:
		return
	var center: Vector2 = size / 2.0
	var radius: float = get_radius()
	draw_circle(center, radius, _plate_color())
	var ring: float = _ring_width()
	var ring_color: Color = _ring_color()
	if ring_color.a > 0.0:
		draw_arc(center, radius - ring / 2.0, 0.0, TAU, 64, ring_color, ring, true)
	_draw_content(center, radius)


func _plate_color() -> Color:
	return icons.plate_color


func _ring_color() -> Color:
	var color: Color = icons.ok_color
	color.a = config.ring_alpha if config != null else 0.55
	return color


func _ring_width() -> float:
	if config == null:
		return 4.0
	return UiScale.px_to_units(config.ring_px_1080, _canvas_height())


func _canvas_height() -> float:
	return get_viewport().get_visible_rect().size.y


## Contenido del botón; el de acción lo sustituye. Pictogramas dibujados (cambiar y pausa).
func _draw_content(center: Vector2, radius: float) -> void:
	var color: Color = icons.ok_color
	match icon_kind:
		Icon.PAUSE:
			var bar: Vector2 = Vector2(radius * 0.2, radius * 0.7)
			var gap: float = radius * 0.16
			draw_rect(Rect2(center + Vector2(-gap - bar.x, -bar.y / 2.0), bar), color)
			draw_rect(Rect2(center + Vector2(gap, -bar.y / 2.0), bar), color)
		Icon.SWITCH:
			_draw_switch(center, radius, color)
		_:
			pass


## Dos personajes (cabeza y cuerpo) con dos flechas de intercambio.
func _draw_switch(center: Vector2, radius: float, color: Color) -> void:
	var head: float = radius * 0.13
	for side: float in [-1.0, 1.0]:
		var x: float = center.x + side * radius * 0.34
		draw_circle(Vector2(x, center.y - radius * 0.12), head, color)
		draw_arc(
			Vector2(x, center.y + radius * 0.3),
			radius * 0.2,
			PI,
			TAU,
			16,
			color,
			radius * 0.1,
			true
		)
	var width: float = radius * 0.07
	var top: float = center.y - radius * 0.5
	var bottom: float = center.y + radius * 0.56
	var span: float = radius * 0.3
	draw_line(Vector2(center.x - span, top), Vector2(center.x + span, top), color, width, true)
	draw_line(
		Vector2(center.x + span, top),
		Vector2(center.x + span - radius * 0.12, top - radius * 0.1),
		color,
		width,
		true
	)
	draw_line(
		Vector2(center.x - span, bottom), Vector2(center.x + span, bottom), color, width, true
	)
	draw_line(
		Vector2(center.x - span, bottom),
		Vector2(center.x - span + radius * 0.12, bottom + radius * 0.1),
		color,
		width,
		true
	)
