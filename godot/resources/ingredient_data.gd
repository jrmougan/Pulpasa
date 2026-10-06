class_name IngredientData
extends Resource
## Ingrediente (porta IngredientSO). `scene` queda vacía hasta la fase 6.

enum IngredientType { OCTOPUS, CACHELOS }
enum CookingState { RAW, COOKED, BURNT }

@export var display_name: String = ""
@export var type: IngredientType = IngredientType.OCTOPUS
@export var is_cookable: bool = false
@export var is_cuttable: bool = false
@export var cook_time: float = 0.0
## Segundos que aguanta cocido en la olla, desde que termina la cocción, antes de quemarse
## (`BURNT`, olla-que-se-pasa). 0 = no se quema (variante de paridad de `coccion-pulpo.md`).
@export var burn_time: float = 0.0
## Segundos desde que termina la cocción hasta el aviso (`burn_warned`, barra parpadeando).
## Con `burn_time` > 0: `0 < warn_time` y `burn_time - warn_time >= 3` (ADR-006 §5).
@export var warn_time: float = 0.0
@export var total_capacity: float = 100.0
## Cantidad de ingrediente que gasta llenar una caja entera; cada corte gasta
## `BoxData.fill_per_press * amount_per_full_box` (PlayerInteractionController.cs:59).
@export var amount_per_full_box: float = 50.0
@export var scene: PackedScene
@export_multiline var description: String = ""
@export var as_seasoning: SeasoningData
