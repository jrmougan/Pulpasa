extends GutTest
## PUL-123 AC2: `action_icons.tres` tiene exactamente las claves del contrato (ADR-003 §11.1/§11.5),
## cada una con su textura, y los valores del diseño (`lenguaje-acciones.md`).

const SET_PATH: String = "res://data/config/action_icons.tres"
const ICON_DIR: String = "res://assets/textures/ui/actions/"
## Verbos y motivos del contrato: los conjuntos cerrados de `core/`.
const VERBS: Array[StringName] = ActionVerb.ALL
const REASONS: Array[StringName] = ActionReason.ALL
const MARKS: Array[String] = [
	"cross",
	"replace",
	"ready",
	"burn_warning",
	"active",
	"offscreen",
	"player_1",
	"player_2",
	"plate",
]

var _set: ActionIconSet


func before_each() -> void:
	_set = load(SET_PATH) as ActionIconSet


func test_loads_with_its_type() -> void:
	assert_not_null(_set, "action_icons.tres carga como ActionIconSet")


func test_verb_keys_are_exactly_the_contract() -> void:
	var keys: Array = _set.verb_icons.keys()
	keys.sort()
	var expected: Array = VERBS.duplicate()
	expected.sort()
	assert_eq(keys, expected)
	for verb: StringName in VERBS:
		_assert_texture(_set.verb_icons.get(verb), "verbo %s" % verb)


func test_reason_keys_are_exactly_the_contract() -> void:
	var keys: Array = _set.reason_icons.keys()
	keys.sort()
	var expected: Array = REASONS.duplicate()
	expected.sort()
	assert_eq(keys, expected)
	for reason: StringName in REASONS:
		_assert_texture(_set.reason_icons.get(reason), "motivo %s" % reason)


func test_marks_have_texture() -> void:
	_assert_texture(_set.plate, "plate")
	_assert_texture(_set.cross, "cross")
	_assert_texture(_set.replace, "replace")
	assert_eq(_set.player_markers.size(), 2, "marcadores J1 y J2")
	for marker: Texture2D in _set.player_markers:
		_assert_texture(marker, "player marker")


func test_every_icon_file_exists_and_is_128_square() -> void:
	var names: Array[String] = []
	for verb: StringName in VERBS:
		names.append("icon_verb_%s" % verb)
	for reason: StringName in REASONS:
		names.append("icon_reason_%s" % reason)
	for mark: String in MARKS:
		names.append("icon_mark_%s" % mark)
	for icon_name: String in names:
		var texture: Texture2D = load(ICON_DIR + icon_name + ".svg") as Texture2D
		assert_not_null(texture, icon_name)
		if texture != null:
			assert_eq(texture.get_size(), Vector2(128, 128), icon_name)


func test_design_values() -> void:
	assert_eq(_set.prompt_icon_px_1080, 64)
	assert_eq(_set.prompt_plate_px_1080, 80)
	assert_eq(_set.prompt_min_px, 48)
	assert_eq(_set.reason_icon_px_1080, 32)
	assert_eq(_set.cross_px_1080, 24)
	assert_almost_eq(_set.prompt_offset, 0.9, 0.0001)
	assert_almost_eq(_set.response_duration, 0.35, 0.0001)
	assert_eq(_set.reject_shake_px, 6)
	assert_eq(_set.ok_color.to_html(false), "ffffff")
	assert_eq(_set.blocked_color.to_html(false), "ffb020")
	assert_eq(_set.plate_color.to_html(false), "1b1b1f")
	assert_almost_eq(_set.plate_color.a, 0.85, 0.001)
	assert_eq(_set.idle_color.to_html(false), "6b6b73")
	assert_almost_eq(_set.idle_alpha, 0.4, 0.0001)


func _assert_texture(texture: Texture2D, what: String) -> void:
	assert_not_null(texture, what)
	if texture != null:
		assert_gt(texture.get_width(), 0, what)
