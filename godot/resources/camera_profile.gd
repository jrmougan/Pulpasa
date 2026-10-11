class_name CameraProfile
extends Resource
## Perfil de cámara por plataforma (ADR-005 E5). Capa común: solo números y `Vector2`.

## `size` de la Camera3D ortográfica (alto de la vista en m).
@export var ortho_size: float = 12.74
## Si la cámara sigue al personaje activo (móvil); si no, queda fija como en D14.
@export var follow: bool = false
## Tiempo de la amortiguación crítica del seguimiento (s).
@export var follow_time: float = 0.2
## Duración del paneo al cambiar de personaje (s, ease-out).
@export var switch_pan_time: float = 0.35
## Cuánto puede salir la vista del límite jugable (m).
@export var camera_margin_m: float = 1.0
## Límite jugable del nivel en el suelo, (x, z).
@export var play_area_min: Vector2 = Vector2(-7.0, -5.0)
@export var play_area_max: Vector2 = Vector2(9.4, 6.6)
## Dato de verificación: px/m mínimos sobre el personaje a 1080 de alto (0 = sin exigencia).
@export var px_per_meter_min: float = 0.0
## Lado de la flecha de borde en px a 1080 de alto.
@export var offscreen_arrow_px: float = 48.0
## Si la banda superior de HUD y tickets (y la safe area) cuenta como zona tapada: el foco se
## calcula sobre la parte visible. Su alto sale de `UiProfile.top_band_max_px`.
@export var respect_top_band: bool = false
## Alto (m) que debe verse sobre un punto del borde norte del área: anillo de la olla,
## prompt y cabeza (solo con `respect_top_band`).
@export var top_reach_height_m: float = 0.0
