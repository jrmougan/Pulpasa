class_name OrderStandModel
extends Node3D
## Vista del puesto de entrega (PUL-053, art-bible §3.5): nodo `Model` de `order_stand.tscn`. Lee el
## `slot_id` de la `OrderStand` padre y no cambia su estado: enseña el toldillo de su color
## (`awning_1..4` de `order_stand.glb`, puestos 1–4; del 5 en adelante se repiten) y escribe el
## número del puesto en `number_label`, sobre la placa del mostrador. Quien cambie `slot_id`
## después de `_ready` llama a `refresh()`.

## Variantes de toldillo del `.glb`.
const AWNING_COUNT: int = 4

## `Label3D` del número de puesto (sobre `Anchor_Number`).
@export var number_label: Label3D


## Variante de toldillo (1–4) de un puesto.
static func awning_index(slot_id: int) -> int:
	return posmod(slot_id - 1, AWNING_COUNT) + 1


func _ready() -> void:
	refresh()


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
