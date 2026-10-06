class_name AudioCue
extends Resource
## Un sonido del mapa de feedback (ADR-006 §4) y su respuesta visual. Lo reproduce un
## `FeedbackPlayer` de la escena donde ocurre el hecho.

## Respuesta visual sobre el objetivo: ninguna, rebote de escala o vaivén lateral.
enum Visual { NONE, POP, SHAKE }

@export var stream: AudioStream
@export var volume_db: float = 0.0
## Variación aleatoria del tono (± fracción) en cada reproducción.
@export var pitch_jitter: float = 0.05
## Espera (s de juego) antes de sonar; se congela en pausa.
@export var delay: float = 0.0
@export var visual: Visual = Visual.NONE
## Duración de la respuesta visual (s); la feature pide ≥ 0,3 s (audio-y-fx AC5).
@export var visual_time: float = 0.4
## Crecimiento máximo del `POP` (0,15 = +15 %).
@export var pop_scale: float = 0.15
## Desplazamiento lateral máximo del `SHAKE` (m).
@export var shake_amplitude: float = 0.04
