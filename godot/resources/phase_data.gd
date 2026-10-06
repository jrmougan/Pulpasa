class_name PhaseData
extends Resource
## Una fase de dificultad de la ronda (M3, ADR-006 §6). Va en `RoundConfig.phases`, ordenadas.

## Inicio de la fase como fracción (0–1) de `RoundConfig.duration` (AC6: escala con la partida).
@export_range(0.0, 1.0) var start_fraction: float = 0.0
## Cuántos puestos aceptan comandas: los primeros de `level.stands`, en su orden.
@export var active_slots: int = 4
## Factor sobre el `max_time` de cada `OrderData` para las comandas creadas en esta fase
## (1,0 = el de la receta). Las comandas vivas conservan el suyo (AC4).
@export var patience_multiplier: float = 1.0
