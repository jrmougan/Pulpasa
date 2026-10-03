class_name InputConfig
extends Resource
## Números de input (ADR-004): zona muerta de stick y cooldown del cambio de personaje.

## Zona muerta aplicada a las acciones de movimiento.
@export var deadzone: float = 0.2
## Segundos mínimos entre dos cambios de personaje (M2).
@export var switch_cooldown: float = 0.2
