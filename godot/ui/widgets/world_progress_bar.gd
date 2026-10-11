class_name WorldProgressBar
extends Sprite3D
## Barra de progreso en el mundo, siempre de cara a la cámara (billboard). Sustituye a
## SimpleProgressBar + FaceToCamera. Capa específica (ADR-003 §0, scene-tree.md §6): pinta un
## `ProgressBar` de un `SubViewport` propio.
## D26.6: el relleno mide >= 8 px a 1080 de alto con la cámara de juego (`get_thickness_px`).
## Con `segments` > 1 dibuja separadores y sirve de contador (`%CutCounter` de la caja).

## Borde del `ProgressBar` (px del `SubViewport`); el relleno queda dentro.
const BORDER_PX: int = 2
## Ancho de cada separador de segmentos (px del `SubViewport`).
const SEPARATOR_PX: int = 3

## Tamaño de la barra en px del `SubViewport` (con `pixel_size`, su tamaño en el mundo).
@export var bar_size: Vector2i = Vector2i(120, 22)
## Segmentos iguales con separadores; 0 o 1 = barra continua.
@export var segments: int = 0
@export var separator_color: Color = Color(0.1, 0.1, 0.1, 1.0)

var _separators: Array[ColorRect] = []

@onready var _viewport: SubViewport = %Viewport
@onready var _bar: ProgressBar = %Bar


func _ready() -> void:
	_viewport.size = bar_size
	_bar.size = Vector2(bar_size)
	_build_separators()
	texture = _viewport.get_texture()


## Cambia el número de segmentos (0 o 1 = barra continua).
func set_segments(count: int) -> void:
	segments = count
	for separator: ColorRect in _separators:
		separator.queue_free()
	_separators.clear()
	_build_separators()


## Progreso 0–1.
func set_progress(value: float) -> void:
	_bar.value = clampf(value, 0.0, 1.0)


func get_progress() -> float:
	return _bar.value


## Grosor del relleno en px de pantalla con una cámara ortográfica de `camera_size` m de alto en
## una ventana de `screen_height` px.
func get_thickness_px(camera_size: float, screen_height: float = 1080.0) -> float:
	var inner: float = float(bar_size.y - 2 * BORDER_PX)
	return inner * pixel_size * screen_height / camera_size


## Ancho de cada segmento en px de pantalla (la barra entera si no tiene segmentos).
func get_segment_width_px(camera_size: float, screen_height: float = 1080.0) -> float:
	var count: int = maxi(segments, 1)
	return float(bar_size.x) / float(count) * pixel_size * screen_height / camera_size


func _build_separators() -> void:
	for i: int in range(1, segments):
		var separator: ColorRect = ColorRect.new()
		separator.color = separator_color
		separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var x: float = float(bar_size.x) * float(i) / float(segments) - SEPARATOR_PX / 2.0
		separator.position = Vector2(x, 0.0)
		separator.size = Vector2(SEPARATOR_PX, bar_size.y)
		_viewport.add_child(separator)
		_separators.append(separator)
