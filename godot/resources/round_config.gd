class_name RoundConfig
extends Resource
## Números de `RoundState` (ADR-002). Paridad M0: 180 s; D5 (300 s) entra en M1.

@export var duration: float = 180.0
@export var first_order_delay: float = 0.0
## Umbrales ascendentes de cajas/minuto (ProductivitySystem.GetPerformanceDescription).
@export var performance_thresholds: Array[float] = []
## Un texto por tramo: `performance_thresholds.size() + 1` (el último, por encima del mayor umbral).
@export var performance_texts: Array[String] = []
