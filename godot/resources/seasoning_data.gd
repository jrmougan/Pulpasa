class_name SeasoningData
extends Resource
## Condimento (porta SpicesSO). `scene` queda vacía hasta la fase 6.

enum SeasoningType { SALT, PAPRIKA, HOT_PAPRIKA, OIL }

@export var display_name: String = ""
## Clave tr() explícita; no se deriva del nombre del fichero.
@export var translation_key: String = ""
@export var type: SeasoningType = SeasoningType.SALT
## Condimentos con el mismo grupo de exclusividad son mutuamente excluyentes (D4).
## Cadena vacía = sin exclusividad.
@export var exclusivity_group: StringName = &""
@export var color: Color = Color.WHITE
@export var icon: Texture2D
@export var scene: PackedScene


func same_as(other: SeasoningData) -> bool:
	if other == null:
		return false
	return self == other or type == other.type
