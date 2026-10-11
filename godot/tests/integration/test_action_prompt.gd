# gdlint: disable=max-public-methods
extends GutTest
## PUL-127 (D26, ADR-003 §11.5): el prompt de acción sobre el objetivo. AC1 medidas, colores y
## visibilidad; AC2 respuesta de 0,35 s; AC3 Local 2P; AC6 contorno.
## La vista se inyecta (`set_view`): las medidas se comprueban en px de pantalla a 1080 y 720.

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const EventBusScript: GDScript = preload("res://autoload/event_bus.gd")
const CAMERA_SCENE: PackedScene = preload("res://entities/camera/camera_rig.tscn")
const CAMERA_SIZE: float = 12.74
const OUTLINE_CREAM: Color = Color("FFF4D6")
const AMBER: Color = Color("FFB020")

var _level: Node3D
var _bus: Node
var _player: Player
var _prompt: ActionPrompt
var _target: DummyTarget


class DummyTarget:
	extends Node3D
	## Objetivo mínimo: una malla de 1 m y su `Highlightable`.

	func _init() -> void:
		var mesh: MeshInstance3D = MeshInstance3D.new()
		mesh.mesh = BoxMesh.new()
		add_child(mesh)
		add_child(Highlightable.new())


func before_each() -> void:
	ActionPrompt.clear_registry()
	_level = add_child_autofree(Node3D.new())
	_bus = autofree(EventBusScript.new())
	_player = _add_player(1, Vector3.ZERO)
	_prompt = _prompt_of(_player)
	_target = DummyTarget.new()
	_target.position = Vector3(2.0, 0.5, 3.0)
	_level.add_child(_target)
	_prompt.set_view(1080.0, CAMERA_SIZE)
	_prompt.set_mode(GameMode.Mode.SINGLE)


func _add_player(index: int, at: Vector3) -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	player.set_bus(_bus)
	player.position = at
	_level.add_child(player)
	var control: ControlComponent = player.get_node(^"%Control") as ControlComponent
	control.player_index = index
	control.controlled_by = index
	return player


func _prompt_of(player: Player) -> ActionPrompt:
	return player.get_node(^"%ActionPrompt") as ActionPrompt


func _sprite(prompt: ActionPrompt, node_name: String) -> Sprite3D:
	return prompt.get_node("%" + node_name) as Sprite3D


func _show(hint: ActionHint, prompt: ActionPrompt = _prompt) -> void:
	prompt.show_hint(_target, hint)
	await wait_process_frames(1)


## Contraste WCAG entre dos colores opacos.
func _contrast(a: Color, b: Color) -> float:
	var la: float = _luminance(a)
	var lb: float = _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _luminance(color: Color) -> float:
	return 0.2126 * _linear(color.r) + 0.7152 * _linear(color.g) + 0.0722 * _linear(color.b)


func _linear(channel: float) -> float:
	return channel / 12.92 if channel <= 0.04045 else pow((channel + 0.055) / 1.055, 2.4)


# --- AC1: medidas, colores y visibilidad -----------------------------------------------------


func test_ok_prompt_measures_at_1080() -> void:
	await _show(ActionHint.ok(ActionVerb.PICK_UP))
	assert_true(_prompt.is_shown())
	assert_gte(_prompt.size_px_of(_sprite(_prompt, "VerbIcon")), 64.0 - 0.01)
	assert_gte(_prompt.size_px_of(_sprite(_prompt, "Plate")), 80.0 - 0.01)


func test_prompt_measures_at_720() -> void:
	_prompt.set_view(720.0, CAMERA_SIZE)
	await _show(ActionHint.ok(ActionVerb.CUT))
	assert_gte(_prompt.size_px_of(_sprite(_prompt, "VerbIcon")), 48.0 - 0.01, "mínimo absoluto")
	assert_gte(_prompt.size_px_of(_sprite(_prompt, "Plate")), 48.0, "la placa no baja del icono")


func test_prompt_scales_up_with_height() -> void:
	_prompt.set_view(1440.0, CAMERA_SIZE)
	await _show(ActionHint.ok(ActionVerb.COOK))
	assert_almost_eq(_prompt.size_px_of(_sprite(_prompt, "VerbIcon")), 64.0 * 1440.0 / 1080.0, 0.1)


func test_icon_contrasts_with_plate() -> void:
	var icons: ActionIconSet = _prompt.icons
	assert_gte(_contrast(icons.ok_color, icons.plate_color), 4.5)
	assert_gte(_contrast(icons.blocked_color, icons.plate_color), 4.5)


func test_ok_is_white_without_cross_or_reason() -> void:
	await _show(ActionHint.ok(ActionVerb.TRASH))
	var verb: Sprite3D = _sprite(_prompt, "VerbIcon")
	assert_eq(verb.modulate, _prompt.icons.ok_color)
	assert_eq(verb.texture, _prompt.icons.verb_icons[ActionVerb.TRASH])
	assert_false(_sprite(_prompt, "Cross").visible)
	assert_false(_sprite(_prompt, "ReasonIcon").visible)
	assert_false(_sprite(_prompt, "ReplaceBadge").visible)


func test_blocked_is_amber_with_cross_and_reason() -> void:
	await _show(ActionHint.blocked(ActionVerb.CUT, ActionReason.FULL))
	var verb: Sprite3D = _sprite(_prompt, "VerbIcon")
	assert_eq(verb.modulate, _prompt.icons.blocked_color)
	assert_eq(verb.modulate.to_html(false).to_upper(), "FFB020")
	assert_true(_sprite(_prompt, "Cross").visible)
	assert_eq(_sprite(_prompt, "Cross").texture, _prompt.icons.cross)
	var reason: Sprite3D = _sprite(_prompt, "ReasonIcon")
	assert_true(reason.visible)
	assert_eq(reason.texture, _prompt.icons.reason_icons[ActionReason.FULL])
	assert_not_null(reason.texture)


func test_blocked_badges_are_in_their_corners() -> void:
	await _show(ActionHint.blocked(ActionVerb.CUT, ActionReason.FULL))
	var cross: Vector2 = _prompt.offset_px_of(_sprite(_prompt, "Cross"))
	var reason: Vector2 = _prompt.offset_px_of(_sprite(_prompt, "ReasonIcon"))
	assert_gt(cross.x, 0.0, "aspa a la derecha")
	assert_gt(cross.y, 0.0, "aspa arriba")
	assert_gt(reason.x, 0.0, "motivo a la derecha")
	assert_lt(reason.y, 0.0, "motivo abajo")
	assert_almost_eq(_prompt.size_px_of(_sprite(_prompt, "ReasonIcon")), 32.0, 0.1)
	assert_almost_eq(_prompt.size_px_of(_sprite(_prompt, "Cross")), 24.0, 0.1)


func test_replace_badge_only_when_replaces() -> void:
	var hint: ActionHint = ActionHint.ok(ActionVerb.SEASON_HOT)
	hint.replaces = true
	await _show(hint)
	var badge: Sprite3D = _sprite(_prompt, "ReplaceBadge")
	assert_true(badge.visible)
	var corner: Vector2 = _prompt.offset_px_of(badge)
	assert_lt(corner.x, 0.0, "esquina izquierda")
	assert_gt(corner.y, 0.0, "esquina superior")
	await _show(ActionHint.ok(ActionVerb.SEASON_HOT))
	assert_false(badge.visible)


func test_visible_only_with_target_hint_and_control() -> void:
	await _show(ActionHint.none())
	assert_false(_prompt.visible, "NONE")
	await _show(ActionHint.ok(ActionVerb.NONE))
	assert_false(_prompt.visible, "objetivo heredado sin verbo")
	await _show(ActionHint.ok(ActionVerb.PICK_UP))
	assert_true(_prompt.visible)
	(_player.get_node(^"%Control") as ControlComponent).controlled_by = 0
	assert_false(_prompt.visible, "personaje sin control")
	(_player.get_node(^"%Control") as ControlComponent).controlled_by = 1
	assert_true(_prompt.visible, "al recuperar el control vuelve")


func test_prompt_follows_detector_hint() -> void:
	var detector: InteractionDetector = _player.get_node(^"%InteractionDetector")
	detector.hint_changed.emit(_target, ActionHint.ok(ActionVerb.PICK_UP))
	assert_true(_prompt.visible)
	assert_eq(_prompt.get_hint().verb, ActionVerb.PICK_UP)
	detector.hint_changed.emit(null, ActionHint.none())
	assert_false(_prompt.visible)


func test_anchor_is_top_of_highlightable_plus_offset() -> void:
	await _show(ActionHint.ok(ActionVerb.PICK_UP))
	# Caja de 1 m centrada en (2; 0,5; 3): parte alta a y = 1,0.
	var expected: Vector3 = Vector3(2.0, 1.0 + _prompt.icons.prompt_offset, 3.0)
	assert_almost_eq(_prompt.global_position.distance_to(expected), 0.0, 0.001)


func test_anchor_prefers_prompt_anchor_marker() -> void:
	var anchor: Marker3D = Marker3D.new()
	anchor.name = &"PromptAnchor"
	anchor.unique_name_in_owner = false
	_target.add_child(anchor)
	anchor.global_position = Vector3(2.5, 2.5, 3.5)
	await _show(ActionHint.ok(ActionVerb.PICK_UP))
	assert_almost_eq(_prompt.global_position.distance_to(anchor.global_position), 0.0, 0.001)


func test_floor_hint_sits_on_the_drop_point() -> void:
	var hold: HoldComponent = _player.get_node(^"%HoldComponent") as HoldComponent
	_prompt.show_hint(null, ActionHint.ok(ActionVerb.DROP))
	await wait_process_frames(1)
	assert_true(_prompt.visible)
	var expected: Vector3 = hold.get_drop_position() + Vector3.UP * _prompt.icons.prompt_offset
	assert_almost_eq(_prompt.global_position.distance_to(expected), 0.0, 0.001)
	_prompt.show_hint(null, ActionHint.blocked(ActionVerb.DROP, ActionReason.BUSY))
	await wait_process_frames(1)
	assert_true(_prompt.visible, "drop BLOQUEADO busy también se ve")
	assert_true(_sprite(_prompt, "Cross").visible)


# --- AC2: respuesta -----------------------------------------------------------------------------


func _press(hint: ActionHint) -> void:
	var actor: InteractionComponent = _player.get_node(^"%InteractionComponent")
	actor.interaction_resolved.emit(_target, hint)


func test_ok_response_lifts_and_scales_in_035s() -> void:
	await _show(ActionHint.ok(ActionVerb.PICK_UP))
	assert_almost_eq(_prompt.icons.response_duration, 0.35, 0.0001)
	_press(ActionHint.ok(ActionVerb.PICK_UP))
	assert_true(_prompt.is_responding())
	_prompt.advance(0.175)
	assert_almost_eq(_prompt.get_icon_lift_px(), 12.0, 0.01)
	assert_almost_eq(_prompt.get_icon_scale(), 1.25, 0.001)
	_prompt.advance(0.1)
	assert_between(_prompt.get_icon_scale(), 1.0, 1.25, "vuelve a reposo")
	_prompt.advance(0.1)
	assert_false(_prompt.is_responding())
	assert_eq(_prompt.get_icon_lift_px(), 0.0)
	assert_eq(_prompt.get_icon_scale(), 1.0)


func test_ok_response_moves_the_icon_on_screen() -> void:
	await _show(ActionHint.ok(ActionVerb.PICK_UP))
	var verb: Sprite3D = _sprite(_prompt, "VerbIcon")
	var rest: float = _prompt.offset_px_of(verb).y
	var rest_size: float = _prompt.size_px_of(verb)
	_press(ActionHint.ok(ActionVerb.PICK_UP))
	_prompt.advance(0.175)
	await wait_process_frames(1)
	assert_almost_eq(_prompt.offset_px_of(verb).y - rest, 12.0, 0.6)
	assert_almost_eq(_prompt.size_px_of(verb) / rest_size, 1.25, 0.02)


func test_blocked_response_shakes_6px_blinks_and_lasts_035s() -> void:
	await _show(ActionHint.blocked(ActionVerb.CUT, ActionReason.FULL))
	_press(ActionHint.blocked(ActionVerb.CUT, ActionReason.FULL))
	var peak: float = 0.0
	var crossings: int = 0
	var last_sign: float = 0.0
	var blinked: bool = false
	var elapsed: float = 0.0
	while elapsed < 0.3:
		_prompt.advance(0.005)
		elapsed += 0.005
		peak = maxf(peak, absf(_prompt.get_shake_px()))
		blinked = blinked or _prompt.is_blink_hidden()
		var sign_now: float = signf(_prompt.get_shake_px())
		if sign_now != 0.0 and last_sign != 0.0 and sign_now != last_sign:
			crossings += 1
		if sign_now != 0.0:
			last_sign = sign_now
	assert_almost_eq(peak, 6.0, 0.2, "±reject_shake_px")
	assert_gte(crossings, 4, "tres ciclos")
	assert_true(blinked, "aspa y motivo parpadean una vez")
	assert_true(_prompt.is_responding(), "sigue a los 0,3 s")
	_prompt.advance(0.06)
	assert_false(_prompt.is_responding())
	assert_false(_prompt.is_blink_hidden())


func test_blink_hides_cross_and_reason_then_shows_them() -> void:
	await _show(ActionHint.blocked(ActionVerb.COOK, ActionReason.BUSY))
	_press(ActionHint.blocked(ActionVerb.COOK, ActionReason.BUSY))
	_prompt.advance(0.1)
	await wait_process_frames(1)
	assert_false(_sprite(_prompt, "Cross").visible)
	assert_false(_sprite(_prompt, "ReasonIcon").visible)
	_prompt.advance(0.1)
	await wait_process_frames(1)
	assert_true(_sprite(_prompt, "Cross").visible)
	assert_true(_sprite(_prompt, "ReasonIcon").visible)


func test_two_presses_give_two_responses_and_each_restarts() -> void:
	await _show(ActionHint.blocked(ActionVerb.CUT, ActionReason.FULL))
	_press(ActionHint.blocked(ActionVerb.CUT, ActionReason.FULL))
	_prompt.advance(0.1)
	assert_true(_prompt.is_responding())
	_press(ActionHint.blocked(ActionVerb.CUT, ActionReason.FULL))
	assert_eq(_prompt.get_response_count(), 2)
	assert_eq(_prompt.get_shake_px(), 0.0, "la segunda empieza de cero")
	_prompt.advance(0.3)
	assert_true(_prompt.is_responding(), "0,3 s después de la segunda sigue")


func test_response_freezes_with_the_tree_paused() -> void:
	await _show(ActionHint.ok(ActionVerb.PICK_UP))
	_press(ActionHint.ok(ActionVerb.PICK_UP))
	_level.process_mode = Node.PROCESS_MODE_PAUSABLE
	get_tree().paused = true
	await wait_process_frames(3)
	var frozen: float = _prompt.get_icon_scale()
	await wait_process_frames(3)
	get_tree().paused = false
	assert_eq(_prompt.get_icon_scale(), frozen, "congelado en pausa")


# --- AC3: Local 2P -----------------------------------------------------------------------------


func test_two_prompts_on_same_target_are_side_by_side_with_markers() -> void:
	var second: Player = _add_player(2, Vector3(-1.0, 0.0, 0.0))
	var other: ActionPrompt = _prompt_of(second)
	for prompt: ActionPrompt in [_prompt, other]:
		prompt.set_view(1080.0, CAMERA_SIZE)
		prompt.set_mode(GameMode.Mode.COOP_2P)
	_prompt.show_hint(_target, ActionHint.ok(ActionVerb.PICK_UP))
	other.show_hint(_target, ActionHint.ok(ActionVerb.TRASH))
	await wait_process_frames(2)
	assert_true(_prompt.visible and other.visible, "se ven 2 prompts")
	assert_true(_sprite(_prompt, "PlayerMarker").visible)
	assert_true(_sprite(other, "PlayerMarker").visible)
	assert_ne(_sprite(_prompt, "PlayerMarker").texture, _sprite(other, "PlayerMarker").texture)
	var first_center: Vector2 = _prompt.offset_px_of(_sprite(_prompt, "Plate"))
	var second_center: Vector2 = other.offset_px_of(_sprite(other, "Plate"))
	var plate: float = _prompt.plate_px()
	assert_gte(first_center.distance_to(second_center), plate + 8.0 - 0.1, "hueco >= 8 px")
	assert_lt(first_center.x, second_center.x, "J1 a la izquierda")
	assert_almost_eq(first_center.y, second_center.y, 0.1)
	assert_ne(
		_sprite(_prompt, "VerbIcon").texture,
		_sprite(other, "VerbIcon").texture,
		"cada uno ve el verbo de su mano"
	)


func test_single_player_has_no_marker_and_no_offset() -> void:
	await _show(ActionHint.ok(ActionVerb.PICK_UP))
	assert_false(_sprite(_prompt, "PlayerMarker").visible)
	assert_almost_eq(_prompt.offset_px_of(_sprite(_prompt, "Plate")).x, 0.0, 0.01)


func test_prompt_recentres_when_the_other_leaves_the_target() -> void:
	var second: Player = _add_player(2, Vector3(-1.0, 0.0, 0.0))
	var other: ActionPrompt = _prompt_of(second)
	other.set_view(1080.0, CAMERA_SIZE)
	_prompt.show_hint(_target, ActionHint.ok(ActionVerb.PICK_UP))
	other.show_hint(_target, ActionHint.ok(ActionVerb.PICK_UP))
	await wait_process_frames(1)
	assert_ne(_prompt.offset_px_of(_sprite(_prompt, "Plate")).x, 0.0)
	other.show_hint(null, ActionHint.none())
	await wait_process_frames(1)
	assert_almost_eq(_prompt.offset_px_of(_sprite(_prompt, "Plate")).x, 0.0, 0.01)


# --- AC6: contorno ------------------------------------------------------------------------------


func test_outline_is_warm_white_with_xray_pass_at_40_percent() -> void:
	var outline: ShaderMaterial = load("res://shaders/highlight_outline.tres") as ShaderMaterial
	_assert_color(outline.get_shader_parameter(&"outline_color"), OUTLINE_CREAM)
	var xray: ShaderMaterial = _xray_of(outline)
	assert_not_null(xray, "next_pass sin profundidad")
	assert_almost_eq(float(xray.get_shader_parameter(&"opacity")), 0.4, 0.0001)
	_assert_color(xray.get_shader_parameter(&"outline_color"), OUTLINE_CREAM)
	assert_string_contains(xray.shader.code, "depth_test_disabled")


func test_blocked_outline_is_amber_in_every_pass() -> void:
	var blocked: ShaderMaterial = (
		load("res://shaders/highlight_outline_blocked.tres") as ShaderMaterial
	)
	_assert_color(blocked.get_shader_parameter(&"outline_color"), AMBER)
	var xray: ShaderMaterial = _xray_of(blocked)
	assert_not_null(xray)
	_assert_color(xray.get_shader_parameter(&"outline_color"), AMBER)


func test_highlightable_default_outline_is_not_yellow_any_more() -> void:
	var material: ShaderMaterial = Highlightable.DEFAULT_MATERIAL as ShaderMaterial
	var color: Color = material.get_shader_parameter(&"outline_color")
	assert_gt(color.b, 0.8, "blanco calido, no amarillo")


func _xray_of(material: Material) -> ShaderMaterial:
	var pass_material: Material = material.next_pass
	while pass_material != null:
		var shader_material: ShaderMaterial = pass_material as ShaderMaterial
		if shader_material != null and shader_material.shader.code.contains("depth_test_disabled"):
			if shader_material.shader.code.contains("compare_not_equal"):
				return shader_material
		pass_material = pass_material.next_pass
	return null


func _assert_color(actual: Color, expected: Color) -> void:
	var close: bool = absf(actual.r - expected.r) < 0.003 and absf(actual.g - expected.g) < 0.003
	assert_true(close and absf(actual.b - expected.b) < 0.003, "%s ~ %s" % [actual, expected])


func test_every_outline_pass_shares_grow_and_width_with_its_xray() -> void:
	for path: String in [
		"res://shaders/highlight_outline.tres", "res://shaders/highlight_outline_blocked.tres"
	]:
		var hull: ShaderMaterial = load(path) as ShaderMaterial
		var xray: ShaderMaterial = _xray_of(hull)
		assert_not_null(xray, path)
		for parameter: StringName in [&"grow", &"width"]:
			assert_eq(
				xray.get_shader_parameter(parameter),
				hull.get_shader_parameter(parameter),
				"%s: %s" % [path, parameter]
			)


# --- Píxeles reales con stretch canvas_items (base 1280x720) ------------------------------------


func _real_sizes_at(resolution: Vector2i) -> Dictionary:
	var original: Vector2i = get_window().size
	get_window().size = resolution
	await wait_process_frames(3)
	var camera: Camera3D = CAMERA_SCENE.instantiate()
	_level.add_child(camera)
	camera.make_current()
	_prompt.set_view(0.0, 0.0)
	await _show(ActionHint.ok(ActionVerb.PICK_UP))
	var result: Dictionary = {
		&"icon": _prompt.icon_px(),
		&"plate": _prompt.plate_px(),
		&"mpp": _prompt.meters_per_pixel(),
		&"height": ActionPrompt.real_size_of(get_viewport()).y,
		&"camera": camera.size
	}
	get_window().size = original
	await wait_process_frames(2)
	return result


func test_prompt_uses_real_pixels_at_1920x1080_on_a_720_base() -> void:
	var sizes: Dictionary = await _real_sizes_at(Vector2i(1920, 1080))
	assert_almost_eq(float(sizes[&"height"]), 1080.0, 0.5)
	assert_almost_eq(float(sizes[&"icon"]), 64.0, 0.1)
	assert_almost_eq(float(sizes[&"plate"]), 80.0, 0.1)
	assert_almost_eq(float(sizes[&"mpp"]), float(sizes[&"camera"]) / 1080.0, 0.0001)


func test_prompt_keeps_the_48px_floor_in_a_small_window() -> void:
	var sizes: Dictionary = await _real_sizes_at(Vector2i(960, 540))
	assert_almost_eq(float(sizes[&"height"]), 540.0, 0.5)
	assert_gte(float(sizes[&"icon"]), 48.0)
	assert_gte(float(sizes[&"plate"]), 48.0)


func test_marker_is_28px_at_1080_and_24px_at_least_in_a_small_window() -> void:
	var original: Vector2i = get_window().size
	var camera: Camera3D = CAMERA_SCENE.instantiate()
	_level.add_child(camera)
	camera.make_current()
	var marker: Sprite3D = _player.get_node(^"%ActiveMarker") as Sprite3D
	var sides: Array[float] = []
	for resolution: Vector2i in [Vector2i(1920, 1080), Vector2i(960, 540)]:
		get_window().size = resolution
		await wait_process_frames(3)
		var mpp: float = ActionPrompt.meters_per_pixel_of(_player)
		sides.append(marker.pixel_size * float(marker.texture.get_width()) / mpp)
	get_window().size = original
	await wait_process_frames(2)
	assert_almost_eq(sides[0], 28.0, 0.1)
	assert_gte(sides[1], 24.0 - 0.01)
