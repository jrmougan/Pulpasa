class_name SeasoningStation
extends StaticBody3D
## Estación de condimentos al paso (D23, ADR-003 §8; scene-tree.md §3): mostrador de pase de
## 5,2 m con dos dispensadores de aliño y el cuenco de cachelos, sin bandeja: actúan sobre la
## caja que el actor lleva en la mano. No es `interactable`: lo son sus hijos. Da a los hijos el
## lado del jugador (`side_of`). No suena nada (D26.3, ADR-003 §11.7): el rechazo de un
## dispensador o del cuenco lo reproduce el jugador (`rejected`); el `rejected` local de los hijos
## solo queda para tests.

const DEFAULT_DATA: SeasoningStationData = preload("res://data/config/seasoning_station.tres")

@export var data: SeasoningStationData = DEFAULT_DATA

@onready var _dispensers: Node3D = $Dispensers
@onready var _bowl: CachelosBowl = $CachelosBowl
@onready var _pass_side: Node3D = %PassSide
@onready var _operator_side: Node3D = %OperatorSide


func _ready() -> void:
	if data == null:
		data = DEFAULT_DATA
	for child: Node in _dispensers.get_children():
		var dispenser: SeasoningDispenser = child as SeasoningDispenser
		if dispenser != null:
			if dispenser.station == null:
				dispenser.station = self
	if _bowl != null:
		if _bowl.station == null:
			_bowl.station = self


## Lado del mostrador en que está `floor_position` (`(x, z)` global), según `%PassSide` y
## `%OperatorSide` proyectados al suelo (ADR-003 §8.1).
func side_of(floor_position: Vector2) -> StationSide.Side:
	var pass_point: Vector3 = _pass_side.global_position
	var operator_point: Vector3 = _operator_side.global_position
	return StationSide.classify(
		floor_position,
		Vector2(pass_point.x, pass_point.z),
		Vector2(operator_point.x, operator_point.z)
	)
