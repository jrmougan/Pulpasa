extends Node
## Estado de sesión (ADR-002): modo de juego, pausa y cambios de escena.
## Sin lógica de juego: sigue vivo en pausa (PROCESS_MODE_ALWAYS).
## Emisor en el bus de pause_changed, device_assigned y device_disconnected.
## Aplica al InputMap la asignación de mandos de DeviceAssignment (ADR-004 §2): solo reescribe
## los eventos de mando de las acciones `p<n>_*`; los de teclado no se tocan nunca.

## Rutas previstas por ADR-001 / scene-tree.md. Aún no existen: crearlas es de fases posteriores.
const MAIN_MENU_SCENE: String = "res://ui/menus/main_menu.tscn"
const LEVEL_SCENE: String = "res://scenes/levels/level_01.tscn"

const INPUT_CONFIG: InputConfig = preload("res://data/config/input_config.tres")
const MOVE_SUFFIXES: Array[String] = ["move_left", "move_right", "move_up", "move_down"]

var mode: GameMode.Mode = GameMode.Mode.SINGLE

var _bus: Node
## Valor de mando por jugador (índice 0 = J1); vacío hasta el primer reparto.
var _devices: Array[int] = []
## Mando desconectado -> jugador que lo tenía, para devolvérselo al reconectar.
var _lost_by: Dictionary = {}
var _round_active: bool = false
## Acción `p<n>_*` -> eventos de mando de la plantilla de project.godot.
var _pad_template: Dictionary = {}


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	if _bus == null:
		_bus = EventBus
	_copy_pad_template()
	_apply_deadzone()
	_bus.round_started.connect(_on_round_started)
	_bus.round_finished.connect(_on_round_finished)
	Input.joy_connection_changed.connect(handle_joy_connection)


## Inyecta el bus (tests). Llamar antes de añadir el nodo al árbol; por defecto, el autoload.
func set_bus(bus: Node) -> void:
	_bus = bus


## Pausa o reanuda el árbol. Emite pause_changed solo si el estado cambia.
func set_paused(paused: bool) -> void:
	if get_tree().paused == paused:
		return
	get_tree().paused = paused
	_bus.pause_changed.emit(paused)


## Fija el modo y carga el nivel. Devuelve ERR_FILE_NOT_FOUND si la escena aún no existe.
func start_level(new_mode: GameMode.Mode) -> Error:
	assign_devices(new_mode, Input.get_connected_joypads())
	return _change_scene(LEVEL_SCENE)


## Vuelve al menú principal. Devuelve ERR_FILE_NOT_FOUND si la escena aún no existe.
func go_to_main_menu() -> Error:
	_round_active = false
	return _change_scene(MAIN_MENU_SCENE)


## Reintentar del game over: recarga el nivel con el modo actual (el reparto de mandos de M2
## vive en start_level). Devuelve ERR_FILE_NOT_FOUND si la escena aún no existe.
func restart_level() -> Error:
	return start_level(mode)


## Fija el modo y reparte los mandos (`joypads` en orden de conexión). Emite device_assigned
## por jugador. start_level la llama con Input.get_connected_joypads().
func assign_devices(new_mode: GameMode.Mode, joypads: Array[int]) -> void:
	mode = new_mode
	_devices = DeviceAssignment.initial(new_mode, joypads)
	_lost_by.clear()
	apply_devices()
	for i: int in _devices.size():
		_bus.device_assigned.emit(i + 1, _devices[i])


## Valor de mando del jugador (1 o 2): id, DeviceAssignment.ANY o DeviceAssignment.NONE.
## Antes del primer reparto, NONE.
func get_device(player_index: int) -> int:
	if player_index < 1 or player_index > _devices.size():
		return DeviceAssignment.NONE
	return _devices[player_index - 1]


## Reescribe en el InputMap solo los eventos de mando de las acciones `p<n>_*`.
func apply_devices() -> void:
	for action: StringName in _pad_template:
		var device: int = get_device(_player_of(action))
		_remove_pad_events(action)
		if device == DeviceAssignment.NONE:
			continue
		for template: InputEvent in _pad_template[action]:
			var copy: InputEvent = template.duplicate()
			copy.device = device
			InputMap.action_add_event(action, copy)


## Restaura los eventos de mando de plantilla y olvida la asignación (tests: after_each).
func reset_input() -> void:
	_devices.clear()
	_lost_by.clear()
	_round_active = false
	for action: StringName in _pad_template:
		_remove_pad_events(action)
		for template: InputEvent in _pad_template[action]:
			InputMap.action_add_event(action, template.duplicate())


## Hot-plug (Input.joy_connection_changed). Pública para poder probarla sin mandos reales.
func handle_joy_connection(device: int, connected: bool) -> void:
	if _devices.is_empty():
		return
	if connected:
		_on_pad_connected(device)
	else:
		_on_pad_disconnected(device)


func _on_pad_connected(device: int) -> void:
	var player: int = DeviceAssignment.on_connected(_devices, mode, device, _lost_by)
	if player == 0:
		return
	_forget_losses_of(player)
	if _devices[player - 1] != DeviceAssignment.ANY:
		_devices[player - 1] = device
		apply_devices()
	_bus.device_assigned.emit(player, _devices[player - 1])


func _on_pad_disconnected(device: int) -> void:
	var remaining: Array[int] = Input.get_connected_joypads()
	remaining.erase(device)
	var player: int = DeviceAssignment.on_disconnected(_devices, device, remaining)
	if player == 0:
		return
	_lost_by[device] = player
	if _devices[player - 1] != DeviceAssignment.ANY:
		_devices[player - 1] = DeviceAssignment.NONE
		apply_devices()
		# Retirada (signals.md): antes del aviso, para que el último hecho sea la desconexión.
		_bus.device_assigned.emit(player, DeviceAssignment.NONE)
	if _round_active:
		set_paused(true)
		_bus.device_disconnected.emit(player)


func _forget_losses_of(player: int) -> void:
	for lost: int in _lost_by.keys():
		if _lost_by[lost] == player:
			_lost_by.erase(lost)


func _on_round_started(_duration: float) -> void:
	_round_active = true


func _on_round_finished(_result: RoundResult) -> void:
	_round_active = false


## La plantilla sale de ProjectSettings, no del InputMap vivo, por si ya se reescribió.
func _copy_pad_template() -> void:
	_pad_template.clear()
	for action: StringName in InputMap.get_actions():
		if not _is_player_action(action):
			continue
		var events: Array[InputEvent] = []
		var setting: Variant = ProjectSettings.get_setting("input/" + action)
		if setting is Dictionary:
			for event: InputEvent in setting.get("events", []):
				if _is_pad_event(event):
					events.append(event.duplicate())
		_pad_template[action] = events


func _apply_deadzone() -> void:
	for action: StringName in InputMap.get_actions():
		if not _is_player_action(action):
			continue
		for suffix: String in MOVE_SUFFIXES:
			if String(action).ends_with(suffix):
				InputMap.action_set_deadzone(action, INPUT_CONFIG.deadzone)


func _remove_pad_events(action: StringName) -> void:
	for event: InputEvent in InputMap.action_get_events(action):
		if _is_pad_event(event):
			InputMap.action_erase_event(action, event)


func _is_player_action(action: StringName) -> bool:
	return _player_of(action) > 0


## "p2_move_left" -> 2; 0 si la acción no es de jugador.
func _player_of(action: StringName) -> int:
	var name: String = String(action)
	if name.length() < 3 or name[0] != "p" or name[2] != "_" or not name[1].is_valid_int():
		return 0
	return name[1].to_int()


func _is_pad_event(event: InputEvent) -> bool:
	return event is InputEventJoypadButton or event is InputEventJoypadMotion


func _change_scene(path: String) -> Error:
	set_paused(false)
	if not ResourceLoader.exists(path):
		push_warning("GameState: escena %s aún no existe" % path)
		return ERR_FILE_NOT_FOUND
	return get_tree().change_scene_to_file(path)
