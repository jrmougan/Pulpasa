extends SceneTree
## Generador de los datos de audio de PUL-071 (registro reproducible; no es parte del juego):
## data/audio/feedback_map.tres, data/audio/audio_mix.tres y default_bus_layout.tres.
## Uso: godot --headless --audio-driver Dummy --path godot -s "$PWD/docs/evidence/PUL-071/gen_audio_data.gd"

const A := "res://assets/audio/"


func _cue(file: String, visual: int, volume: float = 0.0, delay: float = 0.0, time: float = 0.4, pop: float = 0.15, jitter: float = 0.05, shake: float = 0.04) -> Resource:
	var cue: Resource = load("res://resources/audio_cue.gd").new()
	cue.stream = load(A + file)
	cue.visual = visual
	cue.volume_db = volume
	cue.delay = delay
	cue.visual_time = time
	cue.pop_scale = pop
	cue.pitch_jitter = jitter
	cue.shake_amplitude = shake
	return cue


func _init() -> void:
	var NONE := 0
	var POP := 1
	var SHAKE := 2
	var map: Resource = load("res://resources/audio_feedback_map.gd").new()
	var cues: Dictionary[StringName, AudioCue] = {}
	cues[&"pick_up"] = _cue("fx_grab.ogg", POP, -2.0, 0.0, 0.35, 0.3)
	cues[&"drop"] = _cue("fx_drop.ogg", NONE, -8.0)
	cues[&"cut"] = _cue("cut.ogg", POP, 0.0, 0.0, 0.3, 0.08)
	cues[&"cook_start"] = _cue("fx_drop.ogg", POP, 0.0, 0.0, 0.4, 0.1)
	cues[&"cook_done"] = _cue("fx_ui_click.ogg", POP, 0.0, 0.0, 0.4, 0.25)
	cues[&"season"] = _cue("pepper_mill.ogg", POP, 0.0, 0.0, 0.35, 0.2)
	cues[&"unseason"] = _cue("fx_ui_click.ogg", NONE, -6.0)
	cues[&"season_error"] = _cue("delivery_error.ogg", SHAKE, -3.0, 0.0, 0.3)
	cues[&"deliver_ok"] = _cue("delivery_ok.ogg", POP, 0.0, 0.0, 0.5, 0.2, 0.0)
	cues[&"deliver_error"] = _cue("delivery_error.ogg", SHAKE, 0.0, 0.0, 0.5, 0.15, 0.0, 0.12)
	cues[&"order_new"] = _cue("fx_order_new.ogg", POP, -2.0, 0.5, 0.4, 0.3, 0.0)
	cues[&"order_expired"] = _cue("fx_order_expired.ogg", SHAKE, 0.0, 0.0, 0.5, 0.15, 0.0, 0.08)
	cues[&"burn_warning"] = _cue("fx_burn_warning.ogg", NONE, -2.0, 0.0, 0.4, 0.15, 0.0)
	cues[&"burnt"] = _cue("fx_burned.ogg", SHAKE, 0.0, 0.0, 0.5, 0.15, 0.05, 0.08)
	cues[&"discard"] = _cue("fx_drop.ogg", POP, -2.0, 0.0, 0.35, 0.1)
	cues[&"phase_up"] = _cue("fx_phase_change.ogg", NONE, 0.0, 0.0, 0.4, 0.15, 0.0)
	map.cues = cues
	print(ResourceSaver.save(map, "res://data/audio/feedback_map.tres"))
	var mix: Resource = load("res://resources/audio_mix_config.gd").new()
	print(ResourceSaver.save(mix, "res://data/audio/audio_mix.tres"))
	var layout_bus := AudioServer.bus_count
	for bus_name: String in ["Music", "Ambience", "SFX"]:
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, bus_name)
		AudioServer.set_bus_send(i, &"Master")
	print(layout_bus, " ", ResourceSaver.save(AudioServer.generate_bus_layout(), "res://default_bus_layout.tres"))
	quit()
