extends GutTest
## PUL-124 (D26, ADR-006 §4.1): los cues de respuesta y de estado suenan distinto.

const MAP: AudioFeedbackMap = preload("res://data/audio/feedback_map.tres")
const NEW_CUES: Array[StringName] = [
	&"trash", &"discard", &"cook_ready", &"burn_warning", &"box_full", &"switch", &"rejected"
]
const OLD_CUES: Array[StringName] = [&"pick_up", &"drop", &"cook_start", &"cut", &"season"]
const MAX_LENGTH: float = 0.6


func _path(cue: StringName) -> String:
	return MAP.get_cue(cue).stream.resource_path


func test_new_cues_have_seven_distinct_streams() -> void:
	var seen: Dictionary[String, StringName] = {}
	for cue: StringName in NEW_CUES:
		var path: String = _path(cue)
		assert_false(seen.has(path), "%s repite el sample de %s" % [cue, seen.get(path, "")])
		seen[path] = cue


func test_new_cues_differ_from_the_basic_ones() -> void:
	for cue: StringName in NEW_CUES:
		for other: StringName in OLD_CUES:
			assert_ne(_path(cue), _path(other), "%s suena como %s" % [cue, other])


func test_new_cues_are_short_and_visible() -> void:
	for cue: StringName in NEW_CUES:
		var data: AudioCue = MAP.get_cue(cue)
		assert_lt(data.stream.get_length(), MAX_LENGTH, "%s: demasiado largo" % cue)
		assert_gt(data.stream.get_length(), 0.05, "%s: vacío" % cue)
		assert_gte(data.visual_time, 0.3, "%s: visual_time" % cue)


func test_rejected_shakes() -> void:
	var data: AudioCue = MAP.get_cue(&"rejected")
	assert_eq(data.visual, AudioCue.Visual.SHAKE)
	assert_almost_eq(data.visual_time, 0.35, 0.001)
	assert_almost_eq(data.shake_amplitude, 0.06, 0.001)


func test_legacy_keys_are_gone() -> void:
	for cue: StringName in [&"cook_done", &"season_error", &"deliver_error"]:
		assert_null(MAP.get_cue(cue), String(cue))
