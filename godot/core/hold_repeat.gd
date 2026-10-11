class_name HoldRepeat
extends RefCounted
## Temporizador del corte al mantener pulsado (ADR-003 §11.4). Puro: sin `Input` ni árbol.
## Tras `arm()`, `advance(delta)` da `true` cada `interval` segundos de juego.

## Tolerancia de coma flotante al acumular `delta` (4 × 0,05 ≠ 0,2 exacto).
const EPSILON: float = 0.00001

var interval: float

var _armed: bool = false
var _elapsed: float = 0.0


func _init(new_interval: float = 0.2) -> void:
	interval = new_interval


## Empieza a contar desde cero.
func arm() -> void:
	_armed = true
	_elapsed = 0.0


func disarm() -> void:
	_armed = false
	_elapsed = 0.0


func is_armed() -> bool:
	return _armed


## `true` como mucho una vez por llamada, al cumplirse `interval` desde `arm()` o desde el último
## `true`; el sobrante se conserva. Desarmado, siempre `false`.
func advance(delta: float) -> bool:
	if not _armed:
		return false
	_elapsed += delta
	if _elapsed + EPSILON < interval:
		return false
	_elapsed = maxf(_elapsed - interval, 0.0)
	return true
