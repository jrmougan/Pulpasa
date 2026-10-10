extends GutTest
## PUL-113 AC1 (D25): una sola caja de 6 cortes; sin tallas S/M/L, letra ni icono.

const BOX_PATH: String = "res://data/boxes/box.tres"


func test_ac1_single_box_with_six_presses() -> void:
	var box: BoxData = load(BOX_PATH) as BoxData
	assert_not_null(box)
	if box == null:
		return
	assert_eq(box.presses_to_fill, 6)
	assert_eq(box.fill_after(6), 1.0, "llena exacto en 6")
	assert_lt(box.fill_after(5), 1.0, "no llena antes")
	assert_eq(box.capacity, 100.0)


func test_ac1_only_one_box_resource_in_data() -> void:
	var files: PackedStringArray = DirAccess.get_files_at("res://data/boxes")
	var tres: Array[String] = []
	for file: String in files:
		if file.ends_with(".tres"):
			tres.append(file)
	assert_eq(tres, ["box.tres"] as Array[String])


func test_ac1_box_data_has_no_size_label_or_icon() -> void:
	var names: Array[String] = []
	for prop: Dictionary in (load(BOX_PATH) as BoxData).get_property_list():
		names.append(str(prop["name"]))
	assert_false(names.has("short_label"))
	assert_false(names.has("icon"))


func test_ac1_box_scene_defaults_to_the_single_box() -> void:
	var box: Box = (load("res://entities/items/box.tscn") as PackedScene).instantiate() as Box
	assert_eq(box.data.resource_path, BOX_PATH)
	box.free()


func test_ac1_recipes_no_longer_carry_a_box() -> void:
	var names: Array[String] = []
	for prop: Dictionary in RecipeData.new().get_property_list():
		names.append(str(prop["name"]))
	assert_false(names.has("box"))
