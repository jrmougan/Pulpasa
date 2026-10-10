class_name SeasoningData
extends Resource
## Condimento (porta SpicesSO). `scene` queda vacía hasta la fase 6.

## D25: SALT, PAPRIKA, HOT_PAPRIKA y OIL en desuso (sin `.tres`); los aliños van al final para no
## renumerar `CACHELOS` (4).
enum SeasoningType { SALT, PAPRIKA, HOT_PAPRIKA, OIL, CACHELOS, SWEET_DRESSING, HOT_DRESSING }

@export var display_name: String = ""
## Clave tr() explícita; no se deriva del nombre del fichero.
@export var translation_key: String = ""
@export var type: SeasoningType = SeasoningType.SALT
## Condimentos con el mismo grupo de exclusividad son mutuamente excluyentes (D4).
## Cadena vacía = sin exclusividad.
@export var exclusivity_group: StringName = &""
## Posición en el orden canónico de caja y ticket (`SeasoningRules.canonical_order`): aliño 0,
## cachelos 3. Iguales = sin orden entre ellos (dulce y picante son exclusivos).
@export var sort_order: int = 0
@export var color: Color = Color.WHITE
@export var icon: Texture2D
@export var scene: PackedScene


func same_as(other: SeasoningData) -> bool:
	if other == null:
		return false
	return self == other or type == other.type
