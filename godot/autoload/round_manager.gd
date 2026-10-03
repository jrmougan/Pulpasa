extends Node
## Adaptador de RoundState (ADR-002): arranca la ronda, mete el tiempo en `_physics_process` y
## reenvía las señales del núcleo al bus. Sin reglas de juego. Con el árbol en pausa no avanza
## nada (process_mode INHERIT): ni el reloj de ronda ni la paciencia de las comandas.

## Prioridad de física mínima: el reloj avanza antes que cualquier otro nodo en cada tick.
const PHYSICS_PRIORITY: int = -2147483648

## Ronda en curso, o `null` antes del primer `start_round`.
var round_state: RoundState

var _bus: Node
var _order_service: Node


func _init() -> void:
	process_physics_priority = PHYSICS_PRIORITY


func _ready() -> void:
	if _bus == null:
		_bus = EventBus
	if _order_service == null:
		_order_service = OrderService


## Inyecta el bus (tests). Llamar antes de añadir el nodo al árbol; por defecto, el autoload.
func set_bus(bus: Node) -> void:
	_bus = bus


## Inyecta el OrderService (tests); por defecto, el autoload.
func set_order_service(service: Node) -> void:
	_order_service = service


## Arranque determinista (ADR-002 regla 6): crea un `RoundState` nuevo sobre el tablero de
## `OrderService` y lo arranca (orders_reset, order_generated por puesto, round_started).
func start_round(config: RoundConfig, slot_ids: Array[int]) -> void:
	var service: Node = _order_service if _order_service != null else OrderService
	var board: OrderBoard = service.board
	if board == null:
		push_error("RoundManager: OrderService.setup(catalog) debe llamarse antes de start_round")
		return
	_detach_round_state(board)
	round_state = RoundState.new(config, board)
	round_state.round_started.connect(_on_round_started)
	round_state.round_time_changed.connect(_on_round_time_changed)
	round_state.round_finished.connect(_on_round_finished)
	round_state.score_changed.connect(_on_score_changed)
	round_state.start(slot_ids)


## Suelta el núcleo anterior: el reenvío al bus y las conexiones que él mismo hizo al tablero
## (RoundState las crea en su constructor), para que un núcleo conservado no siga emitiendo.
func _detach_round_state(board: OrderBoard) -> void:
	var previous: RoundState = round_state
	if previous == null:
		return
	previous.round_started.disconnect(_on_round_started)
	previous.round_time_changed.disconnect(_on_round_time_changed)
	previous.round_finished.disconnect(_on_round_finished)
	previous.score_changed.disconnect(_on_score_changed)
	for board_signal: Signal in [
		board.order_completed, board.order_expired, board.delivery_rejected
	]:
		for connection: Dictionary in board_signal.get_connections():
			var callable: Callable = connection["callable"]
			if callable.get_object() == previous:
				board_signal.disconnect(callable)
	round_state = null


func _physics_process(delta: float) -> void:
	if round_state != null:
		round_state.advance(delta)


func _get_bus() -> Node:
	return _bus if _bus != null else EventBus


func _on_round_started(duration: float) -> void:
	_get_bus().round_started.emit(duration)


func _on_round_time_changed(time_left: float) -> void:
	_get_bus().round_time_changed.emit(time_left)


func _on_round_finished(result: RoundResult) -> void:
	_get_bus().round_finished.emit(result)


func _on_score_changed(boxes_delivered: int, revenue: int) -> void:
	_get_bus().score_changed.emit(boxes_delivered, revenue)
