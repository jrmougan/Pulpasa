extends SceneTree
## Generador tipado de escenas para PUL-021. Ejecutar con Godot --headless -s.

const DIRECTORY: String = "res://ui/menus/"
const THEME: Theme = preload("res://ui/theme/default_theme.tres")


func _initialize() -> void:
	_build_panel()
	_build_overlay("pause_menu", "PauseMenu")
	_build_overlay("game_over", "GameOver")
	_build_sandbox()
	quit()


func _attach(parent: Node, child: Node, node_name: String, owner_root: Node) -> void:
	child.name = node_name
	parent.add_child(child)
	child.owner = owner_root


func _full(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _save(node: Node, path: String) -> void:
	var packed: PackedScene = PackedScene.new()
	assert(packed.pack(node) == OK)
	assert(ResourceSaver.save(packed, path) == OK)
	node.free()


func _label(parent: Node, node_name: String, size: int, owner_root: Node) -> Label:
	var label: Label = Label.new()
	_attach(parent, label, node_name, owner_root)
	label.unique_name_in_owner = true
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _build_panel() -> void:
	var panel: Control = Control.new()
	panel.name = "MenuPanel"
	panel.set_script(load(DIRECTORY + "menu_panel.gd"))
	_full(panel)
	panel.theme = THEME
	var shade: ColorRect = ColorRect.new()
	_attach(panel, shade, "Shade", panel)
	_full(shade)
	shade.color = Color(0.04, 0.06, 0.08, 0.82)
	var center: CenterContainer = CenterContainer.new()
	_attach(panel, center, "Center", panel)
	_full(center)
	var card: PanelContainer = PanelContainer.new()
	_attach(center, card, "Card", panel)
	card.custom_minimum_size = Vector2(520, 0)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("20343d")
	style.set_corner_radius_all(16)
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 32
	style.content_margin_bottom = 32
	card.add_theme_stylebox_override("panel", style)
	var content: VBoxContainer = VBoxContainer.new()
	_attach(card, content, "Content", panel)
	content.add_theme_constant_override("separation", 20)
	var brand: Label = _label(content, "Brand", 18, panel)
	brand.text = "PULPASA"
	brand.modulate = Color("f0c37c")
	_label(content, "Title", 34, panel)
	_label(content, "Description", 22, panel)
	_label(content, "Ratio", 20, panel)
	var buttons: Array[Button] = []
	for node_name: String in ["PrimaryButton", "ExitButton"]:
		var button: Button = Button.new()
		_attach(content, button, node_name, panel)
		button.unique_name_in_owner = true
		button.custom_minimum_size.y = 52
		var focus: StyleBoxFlat = StyleBoxFlat.new()
		focus.bg_color = Color(0, 0, 0, 0)
		focus.border_color = Color("f0c37c")
		focus.set_border_width_all(3)
		focus.set_corner_radius_all(5)
		button.add_theme_stylebox_override("focus", focus)
		buttons.append(button)
	for index: int in range(2):
		var neighbor: NodePath = buttons[index].get_path_to(buttons[1 - index])
		buttons[index].focus_neighbor_top = neighbor
		buttons[index].focus_neighbor_bottom = neighbor
		buttons[index].focus_neighbor_left = neighbor
		buttons[index].focus_neighbor_right = neighbor
		buttons[index].focus_next = neighbor
		buttons[index].focus_previous = neighbor
	_save(panel, DIRECTORY + "menu_panel.tscn")


func _build_overlay(file_name: String, node_name: String) -> void:
	var overlay: Control = Control.new()
	overlay.name = node_name
	overlay.set_script(load(DIRECTORY + file_name + ".gd"))
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false
	_full(overlay)
	var packed: PackedScene = load(DIRECTORY + "menu_panel.tscn") as PackedScene
	var panel: Node = packed.instantiate()
	_attach(overlay, panel, "MenuPanel", overlay)
	panel.unique_name_in_owner = true
	_save(overlay, DIRECTORY + file_name + ".tscn")


func _build_sandbox() -> void:
	var sandbox: Control = Control.new()
	sandbox.name = "MenuSandbox"
	sandbox.set_script(load(DIRECTORY + "sandbox/menu_sandbox.gd"))
	_full(sandbox)
	sandbox.theme = THEME
	var background: ColorRect = ColorRect.new()
	_attach(sandbox, background, "Background", sandbox)
	_full(background)
	background.color = Color("53675c")
	var center: CenterContainer = CenterContainer.new()
	_attach(sandbox, center, "Center", sandbox)
	_full(center)
	var content: VBoxContainer = VBoxContainer.new()
	_attach(center, content, "Content", sandbox)
	content.custom_minimum_size.x = 600
	content.add_theme_constant_override("separation", 24)
	var heading: Label = _label(content, "Heading", 36, sandbox)
	heading.text = "Pulpasa · Romería"
	var hint: Label = _label(content, "Hint", 20, sandbox)
	hint.text = "Esc / Start: pausa · Flechas / cruceta: elegir · A / Intro: aceptar"
	var start: Button = Button.new()
	_attach(content, start, "StartButton", sandbox)
	start.unique_name_in_owner = true
	start.custom_minimum_size.y = 56
	var overlays: CanvasLayer = CanvasLayer.new()
	_attach(sandbox, overlays, "Overlays", sandbox)
	for file_name: String in ["pause_menu", "game_over"]:
		var scene: PackedScene = load(DIRECTORY + file_name + ".tscn") as PackedScene
		var overlay: Node = scene.instantiate()
		_attach(overlays, overlay, overlay.name, sandbox)
	_save(sandbox, DIRECTORY + "sandbox/menu_sandbox.tscn")
