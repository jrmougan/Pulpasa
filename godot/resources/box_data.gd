class_name BoxData
extends Resource
## Tipo de caja (porta BoxSO). `fill_per_press` viene de los prefabs Small/Medium/Large.
## `scene` queda vacía hasta la fase 6.

@export var display_name: String = ""
@export var capacity: float = 100.0
@export var fill_per_press: float = 0.0
@export var scene: PackedScene
@export_multiline var description: String = ""
