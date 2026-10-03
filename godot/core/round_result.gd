class_name RoundResult
extends RefCounted
## Resultado de una ronda (porta ProductivitySystem: ratio y texto de rendimiento).

## Umbrales de cajas/minuto y textos del prototipo (paridad M0; M1 pasa a recaudación y estrellas).
const PERFORMANCE_THRESHOLDS: Array[float] = [1.0, 2.0, 3.0]
const PERFORMANCE_TEXTS: Array[String] = [
	"Pulpeiro ineficiente",
	"Pulpeiro aceptable",
	"Pulpeiro eficiente",
	"!Pulpeiro lexendario!",
]

## Segundos jugados.
var duration: float = 0.0
var boxes_delivered: int = 0
var boxes_per_minute: float = 0.0
## M1 (D2).
var revenue: int = 0
## M1 (D2).
var stars: int = 0


func _init(p_duration: float = 0.0, p_boxes_delivered: int = 0, p_revenue: int = 0) -> void:
	duration = p_duration
	boxes_delivered = p_boxes_delivered
	revenue = p_revenue
	boxes_per_minute = 0.0 if duration <= 0.0 else boxes_delivered / (duration / 60.0)


func get_performance_description() -> String:
	for i: int in range(PERFORMANCE_THRESHOLDS.size()):
		if boxes_per_minute < PERFORMANCE_THRESHOLDS[i]:
			return PERFORMANCE_TEXTS[i]
	return PERFORMANCE_TEXTS[PERFORMANCE_TEXTS.size() - 1]
