class_name TouchHudLayout
extends RefCounted
## Medidas de la banda superior en MOBILE (controles-tactiles.md, «Maquetación de la banda
## superior»; ADR-005 E4). Todo en px de pantalla a 1080 de alto; UiScale.px_to_units las pasa a
## unidades de lienzo. Puro: sin nodos.

## Margen a los bordes de la safe area (`button_margin_px` del diseño).
const EDGE_MARGIN_PX: float = 48.0
## Distancia del borde superior al HUD y a los tickets.
const TOP_PX: float = 24.0
## Diámetro del botón de pausa (esquina superior derecha; lo monta PUL-128).
const PAUSE_BUTTON_PX: float = 120.0
## Hueco mínimo entre el HUD, los tickets y el botón de pausa.
const BLOCK_GAP_PX: float = 24.0
## Tickets en la fila: uno por puesto.
const TICKET_COUNT: int = 4


## Desplazamiento (px) del borde izquierdo de la fila de tickets respecto a la safe area.
static func tickets_left_px(profile: UiProfile) -> float:
	return EDGE_MARGIN_PX + profile.hud_block_width + BLOCK_GAP_PX


## Espacio (px) que se deja a la derecha de la fila para el botón de pausa.
static func tickets_right_px() -> float:
	return EDGE_MARGIN_PX + PAUSE_BUTTON_PX + BLOCK_GAP_PX


## Ancho de cada ticket: `clamp((disponible - huecos) / 4, min, max)`.
static func ticket_width_px(available_px: float, profile: UiProfile) -> float:
	var gaps: float = profile.ticket_gap * float(TICKET_COUNT - 1)
	var width: float = (available_px - gaps) / float(TICKET_COUNT)
	return clampf(width, profile.ticket_width_min, profile.ticket_width_max)
