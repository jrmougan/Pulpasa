class_name OrderValidator
extends RefCounted
## Validación pura de una caja contra una comanda (ADR-002, regla 5: validar no muta).


## M0 (paridad, B15): misma caja, mismo ingrediente cocido y especias pedidas ⊆ especias de la caja.
## Las especias de más se aceptan; M1 (D4) decidirá la igualdad exacta.
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
	for seasoning: SeasoningData in order_data.seasonings:
		if not contents.seasonings.has(seasoning):
			return false
	return true
