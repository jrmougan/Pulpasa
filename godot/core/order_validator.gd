class_name OrderValidator
extends RefCounted
## Validación pura de una caja contra una comanda (ADR-002, regla 5: validar no muta).


## M1 (D4/D17): misma caja, mismo ingrediente cocido e igualdad exacta del conjunto de condimentos.
## Condimento de más -> inválida; condimento de menos -> inválida; exacta -> válida.
static func matches(order_data: OrderData, contents: BoxContents) -> bool:
	if order_data == null or order_data.recipe == null or contents == null:
		return false
	var recipe: RecipeData = order_data.recipe
	if contents.box == null or contents.box != recipe.box:
		return false
	if contents.ingredient == null or contents.ingredient != recipe.ingredient:
		return false
	if contents.ingredient_state != IngredientData.CookingState.COOKED:
		return false
	if contents.seasonings.size() != order_data.seasonings.size():
		return false
	for seasoning: SeasoningData in order_data.seasonings:
		if not _has_seasoning(contents.seasonings, seasoning):
			return false
	for seasoning: SeasoningData in contents.seasonings:
		if not _has_seasoning(order_data.seasonings, seasoning):
			return false
	return true


static func _has_seasoning(list: Array[SeasoningData], target: SeasoningData) -> bool:
	if target == null:
		return false
	for item: SeasoningData in list:
		if item != null and item.same_as(target):
			return true
	return false
