class_name GameOver
extends Control
## Resultado por señal, sin sondeo ni cálculo local de productividad.

var _game_state: Node

@onready var panel: MenuPanel = %MenuPanel


func _ready() -> void:
	if _game_state == null:
		_game_state = GameState
	hide()
	panel.configure("Turno terminado", "Reintentar")
	panel.primary_button.pressed.connect(_restart)
	panel.exit_button.pressed.connect(_exit)
	EventBus.round_started.connect(_on_round_started)
	EventBus.round_finished.connect(_on_round_finished)


## Inyección para pruebas; por defecto se usa el autoload. Llamar antes de _ready.
func set_game_state(state: Node) -> void:
	_game_state = state


func _restart() -> void:
	_game_state.restart_level()


func _exit() -> void:
	_game_state.go_to_main_menu()


func _on_round_started(_duration: float) -> void:
	hide()


func _on_round_finished(result: RoundResult) -> void:
	if visible:
		return
	panel.description.text = tr(result.get_performance_description())
	panel.ratio.text = tr("Rendimiento: %.2f cajas/minuto") % result.boxes_per_minute
	show()
	panel.focus_primary()
