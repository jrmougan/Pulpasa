class_name WorldProgressBar
extends Sprite3D
## Barra de progreso en el mundo, siempre de cara a la cámara (billboard). Sustituye a
## SimpleProgressBar + FaceToCamera. Capa específica (ADR-003 §0, scene-tree.md §6): pinta un
## `ProgressBar` de un `SubViewport` propio.

@onready var _viewport: SubViewport = %Viewport
@onready var _bar: ProgressBar = %Bar


func _ready() -> void:
	texture = _viewport.get_texture()


## Progreso 0–1.
func set_progress(value: float) -> void:
	_bar.value = clampf(value, 0.0, 1.0)


func get_progress() -> float:
	return _bar.value
