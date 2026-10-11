class_name TouchConfig
extends Resource
## Medidas y ajustes de los controles táctiles (ADR-004 §6.2, diseño `controles-tactiles.md`).
## Las medidas en px son de pantalla a 1080 de alto; UiScale las pasa a unidades de lienzo.

## 1 dp equivale a esto en px a 1080 de alto.
@export var px_per_dp_at_1080: float = 2.5
## Botón de acción (180 px) y botones de cambiar y pausa (120 px), en dp.
@export var action_button_dp: float = 72.0
@export var small_button_dp: float = 48.0
## Margen añadido a la zona táctil del botón de acción.
@export var hit_slop_px_1080: float = 12.0
## Margen de los botones a los bordes de la safe area y separación entre cambiar y acción.
@export var button_margin_px_1080: float = 48.0
@export var button_gap_px_1080: float = 24.0
## Base del stick (300 px) y recorrido del pulgar (150 px), en dp.
@export var stick_base_dp: float = 120.0
@export var stick_radius_dp: float = 60.0
@export_range(0.0, 1.0) var stick_deadzone: float = 0.2
## Fracción del ancho de pantalla (desde la izquierda) donde nace el stick.
@export_range(0.0, 1.0) var stick_zone_fraction: float = 0.5
## El stick no nace por encima de esta línea (banda de HUD y tickets).
@export var stick_zone_top_px_1080: float = 200.0
@export var stick_fade_s: float = 0.15
@export_group("Botones")
## Lado del icono dentro del botón de acción, en px a 1080 de alto.
@export var action_icon_px_1080: float = 96.0
## Escala del botón hundido y tiempo en alcanzarla.
@export var press_scale: float = 0.92
@export var press_time: float = 0.1
## Contorno del aro del estado OK y BLOQUEADO.
@export var ring_px_1080: float = 6.0
@export_group("Háptica")
@export var haptics_enabled: bool = true
@export var haptic_ok_ms: int = 20
@export var haptic_reject_ms: int = 20
