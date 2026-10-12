class_name UiProfile
extends Resource
## Escala y mínimos de UI por perfil de plataforma (ADR-005 E3). Todas las medidas son px de
## pantalla a 1080 de alto; UiScale.px_to_units las pasa a unidades de lienzo.

## Se aplica a `content_scale_factor` de la ventana raíz; multiplica el estiramiento del proyecto.
@export var content_scale: float = 1.0
## Tamaño mínimo de todo texto (0 = sin mínimo).
@export var text_min_px: float = 0.0
@export var menu_button_min_px: float = 90.0
@export var menu_button_gap_px: float = 24.0
## Ancho mínimo de la tarjeta de pausa y game over, en unidades de lienzo (0 = el de la escena).
@export var menu_card_width: float = 0.0
@export var ticket_width_min: float = 318.0
@export var ticket_width_max: float = 318.0
@export var ticket_height: float = 150.0
@export var ticket_gap: float = 18.0
@export var hud_block_width: float = 264.0
@export var top_band_max_px: float = 200.0
@export var ticket_icon_px: float = 48.0
@export var patience_bar_px: float = 12.0
## Zonas reservadas del táctil: stick (x < fracción del ancho, y >= top) y botones, anclada a la
## esquina inferior derecha de la safe area (ADR-005 E4, D27.2): x >= ancho - safe der. - width,
## y >= alto - safe inf. - height.
@export var stick_zone_fraction: float = 0.5
@export var stick_zone_top_px: float = 200.0
@export var button_zone_width_px: float = 390.0
## Alto de la zona de botones desde el borde inferior de la safe area.
@export var button_zone_height_px: float = 240.0
