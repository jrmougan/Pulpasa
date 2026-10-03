class_name RoundState
extends RefCounted
## Reloj único de ronda y contador de entregas (porta ProductivitySystem sin B2, ADR-002).
## Escucha directamente al `OrderBoard` inyectado; el tiempo solo avanza con `advance(delta)`.

signal round_started(duration: float)
signal round_time_changed(time_left: float)
signal round_finished(result: RoundResult)
signal score_changed(boxes_delivered: int, revenue: int)

## Tolerancia del reloj: 10800 × 1/60 debe acabar en el tick 10800 pese al error de coma flotante.
const TIME_EPSILON: float = 1e-6

var _config: RoundConfig
var _board: OrderBoard
var _time_left: float = 0.0
var _boxes_delivered: int = 0
## M0: siempre 0 (paridad). M1 (D2) suma puntos y resta penalizaciones.
var _revenue: int = 0
var _running: bool = false
var _finished: bool = false
var _result: RoundResult


func _init(config: RoundConfig, board: OrderBoard) -> void:
	_config = config
	_board = board
	_time_left = config.duration
	_board.order_completed.connect(_on_order_completed)
	_board.order_expired.connect(_on_order_expired)
	_board.delivery_rejected.connect(_on_delivery_rejected)


## Arranque determinista (B10, B11): reset del tablero, comandas iniciales, reloj y `round_started`.
func start(slot_ids: Array[int]) -> void:
	_time_left = _config.duration
	_boxes_delivered = 0
	_revenue = 0
	_finished = false
	_result = null
	_board.reset()
	_board.fill_slots(slot_ids)
	_running = true
	round_time_changed.emit(_time_left)
	round_started.emit(_config.duration)


## Un paso de reloj, en el orden de ADR-002: paciencia y caducidad del tablero, luego el reloj y,
## si llega a 0, `OrderBoard.stop()` y `round_finished` (exactamente en `duration`, B2).
func advance(delta: float) -> void:
	if not _running or _finished or delta <= 0.0:
		return
	var d: float = _time_left if _time_left - delta <= TIME_EPSILON else delta
	_board.advance(d)
	var previous_second: int = _whole_second(_time_left)
	_time_left = 0.0 if d >= _time_left else _time_left - d
	if _whole_second(_time_left) != previous_second:
		round_time_changed.emit(_time_left)
	if _time_left <= 0.0:
		_finish()


func get_time_left() -> float:
	return _time_left


func get_boxes_delivered() -> int:
	return _boxes_delivered


func get_revenue() -> int:
	return _revenue


func is_running() -> bool:
	return _running and not _finished


func is_finished() -> bool:
	return _finished


## Resultado final, o `null` si la ronda no ha terminado.
func get_result() -> RoundResult:
	return _result


func _finish() -> void:
	_finished = true
	_running = false
	_board.stop()
	_result = RoundResult.new(_config.duration, _boxes_delivered, _revenue)
	round_finished.emit(_result)


func _whole_second(time_left: float) -> int:
	return ceili(time_left - TIME_EPSILON)


func _on_order_completed(_order: ActiveOrder, _points: int) -> void:
	_boxes_delivered += 1
	score_changed.emit(_boxes_delivered, _revenue)


func _on_order_expired(_order: ActiveOrder, _penalty: int) -> void:
	score_changed.emit(_boxes_delivered, _revenue)


func _on_delivery_rejected(_slot_id: int, _order_id: int, penalty: int) -> void:
	if penalty > 0:
		score_changed.emit(_boxes_delivered, _revenue)
