class_name BoxContents
extends RefCounted
## Lo que lleva una caja al entregarla. Es el parámetro de `try_deliver`: el servicio valida datos,
## nunca un nodo (ADR-002, regla 4).

var box: BoxData
## `null` si la caja está vacía.
var ingredient: IngredientData
## Estado de cocción del ingrediente cortado en la caja (en M0 solo se corta pulpo cocido).
var ingredient_state: IngredientData.CookingState = IngredientData.CookingState.RAW
## Llenado 0–1.
var fill: float = 0.0
var seasonings: Array[SeasoningData] = []


func _init(
	p_box: BoxData = null,
	p_ingredient: IngredientData = null,
	p_ingredient_state: IngredientData.CookingState = IngredientData.CookingState.RAW,
	p_fill: float = 0.0,
	p_seasonings: Array[SeasoningData] = []
) -> void:
	box = p_box
	ingredient = p_ingredient
	ingredient_state = p_ingredient_state
	fill = p_fill
	seasonings = p_seasonings.duplicate()
