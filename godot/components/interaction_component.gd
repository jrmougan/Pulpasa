class_name InteractionComponent
extends Node
## Despacha la pulsación de interactuar (ADR-003 §3). Común a 3D y 2D.
##
## Guarda el objetivo que publica el detector (`target_changed`, conectado por nombre).
## Al pulsar `p<n>_interact`: si el objetivo acepta y consume, listo; si nada consume y la
## mano está llena, suelta. La lógica contextual (cortar, condimentar) vive en el receptor
## (ADR-003 §4), no aquí.

@export var control: ControlComponent
@export var holder: Holder
## Cualquier nodo con la señal `target_changed(previous, current)`.
@export var detector: Node

var _target: Node


func _ready() -> void:
	if detector != null:
		detector.connect(&"target_changed", _on_target_changed)


func _unhandled_input(event: InputEvent) -> void:
	var player_input: PlayerInput = control.get_player_input() if control != null else null
	if player_input == null or not player_input.is_interact_event(event):
		return
	interact_pressed()
	get_viewport().set_input_as_handled()


## Una pulsación de interactuar. Devuelve `true` si el objetivo la consumió.
func interact_pressed() -> bool:
	# B18: el objetivo puede haberse liberado desde la última señal.
	if is_instance_valid(_target) and _target.call(&"can_interact", self):
		if _target.call(&"interact", self):
			return true
	if holder != null and holder.get_held_item() != null:
		holder.drop()
		return true
	return false


func _on_target_changed(_previous: Node, current: Node) -> void:
	_target = current
