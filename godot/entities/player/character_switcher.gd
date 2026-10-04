class_name CharacterSwitcher
extends Node
## Reparte los personajes entre jugadores (ADR-004 §4). Común a 3D y 2D: solo ve
## `ControlComponent`, nunca `Player`.
##
## Al `round_started` asigna según el modo (`SINGLE`: J1 al primero; `COOP_2P`: J1 y J2) y emite
## `character_switched` por cada asignación. En `SINGLE`, `p1_switch` pasa el control de J1 al
## siguiente personaje en la misma llamada, con `switch_cooldown` y solo con la ronda en curso.

const SWITCH_ACTION: StringName = &"p1_switch"

## Componentes de control de cada personaje, en orden de cambio.
@export var characters: Array[ControlComponent] = []
## `switch_cooldown` (InputConfig.tres).
@export var config: InputConfig

var _bus: Node
var _mode: GameMode.Mode = GameMode.Mode.SINGLE
var _mode_injected: bool = false
var _round_active: bool = false
var _since_switch: float = 0.0


func _ready() -> void:
	if config == null:
		config = InputConfig.new()
	if _bus == null:
		_bus = EventBus
	_bus.round_started.connect(_on_round_started)
	_bus.round_finished.connect(_on_round_finished)


func _process(delta: float) -> void:
	advance(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(SWITCH_ACTION, false, true):
		return
	if switch_pressed():
		get_viewport().set_input_as_handled()


## Inyecta el bus (tests). Llamar antes de añadir el nodo al árbol; por defecto, el autoload.
func set_bus(bus: Node) -> void:
	_bus = bus


## Fija el modo (tests); por defecto se lee `GameState.mode` al empezar la ronda.
func set_mode(mode: GameMode.Mode) -> void:
	_mode = mode
	_mode_injected = true


## Avanza el reloj del cooldown (lo llama `_process`; en pausa no corre).
func advance(delta: float) -> void:
	_since_switch += delta


## Una pulsación de cambiar. Devuelve `true` si J1 pasó al siguiente personaje.
func switch_pressed() -> bool:
	if not _round_active or _mode != GameMode.Mode.SINGLE or characters.size() < 2:
		return false
	if _since_switch < config.switch_cooldown:
		return false
	var current: int = _index_controlled_by(1)
	var next: int = (current + 1) % characters.size()
	if current >= 0:
		characters[current].controlled_by = 0
	characters[next].controlled_by = 1
	_since_switch = 0.0
	_bus.character_switched.emit(1, characters[next].player_index)
	return true


func _index_controlled_by(player: int) -> int:
	for i: int in characters.size():
		if characters[i].controlled_by == player:
			return i
	return -1


func _assign(players: int) -> void:
	for i: int in characters.size():
		characters[i].controlled_by = i + 1 if i < players else 0
	for i: int in mini(players, characters.size()):
		_bus.character_switched.emit(i + 1, characters[i].player_index)


func _on_round_started(_duration: float) -> void:
	if not _mode_injected:
		_mode = GameState.mode
	_assign(2 if _mode == GameMode.Mode.COOP_2P else 1)
	_round_active = true
	_since_switch = config.switch_cooldown


func _on_round_finished(_result: RoundResult) -> void:
	_round_active = false
