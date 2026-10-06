class_name AudioFeedbackMap
extends Resource
## Mapa evento → sonido/visual (ADR-006 §4), en `data/audio/feedback_map.tres`. Las claves son
## cerradas: las que lista la tabla del ADR.

@export var cues: Dictionary[StringName, AudioCue] = {}


## Cue de `key`, o `null` si el mapa no la tiene.
func get_cue(key: StringName) -> AudioCue:
	return cues.get(key) as AudioCue
