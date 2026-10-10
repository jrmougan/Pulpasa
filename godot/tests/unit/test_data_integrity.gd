extends GutTest
## AC3: todos los .tres de data/ cargan con su tipo y sin referencias rotas.

const DATA_DIR: String = "res://data"
## Carpetas de `data/` con un solo tipo de Resource.
const FOLDER_TYPES: Dictionary[String, String] = {
	"boxes": "BoxData",
	"ingredients": "IngredientData",
	"recipes": "RecipeData",
	"seasonings": "SeasoningData",
}
## Mínimo de `.tres` por carpeta: detecta un borrado sin fijar el total (añadir no rompe).
const MIN_PER_FOLDER: Dictionary[String, int] = {
	"audio": 2,
	"boxes": 1,
	"config": 6,
	"ingredients": 2,
	"orders": 5,
	"recipes": 4,
	"seasonings": 3,
}
## Datos que deben existir, con su tipo.
const KNOWN: Dictionary[String, String] = {
	"res://data/config/box_badges.tres": "BoxBadgeStyle",
	"res://data/config/input_config.tres": "InputConfig",
	"res://data/config/kitchen.tres": "KitchenData",
	"res://data/config/player_config.tres": "PlayerConfig",
	"res://data/config/round_config.tres": "RoundConfig",
	"res://data/config/seasoning_station.tres": "SeasoningStationData",
	"res://data/orders/order_catalog.tres": "OrderCatalog",
	"res://data/audio/feedback_map.tres": "AudioFeedbackMap",
	"res://data/audio/audio_mix.tres": "AudioMixConfig",
}


func _collect(dir_path: String, out: Array[String]) -> void:
	for file: String in DirAccess.get_files_at(dir_path):
		if file.ends_with(".tres"):
			out.append(dir_path.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir_path):
		_collect(dir_path.path_join(sub), out)


## Sin recuento exacto de `.tres` (PUL-071): cada ficha que añade datos lo rompía. Se comprueba
## que todo `.tres` de `data/` carga con una clase propia, que su carpeta fija el tipo cuando es
## homogénea y que existen, con su tipo, los conocidos.
func test_ac3_all_tres_load() -> void:
	var paths: Array[String] = []
	_collect(DATA_DIR, paths)
	for path: String in paths:
		var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		assert_not_null(res, path)
		if res == null:
			continue
		var type: String = _class_of(res)
		assert_ne(type, "", "%s: Resource con class_name" % path)
		var folder: String = path.get_base_dir().get_file()
		if FOLDER_TYPES.has(folder):
			assert_eq(type, FOLDER_TYPES[folder], path)
		elif folder == "orders":
			var catalog: bool = path.get_file().begins_with("order_catalog")
			assert_eq(type, "OrderCatalog" if catalog else "OrderData", path)
	var per_folder: Dictionary[String, int] = {}
	for path: String in paths:
		var folder_name: String = path.get_base_dir().get_file()
		per_folder[folder_name] = per_folder.get(folder_name, 0) + 1
	for folder_name: String in MIN_PER_FOLDER:
		assert_gte(
			per_folder.get(folder_name, 0), MIN_PER_FOLDER[folder_name], "data/%s" % folder_name
		)
	for path: String in KNOWN:
		assert_has(paths, path, "existe %s" % path)
		var known: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if known != null:
			assert_eq(_class_of(known), KNOWN[path], path)


func _class_of(res: Resource) -> String:
	var script: Script = res.get_script() as Script
	return String(script.get_global_name()) if script != null else ""


func test_ac3_no_missing_dependencies() -> void:
	var paths: Array[String] = []
	_collect(DATA_DIR, paths)
	for path: String in paths:
		for dep: String in ResourceLoader.get_dependencies(path):
			var dep_path: String = dep.get_slice("::", 2) if "::" in dep else dep
			assert_true(ResourceLoader.exists(dep_path), "%s -> %s" % [path, dep])


func test_ac3_references_are_filled() -> void:
	for id: String in ["a_feira", "picante", "con_cachelos", "bravo_cachelos"]:
		var recipe: RecipeData = load("res://data/recipes/%s.tres" % id) as RecipeData
		assert_not_null(recipe.ingredient, id)


func test_ac3_seasoning_colors_are_distinct_and_opaque() -> void:
	var expected: Dictionary = {
		"sweet_dressing": Color("D6361F"),
		"hot_dressing": Color("8F1A14"),
		"cachelos": Color("F2D56B"),
	}
	for id: String in expected:
		var seasoning: SeasoningData = load("res://data/seasonings/%s.tres" % id) as SeasoningData
		assert_not_null(seasoning, id)
		if seasoning:
			assert_true(seasoning.color.is_equal_approx(expected[id] as Color), id)
			assert_eq(seasoning.color.a, 1.0, "%s: color opaco" % id)
	var sweet: SeasoningData = load("res://data/seasonings/sweet_dressing.tres")
	var hot: SeasoningData = load("res://data/seasonings/hot_dressing.tres")
	assert_ne(sweet.color, hot.color, "dulce y picante se distinguen")


## PUL-015: parámetros de puntuación del detector (InteractionDetector.cs).
func test_ac1_player_config_has_detector_scoring_values() -> void:
	var cfg: PlayerConfig = load("res://data/config/player_config.tres") as PlayerConfig
	assert_almost_eq(cfg.detector_cone_half_angle, 30.0, 0.001)
	assert_almost_eq(cfg.detector_near_distance, 0.7, 0.001)
	assert_almost_eq(cfg.detector_kitchen_bonus, 1.0, 0.001)
	assert_almost_eq(cfg.detector_origin_height, 0.8, 0.001)


## condimentacion AC9 (D25): exactamente 3 SeasoningData (aliño dulce, aliño picante, cachelos); los
## aliños comparten el grupo "dressing"; no quedan .tres de sal, aceite ni pimentón sueltos.
func test_condimentacion_ac9_seasoning_catalog() -> void:
	var files: Array[String] = []
	for file: String in DirAccess.get_files_at("res://data/seasonings"):
		if file.ends_with(".tres"):
			files.append(file)
	files.sort()
	assert_eq(files, ["cachelos.tres", "hot_dressing.tres", "sweet_dressing.tres"])
	var types: Dictionary = {
		"sweet_dressing": SeasoningData.SeasoningType.SWEET_DRESSING,
		"hot_dressing": SeasoningData.SeasoningType.HOT_DRESSING,
	}
	for id: String in types:
		var dressing: SeasoningData = load("res://data/seasonings/%s.tres" % id) as SeasoningData
		assert_eq(dressing.type, types[id] as int, id)
		assert_eq(dressing.exclusivity_group, &"dressing", id)
	for old: String in ["salt", "oil", "paprika", "hot_paprika"]:
		assert_false(FileAccess.file_exists("res://data/seasonings/%s.tres" % old), old)


## Orden canónico de caja y ticket (aliño → cachelos, D25).
func test_pul114_seasoning_sort_order() -> void:
	var expected: Dictionary = {"sweet_dressing": 0, "hot_dressing": 0, "cachelos": 3}
	for id: String in expected:
		var seasoning: SeasoningData = load("res://data/seasonings/%s.tres" % id) as SeasoningData
		assert_eq(seasoning.sort_order, expected[id] as int, id)


## PUL-057: estilo de pegatinas compartido por BadgeRow y el ticket.
func test_pul057_box_badge_style_values() -> void:
	var style: BoxBadgeStyle = load("res://data/config/box_badges.tres") as BoxBadgeStyle
	assert_not_null(style)
	assert_eq(style.badge_icon_px, 24)
	assert_eq(style.badge_gap_px, 3)
	assert_almost_eq(style.badge_height, 0.35, 0.0001)
	assert_not_null(style.hot_mark)
	assert_eq(style.hot_mark.resource_path, "res://assets/textures/icons/small-fire.svg")
	var hot: SeasoningData = SeasoningData.new()
	hot.type = SeasoningData.SeasoningType.HOT_DRESSING
	var sweet: SeasoningData = SeasoningData.new()
	sweet.type = SeasoningData.SeasoningType.SWEET_DRESSING
	assert_true(style.has_hot_mark(hot))
	assert_false(style.has_hot_mark(sweet))
	assert_false(style.has_hot_mark(null))


## PUL-057 (revisión): toda pegatina necesita un color de fondo visible.
func test_pul057_every_seasoning_color_is_opaque() -> void:
	var count: int = 0
	for file: String in DirAccess.get_files_at("res://data/seasonings"):
		if not file.ends_with(".tres"):
			continue
		var seasoning: SeasoningData = load("res://data/seasonings/%s" % file) as SeasoningData
		assert_not_null(seasoning, file)
		if seasoning:
			assert_eq(seasoning.color.a, 1.0, "%s: color opaco" % file)
			count += 1
	assert_eq(count, 3, "los tres condimentos")


## PUL-058: balance de la estación de condimentos (feature estacion-condimentos, Datos).
func test_pul058_seasoning_station_values() -> void:
	var data: SeasoningStationData = (
		load("res://data/config/seasoning_station.tres") as SeasoningStationData
	)
	assert_not_null(data)
	assert_almost_eq(data.toggle_guard, 0.25, 0.0001)
	assert_eq(data.cachelos_stock_max, 4)
	assert_eq(data.cachelos_initial_stock, 0)
	assert_eq(data.cachelos_portions_per_item, 2)
	assert_null(data.get("paprika_swap"), "D25: sin paprika_swap")
	assert_true(data.operator_side_only)


## AC9 (dificultad-progresiva.md) y AC2 de PUL-115: el pool de cada fase está en datos.
func test_pul115_phase_pools_subset_of_catalog_and_per_phase() -> void:
	var config: RoundConfig = load("res://data/config/round_config.tres") as RoundConfig
	var catalog: OrderCatalog = load("res://data/orders/order_catalog.tres") as OrderCatalog
	var a_feira: OrderData = load("res://data/orders/a_feira.tres") as OrderData
	var picante: OrderData = load("res://data/orders/picante.tres") as OrderData
	var cachelos: OrderData = load("res://data/orders/con_cachelos.tres") as OrderData
	var bravo: OrderData = load("res://data/orders/bravo_cachelos.tres") as OrderData
	assert_eq(config.phases.size(), 3)
	assert_eq(config.phases[0].orders, [a_feira] as Array[OrderData], "fase 1")
	assert_eq(config.phases[1].orders.size(), 2, "fase 2")
	assert_true(config.phases[1].orders.has(a_feira))
	assert_true(config.phases[1].orders.has(picante))
	assert_eq(config.phases[2].orders.size(), 4, "fase 3")
	for order: OrderData in [a_feira, picante, cachelos, bravo]:
		assert_true(config.phases[2].orders.has(order))
	for phase: PhaseData in config.phases:
		for order: OrderData in phase.orders:
			assert_true(catalog.orders.has(order), "pool dentro del catálogo")
