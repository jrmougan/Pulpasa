class_name RoundState
extends RefCounted
## Reloj único de ronda y contador de entregas (porta ProductivitySystem sin B2, ADR-002).
## Escucha directamente al `OrderBoard` inyectado; el tiempo solo avanza con `advance(delta)`.

signal round_started(duration: float)
signal round_time_changed(time_left: float)
signal round_finished(result: RoundResult)
signal score_changed(boxes_delivered: int, revenue: int)
## Fase de dificultad alcanzada (desde 1; M3, ADR-006 §6). Sin `RoundConfig.phases` no se emite.
signal phase_changed(phase: int)

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
## Fases de la ronda en curso (copia de `RoundConfig.phases` al arrancar).
var _phases: Array[PhaseData] = []
## Fase actual (1..n), o 0 sin fases.
var _phase: int = 0
## Puestos que abre la fase actual (con fases); sin fases, `_slot_ids`.
var _active_slot_ids: Array[int] = []


func _init(config: RoundConfig, board: OrderBoard) -> void:
	_config = config
	_board = board
	_time_left = config.duration
	_board.order_completed.connect(_on_order_completed)
	_board.order_expired.connect(_on_order_expired)
	_board.delivery_rejected.connect(_on_delivery_rejected)


## Arranque determinista (B10, B11): reset del tablero, fase 1 (si hay fases), comandas iniciales,
## reloj y `round_started`. Con `first_order_delay` > 0 (M1) las comandas iniciales se difieren a
## `advance`; si es 0 (paridad M0) se generan aquí, antes de `round_started` (signals.md).
func start(slot_ids: Array[int]) -> void:
	_time_left = _config.duration
	_boxes_delivered = 0
	_revenue = 0
	_finished = false
	_result = null
	_slot_ids = slot_ids
	_first_orders_filled = false
	_phases = _config.phases.duplicate()
	_phase = 0
	_active_slot_ids = _slot_ids
	_board.reset()
	_running = true
	if not _phases.is_empty():
		_enter_phase(0)
	if _config.first_order_delay <= 0.0:
		_board.fill_slots(_active_slot_ids)
		_first_orders_filled = true
	round_time_changed.emit(_time_left)
	round_started.emit(_config.duration)


## Un paso de reloj, en el orden de ADR-002: paciencia y caducidad del tablero, luego el reloj,
## las fases alcanzadas (ADR-006 §6) y, si llega a 0, `OrderBoard.stop()` y `round_finished`
## (exactamente en `duration`, B2).
func advance(delta: float) -> void:
	if not _running or _finished or delta <= 0.0:
		return
	var d: float = minf(delta, _time_left)
	_board.advance(d)
	var previous_second: int = _whole_second(_time_left)
	_time_left -= d
	if _time_left <= TIME_EPSILON:
		_time_left = 0.0

	_advance_phases()
	if not _first_orders_filled and (_config.duration - _time_left) >= _config.first_order_delay:
		_board.fill_slots(_active_slot_ids)
		_first_orders_filled = true

	if _whole_second(_time_left) != previous_second:
		round_time_changed.emit(_time_left)
	if _time_left <= 0.0:
		_finish()


## Fase actual (desde 1), o 0 si la ronda no tiene fases.
func get_phase() -> int:
	return _phase


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


## Entra en cada fase cuyo inicio (`start_fraction × duration`) ya se alcanzó, una vez por fase
## aunque un `delta` grande salte varias. Una fase que empieza en `duration` nunca se activa.
func _advance_phases() -> void:
	var elapsed: float = _config.duration - _time_left
	while _phase < _phases.size() and _time_left > 0.0:
		var phase: PhaseData = _phases[_phase]
		if elapsed < phase.start_fraction * _config.duration - TIME_EPSILON:
			return
		_enter_phase(_phase)
		if _first_orders_filled:
			_board.fill_slots(_active_slot_ids)


## Aplica la fase de índice `index` al tablero (puestos y paciencia) y emite `phase_changed`.
func _enter_phase(index: int) -> void:
	var phase: PhaseData = _phases[index]
	var count: int = clampi(phase.active_slots, 0, _slot_ids.size())
	_active_slot_ids = _slot_ids.slice(0, count)
	_board.set_active_slots(_active_slot_ids)
	_board.set_new_order_patience_multiplier(phase.patience_multiplier)
	_phase = index + 1
	phase_changed.emit(_phase)


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
