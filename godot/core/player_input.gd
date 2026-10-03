class_name PlayerInput
extends RefCounted
## Lectura de input de un jugador (ADR-004 §3). Cachea los nombres de acción `p<n>_*`.

var player_index: int
var deadzone: float

var _move_left: StringName
var _move_right: StringName
var _move_up: StringName
var _move_down: StringName
var _interact: StringName


func _init(index: int = 1, move_deadzone: float = 0.2) -> void:
	player_index = index
	deadzone = move_deadzone
	var prefix: String = "p%d_" % index
	_move_left = StringName(prefix + "move_left")
	_move_right = StringName(prefix + "move_right")
	_move_up = StringName(prefix + "move_up")
	_move_down = StringName(prefix + "move_down")
	_interact = StringName(prefix + "interact")


## Plano de pantalla/suelo: x a la derecha, y hacia la cámara.
## Cero bajo la zona muerta; por encima, vector unitario (como el prototipo).
func get_move_vector() -> Vector2:
	var raw: Vector2 = Input.get_vector(_move_left, _move_right, _move_up, _move_down, deadzone)
	return raw.normalized()


func is_interact_just_pressed() -> bool:
	return Input.is_action_just_pressed(_interact)


## Para `_unhandled_input`: la pausa y la UI consumen el evento antes.
func is_interact_event(event: InputEvent) -> bool:
	return event.is_action_pressed(_interact, false, true)
