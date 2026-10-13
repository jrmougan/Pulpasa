extends GutTest
## PUL-154 (H-04 del QA de D26): con el hook previo de `.gutconfig.json`
## (`tests/helpers/gut_pre_run.gd`) el panel de salida de GUT no se queda con el puntero, así que un
## clic real (`InputEventMouseButton` pulsar y soltar, entrado como evento del SO) llega al
## `Control` del juego que hay debajo, en el centro y en la esquina inferior derecha (donde va el
## panel compacto de GUT y los botones táctiles), sin tocar `TestOutput` desde el test. El hook
## solo actúa en headless (`tools/verify.sh`): con ventana la GUI de GUT conserva el ratón y el
## test queda pendiente.

var _button: Button
var _presses: int = 0


func before_each() -> void:
	_presses = 0
	_button = Button.new()
	_button.text = "Pantalla completa"
	_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_button.pressed.connect(_on_pressed)
	add_child_autofree(_button)
	await wait_process_frames(2)


func _on_pressed() -> void:
	_presses += 1


## Pulsa y suelta el botón izquierdo en `at` (unidades de la vista), como haría el SO.
func _click(at: Vector2) -> void:
	# `Input.parse_input_event` entra como un evento del SO: en px de ventana, no en unidades.
	var scale: float = get_tree().root.get_final_transform().get_scale().y
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at * scale
		event.global_position = at * scale
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await wait_process_frames(2)


func test_ac1_real_click_reaches_full_screen_button_under_gut_output() -> void:
	if DisplayServer.get_name() != "headless":
		pending("solo headless: con ventana la GUI de GUT conserva el ratón (PUL-154)")
		return
	var outputs: Array[Node] = get_tree().root.find_children("TestOutput", "", true, false)
	assert_gt(
		outputs.size(), 0, "el panel de salida de GUT está en el árbol (el caso que se cubre)"
	)
	var view: Rect2 = get_viewport().get_visible_rect()
	assert_eq(_button.get_global_rect(), view, "el botón cubre la vista entera")
	await _click(view.get_center())
	assert_eq(_presses, 1, "un clic en el centro emite `pressed` exactamente 1 vez")
	await _click(view.end - Vector2(20.0, 20.0))
	assert_eq(_presses, 2, "un clic en la esquina inferior derecha también llega al botón")
