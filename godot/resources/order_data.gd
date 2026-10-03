class_name OrderData
extends Resource
## Plantilla de comanda (porta OrderSO). `max_time` 0 = sin paciencia (paridad M0).

@export var display_name: String = ""
@export var recipe: RecipeData
@export var seasonings: Array[SeasoningData] = []
@export var max_time: float = 0.0
@export_multiline var description: String = ""
