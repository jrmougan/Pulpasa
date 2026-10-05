class_name OrderStand
extends StaticBody3D
## Puesto de entrega (porta OrderStand.cs; scene-tree.md §3). Al interactuar con una caja en la
## mano (B12) pide `OrderService.try_deliver`, que valida y rechaza con penalización (D8). Al entrar
## el portador en `%DeliveryZone` solo lo pide si la caja ya coincide con la comanda viva del puesto
## (`OrderValidator.matches`): con otra caja la zona no hace nada (PUL-039), así cruzar un puesto
## vecino no penaliza. No completa nada por su cuenta (B1): solo reacciona a las señales de
## `EventBus`. La comanda viva y el label salen de esas señales, sin consultar sistemas (B16).
## Contrato `interactable` (ADR-003 §4).

## Texto del label cuando el puesto no tiene comanda.
const EMPTY_LABEL: String = "–"

## Puesto de comandas al que entrega (`deliverySlotId`).
@export var slot_id: int = 1

var _bus: Node
var _service: Node
## Último intento de entrega (caja y tick de física): `body_entered` e `interact` en el mismo
## tick no deben pedir dos veces lo mismo al servicio.
var _last_box_id: int = 0
var _last_attempt_frame: int = -1
## Copia de la comanda viva de este puesto, o `null` (sale de las señales del bus).
var _order: ActiveOrder
## Tick de física en que caducó la comanda de este puesto: en ese tick la zona no entrega a la
## repuesta, aunque sea la misma receta (AC5b: la entrega de ese tick va a la caducada).
var _expired_frame: int = -1

@onready var _zone: Area3D = %DeliveryZone
@onready var _label: Label3D = %OrderLabel
@onready var _ok_audio: AudioStreamPlayer3D = %OkAudio
@onready var _error_audio: AudioStreamPlayer3D = %ErrorAudio


func _ready() -> void:
	if _bus == null:
		_bus = EventBus
	if _service == null:
		_service = OrderService
	_label.text = EMPTY_LABEL
	_bus.orders_reset.connect(_on_orders_reset)
	_bus.order_generated.connect(_on_order_generated)
	_bus.order_completed.connect(_on_order_completed)
	_bus.order_expired.connect(_on_order_expired)
	_bus.delivery_rejected.connect(_on_delivery_rejected)
	_zone.body_entered.connect(_on_body_entered)
	_rebuild_label()


## Inyecta el bus (tests). Llamar antes de añadir el nodo al árbol; por defecto, el autoload.
func set_bus(bus: Node) -> void:
	_bus = bus


## Inyecta el servicio de comandas (tests); por defecto, el autoload `OrderService`.
func set_service(service: Node) -> void:
	_service = service


func can_interact(actor: InteractionComponent) -> bool:
	return _held_box(actor.holder if actor != null else null) != null


## Entrega la caja en la mano. Consume la pulsación aunque la rechace: la caja se queda en la mano.
func interact(actor: InteractionComponent) -> bool:
	if not can_interact(actor):
		return false
	_try_deliver(actor.holder)
	return true


func _held_box(holder: Holder) -> Box:
	if holder == null:
		return null
	return holder.get_held_item() as Box


## Entrega lo que lleva `holder`; la caja aceptada se suelta y se libera, la rechazada no se toca.
## Con `only_if_valid` (zona) no pide nada si la caja no coincide con la comanda viva.
func _try_deliver(holder: Holder, only_if_valid: bool = false) -> void:
	var box: Box = _held_box(holder)
	if box == null:
		return
	if only_if_valid and not _zone_accepts(box):
		return
	var frame: int = Engine.get_physics_frames()
	if box.get_instance_id() == _last_box_id and frame == _last_attempt_frame:
		return
	_last_box_id = box.get_instance_id()
	_last_attempt_frame = frame
	if _service.try_deliver(slot_id, box.get_contents()) == null:
		return
	holder.drop()
	box.queue_free()


func _zone_accepts(box: Box) -> bool:
	if _order == null or Engine.get_physics_frames() == _expired_frame:
		return false
	return OrderValidator.matches(_order.data, box.get_contents())


## Una sola consulta al cargar (puesto creado con la ronda en marcha); luego, solo señales (B16).
func _rebuild_label() -> void:
	_set_order(null)
	for order: ActiveOrder in _service.get_active_orders():
		if order.slot_id == slot_id:
			_set_order(order)


func _set_order(order: ActiveOrder) -> void:
	_order = order
	_label.text = EMPTY_LABEL if order == null else "#%d" % order.id


func _on_body_entered(body: Node3D) -> void:
	var node: Node = body.get_node_or_null(^"%InteractionComponent")
	var actor: InteractionComponent = node as InteractionComponent
	if actor != null:
		_try_deliver(actor.holder, true)


func _on_orders_reset() -> void:
	_set_order(null)


func _on_order_generated(order: ActiveOrder) -> void:
	if order.slot_id == slot_id:
		_set_order(order)


func _on_order_completed(order: ActiveOrder, _points: int) -> void:
	if order.slot_id != slot_id:
		return
	_set_order(null)
	_ok_audio.play()


func _on_order_expired(order: ActiveOrder, _penalty: int) -> void:
	if order.slot_id == slot_id:
		_expired_frame = Engine.get_physics_frames()
		_set_order(null)


func _on_delivery_rejected(rejected_slot_id: int, _order_id: int, _penalty: int) -> void:
	if rejected_slot_id == slot_id:
		_error_audio.play()
