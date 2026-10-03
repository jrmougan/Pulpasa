class_name ActiveOrder
extends RefCounted
## Comanda viva en un puesto (porta ActiveOrder). Tipo de valor: `OrderBoard` solo entrega copias.

var id: int = 0
var data: OrderData
var slot_id: int = -1
## Paciencia total (de `OrderData`); 0 = sin paciencia (todo M0).
var max_time: float = 0.0
var time_left: float = 0.0


func _init(
	p_id: int = 0, p_data: OrderData = null, p_slot_id: int = -1, p_max_time: float = 0.0
) -> void:
	id = p_id
	data = p_data
	slot_id = p_slot_id
	max_time = p_max_time
	time_left = p_max_time


## Copia independiente (los `Resource` de `data` se comparten: son de solo lectura).
func copy() -> ActiveOrder:
	var other: ActiveOrder = ActiveOrder.new(id, data, slot_id, max_time)
	other.time_left = time_left
	return other
