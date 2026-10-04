extends Control
## Menú común: órdenes al autoload y foco nativo compartido por teclado y mando.

const TEXT: Dictionary[StringName, String] = {
	&"MENU_PLAY": "Individual",
	&"MENU_LOCAL_2P": "Local 2P",
	&"MENU_EXIT": "Salir",
	&"MENU_TAGLINE": "Pulpo á feira · Romerías gallegas",
	&"MENU_MODE": "Individual: un personaje · Local 2P: dos jugadores",
	&"MENU_LEVEL_UNAVAILABLE": "La cocina todavía no está disponible. Vuelve pronto.",
	&"MENU_LOAD_FAILED": "No se pudo abrir la cocina. Inténtalo de nuevo.",
}

var _start_level: Callable
var _quit: Callable

@onready var _play: Button = %Play
@onready var _local_2p: Button = %Local2P
@onready var _exit: Button = %Exit
@onready var _status: Label = %Status


func _ready() -> void:
	if not _start_level.is_valid():
		_start_level = GameState.start_level
	if not _quit.is_valid():
		_quit = get_tree().quit
	_play.text = _text(&"MENU_PLAY")
	_local_2p.text = _text(&"MENU_LOCAL_2P")
	_exit.text = _text(&"MENU_EXIT")
	%Tagline.text = _text(&"MENU_TAGLINE")
	%Mode.text = _text(&"MENU_MODE")
	_play.pressed.connect(_start.bind(GameMode.Mode.SINGLE, _play))
	_local_2p.pressed.connect(_start.bind(GameMode.Mode.COOP_2P, _local_2p))
	_exit.pressed.connect(_on_exit_pressed)
	_play.grab_focus()
	%Column.item_rect_changed.connect(queue_redraw)
	resized.connect(queue_redraw)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("fff7e8"))
	# Marca propia vectorial: pulpo sobre plato, sin assets del prototipo.
	var logo: Control = %Logo
	var center: Vector2 = logo.global_position - global_position + logo.size / 2.0
	var ink: Color = Color("b83d34")
	draw_circle(center, 62.0, Color("f2dcc0"))
	draw_arc(center, 62.0, 0.0, TAU, 64, ink, 2.0, true)
	draw_circle(center + Vector2(0, -12), 25.0, ink)
	for index: int in range(4):
		var x: float = -30.0 + index * 20.0
		draw_arc(center + Vector2(x, 14), 10.0, 0.0, PI, 20, ink, 8.0, true)
	draw_circle(center + Vector2(-8, -15), 3.5, Color("fff7e8"))
	draw_circle(center + Vector2(8, -15), 3.5, Color("fff7e8"))


## Inyección antes de _ready para verificar órdenes sin cambiar de escena ni cerrar GUT.
func set_actions(start_level: Callable, quit_action: Callable) -> void:
	_start_level = start_level
	_quit = quit_action


func _text(key: StringName) -> String:
	var translated: String = tr(key)
	return TEXT[key] if translated == String(key) else translated


func _start(mode: GameMode.Mode, source: Button) -> void:
	_play.disabled = true
	_local_2p.disabled = true
	var error: Error = _start_level.call(mode)
	if error != OK:
		_status.text = _text(
			&"MENU_LEVEL_UNAVAILABLE" if error == ERR_FILE_NOT_FOUND else &"MENU_LOAD_FAILED"
		)
		_status.show()
		_play.disabled = false
		_local_2p.disabled = false
		source.grab_focus()


func _on_exit_pressed() -> void:
	_quit.call()
