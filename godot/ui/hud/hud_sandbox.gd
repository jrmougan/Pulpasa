extends Control
## Composición de prueba: los componentes de UI nunca arrancan la ronda. Monta HUD y tickets con
## sus anclajes por defecto, como en `level_01`. En MOBILE dibuja las zonas reservadas del stick y
## de los botones y marcadores del botón de pausa y de los de acción (los monta PUL-128; aquí solo
## muestran que HUD y tickets no los tocan).

const CATALOG: OrderCatalog = preload("res://data/orders/order_catalog.tres")
const CONFIG: RoundConfig = preload("res://data/config/round_config.tres")
const ZONE_COLOR: Color = Color(0.2, 0.7, 1.0, 0.18)
const MARKER_COLOR: Color = Color(1.0, 1.0, 1.0, 0.35)

var _overlay: Control


func _ready() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20
	OrderService.setup(CATALOG, rng)
	RoundManager.start_round(CONFIG, [1, 2, 3, 4] as Array[int])
	if GameState.platform == PlatformProfile.Kind.MOBILE:
		_overlay = Control.new()
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		_overlay.draw.connect(_draw_zones)
		add_child(_overlay)
		get_viewport().size_changed.connect(_overlay.queue_redraw)
		set_process(true)
	else:
		set_process(false)


## La safe area se puede inyectar después de montar: el overlay se repinta cada frame.
func _process(_delta: float) -> void:
	_overlay.queue_redraw()


func _draw_zones() -> void:
	var profile: UiProfile = GameState.ui_profile
	var size: Vector2 = get_viewport().get_visible_rect().size
	var height: float = size.y
	var stick: Rect2 = Rect2(
		0.0,
		UiScale.px_to_units(profile.stick_zone_top_px, height),
		size.x * profile.stick_zone_fraction,
		size.y
	)
	var safe: SafeAreaMargin = $OrderTicketsPanel as SafeAreaMargin
	var buttons_left: float = (
		size.x
		- safe.get_theme_constant(&"margin_right")
		- UiScale.px_to_units(profile.button_zone_width_px, height)
	)
	var buttons_top: float = (
		size.y
		- safe.get_theme_constant(&"margin_bottom")
		- UiScale.px_to_units(profile.button_zone_height_px, height)
	)
	var buttons: Rect2 = Rect2(buttons_left, buttons_top, size.x, size.y)
	_overlay.draw_rect(stick, ZONE_COLOR)
	_overlay.draw_rect(buttons, ZONE_COLOR)
	var pause_side: float = UiScale.px_to_units(TouchHudLayout.pause_button_px(), height)
	var edge: float = UiScale.px_to_units(TouchHudLayout.edge_margin_px(), height)
	var right_margin: float = safe.get_theme_constant(&"margin_right")
	var pause_center: Vector2 = Vector2(
		size.x - right_margin - edge - pause_side / 2.0, edge + pause_side / 2.0
	)
	_overlay.draw_circle(pause_center, pause_side / 2.0, MARKER_COLOR)
