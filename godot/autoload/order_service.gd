extends Node
## Adaptador de OrderBoard (ADR-002): crea el núcleo, expone sus métodos y reenvía sus señales al
## bus. Sin reglas de juego, sin acceso a escena y sin `_process`: su tiempo lo avanza RoundManager.

## Tablero de comandas, o `null` hasta que `setup` recibe el catálogo.
var board: OrderBoard

var _bus: Node


func _ready() -> void:
	if _bus == null:
		_bus = EventBus


## Inyecta el bus (tests). Llamar antes de añadir el nodo al árbol; por defecto, el autoload.
func set_bus(bus: Node) -> void:
	_bus = bus


## Crea un `OrderBoard` nuevo con el catálogo que inyecta el nivel (ADR-002 regla 7).
## `rng` es opcional: sin él, se usa uno aleatorio.
func setup(
	catalog: OrderCatalog, config: RoundConfig = null, rng: RandomNumberGenerator = null
) -> void:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	_disconnect_board()
	var reject: int = config.wrong_delivery_penalty if config != null else 0
	var expire: int = config.expire_penalty if config != null else 0
	board = OrderBoard.new(catalog, rng, reject, expire)
	board.orders_reset.connect(_on_orders_reset)
	board.order_generated.connect(_on_order_generated)
	board.order_completed.connect(_on_order_completed)
	board.delivery_rejected.connect(_on_delivery_rejected)
	board.order_patience_changed.connect(_on_order_patience_changed)
	board.order_expired.connect(_on_order_expired)


## Entrega una caja en el puesto. Devuelve la comanda completada o `null`.
func try_deliver(slot_id: int, contents: BoxContents) -> ActiveOrder:
	if board == null:
		return null
	return board.try_deliver(slot_id, contents)


## Pide una comanda para el puesto. Devuelve una copia o `null`.
func request_order(slot_id: int) -> ActiveOrder:
	if board == null:
		return null
	return board.request_order(slot_id)


## Copias de las comandas vivas, en orden ascendente de `slot_id`.
func get_active_orders() -> Array[ActiveOrder]:
	if board == null:
		return [] as Array[ActiveOrder]
	return board.get_active_orders()


## Deja de reenviar el tablero anterior, por si alguien conserva una referencia a él.
func _disconnect_board() -> void:
	if board == null:
		return
	board.orders_reset.disconnect(_on_orders_reset)
	board.order_generated.disconnect(_on_order_generated)
	board.order_completed.disconnect(_on_order_completed)
	board.delivery_rejected.disconnect(_on_delivery_rejected)
	board.order_patience_changed.disconnect(_on_order_patience_changed)
	board.order_expired.disconnect(_on_order_expired)


func _get_bus() -> Node:
	return _bus if _bus != null else EventBus


func _on_orders_reset() -> void:
	_get_bus().orders_reset.emit()


func _on_order_generated(order: ActiveOrder) -> void:
	_get_bus().order_generated.emit(order)


func _on_order_completed(order: ActiveOrder, points: int) -> void:
	_get_bus().order_completed.emit(order, points)


func _on_delivery_rejected(slot_id: int, order_id: int, penalty: int) -> void:
	_get_bus().delivery_rejected.emit(slot_id, order_id, penalty)


func _on_order_patience_changed(order_id: int, time_left: float, max_time: float) -> void:
	_get_bus().order_patience_changed.emit(order_id, time_left, max_time)


func _on_order_expired(order: ActiveOrder, penalty: int) -> void:
	_get_bus().order_expired.emit(order, penalty)
