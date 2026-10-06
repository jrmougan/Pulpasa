class_name AudioMix
extends RefCounted
## Núcleo de la mezcla (ADR-006 §2): volumen de usuario por bus y bajada en pausa, sin árbol ni
## `AudioServer`. `AudioDirector` lo adapta y es el único que escribe los buses.

const MUSIC: StringName = &"Music"
const AMBIENCE: StringName = &"Ambience"
const SFX: StringName = &"SFX"
## Buses que gestiona, en el orden en que se aplican.
const BUSES: Array[StringName] = [MUSIC, AMBIENCE, SFX]
## Silencio: suelo de cualquier bus.
const MIN_DB: float = -80.0

var _config: AudioMixConfig
var _volumes: Dictionary[StringName, float] = {}
var _paused: bool = false


func _init(config: AudioMixConfig) -> void:
	_config = config if config != null else AudioMixConfig.new()
	_volumes[MUSIC] = _config.music_volume
	_volumes[AMBIENCE] = _config.ambience_volume
	_volumes[SFX] = _config.sfx_volume


## Volumen lineal (0–1) de `bus`; fuera de rango se recorta.
func set_volume(bus: StringName, linear: float) -> void:
	_volumes[bus] = clampf(linear, 0.0, 1.0)


func get_volume(bus: StringName) -> float:
	return _volumes.get(bus, 1.0)


func set_paused(paused: bool) -> void:
	_paused = paused


func is_paused() -> bool:
	return _paused


## dB que debe tener `bus`: 0 → −80; si no, `linear_to_db`; en pausa `Music` y `Ambience` suman
## `pause_duck_db`. Nunca por debajo de −80.
func get_bus_db(bus: StringName) -> float:
	var linear: float = get_volume(bus)
	if linear <= 0.0:
		return MIN_DB
	var db: float = linear_to_db(linear)
	if _paused and (bus == MUSIC or bus == AMBIENCE):
		db += _config.pause_duck_db
	return maxf(db, MIN_DB)
