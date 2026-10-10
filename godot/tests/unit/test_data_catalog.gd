extends GutTest
## AC1: el catálogo trae las 4 comandas de D25 con receta y condimentos.

const CATALOG_PATH: String = "res://data/orders/order_catalog.tres"
const ROUND_CONFIG_PATH: String = "res://data/config/round_config.tres"


func _seasoning_types(order: OrderData) -> Array:
	var types: Array = []
	for s: SeasoningData in order.seasonings:
		types.append(s.type)
	return types


func test_ac1_catalog_has_four_orders() -> void:
	var catalog: OrderCatalog = load(CATALOG_PATH) as OrderCatalog
	assert_not_null(catalog)
	assert_gte(catalog.orders.size(), 4)
	assert_eq(catalog.max_active_orders, 4)


func test_ac1_order_1_a_feira_sweet_dressing() -> void:
	var order: OrderData = (load(CATALOG_PATH) as OrderCatalog).orders[0]
	assert_eq(order.recipe.display_name, "Á feira")
	assert_eq(order.recipe.ingredient.type, IngredientData.IngredientType.OCTOPUS)
	assert_eq(_seasoning_types(order), [SeasoningData.SeasoningType.SWEET_DRESSING])


func test_ac1_order_2_picante_hot_dressing() -> void:
	var order: OrderData = (load(CATALOG_PATH) as OrderCatalog).orders[1]
	assert_eq(order.recipe.display_name, "Picante")
	assert_eq(_seasoning_types(order), [SeasoningData.SeasoningType.HOT_DRESSING])


func test_ac1_order_3_con_cachelos() -> void:
	var order: OrderData = (load(CATALOG_PATH) as OrderCatalog).orders[2]
	assert_eq(order.recipe.display_name, "Con cachelos")
	assert_eq(
		_seasoning_types(order),
		[SeasoningData.SeasoningType.SWEET_DRESSING, SeasoningData.SeasoningType.CACHELOS]
	)


func test_ac1_order_4_bravo_cachelos() -> void:
	var order: OrderData = (load(CATALOG_PATH) as OrderCatalog).orders[3]
	assert_eq(order.recipe.display_name, "Bravo cachelos")
	assert_eq(
		_seasoning_types(order),
		[SeasoningData.SeasoningType.HOT_DRESSING, SeasoningData.SeasoningType.CACHELOS]
	)


func test_ac1_parity_values() -> void:
	var catalog: OrderCatalog = load(CATALOG_PATH) as OrderCatalog
	for order: OrderData in catalog.orders:
		assert_eq(order.recipe.ingredient.cook_time, 5.0)
		assert_eq(order.recipe.ingredient.total_capacity, 100.0)
		assert_eq(order.recipe.ingredient.amount_per_full_box, 50.0)


func test_pul006_ac5_round_config_performance_tiers() -> void:
	var config: RoundConfig = load(ROUND_CONFIG_PATH) as RoundConfig
	assert_eq(config.performance_thresholds, [1.0, 2.0, 3.0] as Array[float])
	assert_eq(
		config.performance_texts,
		(
			[
				"Pulpeiro ineficiente",
				"Pulpeiro aceptable",
				"Pulpeiro eficiente",
				"!Pulpeiro lexendario!",
			]
			as Array[String]
		)
	)


func test_translation_keys_are_explicit() -> void:
	var expected: Dictionary[String, String] = {
		"res://data/recipes/a_feira.tres": "RECIPE_A_FEIRA",
		"res://data/recipes/picante.tres": "RECIPE_PICANTE",
		"res://data/recipes/con_cachelos.tres": "RECIPE_CON_CACHELOS",
		"res://data/recipes/bravo_cachelos.tres": "RECIPE_BRAVO_CACHELOS",
		"res://data/seasonings/sweet_dressing.tres": "SEASONING_SWEET_DRESSING",
		"res://data/seasonings/hot_dressing.tres": "SEASONING_HOT_DRESSING",
		"res://data/seasonings/cachelos.tres": "SEASONING_CACHELOS",
	}
	for path: String in expected:
		var data: Resource = load(path)
		assert_eq(data.get("translation_key"), expected[path], path)


func test_pul114_dressings_share_the_exclusivity_group() -> void:
	var sweet: SeasoningData = load("res://data/seasonings/sweet_dressing.tres") as SeasoningData
	var hot: SeasoningData = load("res://data/seasonings/hot_dressing.tres") as SeasoningData
	var cachelos: SeasoningData = load("res://data/seasonings/cachelos.tres") as SeasoningData
	assert_eq(sweet.type, SeasoningData.SeasoningType.SWEET_DRESSING)
	assert_eq(hot.type, SeasoningData.SeasoningType.HOT_DRESSING)
	assert_eq(sweet.exclusivity_group, &"dressing")
	assert_eq(hot.exclusivity_group, &"dressing")
	assert_eq(cachelos.exclusivity_group, &"")
	assert_false(sweet.same_as(hot), "dulce y picante son distintos")
	assert_true(sweet.same_as(sweet))
