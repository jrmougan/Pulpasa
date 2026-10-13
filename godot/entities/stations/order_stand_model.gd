class_name OrderStandModel
extends Node3D
## Vista del puesto de entrega (PUL-053, art-bible §3.5): nodo `Model` de `order_stand.tscn`. Lee el
## `slot_id` de la `OrderStand` padre y no cambia su estado: enseña el toldillo de su color
## (`awning_1..4` de `order_stand.glb`, puestos 1–4; del 5 en adelante se repiten) y escribe el
## número del puesto en `number_label`, sobre la placa del mostrador. Quien cambie `slot_id`
## después de `_ready` llama a `refresh()`.
## `number_label` es hermano de `Model` (scene-tree.md §3) pero sigue su transform: el `POP` de
## `deliver_ok` escala `Model` y, si el número se quedara quieto, la placa crecería por delante y lo
## taparía (PUL-142).

## Variantes de toldillo del `.glb`.
const AWNING_COUNT: int = 4

## `Label3D` del número de puesto (sobre `Anchor_Number`).
@export var number_label: Label3D

## Transform de `number_label` relativo a `Model` en reposo.
var _number_offset: Transform3D = Transform3D.IDENTITY


## Variante de toldillo (1–4) de un puesto.
static func awning_index(slot_id: int) -> int:
	return posmod(slot_id - 1, AWNING_COUNT) + 1


func _ready() -> void:
	if number_label != null:
		_number_offset = transform.affine_inverse() * number_label.transform
		set_notify_local_transform(true)
	refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED and number_label != null:
		number_label.transform = transform * _number_offset


## Puesto mostrado (para tests): `slot_id` de la `OrderStand` padre, o 1 sin ella.
func get_slot_id() -> int:
	var stand: OrderStand = get_parent() as OrderStand
	return stand.slot_id if stand != null else 1


func refresh() -> void:
	var slot_id: int = get_slot_id()
	var shown: int = awning_index(slot_id)
	for i: int in range(1, AWNING_COUNT + 1):
		var awning: Node3D = find_child("awning_%d" % i, true, false) as Node3D
		if awning != null:
			awning.visible = i == shown
	if number_label != null:
		number_label.text = str(slot_id)
