class_name LevelAudio
extends Node
## Audio propio del nivel (ADR-006 §2; scene-tree.md §3, común a 3D y 2D): música (BG) en el bus
## `Music` y ambiente (FOL) en `Ambience`, que arrancan con `round_started` y mueren con el nivel,
## y la cue `phase_up` en `SFX` al oír `phase_changed` con fase ≥ 2. `process_mode` `ALWAYS` en
## la raíz: en pausa BG y FOL siguen sonando, atenuados por `AudioDirector` (audio-y-fx AC3).
## No toca el volumen de ningún bus.

const DEFAULT_MAP: AudioFeedbackMap = preload("res://data/audio/feedback_map.tres")
const PHASE_CUE: StringName = &"phase_up"
## Señal de fases de `EventBus` (PUL-070): solo se conecta si el bus la declara.
const PHASE_SIGNAL: StringName = &"phase_changed"

## Bucle de música (BG).
@export var music: AudioStream
## Bucle de ambiente (FOL).
@export var ambience: AudioStream
@export var map: AudioFeedbackMap = DEFAULT_MAP

var _bus: Node

@onready var _music: AudioStreamPlayer = %Music
@onready var _ambience: AudioStreamPlayer = %Ambience
@onready var _phase_cue: AudioStreamPlayer = %PhaseCue


func _ready() -> void:
	if _bus == null:
		_bus = EventBus
	if map == null:
		map = DEFAULT_MAP
	_music.stream = music
	_ambience.stream = ambience
	_bus.round_started.connect(_on_round_started)
	if _bus.has_signal(PHASE_SIGNAL):
		_bus.connect(PHASE_SIGNAL, _on_phase_changed)


## Inyecta el bus (tests). Llamar antes de añadir el nodo al árbol; por defecto, el autoload.
func set_bus(bus: Node) -> void:
	_bus = bus


func _on_round_started(_duration: float) -> void:
	_start(_music)
	_start(_ambience)


func _start(player: AudioStreamPlayer) -> void:
	if player.stream != null and not player.playing:
		player.play()


func _on_phase_changed(phase: int) -> void:
	if phase < 2:
		return
	var cue: AudioCue = map.get_cue(PHASE_CUE)
	if cue == null or cue.stream == null:
		push_warning("LevelAudio: falta la cue %s" % PHASE_CUE)
		return
	_phase_cue.stream = cue.stream
	_phase_cue.volume_db = cue.volume_db
	_phase_cue.play()
