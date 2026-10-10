extends GutTest
## PUL-114 (comandas.md AC5, AC11 y AC12, D25): el catálogo de la alpha son 4 recetas por contenido,
## con los nombres, aliños, cachelos, precios y paciencias de la tabla de `comandas.md`, leídos de
## `.tres`. La selección por fase (AC13) es de `PhaseData.orders` (PUL-115).

const CATALOG_PATH: String = "res://data/orders/order_catalog.tres"
const SWEET: SeasoningData = preload("res://data/seasonings/sweet_dressing.tres")
const HOT: SeasoningData = preload("res://data/seasonings/hot_dressing.tres")
const CACHELOS: SeasoningData = preload("res://data/seasonings/cachelos.tres")
const MAX_NAME_LENGTH: int = 14
## Tabla de recetas de `comandas.md` (id de fichero → nombre, aliños, base_points, max_time).
const TABLE: Dictionary = {
	"a_feira": ["Á feira", [SWEET], 8, 60.0],
	"picante": ["Picante", [HOT], 9, 60.0],
	"con_cachelos": ["Con cachelos", [SWEET, CACHELOS], 12, 80.0],
	"bravo_cachelos": ["Bravo cachelos", [HOT, CACHELOS], 13, 80.0],
}

var _catalog: OrderCatalog


func before_each() -> void:
	_catalog = load(CATALOG_PATH) as OrderCatalog


func _order(id: String) -> OrderData:
	return load("res://data/orders/%s.tres" % id) as OrderData


func test_ac5_catalog_has_exactly_the_four_templates() -> void:
	assert_eq(_catalog.orders.size(), 4)
	assert_eq(_catalog.max_active_orders, 4)
	for id: String in TABLE:
		assert_has(_catalog.orders, _order(id), id)


func test_ac5_names_dressings_cachelos_prices_and_patience_match_the_table() -> void:
	for id: String in TABLE:
		var row: Array = TABLE[id]
		var order: OrderData = _order(id)
		assert_eq(order.recipe.display_name, row[0], id)
		assert_eq(order.display_name, row[0], id)
		assert_eq(
			order.recipe, load("res://data/recipes/%s.tres" % id), "receta 1:1 con la comanda"
		)
		assert_eq(order.recipe.base_points, row[2], "%s: precio" % id)
		assert_almost_eq(order.max_time, row[3] as float, 0.0001, "%s: paciencia" % id)
		var expected: Array = row[1]
		assert_eq(order.seasonings.size(), expected.size(), id)
		for index: int in expected.size():
			assert_true(order.seasonings[index].same_as(expected[index] as SeasoningData), id)
		assert_eq(
			order.recipe.ingredient, load("res://data/ingredients/octopus.tres"), "%s: pulpo" % id
		)


func test_ac5_each_template_has_one_dressing_and_cachelos_only_in_the_last_two() -> void:
	for id: String in TABLE:
		var order: OrderData = _order(id)
		var dressings: int = 0
		for seasoning: SeasoningData in order.seasonings:
			if seasoning.exclusivity_group == &"dressing":
				dressings += 1
		assert_eq(dressings, 1, "%s: exactamente 1 aliño" % id)
		var has_cachelos: bool = order.seasonings.any(
			func(s: SeasoningData) -> bool: return s.same_as(CACHELOS)
		)
		assert_eq(has_cachelos, id.contains("cachelos"), id)


func test_ac5_old_recipes_and_orders_are_gone() -> void:
	for gone: String in [
		"res://data/recipes/individual.tres",
		"res://data/recipes/combo_duo.tres",
		"res://data/recipes/familiar.tres",
		"res://data/orders/order_catalog_basic.tres",
	]:
		assert_false(FileAccess.file_exists(gone), gone)
	for index: int in range(1, 7):
		assert_false(FileAccess.file_exists("res://data/orders/order_%d.tres" % index), str(index))


func test_ac11_names_are_at_most_14_characters() -> void:
	var longest: int = 0
	for order: OrderData in _catalog.orders:
		longest = maxi(longest, order.recipe.display_name.length())
		assert_lte(order.recipe.display_name.length(), MAX_NAME_LENGTH, order.recipe.display_name)
	assert_eq(longest, MAX_NAME_LENGTH, "«Bravo cachelos» mide 14")


func test_ac12_price_grows_with_effort() -> void:
	assert_gt(_order("con_cachelos").recipe.base_points, _order("a_feira").recipe.base_points)
	assert_gt(_order("bravo_cachelos").recipe.base_points, _order("picante").recipe.base_points)
	for order: OrderData in _catalog.orders:
		assert_between(order.recipe.base_points, 8, 14, order.display_name)


func test_recipe_data_has_no_box_field() -> void:
	## ADR-003 §10.1: la receta ya no apunta a una caja (PUL-113).
	for order: OrderData in _catalog.orders:
		for property: Dictionary in order.recipe.get_property_list():
			assert_ne(property["name"], "box")
