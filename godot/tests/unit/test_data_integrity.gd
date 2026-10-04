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
	assert_eq(paths.size(), 22)
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


func test_ac3_seasoning_colors_are_distinct_and_opaque() -> void:
	var expected: Dictionary = {
		"salt": Color(0.5931827, 0.8113208, 0.7928984, 1.0),
		"paprika": Color(0.95, 0.55, 0.2, 1.0),
		"hot_paprika": Color(0.85, 0.12, 0.1, 1.0),
	}
	for id: String in expected:
		var seasoning: SeasoningData = load("res://data/seasonings/%s.tres" % id) as SeasoningData
		assert_not_null(seasoning, id)
		if seasoning:
			assert_eq(seasoning.color, expected[id] as Color, id)
			assert_eq(seasoning.color.a, 1.0, "%s: color opaco" % id)
	var sweet: SeasoningData = load("res://data/seasonings/paprika.tres")
	var hot: SeasoningData = load("res://data/seasonings/hot_paprika.tres")
	assert_ne(sweet.color, hot.color, "dulce y picante se distinguen")


## PUL-015: parámetros de puntuación del detector (InteractionDetector.cs).
func test_ac1_player_config_has_detector_scoring_values() -> void:
	var cfg: PlayerConfig = load("res://data/config/player_config.tres") as PlayerConfig
	assert_almost_eq(cfg.detector_cone_half_angle, 30.0, 0.001)
	assert_almost_eq(cfg.detector_near_distance, 0.7, 0.001)
	assert_almost_eq(cfg.detector_kitchen_bonus, 1.0, 0.001)
	assert_almost_eq(cfg.detector_origin_height, 0.8, 0.001)


## Comandas AC5: el catálogo de la alpha cumple los rangos de M1 (paciencia 40–90 s,
## base 8–14 €) y hay plantillas con aceite y con pimentón.
func test_comandas_ac5_m1_data_ranges() -> void:
	var catalog: OrderCatalog = load("res://data/orders/order_catalog.tres") as OrderCatalog
	assert_gte(catalog.orders.size(), 4, "al menos 4 plantillas distintas")
	var has_oil: bool = false
	var has_paprika: bool = false

	for order: OrderData in catalog.orders:
		assert_between(order.max_time, 40.0, 90.0, "La paciencia debe estar entre 40 y 90")
		assert_between(order.recipe.base_points, 8, 14, "El precio base debe estar entre 8 y 14")
		for s: SeasoningData in order.seasonings:
			if s.type == SeasoningData.SeasoningType.OIL:
				has_oil = true
			if (
				s.type == SeasoningData.SeasoningType.PAPRIKA
				or s.type == SeasoningData.SeasoningType.HOT_PAPRIKA
			):
				has_paprika = true

	assert_true(has_oil, "Debe haber al menos una comanda con aceite")
	assert_true(has_paprika, "Debe haber al menos una comanda con pimentón")
