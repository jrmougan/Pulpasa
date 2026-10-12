class_name TouchControls
extends Control
## Controles táctiles de J1 en Individual (ADR-004 §6). Cuelga de la `UI` del nivel, encima del HUD
## y los tickets. Solo existe en el perfil MOBILE (en DESKTOP se libera en `_ready`); se ve según
## `TouchInput.controls_visible` y se oculta mientras la última entrada sea un mando.
## Maqueta los cuatro controles dentro de la safe area con las medidas de `TouchConfig`.

@export var config: TouchConfig
@export var icons: ActionIconSet
@export var input_config: InputConfig = preload("res://data/config/input_config.tres")

var _last_source: TouchInput.Source = TouchInput.Source.NONE

@onready var _safe_area: SafeAreaMargin = %SafeArea
@onready var _content: Control = %Content
@onready var _stick: VirtualStick = %MoveStick
@onready var _action: ActionButton = %ActionButton
@onready var _switch: TouchButton = %SwitchButton
@onready var _pause: TouchButton = %PauseButton


func _ready() -> void:
	if GameState.platform != PlatformProfile.Kind.MOBILE:
		visible = false
		set_process_input(false)
		queue_free()
		return
	_stick.setup(config)
	_action.setup(config, icons)
	_switch.setup(config, icons)
	_pause.setup(config, icons)
	_stick.gate = accepts_input
	_action.gate = accepts_input
	_switch.gate = accepts_input
	_pause.gate = accepts_input
	_stick.blockers = [_action, _switch, _pause] as Array[TouchButton]
	get_viewport().size_changed.connect(refresh_layout)
	EventBus.pause_changed.connect(_on_pause_changed)
	refresh_layout()
	_update_visibility()


func _exit_tree() -> void:
	release_all()


func _input(event: InputEvent) -> void:
	_note(event)


func _notification(what: int) -> void:
	if (
		what == NOTIFICATION_APPLICATION_FOCUS_OUT
		or what == NOTIFICATION_APPLICATION_PAUSED
		or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT
	):
		release_all()


## Puerta de los controles hijos: anota la fuente del evento (por si es el toque que los hace
## reaparecer) y dice si ahora se ven. Así ese mismo toque actúa aunque los hijos reciban `_input`
## antes que este nodo.
func accepts_input(event: InputEvent) -> bool:
	_note(event)
	return visible


func _note(event: InputEvent) -> void:
	var source: TouchInput.Source = TouchInput.source_of(event, input_config.deadzone)
	if source == TouchInput.Source.NONE or source == _last_source:
		return
	_last_source = source
	_update_visibility()


## Última fuente de entrada vista.
func get_last_source() -> TouchInput.Source:
	return _last_source


## Fuerza la fuente (tests y sandbox) y reevalúa la visibilidad.
func set_last_source(source: TouchInput.Source) -> void:
	_last_source = source
	_update_visibility()


## Suelta todo lo que los controles tengan pulsado.
func release_all() -> void:
	for node: Node in [_stick, _action, _switch, _pause]:
		if node != null and node.has_method(&"release_all"):
			node.call(&"release_all")


## Inyecta la safe area (px de pantalla) y recoloca los controles. Para pruebas y capturas.
func apply_safe_rect(rect: Rect2, window_size: Vector2) -> void:
	_safe_area.set_safe_rect(rect, window_size)
	refresh_layout()


## Safe area en unidades de lienzo, local a este control.
func get_safe_rect() -> Rect2:
	var canvas: Vector2 = get_viewport().get_visible_rect().size
	var left: float = _safe_area.get_theme_constant(&"margin_left")
	var top: float = _safe_area.get_theme_constant(&"margin_top")
	var right: float = _safe_area.get_theme_constant(&"margin_right")
	var bottom: float = _safe_area.get_theme_constant(&"margin_bottom")
	return Rect2(left, top, canvas.x - left - right, canvas.y - top - bottom)


## Zona donde nace el stick, local a este control.
func get_stick_zone() -> Rect2:
	var canvas: Vector2 = get_viewport().get_visible_rect().size
	var top: float = UiScale.px_to_units(config.stick_zone_top_px_1080, canvas.y)
	return Rect2(0.0, top, canvas.x * config.stick_zone_fraction, canvas.y - top)


## Coloca el stick y los botones. Se repite al cambiar el tamaño del lienzo.
func refresh_layout() -> void:
	if config == null or _content == null:
		return
	var canvas: Vector2 = get_viewport().get_visible_rect().size
	var safe: Rect2 = get_safe_rect()
	var margin: float = UiScale.px_to_units(config.button_margin_px_1080, canvas.y)
	var gap: float = UiScale.px_to_units(config.button_gap_px_1080, canvas.y)
	var big: float = UiScale.dp_to_units(
		config.action_button_dp, config.px_per_dp_at_1080, canvas.y
	)
	var small: float = UiScale.dp_to_units(
		config.small_button_dp, config.px_per_dp_at_1080, canvas.y
	)
	_content.global_position = global_position
	_content.size = canvas
	var action_center: Vector2 = Vector2(
		safe.end.x - margin - big / 2.0, safe.end.y - margin - big / 2.0
	)
	# Cambiar a la izquierda de acción, con los bordes inferiores alineados (ADR-005 E4, D27.1).
	var switch_center: Vector2 = (
		action_center + Vector2(-(big / 2.0 + gap + small / 2.0), big / 2.0 - small / 2.0)
	)
	var pause_center: Vector2 = Vector2(
		safe.end.x - margin - small / 2.0, safe.position.y + margin + small / 2.0
	)
	_place(_action, action_center, big)
	_action.hit_slop = UiScale.px_to_units(config.hit_slop_px_1080, canvas.y)
	_place(_switch, switch_center, small)
	_place(_pause, pause_center, small)
	var zone: Rect2 = get_stick_zone()
	_stick.position = zone.position
	_stick.size = zone.size
	_stick.safe_rect = Rect2(global_position + safe.position, safe.size)


func _place(button: TouchButton, center: Vector2, diameter: float) -> void:
	button.size = Vector2.ONE * diameter
	button.position = center - button.size / 2.0


func _update_visibility() -> void:
	var show_controls: bool = TouchInput.controls_visible(
		GameState.platform, GameState.mode, _last_source
	)
	if visible and not show_controls:
		release_all()
	visible = show_controls


func _on_pause_changed(paused: bool) -> void:
	if paused:
		release_all()
