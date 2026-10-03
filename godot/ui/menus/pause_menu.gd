class_name PauseMenu
extends Control
## Overlay del nivel: la única fuente de pausa es SceneTree, a través de GameState.

var _round_finished: bool = false
var _game_state: Node

@onready var panel: MenuPanel = %MenuPanel


func _ready() -> void:
	if _game_state == null:
		_game_state = GameState
	panel.configure("Pausa", "Reanudar")
	panel.description.text = tr("La romería puede esperar un momento.")
	panel.ratio.hide()
	panel.primary_button.pressed.connect(_resume)
	panel.exit_button.pressed.connect(_exit)
	EventBus.pause_changed.connect(_on_pause_changed)
	EventBus.round_started.connect(_on_round_started)
	EventBus.round_finished.connect(_on_round_finished)
	_on_pause_changed(get_tree().paused)


func _input(event: InputEvent) -> void:
	if not _round_finished and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_game_state.set_paused(not get_tree().paused)


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
