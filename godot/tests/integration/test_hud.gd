extends GutTest
## PUL-020: HUD dirigido exclusivamente por eventos del reloj de ronda.
## PUL-030: recaudación en € (AC9–AC11 de entrega-y-puntuacion).
## PUL-086: panel compacto de marca con cifras en `ui_digits` y escala por resolución.

const HUD_SCENE: PackedScene = preload("res://ui/hud/hud.tscn")
const BusScript: GDScript = preload("res://autoload/event_bus.gd")
const ServiceScript: GDScript = preload("res://autoload/order_service.gd")
const ManagerScript: GDScript = preload("res://autoload/round_manager.gd")
const CATALOG: OrderCatalog = preload("res://data/orders/order_catalog.tres")

var _bus: Node
var _service: Node
var _manager: Node
var _hud: RoundHUD
var _state: StateSpy


class StateSpy:
	extends Node
	var mode: GameMode.Mode = GameMode.Mode.SINGLE


func before_each() -> void:
	_bus = add_child_autofree(BusScript.new())
	_service = ServiceScript.new()
	_service.set_bus(_bus)
	add_child_autofree(_service)
	_service.setup(CATALOG)
	_manager = ManagerScript.new()
	_manager.set_bus(_bus)
	_manager.set_order_service(_service)
	_manager.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child_autofree(_manager)
	_manager.set_physics_process(false)
	_hud = HUD_SCENE.instantiate()
	_state = add_child_autofree(StateSpy.new())
	_hud.set_bus(_bus)
	_hud.set_game_state(_state)
	add_child_autofree(_hud)


func after_each() -> void:
	get_tree().paused = false


func _start() -> void:
	var config: RoundConfig = RoundConfig.new()
	config.duration = 180.0
	_manager.start_round(config, [1] as Array[int])


func _text(node_name: String) -> String:
	return (_hud.get_node("%" + node_name) as Label).text


func test_ac1_mount_does_not_start_round_or_own_clock() -> void:
	assert_null(_manager.round_state)
	assert_eq(_text("TimeLeft"), "0.0s")
	_bus.round_started.emit(180.0)
	await wait_physics_frames(4)
	assert_eq(_text("TimeLeft"), "180.0s", "sin eventos no avanza")


func test_ac1_round_signals_update_time_and_finish_at_zero() -> void:
	_start()
	assert_eq(_text("TimeLeft"), "180.0s")
	_manager.round_state.advance(60.0)
	assert_eq(_text("TimeLeft"), "120.0s")
	_manager.round_state.advance(120.0)
	assert_eq(_text("TimeLeft"), "0.0s")
	assert_true(_manager.round_state.is_finished())


func test_ac1_pause_freezes_actual_round_and_hud() -> void:
	_start()
	_manager.set_physics_process(true)
	get_tree().paused = true
	var before: float = _manager.round_state.get_time_left()
	await wait_process_frames(4)
	assert_eq(_manager.round_state.get_time_left(), before)
	assert_eq(_text("TimeLeft"), "180.0s")
	get_tree().paused = false
	await wait_physics_frames(4)
	assert_lt(_manager.round_state.get_time_left(), before)


func test_ac9_revenue_starts_at_zero_euros() -> void:
	assert_eq(_text("Revenue"), "0 €", "recién montado")
	_start()
	assert_eq(_text("Revenue"), "0 €", "partida recién iniciada")


func test_ac10_delivery_updates_revenue_on_the_signal() -> void:
	_start()
	_bus.score_changed.emit(1, 12)
	assert_eq(_text("Revenue"), "12 €", "≤ 0,2 s: se actualiza al recibir score_changed")
	_bus.score_changed.emit(2, 24)
	assert_eq(_text("Revenue"), "24 €")


func test_ac11_expiry_subtracts_revenue_but_never_below_zero() -> void:
	_start()
	_bus.score_changed.emit(2, 20)
	assert_eq(_text("Revenue"), "20 €")
	_bus.score_changed.emit(2, 17)
	assert_eq(_text("Revenue"), "17 €", "caducidad con penalización de 3 €")
	_bus.score_changed.emit(2, -5)
	assert_eq(_text("Revenue"), "0 €", "nunca por debajo de 0")


func test_pause_changed_dims_and_restores_hud() -> void:
	assert_eq(_hud.modulate, Color.WHITE)
	_bus.pause_changed.emit(true)
	assert_lt(_hud.modulate.a, 1.0)
	_bus.pause_changed.emit(false)
	assert_eq(_hud.modulate, Color.WHITE)


func test_ac5_character_switched_updates_indicator() -> void:
	assert_false((_hud.get_node("%ActiveCharacter") as Label).visible)
	_bus.character_switched.emit(1, 2)
	assert_true((_hud.get_node("%ActiveCharacter") as Label).visible)
	assert_string_contains(_text("ActiveCharacter"), "2")
	_bus.character_switched.emit(1, 1)
	assert_string_contains(_text("ActiveCharacter"), "1")


func test_ac5_coop_initial_assignments_keep_indicator_hidden() -> void:
	_state.mode = GameMode.Mode.COOP_2P
	_bus.character_switched.emit(1, 1)
	_bus.character_switched.emit(2, 2)
	assert_false((_hud.get_node("%ActiveCharacter") as Label).visible)


func test_ac5_single_ignores_other_players_switch() -> void:
	_bus.character_switched.emit(2, 2)
	assert_false((_hud.get_node("%ActiveCharacter") as Label).visible)
	_bus.character_switched.emit(1, 2)
	_bus.character_switched.emit(2, 1)
	assert_string_contains(_text("ActiveCharacter"), "2")


func test_ac5_device_assigned_shows_brief_notice() -> void:
	_bus.device_assigned.emit(2, 4)
	assert_true((_hud.get_node("%DeviceNotice") as Label).visible)
	assert_eq(_text("DeviceNotice"), "J2 conectado")
	await wait_seconds(2.3)
	assert_false((_hud.get_node("%DeviceNotice") as Label).visible)


func test_ac5_keyboard_only_assignment_shows_no_notice() -> void:
	_bus.device_assigned.emit(2, DeviceAssignment.NONE)
	assert_false((_hud.get_node("%DeviceNotice") as Label).visible)


func test_pul086_figures_use_brand_digits_on_brand_panel() -> void:
	for name: String in ["TimeLeft", "Revenue"]:
		var label: Label = _hud.get_node("%" + name)
		assert_eq(label.theme_type_variation, &"FigureLabel", name)
		assert_eq(label.get_theme_color(&"font_color"), Color("5b8db8"), "%s: ui_digits" % name)
	var background: PanelContainer = _hud.get_node("%Background")
	assert_eq(background.theme_type_variation, &"UiPanel")
	assert_eq(_text("Shift"), "Turno")


func test_pul122_ac8_hud_keeps_size_at_720p_and_1080p_without_double_scale() -> void:
	## ADR-005 E2: la escala la da `stretch` del proyecto; el HUD ya no se escala a sí mismo.
	assert_eq(_hud.scale, Vector2.ONE, "sin escala propia")
	var background: Control = _hud.get_node("%Background")
	var original: Vector2i = get_window().size
	var units: Array[Vector2] = []
	var fractions: Array[float] = []
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		get_window().size = resolution
		await wait_process_frames(3)
		var stretch: float = get_viewport().get_final_transform().get_scale().x
		units.append(background.size)
		fractions.append(background.size.y * stretch / float(resolution.y))
	get_window().size = original
	assert_eq(units[0], units[1], "mismas unidades de interfaz")
	assert_almost_eq(fractions[0], fractions[1], 0.0001, "misma proporción de pantalla")
	assert_almost_eq(fractions[0], background.size.y / 720.0, 0.0001, "tamaño de 720p intacto")


func test_pul086_hud_fits_compact_corner_at_720p() -> void:
	var background: Control = _hud.get_node("%Background")
	_start()
	_bus.score_changed.emit(12, 1234)
	await wait_process_frames(2)
	var size: Vector2 = background.get_combined_minimum_size()
	assert_lt(size.x, 230.0, "compacto: ancho")
	assert_lt(size.y, 300.0, "compacto: alto")


func test_d26_hud_shows_no_boxes_per_minute_in_desktop() -> void:
	_start()
	_bus.score_changed.emit(2, 24)
	await wait_process_frames(2)
	for node: Node in _hud.find_children("*", "Label", true, false):
		var label: Label = node as Label
		if label.is_visible_in_tree():
			assert_false(label.text.containsn("minuto"), label.name)
	assert_null(_hud.find_child("RateTitle", true, false), "sin título de la métrica")
	assert_false((_hud.get_node("%BoxesPerMinute") as Label).is_visible_in_tree())


func test_pul129_desktop_hud_keeps_the_bottom_left_corner_and_scene_sizes() -> void:
	await wait_process_frames(2)
	var viewport: Vector2 = get_viewport().get_visible_rect().size
	var background: Control = _hud.get_node("%Background")
	assert_almost_eq(background.global_position.x, 8.0, 0.5, "8 unidades del borde izquierdo")
	assert_almost_eq(
		background.get_global_rect().end.y, viewport.y - 8.0, 0.5, "y del borde inferior"
	)
	assert_eq(_hud.get_node("%Shift").get_parent().get_parent().visible, true, "cabecera de marca")
