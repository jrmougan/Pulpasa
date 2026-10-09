class_name StandPalette
extends Resource
## Color de cada puesto de entrega (D23, R13). Única forma de leerlo: `color_for`.
## Lo usan el ticket (franja) y el puesto (zona iluminada: `albedo_color` y `emission`).

## Colores de los toldos, índice `slot_id - 1`.
@export var colors: Array[Color] = []
## Para un `slot_id` fuera de rango (no se espera en el nivel).
@export var fallback: Color = Color.GRAY


func color_for(slot_id: int) -> Color:
	if slot_id < 1 or slot_id > colors.size():
		return fallback
	return colors[slot_id - 1]
