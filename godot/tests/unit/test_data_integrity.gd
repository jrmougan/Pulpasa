extends GutTest
## AC3: todos los .tres de data/ cargan con su tipo y sin referencias rotas.

const DATA_DIR: String = "res://data"


func _collect(dir_path: String, out: Array[String]) -> void:
	for file: String in DirAccess.get_files_at(dir_path):
		if file.ends_with(".tres"):
			out.append(dir_path.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir_path):
		_collect(dir_path.path_join(sub), out)


func test_ac3_all_tres_load() -> void:
	var paths: Array[String] = []
	_collect(DATA_DIR, paths)
	assert_eq(paths.size(), 21)
	for path: String in paths:
		var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		assert_not_null(res, path)


func test_ac3_no_missing_dependencies() -> void:
	var paths: Array[String] = []
	_collect(DATA_DIR, paths)
	for path: String in paths:
		for dep: String in ResourceLoader.get_dependencies(path):
			var dep_path: String = dep.get_slice("::", 2) if "::" in dep else dep
			assert_true(ResourceLoader.exists(dep_path), "%s -> %s" % [path, dep])


func test_ac3_references_are_filled() -> void:
	for id: String in ["individual", "combo_duo", "familiar"]:
		var recipe: RecipeData = load("res://data/recipes/%s.tres" % id) as RecipeData
		assert_not_null(recipe.ingredient, id)
		assert_not_null(recipe.box, id)


func test_ac3_seasoning_colors_match_prototype() -> void:
	var expected: Dictionary = {
		"salt": Color(0.5931827, 0.8113208, 0.7928984, 1.0),
		"paprika": Color(0, 0, 0, 0),
		"hot_paprika": Color(0, 0, 0, 0),
	}
	for id: String in expected:
		var seasoning: SeasoningData = load("res://data/seasonings/%s.tres" % id) as SeasoningData
		assert_not_null(seasoning, id)
		if seasoning:
			assert_eq(seasoning.color, expected[id] as Color, id)


## PUL-015: parámetros de puntuación del detector (InteractionDetector.cs).
func test_ac1_player_config_has_detector_scoring_values() -> void:
	var cfg: PlayerConfig = load("res://data/config/player_config.tres") as PlayerConfig
	assert_almost_eq(cfg.detector_cone_half_angle, 30.0, 0.001)
	assert_almost_eq(cfg.detector_near_distance, 0.7, 0.001)
	assert_almost_eq(cfg.detector_kitchen_bonus, 1.0, 0.001)
	assert_almost_eq(cfg.detector_origin_height, 0.8, 0.001)
