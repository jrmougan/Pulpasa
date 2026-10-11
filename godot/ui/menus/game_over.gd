class_name GameOver
extends Control
## Resultado por señal, sin sondeo ni cálculo local de productividad.

const STAR_FULL: Texture2D = preload("res://assets/textures/icons/star_full.svg")
const STAR_EMPTY: Texture2D = preload("res://assets/textures/icons/star_empty.svg")

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
	_set_touch_controls_enabled(true)


func _on_round_finished(result: RoundResult) -> void:
	if visible:
		return
	panel.description.text = tr(result.get_performance_description())
	panel.ratio.text = tr("Rendimiento: %.2f cajas/minuto") % result.boxes_per_minute
	%Revenue.text = tr("Recaudación: %d €") % result.revenue
	var stars: Array[Node] = %Stars.get_children()
	for i: int in range(stars.size()):
		(stars[i] as TextureRect).texture = STAR_FULL if i < result.stars else STAR_EMPTY
	show()
	_set_touch_controls_enabled(false)
	panel.focus_primary()


## El árbol no se pausa al acabar la ronda (el game over es un menú sobre el juego): los controles
## táctiles hermanos de la `UI` se sueltan, se ocultan y dejan de recibir input mientras dure.
## Al arrancar otra ronda se reactivan y recuperan su visibilidad según la última entrada.
func _set_touch_controls_enabled(enabled: bool) -> void:
	var parent: Node = get_parent()
	if parent == null:
		return
	for sibling: Node in parent.get_children():
		var touch: TouchControls = sibling as TouchControls
		if touch == null or touch.is_queued_for_deletion():
			continue
		if enabled:
			touch.process_mode = Node.PROCESS_MODE_INHERIT
			touch.set_last_source(touch.get_last_source())
		else:
			touch.release_all()
			touch.hide()
			touch.process_mode = Node.PROCESS_MODE_DISABLED
