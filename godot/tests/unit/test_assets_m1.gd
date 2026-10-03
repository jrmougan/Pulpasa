extends GutTest
## PUL-031: iconos y placeholders de aceite, cachelos y estrellas (M1).

const ICON_DIR := "res://assets/textures/icons/"
const ICON_FILES: Array[String] = ["oil.svg", "potato.svg", "star_full.svg", "star_empty.svg"]
const PLACEHOLDER_DIR := "res://assets/models/placeholders/"
const PLACEHOLDER_FILES: Array[String] = [
	"oil_bottle.tscn",
	"cachelos_raw.tscn",
	"cachelos_cooked.tscn",
	"cachelera.tscn",
]


func test_ac1_iconos_cargan_como_texturas() -> void:
	for file_name: String in ICON_FILES:
		var texture: Texture2D = load(ICON_DIR + file_name) as Texture2D
		assert_not_null(texture, "no carga %s" % file_name)
		if texture != null:
			assert_gt(texture.get_width(), 0, "%s vacío" % file_name)


func test_ac1_placeholders_cargan_e_instancian() -> void:
	for file_name: String in PLACEHOLDER_FILES:
		var scene: PackedScene = load(PLACEHOLDER_DIR + file_name) as PackedScene
		assert_not_null(scene, "no carga %s" % file_name)
		if scene == null:
			continue
		var instance: Node3D = scene.instantiate() as Node3D
		assert_not_null(instance, "la raíz de %s no es Node3D" % file_name)
		if instance == null:
			continue
		add_child_autofree(instance)
		assert_not_null(instance.get_node_or_null("Front"), "%s sin marcador Front" % file_name)
		assert_gt(_count_meshes(instance), 0, "%s sin mallas" % file_name)


func test_ac1_cachelos_crudo_y_cocido_tienen_color_distinto() -> void:
	var raw_mat: StandardMaterial3D = load("res://assets/materials/ph_cachelo_raw.tres")
	var cooked_mat: StandardMaterial3D = load("res://assets/materials/ph_cachelo_cooked.tres")
	assert_not_null(raw_mat)
	assert_not_null(cooked_mat)
	if raw_mat == null or cooked_mat == null:
		return
	assert_ne(raw_mat.albedo_color, cooked_mat.albedo_color, "crudo y cocido deben distinguirse")


func test_ac2_atribuciones_mencionan_los_assets_nuevos() -> void:
	var credits: String = FileAccess.get_file_as_string("res://assets/CREDITS.md")
	assert_ne(credits, "", "no se lee CREDITS.md")
	var licenses: String = FileAccess.get_file_as_string("res://../docs/assets/licenses-pul-031.md")
	assert_ne(licenses, "", "no se lee licenses-pul-031.md")
	for file_name: String in ICON_FILES:
		assert_string_contains(credits, file_name, "CREDITS sin %s" % file_name)
		assert_string_contains(licenses, file_name, "licenses sin %s" % file_name)
	for file_name: String in PLACEHOLDER_FILES:
		assert_string_contains(licenses, file_name, "licenses sin %s" % file_name)
	for needle: String in ["CC BY 3.0", "Delapouite", "game-icons.net"]:
		assert_string_contains(credits, needle, "CREDITS sin «%s»" % needle)
		assert_string_contains(licenses, needle, "licenses sin «%s»" % needle)


func _count_meshes(node: Node) -> int:
	var count: int = 0
	if node is MeshInstance3D:
		count += 1
	for child: Node in node.get_children():
		count += _count_meshes(child)
	return count
