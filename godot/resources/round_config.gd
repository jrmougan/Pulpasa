class_name RoundConfig
extends Resource
## Números de `RoundState` (ADR-002). Paridad M0: 180 s; D5 (300 s) entra en M1.

@export var duration: float = 180.0
@export var first_order_delay: float = 0.0
## Bonus máximo por entregar rápido (M1).
@export var time_bonus_max: int = 0
## Penalización por comanda caducada (M1).
@export var expire_penalty: int = 0
## Penalización por caja errónea (M1, D8).
@export var wrong_delivery_penalty: int = 0
## Umbrales ascendentes de recaudación para 1, 2 y 3 estrellas (M1).
@export var revenue_thresholds: Array[int] = []

## Umbrales ascendentes de cajas/minuto (ProductivitySystem.GetPerformanceDescription).
@export var performance_thresholds: Array[float] = []
## Un texto por tramo: `performance_thresholds.size() + 1` (el último, por encima del mayor umbral).
@export var performance_texts: Array[String] = []

## Fases de dificultad (M3, ADR-006 §6), ordenadas y la primera con `start_fraction` = 0.
## Vacía = sin fases: todos los puestos, `max_time` de la receta y ninguna `phase_changed`.
@export var phases: Array[PhaseData] = []
## Semilla del generador de comandas (AC5). 0 = aleatoria.
@export var rng_seed: int = 0
