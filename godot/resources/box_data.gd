class_name BoxData
extends Resource
## Caja única (D25): `data/boxes/box.tres`, 6 cortes. `scene` queda vacía hasta la fase 6.

@export var display_name: String = ""
@export var capacity: float = 100.0
## Pulsaciones (cortes) que llenan la caja; el llenado por corte es `1 / presses_to_fill`.
@export_range(1, 20) var presses_to_fill: int = 1
## Segundos que se ve `total/total` en el corte que llena antes de ocultarse el contador (D26.6).
@export_range(0.1, 5.0) var counter_full_time: float = 0.5
@export var scene: PackedScene
@export_multiline var description: String = ""


## Llenado de la caja tras `presses` cortes (0-1); exacto en el último corte.
func fill_after(presses: int) -> float:
	return clampf(float(presses) / float(maxi(presses_to_fill, 1)), 0.0, 1.0)
