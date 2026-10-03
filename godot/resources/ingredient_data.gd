class_name IngredientData
extends Resource
## Ingrediente (porta IngredientSO). `scene` queda vacía hasta la fase 6.

enum IngredientType { OCTOPUS }
enum CookingState { RAW, COOKED, BURNT }

@export var display_name: String = ""
@export var type: IngredientType = IngredientType.OCTOPUS
@export var is_cookable: bool = false
@export var is_cuttable: bool = false
@export var cook_time: float = 0.0
@export var total_capacity: float = 100.0
@export var scene: PackedScene
@export_multiline var description: String = ""
