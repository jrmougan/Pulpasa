class_name OrderTicket
extends PanelContainer
## Un ticket por id; solo el bus modifica su paciencia. Barra y reloj de 7 segmentos (PUL-086)
## muestran el mismo `time_left`; con paciencia baja la barra pasa a `alert_color` y parpadea.

## Periodo del parpadeo de paciencia baja (s): el aviso nunca es solo color (biblia §2.6).
const BLINK_PERIOD: float = 0.5
const BLINK_MIN_ALPHA: float = 0.35

## Color del puesto (franja superior, R13); el puesto lo lee de la misma paleta (PUL-100).
const PALETTE: StandPalette = preload("res://data/config/stand_palette.tres")

var order_id: int = -1
var _bus: Node
var _low: bool = false

@onready var _stripe: ColorRect = %Stripe
@onready var _bar: TextureProgressBar = %PatienceBar
@onready var _clock: Label = %Clock


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
	%OrderId.text = _text("TICKET_ID_FORMAT", "#%d") % order_id
	_stripe.color = PALETTE.color_for(order.slot_id)
	%Entry.setup(order.data)
	_show_patience(false)


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


func _text(key: String, fallback: String) -> String:
	var translated: String = tr(key)
	return fallback if translated == key else translated
