class_name BoxData
extends Resource
## Las pulsaciones por caja (4/6/10) vienen de los prefabs Small/Medium/Large.
## `scene` queda vacía hasta la fase 6.

@export var display_name: String = ""
@export var capacity: float = 100.0
## Pulsaciones (cortes) que llenan la caja; el llenado por corte es `1 / presses_to_fill`.
@export var presses_to_fill: int = 1
## Letra de talla («S», «M», «L») que muestran el ticket y el rack (R10).
@export var short_label: String = ""
## Silueta + letra de `assets/textures/ui/box_sizes/`; el mismo recurso en ticket y rack.
@export var icon: Texture2D
@export var scene: PackedScene
@export_multiline var description: String = ""


## Llenado de la caja tras `presses` cortes (0-1); exacto en el último corte.
func fill_after(presses: int) -> float:
	return clampf(float(presses) / float(maxi(presses_to_fill, 1)), 0.0, 1.0)
