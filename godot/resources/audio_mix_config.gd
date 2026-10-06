class_name AudioMixConfig
extends Resource
## Volúmenes por defecto por bus y bajada en pausa (ADR-006 §2), en `data/audio/audio_mix.tres`.
## Defaults de `opciones-de-volumen` AC4.

## Volumen lineal (0–1) de cada bus.
@export_range(0.0, 1.0) var music_volume: float = 0.7
@export_range(0.0, 1.0) var ambience_volume: float = 0.7
@export_range(0.0, 1.0) var sfx_volume: float = 1.0
## dB que bajan `Music` y `Ambience` con el juego en pausa (audio-y-fx AC3: ≤ −12).
@export var pause_duck_db: float = -12.0
