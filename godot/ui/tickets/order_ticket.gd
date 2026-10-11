class_name OrderTicket
extends PanelContainer
## Un ticket por id; solo el bus modifica su paciencia. Barra y reloj de 7 segmentos (PUL-086)
## muestran el mismo `time_left`; con paciencia baja la barra pasa a `alert_color` y parpadea.

## Periodo del parpadeo de paciencia baja (s): el aviso nunca es solo color (biblia §2.6).
const BLINK_PERIOD: float = 0.5
const BLINK_MIN_ALPHA: float = 0.35
## Cifras del reloj en MOBILE: el suelo de texto (24 unidades a 720) ya las deja a 36 px a 1080.
const MOBILE_CLOCK_UNITS: int = 24

## Color del puesto (franja superior, R13); el puesto lo lee de la misma paleta (PUL-100).
const PALETTE: StandPalette = preload("res://data/config/stand_palette.tres")

var order_id: int = -1
var _bus: Node
var _low: bool = false
var _mobile_built: bool = false
var _min_text_units: float = 0.0

@onready var _stripe: ColorRect = %Stripe
@onready var _bar: TextureProgressBar = %PatienceBar
@onready var _clock: Label = %Clock
@onready var _order_id: Label = %OrderId
@onready var _entry: TicketEntry = %Entry


func _ready() -> void:
	if _bus == null:
		_bus = EventBus
	_bus.order_patience_changed.connect(_on_patience_changed)
	%Title.text = _text("TICKET_TITLE", "Comanda")
	_bar.tint_under = get_theme_color(&"track_color", &"OrderTicket")
	_set_low(false)
	_show_patience(false)
	set_process(false)


func set_bus(bus: Node) -> void:
	_bus = bus


func setup(order: ActiveOrder) -> void:
	order_id = order.id
	_order_id.text = _text("TICKET_ID_FORMAT", "#%d") % order_id
	_stripe.color = PALETTE.color_for(order.slot_id)
	_entry.setup(order.data)
	_show_patience(false)
	if _mobile_built:
		_apply_floor()


## Ticket MOBILE (PUL-129, controles-tactiles.md): `width_units` x `ticket_height` px, receta
## arriba y, debajo, pegatinas + id + reloj en una fila, con la barra de paciencia de 12 px. Se
## puede repetir al cambiar el alto del lienzo; la reestructuración solo ocurre la primera vez.
func apply_mobile_layout(profile: UiProfile, width_units: float) -> void:
	var canvas_height: float = get_viewport().get_visible_rect().size.y
	if not _mobile_built:
		_build_mobile_structure()
	custom_minimum_size = Vector2(
		width_units, UiScale.px_to_units(profile.ticket_height, canvas_height)
	)
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_bar.custom_minimum_size.y = UiScale.px_to_units(profile.patience_bar_px, canvas_height)
	_entry.set_icon_px(UiScale.px_to_units(profile.ticket_icon_px, canvas_height))
	_min_text_units = UiScale.px_to_units(profile.text_min_px, canvas_height)
	_apply_floor()


## Paciencia por debajo del umbral de aviso (para tests).
func is_low_patience() -> bool:
	return _low


## «MM:SS» redondeando hacia arriba: «00:00» solo cuando la paciencia se ha agotado.
static func format_clock(seconds: float) -> String:
	var total: int = ceili(maxf(seconds, 0.0))
	return "%02d:%02d" % [mini(total / 60, 99), total % 60]


func _process(_delta: float) -> void:
	var phase: float = fmod(Time.get_ticks_msec() / 1000.0, BLINK_PERIOD) / BLINK_PERIOD
	_bar.self_modulate.a = 1.0 if phase < 0.5 else BLINK_MIN_ALPHA


func _on_patience_changed(id: int, time_left: float, max_time: float) -> void:
	if id != order_id:
		return
	_show_patience(max_time > 0.0)
	if max_time <= 0.0:
		return
	_bar.max_value = max_time
	_bar.value = clampf(time_left, 0.0, max_time)
	_clock.text = format_clock(time_left)
	var threshold: float = get_theme_constant(&"alert_percent", &"OrderTicket") / 100.0
	_set_low(time_left <= max_time * threshold)


func _show_patience(shown: bool) -> void:
	_bar.visible = shown
	%ClockWell.visible = shown
	if not shown:
		_set_low(false)


func _set_low(low: bool) -> void:
	_low = low
	var tone: StringName = &"alert_color" if low else &"bar_color"
	_bar.tint_progress = get_theme_color(tone, &"OrderTicket")
	var digits: StringName = &"alert_color" if low else &"digits_color"
	_clock.add_theme_color_override(&"font_color", get_theme_color(digits, &"OrderTicket"))
	_bar.self_modulate.a = 1.0
	set_process(low)


func _build_mobile_structure() -> void:
	_mobile_built = true
	%Header.hide()
	_stripe.custom_minimum_size.y = 4.0
	$Content.add_theme_constant_override(&"separation", 2)
	var extras: HBoxContainer = _entry.extras()
	_order_id.reparent(extras, false)
	%ClockWell.reparent(extras, false)
	extras.show()
	_entry.compact()
	for digits: Label in [_clock, %Ghost]:
		digits.add_theme_font_size_override(&"font_size", MOBILE_CLOCK_UNITS)
	var well: StyleBox = (%ClockWell as PanelContainer).get_theme_stylebox(&"panel").duplicate()
	well.content_margin_top = 0.0
	well.content_margin_bottom = 0.0
	well.content_margin_left = 4.0
	well.content_margin_right = 4.0
	%ClockWell.add_theme_stylebox_override(&"panel", well)
	var card: StyleBox = get_theme_stylebox(&"panel").duplicate()
	card.content_margin_top = 6.0
	card.content_margin_bottom = 6.0
	card.content_margin_left = 8.0
	card.content_margin_right = 8.0
	add_theme_stylebox_override(&"panel", card)


func _apply_floor() -> void:
	TextFloor.apply(self, _min_text_units)


func _text(key: String, fallback: String) -> String:
	var translated: String = tr(key)
	return fallback if translated == key else translated
