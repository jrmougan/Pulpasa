class_name SeasoningStation
extends StaticBody3D
## Estación de condimentos (D18, ADR-003 §8; scene-tree.md §3): mostrador de pase con la bandeja
## (`Tray`, un `Slot` de cajas), cuatro dispensadores y el cuenco de cachelos. No es `interactable`:
## lo son sus hijos. Da a los hijos el lado del jugador (`side_of`) y la caja de la bandeja
## (`get_box`), y oye sus rechazos: `%Feedback` suena `season_error` y sacude al emisor.

const DEFAULT_DATA: SeasoningStationData = preload("res://data/config/seasoning_station.tres")

@export var data: SeasoningStationData = DEFAULT_DATA

@onready var _tray: Slot = $Tray
@onready var _dispensers: Node3D = $Dispensers
@onready var _bowl: CachelosBowl = $CachelosBowl
@onready var _pass_side: Node3D = %PassSide
@onready var _operator_side: Node3D = %OperatorSide
@onready var _feedback: FeedbackPlayer = %Feedback


func _ready() -> void:
	if data == null:
		data = DEFAULT_DATA
	for child: Node in _dispensers.get_children():
		var dispenser: SeasoningDispenser = child as SeasoningDispenser
		if dispenser != null:
			if dispenser.station == null:
				dispenser.station = self
			dispenser.rejected.connect(_on_rejected.bind(dispenser))
	if _bowl != null:
		if _bowl.station == null:
			_bowl.station = self
		_bowl.rejected.connect(_on_rejected.bind(_bowl))


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


## Caja de la bandeja, o `null`.
func get_box() -> Box:
	return _tray.get_item() as Box


func get_tray() -> Slot:
	return _tray


## Sacudida en curso del `Model` de `emitter`, o `null` (para avanzarla a mano en tests).
func get_shake(emitter: Node3D) -> Tween:
	return _feedback.get_visual_tween(emitter)


func _on_rejected(_reason: SeasoningRules.Rejection, emitter: Node3D) -> void:
	_feedback.play_cue(&"season_error", emitter)
