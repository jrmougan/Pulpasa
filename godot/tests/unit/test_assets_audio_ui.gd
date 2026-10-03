extends GutTest
## PUL-009: SFX libres, fuente y tema por defecto.

const SFX_DIR := "res://assets/audio/"
const SFX_FILES: Array[String] = [
	"boiling_water_loop.ogg",
	"cut.ogg",
	"pepper_mill.ogg",
	"delivery_ok.ogg",
	"delivery_error.ogg",
]
const FONT_PATH := "res://assets/fonts/LiberationSans.ttf"
const THEME_PATH := "res://ui/theme/default_theme.tres"


func test_sfx_load_as_audio_streams() -> void:
	for file_name: String in SFX_FILES:
		var stream: AudioStream = load(SFX_DIR + file_name) as AudioStream
		assert_not_null(stream, "no carga %s" % file_name)
		if stream != null:
			assert_gt(stream.get_length(), 0.0, "%s vacío" % file_name)


func test_boiling_water_loops() -> void:
	var stream: AudioStreamOggVorbis = load(SFX_DIR + "boiling_water_loop.ogg")
	assert_not_null(stream)
	assert_true(stream.loop)


func test_one_shot_sfx_do_not_loop() -> void:
	for file_name: String in SFX_FILES.slice(1):
		var stream: AudioStreamOggVorbis = load(SFX_DIR + file_name)
		assert_not_null(stream, file_name)
		assert_false(stream.loop, "%s no debe repetirse" % file_name)


func test_default_theme_uses_bundled_font() -> void:
	var theme: Theme = load(THEME_PATH)
	assert_not_null(theme)
	var font: Font = load(FONT_PATH)
	assert_not_null(font)
	assert_eq(theme.default_font, font)
	assert_gt(theme.default_font_size, 0)


func test_icons_and_logo_load() -> void:
	var paths: Array[String] = [
		"res://assets/textures/icons/pepper-hot-solid.svg",
		"res://assets/textures/icons/octopus.svg",
		"res://assets/textures/icons/salt.svg",
		"res://assets/textures/icons/selection.svg",
		"res://assets/textures/logo/PulpaSA.png",
	]
	for path: String in paths:
		assert_not_null(load(path) as Texture2D, path)
