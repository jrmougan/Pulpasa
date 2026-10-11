class_name HeldKind
extends RefCounted
## Traduce el objeto de la mano a `ActionRules.Held` (ADR-003 §11.1). Capa específica: conoce
## `Box` e `Ingredient`. Único sitio que clasifica la mano: lo usan todos los receptores y el
## detector.


static func of(item: Node) -> ActionRules.Held:
	if item == null or not is_instance_valid(item):
		return ActionRules.Held.NOTHING
	if item is Box:
		return _of_box(item as Box)
	if item is Ingredient:
		return _of_ingredient(item as Ingredient)
	return ActionRules.Held.OTHER


static func _of_box(box: Box) -> ActionRules.Held:
	if box.is_full():
		return ActionRules.Held.BOX_FULL
	if box.fill > 0.0:
		return ActionRules.Held.BOX_PARTIAL
	return ActionRules.Held.BOX_EMPTY


## Un quemado nunca llega a la mano: si llegara, cuenta como `OTHER`.
static func _of_ingredient(ingredient: Ingredient) -> ActionRules.Held:
	if ingredient.data == null:
		return ActionRules.Held.OTHER
	var octopus: bool = ingredient.data.type == IngredientData.IngredientType.OCTOPUS
	match ingredient.state:
		IngredientData.CookingState.RAW:
			return ActionRules.Held.OCTOPUS_RAW if octopus else ActionRules.Held.CACHELOS_RAW
		IngredientData.CookingState.COOKED:
			return ActionRules.Held.OCTOPUS_COOKED if octopus else ActionRules.Held.CACHELOS_COOKED
	return ActionRules.Held.OTHER
