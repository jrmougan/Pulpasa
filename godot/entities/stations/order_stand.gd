class_name OrderStand
extends StaticBody3D
## Puesto de entrega (porta OrderStand.cs; scene-tree.md §3). Al entrar el portador con una caja en
## `%DeliveryZone`, o al interactuar con ella en la mano (B12), pide `OrderService.try_deliver`.
## No completa nada por su cuenta (B1): solo reacciona a las señales de `EventBus`. El label sale
## de esas señales, sin consultar sistemas (B16). Contrato `interactable` (ADR-003 §4).

## Texto del label cuando el puesto no tiene comanda.
const EMPTY_LABEL: String = "–"

## Puesto de comandas al que entrega (`deliverySlotId`).
@export var slot_id: int = 1

var _bus: Node
var _service: Node

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
func _try_deliver(holder: Holder) -> void:
	var box: Box = _held_box(holder)
	if box == null:
		return
	if _service.try_deliver(slot_id, box.get_contents()) == null:
		return
	holder.drop()
	box.queue_free()


func _on_body_entered(body: Node3D) -> void:
	var node: Node = body.get_node_or_null(^"%InteractionComponent")
	var actor: InteractionComponent = node as InteractionComponent
	if actor != null:
		_try_deliver(actor.holder)


func _on_orders_reset() -> void:
	_label.text = EMPTY_LABEL


func _on_order_generated(order: ActiveOrder) -> void:
	if order.slot_id == slot_id:
		_label.text = "#%d" % order.id


func _on_order_completed(order: ActiveOrder, _points: int) -> void:
	if order.slot_id != slot_id:
		return
	_label.text = EMPTY_LABEL
	_ok_audio.play()


func _on_order_expired(order: ActiveOrder, _penalty: int) -> void:
	if order.slot_id == slot_id:
		_label.text = EMPTY_LABEL


func _on_delivery_rejected(rejected_slot_id: int, _order_id: int, _penalty: int) -> void:
	if rejected_slot_id == slot_id:
		_error_audio.play()
