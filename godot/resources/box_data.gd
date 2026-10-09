class_name BoxData
extends Resource
## Tipo de caja (porta BoxSO). `fill_per_press` viene de los prefabs Small/Medium/Large.
## `scene` queda vacía hasta la fase 6.

@export var display_name: String = ""
@export var capacity: float = 100.0
@export var fill_per_press: float = 0.0
## Letra de talla («S», «M», «L») que muestran el ticket y el rack (R10).
@export var short_label: String = ""
## Silueta + letra de `assets/textures/ui/box_sizes/`; el mismo recurso en ticket y rack.
@export var icon: Texture2D
@export var scene: PackedScene
@export_multiline var description: String = ""
