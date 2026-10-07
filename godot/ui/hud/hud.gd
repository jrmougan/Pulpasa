class_name RoundHUD
extends Control
## Presentación del reloj único y la recaudación. No arranca rondas ni acumula delta.
## Panel compacto de marca abajo a la izquierda, cifras en `ui_digits` (PUL-086). El display de 7
## segmentos queda para los relojes de los tickets: confunde «s» con «5» y apenas marca el decimal.

var _bus: Node
var _game_state: Node
var _duration: float = 0.0
var _time_left: float = 0.0
var _boxes: int = 0
var _revenue: int = 0
var _notice_tween: Tween

@onready var _time_label: Label = %TimeLeft
@onready var _rate_label: Label = %BoxesPerMinute
@onready var _revenue_label: Label = %Revenue
@onready var _active_label: Label = %ActiveCharacter
@onready var _notice: Label = %DeviceNotice


func _ready() -> void:
	if _bus == null:
		_bus = EventBus
	if _game_state == null:
		_game_state = GameState
	_bus.round_started.connect(_on_round_started)
	_bus.round_time_changed.connect(_on_time_changed)
	_bus.score_changed.connect(_on_score_changed)
	_bus.pause_changed.connect(_on_pause_changed)
	_bus.character_switched.connect(_on_character_switched)
	_bus.device_assigned.connect(_on_device_assigned)
	%Shift.text = _text("HUD_SHIFT", "Turno")
	%TimeTitle.text = _text("HUD_TIME_LEFT", "Tiempo restante")
	%RateTitle.text = _text("HUD_BOXES_PER_MINUTE", "Cajas / minuto")
	%RevenueTitle.text = _text("HUD_REVENUE", "Recaudación")
	get_viewport().size_changed.connect(_apply_ui_scale)
	_apply_ui_scale()
	_render()


func set_bus(bus: Node) -> void:
	_bus = bus


## Inyección para pruebas (solo se lee `mode`); por defecto se usa el autoload.
func set_game_state(state: Node) -> void:
	_game_state = state


func _apply_ui_scale() -> void:
	scale = Vector2.ONE * UiScale.factor(get_viewport_rect().size.y)


func _on_round_started(duration: float) -> void:
	_duration = duration
	_time_left = duration
	_boxes = 0
	_revenue = 0
	_render()


func _on_time_changed(time_left: float) -> void:
	_time_left = maxf(time_left, 0.0)
	_render()


func _on_score_changed(boxes_delivered: int, revenue: int) -> void:
	_boxes = boxes_delivered
	_revenue = maxi(revenue, 0)
	_render()


func _on_character_switched(player_index: int, character_index: int) -> void:
	# En COOP_2P cada jugador tiene su personaje fijo: el indicador solo tiene sentido en SINGLE.
	if _game_state.mode != GameMode.Mode.SINGLE or player_index != 1:
		return
	_active_label.text = _text("HUD_ACTIVE_CHARACTER", "Controlas: P%d") % character_index
	_active_label.show()


func _on_device_assigned(player_index: int, device: int) -> void:
	if device == DeviceAssignment.NONE:
		return
	_notice.text = _text("HUD_DEVICE_CONNECTED", "J%d conectado") % player_index
	_notice.show()
	if _notice_tween != null:
		_notice_tween.kill()
	_notice_tween = create_tween()
	_notice_tween.tween_interval(2.0)
	_notice_tween.tween_callback(_notice.hide)


func _on_pause_changed(paused: bool) -> void:
	modulate = get_theme_color(&"paused_color", &"RoundHUD") if paused else Color.WHITE


func _render() -> void:
	_time_label.text = _text("HUD_SECONDS_FORMAT", "%.1fs") % _time_left
	var elapsed: float = maxf(_duration - _time_left, 0.0)
	var rate: float = float(_boxes) * 60.0 / elapsed if elapsed > 0.0 else 0.0
	_rate_label.text = "%.2f" % rate
	var tone: StringName = &"ratio_good_color" if rate > 1.0 else &"ratio_bad_color"
	_rate_label.add_theme_color_override(&"font_color", get_theme_color(tone, &"RoundHUD"))
	_revenue_label.text = _text("HUD_REVENUE_FORMAT", "%d €") % _revenue


func _text(key: String, fallback: String) -> String:
	var translated: String = tr(key)
	return fallback if translated == key else translated
