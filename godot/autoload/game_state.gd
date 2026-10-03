extends Node
## Estado de sesión (ADR-002): modo de juego, pausa y cambios de escena.
## Sin lógica de juego: sigue vivo en pausa (PROCESS_MODE_ALWAYS).
## Emisor en el bus de pause_changed y, en M2, de device_assigned y device_disconnected.

## Rutas previstas por ADR-001 / scene-tree.md. Aún no existen: crearlas es de fases posteriores.
const MAIN_MENU_SCENE: String = "res://ui/menus/main_menu.tscn"
const LEVEL_SCENE: String = "res://scenes/levels/level_01.tscn"

var mode: GameMode.Mode = GameMode.Mode.SINGLE

var _bus: Node


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	if _bus == null:
		_bus = EventBus
	# M2 (ADR-004 §2): copiar aquí la plantilla de mando del InputMap, conectar
	# Input.joy_connection_changed y aplicar DeviceAssignment con apply_devices().


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
	mode = new_mode
	# M2: repartir mandos con DeviceAssignment según el modo y los mandos conectados.
	return _change_scene(LEVEL_SCENE)


## Vuelve al menú principal. Devuelve ERR_FILE_NOT_FOUND si la escena aún no existe.
func go_to_main_menu() -> Error:
	return _change_scene(MAIN_MENU_SCENE)


func _change_scene(path: String) -> Error:
	set_paused(false)
	if not ResourceLoader.exists(path):
		push_warning("GameState: escena %s aún no existe" % path)
		return ERR_FILE_NOT_FOUND
	return get_tree().change_scene_to_file(path)
