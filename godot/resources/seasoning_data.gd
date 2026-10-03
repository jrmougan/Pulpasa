class_name SeasoningData
extends Resource
## Condimento (porta SpicesSO). `scene` queda vacía hasta la fase 6.

enum SeasoningType { SALT, PAPRIKA, HOT_PAPRIKA }

@export var display_name: String = ""
@export var type: SeasoningType = SeasoningType.SALT
@export var color: Color = Color.WHITE
@export var scene: PackedScene
