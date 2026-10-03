extends GutTest
## AC1: el catálogo trae las 3 comandas del prototipo con receta, caja y condimentos.

const CATALOG_PATH: String = "res://data/orders/order_catalog.tres"
const ROUND_CONFIG_PATH: String = "res://data/config/round_config.tres"


func _seasoning_types(order: OrderData) -> Array:
	var types: Array = []
	for s: SeasoningData in order.seasonings:
		types.append(s.type)
	return types


func test_ac1_catalog_has_three_orders() -> void:
	var catalog: OrderCatalog = load(CATALOG_PATH) as OrderCatalog
	assert_not_null(catalog)
	assert_eq(catalog.orders.size(), 3)
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


func test_ac1_order_3_combo_duo_without_spices() -> void:
	var order: OrderData = (load(CATALOG_PATH) as OrderCatalog).orders[2]
	assert_eq(order.recipe.display_name, "Pulpo Doble")
	assert_eq(order.recipe.box.display_name, "Mediana")
	assert_eq(order.seasonings.size(), 0)


func test_ac1_parity_values() -> void:
	var catalog: OrderCatalog = load(CATALOG_PATH) as OrderCatalog
	for order: OrderData in catalog.orders:
		assert_eq(order.max_time, 0.0)
		assert_eq(order.recipe.base_points, 0)
		assert_eq(order.recipe.ingredient.cook_time, 5.0)
	var config: RoundConfig = load(ROUND_CONFIG_PATH) as RoundConfig
	assert_eq(config.duration, 180.0)


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
