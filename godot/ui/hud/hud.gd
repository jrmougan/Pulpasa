class_name RoundHUD
extends SafeAreaMargin
## Presentación del reloj único y la recaudación. No arranca rondas ni acumula delta.
## Panel compacto de marca abajo a la izquierda, cifras en `ui_digits` (PUL-086). El display de 7
## segmentos queda para los relojes de los tickets: confunde «s» con «5» y apenas marca el decimal.
## Sin «Cajas / minuto» (D26.7). En MOBILE (PUL-129) es un bloque de dos líneas, recaudación y
## tiempo, arriba a la izquierda dentro de la safe area (controles-tactiles.md).

var _bus: Node
var _game_state: Node
var _duration: float = 0.0
var _time_left: float = 0.0
var _boxes: int = 0
var _revenue: int = 0
var _notice_tween: Tween
var _mobile: bool = false

@onready var _background: PanelContainer = %Background
@onready var _stats: VBoxContainer = %Background/Stats
@onready var _time_label: Label = %TimeLeft
## Oculto: lo conserva `test_parity_smoke.gd` (PUL-131 lo retira con el montaje).
@onready var _rate_label: Label = %BoxesPerMinute
@onready var _revenue_label: Label = %Revenue
@onready var _active_label: Label = %ActiveCharacter
@onready var _notice: Label = %DeviceNotice


func _ready() -> void:
	super._ready()
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
	%RevenueTitle.text = _text("HUD_REVENUE", "Recaudación")
	_render()
	_apply_layout()


## SafeAreaMargin llama aquí al cambiar la ventana: la banda se recalcula con el alto nuevo.
func refresh() -> void:
	super.refresh()
	if is_node_ready():
		_apply_layout()


func set_bus(bus: Node) -> void:
	_bus = bus


## Inyección para pruebas (solo se lee `mode`); por defecto se usa el autoload.
func set_game_state(state: Node) -> void:
	_game_state = state


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
	if _mobile or _game_state.mode != GameMode.Mode.SINGLE or player_index != 1:
		return
	_active_label.text = _text("HUD_ACTIVE_CHARACTER", "Controlas: P%d") % character_index
	_active_label.show()


func _on_device_assigned(player_index: int, device: int) -> void:
	if _mobile or device == DeviceAssignment.NONE:
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
	_revenue_label.text = _text("HUD_REVENUE_FORMAT", "%d €") % _revenue


## Disposición del perfil (ADR-005 E4). En DESKTOP no cambia nada de la escena.
func _apply_layout() -> void:
	_mobile = GameState.platform == PlatformProfile.Kind.MOBILE
	if not _mobile:
		return
	var profile: UiProfile = GameState.ui_profile
	var canvas_height: float = get_viewport().get_visible_rect().size.y
	var left: float = UiScale.px_to_units(TouchHudLayout.EDGE_MARGIN_PX, canvas_height)
	var top: float = UiScale.px_to_units(TouchHudLayout.TOP_PX, canvas_height)
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	offset_left = left
	offset_right = left
	offset_top = top
	offset_bottom = top
	grow_horizontal = Control.GROW_DIRECTION_END
	grow_vertical = Control.GROW_DIRECTION_END
	for hidden: Control in [
		%Shift.get_parent().get_parent(),
		%ActiveCharacter,
		%DeviceNotice,
		%TimeTitle,
		%RevenueTitle,
	]:
		hidden.hide()
	var revenue_block: Node = %RevenueTitle.get_parent()
	_stats.move_child(revenue_block, 0)
	_stats.add_theme_constant_override(&"separation", 0)
	_background.custom_minimum_size = Vector2(
		UiScale.px_to_units(profile.hud_block_width, canvas_height),
		UiScale.px_to_units(profile.ticket_height, canvas_height)
	)
	TextFloor.apply(self, UiScale.px_to_units(profile.text_min_px, canvas_height))


func _text(key: String, fallback: String) -> String:
	var translated: String = tr(key)
	return fallback if translated == key else translated
