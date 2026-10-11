extends GutTest
## PUL-122 AC5 (controles-tactiles AC14): en el perfil MOBILE ningún texto de menú, pausa o game
## over mide menos de 36 px a 1080 de alto (24 px a 720). Medido en pantalla: tamaño de fuente
## en unidades de lienzo por la escala de estiramiento de la ventana.

const MAIN_MENU: PackedScene = preload("res://ui/menus/main_menu.tscn")
const PAUSE: PackedScene = preload("res://ui/menus/pause_menu.tscn")
const GAME_OVER: PackedScene = preload("res://ui/menus/game_over.tscn")

var _original_size: Vector2i


func before_each() -> void:
	_original_size = get_window().size
	GameState.set_platform(PlatformProfile.Kind.MOBILE)


func after_each() -> void:
	get_window().size = _original_size
	GameState.set_platform(PlatformProfile.Kind.DESKTOP)
	GameState.set_paused(false)


func _resize(resolution: Vector2i) -> float:
	get_window().size = resolution
	await wait_process_frames(2)
	return get_viewport().get_final_transform().get_scale().y


func _texts_below(root: Node, minimum_px: float, stretch: float) -> PackedStringArray:
	var failures: PackedStringArray = []
	for node: Node in root.find_children("*", "Control", true, false):
		var size: int = TextFloor.font_size_of(node as Control)
		if size > 0 and size * stretch < minimum_px - 0.01:
			failures.append("%s: %.1f px" % [root.get_path_to(node), size * stretch])
	return failures


func _mount_all() -> Array[Control]:
	var menus: Array[Control] = []
	for scene: PackedScene in [MAIN_MENU, PAUSE, GAME_OVER]:
		var menu: Control = scene.instantiate()
		add_child_autofree(menu)
		menus.append(menu)
	return menus


func _check(resolution: Vector2i, minimum_px: float) -> void:
	var menus: Array[Control] = _mount_all()
	var stretch: float = await _resize(resolution)
	for menu: Control in menus:
		var failures: PackedStringArray = _texts_below(menu, minimum_px, stretch)
		assert_eq(failures, PackedStringArray(), "%s a %s" % [menu.name, resolution])


func test_ac5_text_is_at_least_36_px_at_2340x1080() -> void:
	await _check(Vector2i(2340, 1080), 36.0)


func test_ac5_text_is_at_least_24_px_at_1600x720() -> void:
	await _check(Vector2i(1600, 720), 24.0)


func test_ac5_text_is_at_least_36_px_at_1920x1080() -> void:
	await _check(Vector2i(1920, 1080), 36.0)


func test_ac5_device_warning_in_pause_follows_the_floor() -> void:
	var menus: Array[Control] = _mount_all()
	var stretch: float = await _resize(Vector2i(2340, 1080))
	EventBus.device_disconnected.emit(2)
	await get_tree().process_frame
	assert_eq(_texts_below(menus[1], 36.0, stretch), PackedStringArray(), "pausa con aviso")
	var warning: Label = menus[1].get_node("%DeviceWarning")
	assert_true(warning.visible)
	assert_gte(warning.get_theme_font_size(&"font_size") * stretch, 35.99)
	EventBus.device_assigned.emit(2, DeviceAssignment.NONE)


func test_text_floor_is_reversible_and_leaves_larger_text_alone() -> void:
	var root: Control = Control.new()
	var small: Label = Label.new()
	small.add_theme_font_size_override(&"font_size", 12)
	var big: Label = Label.new()
	big.add_theme_font_size_override(&"font_size", 40)
	root.add_child(small)
	root.add_child(big)
	add_child_autofree(root)
	TextFloor.apply(root, 24.0)
	assert_eq(TextFloor.font_size_of(small), 24)
	assert_eq(TextFloor.font_size_of(big), 40)
	TextFloor.apply(root, 30.0)
	assert_eq(TextFloor.font_size_of(small), 30)
	TextFloor.apply(root, 0.0)
	assert_eq(TextFloor.font_size_of(small), 12)
	assert_eq(TextFloor.font_size_of(big), 40)


func test_desktop_profile_leaves_menu_text_unchanged() -> void:
	GameState.set_platform(PlatformProfile.Kind.DESKTOP)
	var menu: Control = MAIN_MENU.instantiate()
	add_child_autofree(menu)
	await get_tree().process_frame
	assert_eq(TextFloor.font_size_of(menu.get_node("%Play")), 22)
	assert_eq(TextFloor.font_size_of(menu.get_node("%Mode")), 16)
