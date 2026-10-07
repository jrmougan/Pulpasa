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

## Marca PulpaSA (brand.md, propuesta A · Mariña).
const LOGO: Texture2D = preload("res://assets/textures/brand/pulpasa_horizontal.png")
const BACKGROUND: Color = Color("13202f")
const PAPER: Color = Color("f4efe6")
const NAVY: Color = Color("1d3557")

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
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
	# Logotipo horizontal sobre placa «papel» con borde marino (brand.md: fondos con detalle).
	var logo: Control = %Logo
	var rect: Rect2 = Rect2(logo.global_position - global_position, logo.size)
	var plate: StyleBoxFlat = StyleBoxFlat.new()
	plate.bg_color = PAPER
	plate.border_color = NAVY
	plate.set_border_width_all(4)
	plate.set_corner_radius_all(14)
	draw_style_box(plate, rect)
	var art: Vector2 = LOGO.get_size()
	var fit: float = minf(rect.size.x / art.x, rect.size.y / art.y)
	var drawn: Vector2 = art * fit
	draw_texture_rect(LOGO, Rect2(rect.get_center() - drawn / 2.0, drawn), false)


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
