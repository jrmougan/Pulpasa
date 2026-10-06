extends Node
## Adaptador de `AudioMix` (ADR-006 §2): único escritor del volumen de los buses `Music`,
## `Ambience` y `SFX`. Baja `Music` y `Ambience` en pausa (audio-y-fx AC3) al oír
## `pause_changed`. Receptor puro: no emite al bus ni reproduce nada (BG/FOL son de `LevelAudio`).

const CONFIG: AudioMixConfig = preload("res://data/audio/audio_mix.tres")

var _bus: Node
var _mix: AudioMix


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	if _bus == null:
		_bus = EventBus
	_mix = AudioMix.new(CONFIG)
	_mix.set_paused(get_tree().paused)
	_bus.pause_changed.connect(_on_pause_changed)
	_apply()


## Inyecta el bus (tests). Llamar antes de añadir el nodo al árbol; por defecto, el autoload.
func set_bus(bus: Node) -> void:
	_bus = bus


## Volumen de usuario (0–1) de `bus` (Should `opciones-de-volumen`).
func set_volume(bus: StringName, linear: float) -> void:
	_mix.set_volume(bus, linear)
	_apply()


func get_volume(bus: StringName) -> float:
	return _mix.get_volume(bus)


func _on_pause_changed(is_paused: bool) -> void:
	_mix.set_paused(is_paused)
	_apply()


func _apply() -> void:
	for bus: StringName in AudioMix.BUSES:
		var index: int = AudioServer.get_bus_index(bus)
		if index < 0:
			push_warning("AudioDirector: falta el bus %s" % bus)
			continue
		AudioServer.set_bus_volume_db(index, _mix.get_bus_db(bus))
