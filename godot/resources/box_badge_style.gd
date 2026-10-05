class_name BoxBadgeStyle
extends Resource
## Estilo de las pegatinas de condimento (D18): lo comparten la fila de la caja (`BadgeRow`, mundo)
## y el ticket (HUD) para que tamaño relativo y marca de picante sean los mismos.

## Lado de cada pegatina en pantalla, en px a 1280×720.
@export var badge_icon_px: int = 24
## Separación entre pegatinas, en px.
@export var badge_gap_px: int = 3
## Altura de la fila sobre la tapa de la caja, en m.
@export var badge_height: float = 0.35
## Marca de llama del picante: distingue dulce y picante sin depender del color.
@export var hot_mark: Texture2D


## Si la pegatina de `seasoning` lleva `hot_mark` (pimentón picante).
func has_hot_mark(seasoning: SeasoningData) -> bool:
	return seasoning != null and seasoning.type == SeasoningData.SeasoningType.HOT_PAPRIKA
