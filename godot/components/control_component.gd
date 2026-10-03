class_name ControlComponent
extends Node
## Quién controla a un personaje (ADR-003 §3, ADR-004 §3). Común a 3D y 2D.
##
## `player_index` es la identidad del personaje; `controlled_by` el jugador que lo
## controla (0 = nadie). M0: un personaje con `controlled_by = 1`; el cambio es M2.

signal control_changed(controlled_by: int)

@export var player_index: int = 1
@export var config: InputConfig

## Jugador que controla este personaje; 0 = nadie. Emite `control_changed` solo si cambia.
@export var controlled_by: int = 1:
	set(value):
		if value == controlled_by:
			return
		controlled_by = value
		_rebuild_input()
		control_changed.emit(controlled_by)

var _player_input: PlayerInput


func _ready() -> void:
	_rebuild_input()


## Input del jugador que controla; `null` si nadie.
func get_player_input() -> PlayerInput:
	if _player_input == null:
		_rebuild_input()
	return _player_input


func _rebuild_input() -> void:
	if controlled_by <= 0:
		_player_input = null
		return
	var deadzone: float = (config if config != null else InputConfig.new()).deadzone
	_player_input = PlayerInput.new(controlled_by, deadzone)
