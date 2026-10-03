class_name RoundHUD
extends Control
## Presentación del reloj único. No arranca rondas ni acumula delta.

var _bus: Node
var _duration: float = 0.0
var _time_left: float = 0.0
var _boxes: int = 0

@onready var _time_label: Label = %TimeLeft
@onready var _rate_label: Label = %BoxesPerMinute


func _ready() -> void:
	if _bus == null:
		_bus = EventBus
	_bus.round_started.connect(_on_round_started)
	_bus.round_time_changed.connect(_on_time_changed)
	_bus.score_changed.connect(_on_score_changed)
	%TimeTitle.text = _text("HUD_TIME_LEFT", "Tiempo restante")
	%RateTitle.text = _text("HUD_BOXES_PER_MINUTE", "Cajas / minuto")
	_render()


func set_bus(bus: Node) -> void:
	_bus = bus


func _on_round_started(duration: float) -> void:
	_duration = duration
	_time_left = duration
	_boxes = 0
	_render()


func _on_time_changed(time_left: float) -> void:
	_time_left = maxf(time_left, 0.0)
	_render()


func _on_score_changed(boxes_delivered: int, _revenue: int) -> void:
	_boxes = boxes_delivered
	_render()


func _render() -> void:
	_time_label.text = _text("HUD_SECONDS_FORMAT", "%.1f s") % _time_left
	var elapsed: float = maxf(_duration - _time_left, 0.0)
	var rate: float = float(_boxes) * 60.0 / elapsed if elapsed > 0.0 else 0.0
	_rate_label.text = "%.2f" % rate


func _text(key: String, fallback: String) -> String:
	var translated: String = tr(key)
	return fallback if translated == key else translated
