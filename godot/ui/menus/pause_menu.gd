class_name PauseMenu
extends Control
## Overlay del nivel: la única fuente de pausa es SceneTree, a través de GameState.

var _round_finished: bool = false
var _game_state: Node
var _disconnected: Dictionary[int, bool] = {}

@onready var panel: MenuPanel = %MenuPanel
@onready var _warning: Label = %DeviceWarning


func _ready() -> void:
	if _game_state == null:
		_game_state = GameState
	panel.configure("Pausa", "Reanudar")
	panel.description.text = tr("La romería puede esperar un momento.")
	panel.ratio.hide()
	# El aviso vive en la tarjeta (centrada), no en el borde superior donde van los tickets.
	_warning.reparent(panel.description.get_parent(), false)
	_warning.get_parent().move_child(_warning, panel.description.get_index() + 1)
	panel.primary_button.pressed.connect(_resume)
	panel.exit_button.pressed.connect(_exit)
	EventBus.pause_changed.connect(_on_pause_changed)
	EventBus.round_started.connect(_on_round_started)
	EventBus.round_finished.connect(_on_round_finished)
	EventBus.device_disconnected.connect(_on_device_disconnected)
	EventBus.device_assigned.connect(_on_device_assigned)
	_on_pause_changed(get_tree().paused)


func _input(event: InputEvent) -> void:
	if _round_finished:
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_game_state.set_paused(not get_tree().paused)
	elif get_tree().paused and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_game_state.set_paused(false)


## Inyección para pruebas; por defecto se usa el autoload. Llamar antes de _ready.
func set_game_state(state: Node) -> void:
	_game_state = state


func _resume() -> void:
	_game_state.set_paused(false)


func _exit() -> void:
	_game_state.go_to_main_menu()


func _on_pause_changed(paused: bool) -> void:
	visible = paused and not _round_finished
	if visible:
		panel.focus_primary()


func _on_round_started(_duration: float) -> void:
	_round_finished = false
	_on_pause_changed(get_tree().paused)


func _on_round_finished(_result: RoundResult) -> void:
	_round_finished = true
	hide()


func _on_device_disconnected(player_index: int) -> void:
	_disconnected[player_index] = true
	_refresh_warning()


func _on_device_assigned(player_index: int, _device: int) -> void:
	_disconnected.erase(player_index)
	_refresh_warning()


func _refresh_warning() -> void:
	var keys: Array[int] = _disconnected.keys()
	keys.sort()
	var lines: PackedStringArray = []
	for index: int in keys:
		lines.append(_text("PAUSE_DEVICE_DISCONNECTED", "Mando de J%d desconectado") % index)
	_warning.text = "\n".join(lines)
	_warning.visible = not lines.is_empty()


func _text(key: String, fallback: String) -> String:
	var translated: String = tr(key)
	return fallback if translated == key else translated
