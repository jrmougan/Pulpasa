extends Control
## Sandbox de los controles táctiles (PUL-128): fondo de prueba, `TouchControls` y teclas 1-6 que
## simulan los seis hints del botón de acción. No arranca ronda ni toca el mundo.
## Capturas: `godot --path godot --resolution 2340x1080 res://ui/touch/sandbox/touch_sandbox.tscn
## -- --touch --capture=<carpeta>` guarda un PNG por estado y sale. Con 2340 de ancho simula la
## safe area 132 / 0 / 132 / 63; con otro tamaño no hay safe area.

const SAFE_LEFT: float = 132.0
const SAFE_BOTTOM: float = 63.0
const ARG_CAPTURE: String = "--capture="
## (nombre, verbo, estado, motivo) de los seis casos del diseño (AC8).
const CASES: Array[Array] = [
	["idle", &"", 0, &""],
	["pick_up", &"pick_up", 1, &""],
	["cut", &"cut", 1, &""],
	["season_hot", &"season_hot", 1, &""],
	["blocked", &"season_sweet", 2, &"box_not_full"],
	["drop", &"drop", 1, &""],
]

@onready var _controls: TouchControls = %TouchControls
@onready var _caption: Label = %Caption


func _ready() -> void:
	await get_tree().process_frame
	var window: Vector2 = Vector2(get_window().size)
	if window.x >= 2300.0:
		var safe: Rect2 = Rect2(SAFE_LEFT, 0.0, window.x - 2.0 * SAFE_LEFT, window.y - SAFE_BOTTOM)
		_controls.apply_safe_rect(safe, window)
	_show_case(0)
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with(ARG_CAPTURE):
			_capture(argument.trim_prefix(ARG_CAPTURE))


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed:
		return
	var index: int = key.keycode - KEY_1
	if index >= 0 and index < CASES.size():
		_show_case(index)


func _show_case(index: int) -> void:
	var case: Array = CASES[index]
	EventBus.action_hint_changed.emit(1, case[1], case[2], case[3])
	_caption.text = "[%d] %s" % [index + 1, case[0]]


func _touch(index: int, position: Vector2, pressed: bool) -> void:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = index
	event.position = position / _scale()
	event.pressed = pressed
	get_viewport().push_input(event, true)
	Input.flush_buffered_events()


func _drag(index: int, position: Vector2) -> void:
	var event: InputEventScreenDrag = InputEventScreenDrag.new()
	event.index = index
	event.position = position / _scale()
	get_viewport().push_input(event, true)


func _scale() -> float:
	return get_viewport().get_final_transform().get_scale().y


func _capture(directory: String) -> void:
	DirAccess.make_dir_recursive_absolute(directory)
	var size: Vector2i = get_window().size
	var tag: String = "%dx%d" % [size.x, size.y]
	for i: int in CASES.size():
		_show_case(i)
		await _frames(4)
		_save("%s/%s_%s.png" % [directory, tag, CASES[i][0]])
	# Stick activo con el dedo a media carrera, y el botón de acción pulsado con CORTAR.
	_show_case(2)
	_touch(0, Vector2(300.0, 700.0), true)
	_drag(0, Vector2(375.0, 640.0))
	_touch(1, Vector2(size.x - 270.0, size.y - 201.0), true)
	await _frames(4)
	_save("%s/%s_stick_and_press.png" % [directory, tag])
	get_tree().quit()


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().process_frame


func _save(path: String) -> void:
	var image: Image = get_viewport().get_texture().get_image()
	var error: Error = image.save_png(path)
	print("captura %s (%dx%d) -> %d" % [path, image.get_width(), image.get_height(), error])
