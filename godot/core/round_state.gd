class_name RoundState
extends RefCounted
## Reloj único de ronda y contador de entregas (porta ProductivitySystem sin B2, ADR-002).
## Escucha directamente al `OrderBoard` inyectado; el tiempo solo avanza con `advance(delta)`.

signal round_started(duration: float)
signal round_time_changed(time_left: float)
signal round_finished(result: RoundResult)
signal score_changed(boxes_delivered: int, revenue: int)

## Residuo de coma flotante que se absorbe al llegar a 0: acumular 1/60 s deja restos del orden
## de 1e-12, así que 10800 × 1/60 acaba en el tick 10800. Es muy inferior a cualquier delta real:
## la ronda nunca acaba antes del límite (advance(179,9999995) deja 5e-7 s y no acaba).
const TIME_EPSILON: float = 1e-9

var _config: RoundConfig
var _board: OrderBoard
var _time_left: float = 0.0
var _boxes_delivered: int = 0
## Recaudación actual en euros (M1, D2).
var _revenue: int = 0
var _running: bool = false
var _finished: bool = false
var _result: RoundResult
var _slot_ids: Array[int] = []
var _first_orders_filled: bool = false


func _init(config: RoundConfig, board: OrderBoard) -> void:
	_config = config
	_board = board
	_time_left = config.duration
	_board.order_completed.connect(_on_order_completed)
	_board.order_expired.connect(_on_order_expired)
	_board.delivery_rejected.connect(_on_delivery_rejected)


## Arranque determinista (B10, B11): reset del tablero, comandas iniciales, reloj y `round_started`.
## Con `first_order_delay` > 0 (M1) las comandas iniciales se difieren a `advance`; si es 0
## (paridad M0) se generan aquí, antes de `round_started` (signals.md).
func start(slot_ids: Array[int]) -> void:
	_time_left = _config.duration
	_boxes_delivered = 0
	_revenue = 0
	_finished = false
	_result = null
	_slot_ids = slot_ids
	_first_orders_filled = false
	_board.reset()
	_running = true
	if _config.first_order_delay <= 0.0:
		_board.fill_slots(_slot_ids)
		_first_orders_filled = true
	round_time_changed.emit(_time_left)
	round_started.emit(_config.duration)


## Un paso de reloj, en el orden de ADR-002: paciencia y caducidad del tablero, luego el reloj y,
## si llega a 0, `OrderBoard.stop()` y `round_finished` (exactamente en `duration`, B2).
func advance(delta: float) -> void:
	if not _running or _finished or delta <= 0.0:
		return
	var d: float = minf(delta, _time_left)
	_board.advance(d)
	var previous_second: int = _whole_second(_time_left)
	_time_left -= d

	if not _first_orders_filled and (_config.duration - _time_left) >= _config.first_order_delay:
		_board.fill_slots(_slot_ids)
		_first_orders_filled = true

	if _time_left <= TIME_EPSILON:
		_time_left = 0.0
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
	_result = RoundResult.new(
		_config.duration,
		_boxes_delivered,
		_revenue,
		_config.performance_thresholds,
		_config.performance_texts,
		_config.revenue_thresholds
	)
	round_finished.emit(_result)


func _whole_second(time_left: float) -> int:
	return ceili(time_left - TIME_EPSILON)


func _on_order_completed(order: ActiveOrder, points: int) -> void:
	var bonus: int = 0
	if order.max_time > 0.0:
		bonus = floori((order.time_left / order.max_time) * _config.time_bonus_max)
	_revenue = maxi(0, _revenue + points + bonus)
	_boxes_delivered += 1
	score_changed.emit(_boxes_delivered, _revenue)


func _on_order_expired(_order: ActiveOrder, penalty: int) -> void:
	if penalty > 0:
		_revenue = maxi(0, _revenue - penalty)
		score_changed.emit(_boxes_delivered, _revenue)


func _on_delivery_rejected(_slot_id: int, _order_id: int, penalty: int) -> void:
	if penalty > 0:
		_revenue = maxi(0, _revenue - penalty)
		score_changed.emit(_boxes_delivered, _revenue)
