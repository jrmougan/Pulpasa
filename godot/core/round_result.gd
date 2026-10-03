class_name RoundResult
extends RefCounted
## Resultado de una ronda (porta ProductivitySystem: ratio y texto de rendimiento).

## Segundos jugados.
var duration: float = 0.0
var boxes_delivered: int = 0
var boxes_per_minute: float = 0.0
## M1 (D2).
var revenue: int = 0
## M1 (D2).
var stars: int = 0

## Tramos de rendimiento inyectados desde `RoundConfig` (paridad M0: valores de Unity).
var _thresholds: Array[float] = []
var _texts: Array[String] = []


func _init(
	p_duration: float = 0.0,
	p_boxes_delivered: int = 0,
	p_revenue: int = 0,
	p_thresholds: Array[float] = [],
	p_texts: Array[String] = []
) -> void:
	duration = p_duration
	boxes_delivered = p_boxes_delivered
	revenue = p_revenue
	_thresholds = p_thresholds.duplicate()
	_texts = p_texts.duplicate()
	boxes_per_minute = 0.0 if duration <= 0.0 else boxes_delivered / (duration / 60.0)


## Texto del primer tramo cuyo umbral supera el ratio (o el último). Vacío si la configuración
## no trae un texto por tramo.
func get_performance_description() -> String:
	if _texts.size() != _thresholds.size() + 1:
		return ""
	for i: int in range(_thresholds.size()):
		if boxes_per_minute < _thresholds[i]:
			return _texts[i]
	return _texts[_texts.size() - 1]
