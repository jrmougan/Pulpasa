class_name OrderBoard
extends RefCounted
## Comandas activas por puesto (porta OrderSystem sin acceso a escena, ADR-002).
## Genera, avanza la paciencia, caduca, valida con `OrderValidator` y repone. Las señales y los
## getters entregan copias de `ActiveOrder`. El tiempo solo avanza con `advance(delta)`.

signal orders_reset
signal order_generated(order: ActiveOrder)
signal order_completed(order: ActiveOrder, points: int)
signal delivery_rejected(slot_id: int, order_id: int, penalty: int)
signal order_patience_changed(order_id: int, time_left: float, max_time: float)
signal order_expired(order: ActiveOrder, penalty: int)

## `order_id` de `delivery_rejected` cuando el puesto no tiene comanda.
const NO_ORDER: int = -1
## Residuo de coma flotante que cuenta como paciencia agotada: 3600 × 1/60 deja restos del orden de
## 1e-12 y debe caducar en el tick 3600. Es muy inferior a cualquier delta real, así que nunca se
## caduca antes del límite (advance(59,9999995) deja 5e-7 s y no caduca).
const EXPIRY_EPSILON: float = 1e-9

var _catalog: OrderCatalog
var _rng: RandomNumberGenerator
var _reject_penalty: int
var _expire_penalty: int
## slot_id → comanda viva (original, nunca sale del núcleo).
var _orders: Dictionary[int, ActiveOrder] = {}
## slot_id → order_id de las comandas caducadas en el último `advance` (empate, ADR-002).
var _expired_this_tick: Dictionary[int, int] = {}
var _next_order_id: int = 1
var _stopped: bool = false
## Puestos que aceptan comandas nuevas; sin `set_active_slots`, todos (ADR-006 §6).
var _active_slots: Array[int] = []
var _all_slots_active: bool = true
## Factor sobre el `max_time` de `OrderData` para las comandas que se creen desde ahora.
var _patience_multiplier: float = 1.0


func _init(
	catalog: OrderCatalog,
	rng: RandomNumberGenerator,
	reject_penalty: int = 0,
	expire_penalty: int = 0
) -> void:
	_catalog = catalog
	_rng = rng
	_reject_penalty = reject_penalty
	_expire_penalty = expire_penalty


## Vacía el tablero y reinicia ids, puestos activos (todos) y multiplicador de paciencia (1,0).
## Emite `orders_reset` (los puestos limpian su vista, B16).
func reset() -> void:
	_orders.clear()
	_expired_this_tick.clear()
	_next_order_id = 1
	_stopped = false
	_active_slots.clear()
	_all_slots_active = true
	_patience_multiplier = 1.0
	orders_reset.emit()


## Limita las comandas nuevas a estos puestos (fases, ADR-006 §6): `request_order` en otro puesto
## devuelve `null`. La comanda viva de un puesto que se desactiva sigue hasta entregarse o caducar
## y no se repone.
func set_active_slots(slot_ids: Array[int]) -> void:
	_active_slots = slot_ids.duplicate()
	_all_slots_active = false


## Multiplica el `max_time` de `OrderData` de las comandas que se creen desde ahora (1,0 = sin
## cambio). Las vivas conservan el suyo: `ActiveOrder` lo copia al crearse (AC4).
func set_new_order_patience_multiplier(factor: float) -> void:
	_patience_multiplier = factor


## Pide una comanda por puesto, en el orden dado, hasta el máximo de activas.
func fill_slots(slot_ids: Array[int]) -> void:
	for slot_id: int in slot_ids:
		request_order(slot_id)


## Crea una comanda para el puesto. Devuelve una copia, o `null` si el tablero está parado,
## el catálogo vacío, el puesto inactivo u ocupado o ya hay el máximo de activas.
func request_order(slot_id: int) -> ActiveOrder:
	if _stopped or _catalog == null or _catalog.orders.is_empty():
		return null
	if not _all_slots_active and not _active_slots.has(slot_id):
		return null
	if _orders.has(slot_id) or _orders.size() >= _catalog.max_active_orders:
		return null
	var data: OrderData = _catalog.orders[_rng.randi_range(0, _catalog.orders.size() - 1)]
	var max_time: float = data.max_time * _patience_multiplier
	var order: ActiveOrder = ActiveOrder.new(_next_order_id, data, slot_id, max_time)
	_next_order_id += 1
	_orders[slot_id] = order
	order_generated.emit(order.copy())
	return order.copy()


## Avanza la paciencia `delta` segundos: emite `order_patience_changed` por comanda con
## `max_time > 0` y, en orden ascendente de `slot_id`, caduca y repone las agotadas.
func advance(delta: float) -> void:
	if _stopped:
		return
	_expired_this_tick.clear()
	var slot_ids: Array[int] = _sorted_slots()
	var expired: Array[int] = []
	for slot_id: int in slot_ids:
		var order: ActiveOrder = _orders[slot_id]
		if order.max_time <= 0.0:
			continue
		order.time_left -= delta
		if order.time_left <= EXPIRY_EPSILON:
			order.time_left = 0.0
			expired.append(slot_id)
		order_patience_changed.emit(order.id, order.time_left, order.max_time)
	for slot_id: int in expired:
		var order: ActiveOrder = _orders[slot_id]
		_orders.erase(slot_id)
		_expired_this_tick[slot_id] = order.id
		order_expired.emit(order.copy(), _expire_penalty)
		request_order(slot_id)


## Intenta entregar en el puesto. Si la comanda del puesto caducó en el último `advance`, rechaza
## sin redirigir a la repuesta. Si la caja coincide, completa esa comanda una vez y repone el
## puesto en la misma llamada (B1). Devuelve la comanda completada (copia) o `null`.
## Con el tablero parado devuelve `null` sin señales.
func try_deliver(slot_id: int, contents: BoxContents) -> ActiveOrder:
	if _stopped:
		return null
	if _expired_this_tick.has(slot_id):
		delivery_rejected.emit(slot_id, _expired_this_tick[slot_id], 0)
		return null
	var order: ActiveOrder = _orders.get(slot_id) as ActiveOrder
	if order == null:
		delivery_rejected.emit(slot_id, NO_ORDER, 0)
		return null
	if order.max_time > 0.0 and order.time_left <= 0.0:
		delivery_rejected.emit(slot_id, order.id, 0)
		return null
	if not OrderValidator.matches(order.data, contents):
		delivery_rejected.emit(slot_id, order.id, _reject_penalty)
		return null
	_orders.erase(slot_id)
	var completed: ActiveOrder = order.copy()
	order_completed.emit(completed.copy(), order.data.recipe.base_points)
	request_order(slot_id)
	return completed


## Detiene el tablero (fin de ronda): no avanza, no repone, no caduca ni acepta entregas.
func stop() -> void:
	_stopped = true


func is_stopped() -> bool:
	return _stopped


## Copias de las comandas vivas, en orden ascendente de `slot_id`.
func get_active_orders() -> Array[ActiveOrder]:
	var result: Array[ActiveOrder] = []
	for slot_id: int in _sorted_slots():
		result.append(_orders[slot_id].copy())
	return result


## Copia de la comanda viva del puesto, o `null`.
func get_order_for_slot(slot_id: int) -> ActiveOrder:
	var order: ActiveOrder = _orders.get(slot_id) as ActiveOrder
	return null if order == null else order.copy()


func _sorted_slots() -> Array[int]:
	var slot_ids: Array[int] = []
	slot_ids.assign(_orders.keys())
	slot_ids.sort()
	return slot_ids
