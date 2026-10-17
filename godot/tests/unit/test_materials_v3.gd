extends GutTest
## PUL-182: biblioteca cerrada de materiales planos v3 (art-bible §3.1, D28).

const MAT_DIR := "res://assets/materials/v3/"
const TENT_PLATE := "mat_tent_plate.tres"
const HIDDEN_ALPHA := "mat_hidden_alpha.tres"
const TENT_PLATE_TEXTURE := "res://assets/models/environment/romeria_v2/tent_plate_albedo.png"
const COLOR_TOLERANCE := 0.005
const MAX_TRES := 20

## Materiales opacos: nombre de archivo → [hex, roughness].
const OPAQUE: Dictionary[String, Array] = {
	"mat_ground_sand.tres": ["#C4A882", 0.95],
	"mat_wall_granite.tres": ["#9A948C", 0.92],
	"mat_meadow_green.tres": ["#4FA05A", 0.95],
	"mat_surface_top.tres": ["#EDE8DF", 0.85],
	"mat_brand_navy.tres": ["#1D3557", 0.90],
	"mat_brand_red.tres": ["#C8402F", 0.80],
	"mat_ui_cream.tres": ["#F7F4EC", 0.90],
	"mat_octopus_raw.tres": ["#E0AFB2", 0.88],
	"mat_octopus_cooked.tres": ["#B8283D", 0.65],
	"mat_potato_raw.tres": ["#8E6B47", 0.92],
	"mat_cachelos_cooked.tres": ["#F2D56B", 0.80],
	"mat_state_burnt.tres": ["#2A2320", 0.95],
	"mat_paprika_sweet.tres": ["#D6361F", 0.75],
	"mat_paprika_hot.tres": ["#8F1A14", 0.75],
	"mat_p1_blue.tres": ["#2F6FB5", 0.75],
	"mat_p2_amber.tres": ["#F2C230", 0.75],
}


func _list_tres() -> PackedStringArray:
	var names: PackedStringArray = []
	for file_name: String in DirAccess.get_files_at(MAT_DIR):
		if file_name.ends_with(".tres"):
			names.append(file_name)
	names.sort()
	return names


func _load(file_name: String) -> StandardMaterial3D:
	return load(MAT_DIR + file_name) as StandardMaterial3D


func _assert_no_maps(mat: StandardMaterial3D, file_name: String) -> void:
	assert_eq(mat.metallic, 0.0, "%s metallic" % file_name)
	assert_eq(mat.specular_mode, BaseMaterial3D.SPECULAR_DISABLED, "%s specular_mode" % file_name)
	assert_false(mat.normal_enabled, "%s normal_enabled" % file_name)
	assert_null(mat.normal_texture, "%s normal_texture" % file_name)
	assert_false(mat.ao_enabled, "%s ao_enabled" % file_name)
	assert_null(mat.ao_texture, "%s ao_texture" % file_name)
	assert_null(mat.roughness_texture, "%s roughness_texture" % file_name)
	assert_null(mat.metallic_texture, "%s metallic_texture" % file_name)


func _assert_color_close(actual: Color, expected: Color, label: String) -> void:
	for channel: int in 4:
		assert_almost_eq(actual[channel], expected[channel], COLOR_TOLERANCE, label)


func test_ac1_catalogo_cerrado_de_18_materiales() -> void:
	var names: PackedStringArray = _list_tres()
	var expected: PackedStringArray = PackedStringArray(OPAQUE.keys())
	expected.append(TENT_PLATE)
	expected.append(HIDDEN_ALPHA)
	expected.sort()
	assert_eq(names.size(), 18, "la biblioteca v3 debe tener 18 .tres")
	assert_lte(names.size(), MAX_TRES, "más de %d .tres en v3" % MAX_TRES)
	assert_eq(names, expected, "catálogo v3 distinto del de art-bible §3.1")
	for file_name: String in names:
		assert_not_null(_load(file_name), "%s no carga como StandardMaterial3D" % file_name)


func test_ac2_materiales_opacos_planos() -> void:
	for file_name: String in OPAQUE:
		var mat: StandardMaterial3D = _load(file_name)
		assert_not_null(mat, "no carga %s" % file_name)
		if mat == null:
			continue
		var spec: Array = OPAQUE[file_name]
		_assert_color_close(mat.albedo_color, Color(spec[0] as String), file_name)
		assert_almost_eq(mat.roughness, spec[1] as float, 0.001, "%s roughness" % file_name)
		assert_null(mat.albedo_texture, "%s albedo_texture" % file_name)
		assert_eq(
			mat.transparency, BaseMaterial3D.TRANSPARENCY_DISABLED, "%s transparency" % file_name
		)
		_assert_no_maps(mat, file_name)


func test_ac3_tent_plate_solo_lleva_su_albedo() -> void:
	var mat: StandardMaterial3D = _load(TENT_PLATE)
	assert_not_null(mat)
	if mat == null:
		return
	_assert_color_close(mat.albedo_color, Color("#F7F4EC"), TENT_PLATE)
	assert_not_null(mat.albedo_texture, "tent_plate sin textura")
	if mat.albedo_texture != null:
		assert_eq(mat.albedo_texture.resource_path, TENT_PLATE_TEXTURE)
	assert_almost_eq(mat.roughness, 0.90, 0.001, "tent_plate roughness")
	_assert_no_maps(mat, TENT_PLATE)


func test_ac3_hidden_alpha_es_transparente() -> void:
	var mat: StandardMaterial3D = _load(HIDDEN_ALPHA)
	assert_not_null(mat)
	if mat == null:
		return
	assert_eq(mat.transparency, BaseMaterial3D.TRANSPARENCY_ALPHA)
	assert_eq(mat.albedo_color.a, 0.0, "hidden_alpha debe ser invisible")
	assert_almost_eq(mat.roughness, 1.0, 0.001, "hidden_alpha roughness")
	_assert_no_maps(mat, HIDDEN_ALPHA)
