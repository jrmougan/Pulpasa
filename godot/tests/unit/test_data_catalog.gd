extends GutTest
## AC1: el catálogo trae las 3 comandas del prototipo con receta, caja y condimentos.

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


func test_ac1_order_1_familiar_with_two_spices() -> void:
	var order: OrderData = (load(CATALOG_PATH) as OrderCatalog).orders[0]
	assert_eq(order.recipe.display_name, "Pulpo Familiar")
	assert_eq(order.recipe.box.display_name, "Grande")
	assert_eq(order.recipe.ingredient.type, IngredientData.IngredientType.OCTOPUS)
	assert_eq(
		_seasoning_types(order),
		[SeasoningData.SeasoningType.HOT_PAPRIKA, SeasoningData.SeasoningType.SALT]
	)


func test_ac1_order_2_individual_with_two_spices() -> void:
	var order: OrderData = (load(CATALOG_PATH) as OrderCatalog).orders[1]
	assert_eq(order.recipe.display_name, "Pulpo Individual")
	assert_eq(order.recipe.box.display_name, "Pequeña")
	assert_eq(
		_seasoning_types(order),
		[SeasoningData.SeasoningType.PAPRIKA, SeasoningData.SeasoningType.SALT]
	)


func test_ac1_order_3_combo_duo_with_oil() -> void:
	var order: OrderData = (load(CATALOG_PATH) as OrderCatalog).orders[2]
	assert_eq(order.recipe.display_name, "Pulpo Doble")
	assert_eq(order.recipe.box.display_name, "Mediana")
	# M1 (PUL-027): el combo duo lleva aceite (comandas AC5: plantillas con aceite y pimentón).
	assert_eq(_seasoning_types(order), [SeasoningData.SeasoningType.OIL])


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
		"res://data/recipes/familiar.tres": "RECIPE_FAMILIAR",
		"res://data/recipes/individual.tres": "RECIPE_INDIVIDUAL",
		"res://data/recipes/combo_duo.tres": "RECIPE_COMBO_DUO",
		"res://data/seasonings/salt.tres": "SEASONING_SALT",
		"res://data/seasonings/paprika.tres": "SEASONING_PAPRIKA",
		"res://data/seasonings/hot_paprika.tres": "SEASONING_HOT_PAPRIKA",
		"res://data/seasonings/oil.tres": "SEASONING_OIL",
	}
	for path: String in expected:
		var data: Resource = load(path)
		assert_eq(data.get("translation_key"), expected[path], path)


func test_pul028_ac1_seasoning_data_oil_and_exclusivity_groups() -> void:
	var salt: SeasoningData = load("res://data/seasonings/salt.tres") as SeasoningData
	var paprika: SeasoningData = load("res://data/seasonings/paprika.tres") as SeasoningData
	var hot_paprika: SeasoningData = load("res://data/seasonings/hot_paprika.tres") as SeasoningData
	var oil: SeasoningData = load("res://data/seasonings/oil.tres") as SeasoningData

	assert_not_null(oil)
	assert_eq(oil.display_name, "Aceite")
	assert_eq(oil.translation_key, "SEASONING_OIL")
	assert_eq(oil.type, SeasoningData.SeasoningType.OIL)
	assert_true(oil.same_as(oil))
	assert_false(oil.same_as(salt))
	assert_eq(oil.exclusivity_group, &"")

	assert_eq(paprika.exclusivity_group, &"paprika")
	assert_eq(hot_paprika.exclusivity_group, &"paprika")
	assert_eq(paprika.exclusivity_group, hot_paprika.exclusivity_group)
	assert_eq(salt.exclusivity_group, &"")


func test_pul033_ac1_at_least_two_orders_with_cachelos_and_valid_ranges() -> void:
	var catalog: OrderCatalog = load(CATALOG_PATH) as OrderCatalog
	var with_cachelos: int = 0
	var with_cachelos_and_oil_or_salt: int = 0
	for order: OrderData in catalog.orders:
		assert_between(order.max_time, 80.0, 180.0, order.display_name)
		assert_between(order.recipe.base_points, 8, 14, order.display_name)
		var types: Array = _seasoning_types(order)
		if types.has(SeasoningData.SeasoningType.CACHELOS):
			with_cachelos += 1
			if (
				types.has(SeasoningData.SeasoningType.OIL)
				or types.has(SeasoningData.SeasoningType.SALT)
			):
				with_cachelos_and_oil_or_salt += 1
	assert_gte(with_cachelos, 2, "al menos 2 comandas con cachelos")
	assert_gte(with_cachelos_and_oil_or_salt, 1, "una con cachelos + aceite o sal")
	var hot: bool = false
	for order: OrderData in catalog.orders:
		var t: Array = _seasoning_types(order)
		if (
			t.has(SeasoningData.SeasoningType.HOT_PAPRIKA)
			and t.has(SeasoningData.SeasoningType.CACHELOS)
		):
			hot = true
	assert_true(hot, "pimentón picante + cachelos")
