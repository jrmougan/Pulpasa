class_name RecipeData
extends Resource
## Receta (porta RecipeSO). `base_points` es 0 en paridad M0; M1 (D2) fija el precio base.

@export var display_name: String = ""
## Clave tr() explícita; no se deriva del nombre del fichero.
@export var translation_key: String = ""
@export var ingredient: IngredientData
@export var box: BoxData
@export var base_points: int = 0
@export var base_price: int = 0
@export_multiline var description: String = ""
