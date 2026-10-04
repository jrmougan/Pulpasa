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
var _performance_thresholds: Array[float] = []
var _texts: Array[String] = []
var _revenue_thresholds: Array[int] = []


func _init(
	p_duration: float = 0.0,
	p_boxes_delivered: int = 0,
	p_revenue: int = 0,
	p_performance_thresholds: Array[float] = [],
	p_texts: Array[String] = [],
	p_revenue_thresholds: Array[int] = []
) -> void:
	duration = p_duration
	boxes_delivered = p_boxes_delivered
	revenue = p_revenue
	_performance_thresholds = p_performance_thresholds.duplicate()
	_texts = p_texts.duplicate()
	_revenue_thresholds = p_revenue_thresholds.duplicate()
	boxes_per_minute = 0.0 if duration <= 0.0 else boxes_delivered / (duration / 60.0)

	stars = 0
	if _revenue_thresholds.size() == 3:
		if revenue >= _revenue_thresholds[2]:
			stars = 3
		elif revenue >= _revenue_thresholds[1]:
			stars = 2
		elif revenue >= _revenue_thresholds[0]:
			stars = 1


## Texto del primer tramo cuyo umbral supera el ratio (o el último). Vacío si la configuración
## no trae un texto por tramo.
func get_performance_description() -> String:
	if _texts.size() != _performance_thresholds.size() + 1:
		return ""
	for i: int in range(_performance_thresholds.size()):
		if boxes_per_minute < _performance_thresholds[i]:
			return _texts[i]
	return _texts[_texts.size() - 1]
