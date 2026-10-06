extends GutTest
## PUL-071: núcleo de la mezcla `AudioMix` (ADR-006 §2) y sus datos. AC3 de `audio-y-fx` es
## aritmética: en pausa `Music` y `Ambience` bajan ≥ 12 dB y vuelven al reanudar; `SFX` no cambia.

const MIX_DATA: AudioMixConfig = preload("res://data/audio/audio_mix.tres")
const DUCK_MIN_DB: float = 12.0


func _mix() -> AudioMix:
	return AudioMix.new(MIX_DATA)


func test_data_defaults_and_pause_duck() -> void:
	assert_almost_eq(MIX_DATA.music_volume, 0.7, 0.001)
	assert_almost_eq(MIX_DATA.ambience_volume, 0.7, 0.001)
	assert_almost_eq(MIX_DATA.sfx_volume, 1.0, 0.001)
	assert_true(MIX_DATA.pause_duck_db <= -DUCK_MIN_DB, "bajada en pausa ≥ 12 dB")


func test_volumes_start_from_config() -> void:
	var mix: AudioMix = _mix()
	assert_almost_eq(mix.get_volume(AudioMix.MUSIC), MIX_DATA.music_volume, 0.001)
	assert_almost_eq(mix.get_volume(AudioMix.AMBIENCE), MIX_DATA.ambience_volume, 0.001)
	assert_almost_eq(mix.get_volume(AudioMix.SFX), MIX_DATA.sfx_volume, 0.001)
	assert_almost_eq(mix.get_bus_db(AudioMix.SFX), 0.0, 0.001)
	assert_almost_eq(mix.get_bus_db(AudioMix.MUSIC), linear_to_db(0.7), 0.001)


func test_ac3_pause_ducks_music_and_ambience_only() -> void:
	var mix: AudioMix = _mix()
	var before: Dictionary[StringName, float] = {}
	for bus: StringName in AudioMix.BUSES:
		before[bus] = mix.get_bus_db(bus)
	mix.set_paused(true)
	assert_true(mix.get_bus_db(AudioMix.MUSIC) <= before[AudioMix.MUSIC] - DUCK_MIN_DB)
	assert_true(mix.get_bus_db(AudioMix.AMBIENCE) <= before[AudioMix.AMBIENCE] - DUCK_MIN_DB)
	assert_almost_eq(mix.get_bus_db(AudioMix.SFX), before[AudioMix.SFX], 0.001, "SFX igual")
	mix.set_paused(false)
	for bus: StringName in AudioMix.BUSES:
		assert_almost_eq(mix.get_bus_db(bus), before[bus], 0.001, "%s vuelve" % bus)


func test_zero_volume_is_silence_and_never_below_floor() -> void:
	var mix: AudioMix = _mix()
	mix.set_volume(AudioMix.MUSIC, 0.0)
	assert_eq(mix.get_bus_db(AudioMix.MUSIC), AudioMix.MIN_DB)
	mix.set_paused(true)
	assert_eq(mix.get_bus_db(AudioMix.MUSIC), AudioMix.MIN_DB)
	mix.set_volume(AudioMix.AMBIENCE, 0.00001)
	assert_eq(mix.get_bus_db(AudioMix.AMBIENCE), AudioMix.MIN_DB, "recorta en −80")


func test_set_volume_clamps_to_unit_range() -> void:
	var mix: AudioMix = _mix()
	mix.set_volume(AudioMix.SFX, 3.0)
	assert_eq(mix.get_volume(AudioMix.SFX), 1.0)
	mix.set_volume(AudioMix.SFX, -1.0)
	assert_eq(mix.get_volume(AudioMix.SFX), 0.0)


func test_null_config_uses_defaults() -> void:
	var mix: AudioMix = AudioMix.new(null)
	assert_almost_eq(mix.get_volume(AudioMix.MUSIC), 0.7, 0.001)
	mix.set_paused(true)
	assert_true(mix.is_paused())
