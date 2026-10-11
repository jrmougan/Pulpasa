class_name SafeAreaMargin
extends MarginContainer
## Contenedor raíz que respeta la safe area del dispositivo (ADR-005 E4): márgenes con
## UiScale.safe_margins() al entrar y al cambiar el tamaño de la ventana.

var _safe_rect: Rect2 = Rect2()
var _window_size: Vector2 = Vector2.ZERO
var _injected: bool = false


func _ready() -> void:
	get_viewport().size_changed.connect(refresh)
	refresh()


## Inyección para pruebas (el diseño simula 132 / 0 / 132 / 63 a 2340x1080 en px de pantalla).
## `window_size` en px; sin él se usa el de DisplayServer.
func set_safe_rect(rect: Rect2, window_size: Vector2 = Vector2.ZERO) -> void:
	_safe_rect = rect
	_window_size = window_size
	_injected = true
	if is_inside_tree():
		refresh()


func refresh() -> void:
	var window_size: Vector2 = _window_size
	if window_size == Vector2.ZERO:
		window_size = Vector2(DisplayServer.window_get_size())
	var safe: Rect2 = _safe_rect
	if not _injected:
		safe = Rect2(DisplayServer.get_display_safe_area())
	var canvas: Vector2 = get_viewport().get_visible_rect().size
	var margins: Vector4 = UiScale.safe_margins(window_size, safe, canvas)
	add_theme_constant_override(&"margin_left", roundi(margins.x))
	add_theme_constant_override(&"margin_top", roundi(margins.y))
	add_theme_constant_override(&"margin_right", roundi(margins.z))
	add_theme_constant_override(&"margin_bottom", roundi(margins.w))
