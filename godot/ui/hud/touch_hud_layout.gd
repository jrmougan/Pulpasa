class_name TouchHudLayout
extends RefCounted
## Medidas de la banda superior en MOBILE (controles-tactiles.md, «Maquetación de la banda
## superior»; ADR-005 E4). Todo en px de pantalla a 1080 de alto; UiScale.px_to_units las pasa a
## unidades de lienzo. Puro: sin nodos.

const CONFIG: TouchConfig = preload("res://data/config/touch_config.tres")
## Distancia del borde superior al HUD y a los tickets (diseño: 24 px; sin dato propio).
const TOP_PX: float = 24.0
## Hueco mínimo entre el HUD, los tickets y el botón de pausa (diseño: 24 px; sin dato propio).
const BLOCK_GAP_PX: float = 24.0
## Tickets en la fila: uno por puesto.
const TICKET_COUNT: int = 4


## Margen a los bordes de la safe area: `button_margin_px_1080` de `touch_config.tres`.
static func edge_margin_px() -> float:
	return CONFIG.button_margin_px_1080


## Diámetro del botón de pausa: `small_button_dp` x `px_per_dp_at_1080`.
static func pause_button_px() -> float:
	return CONFIG.small_button_dp * CONFIG.px_per_dp_at_1080


## Desplazamiento (px) del borde izquierdo de la fila de tickets respecto a la safe area.
static func tickets_left_px(profile: UiProfile) -> float:
	return edge_margin_px() + profile.hud_block_width + BLOCK_GAP_PX


## Espacio (px) que se deja a la derecha de la fila para el botón de pausa.
static func tickets_right_px() -> float:
	return edge_margin_px() + pause_button_px() + BLOCK_GAP_PX


## Ancho de cada ticket: `clamp((disponible - huecos) / 4, min, max)`.
static func ticket_width_px(available_px: float, profile: UiProfile) -> float:
	var gaps: float = profile.ticket_gap * float(TICKET_COUNT - 1)
	var width: float = (available_px - gaps) / float(TICKET_COUNT)
	return clampf(width, profile.ticket_width_min, profile.ticket_width_max)
