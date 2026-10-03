class_name FakeHolder
extends Holder
## Holder de prueba (ADR-003 §0): valida antes de mutar y avisa al objeto por
## `on_picked_up` / `on_dropped`. Registra el orden de las operaciones en `log`.

var log: Array[String] = []
var _held: Node


func get_held_item() -> Node:
	return _held


func can_hold(item: Node) -> bool:
	return _held == null and item != null and item.has_method("on_picked_up")


func pick_up(item: Node) -> bool:
	log.append("validate")
	if not can_hold(item):
		return false
	log.append("mutate")
	_held = item
	item.call("on_picked_up", self)
	item_picked_up.emit(item)
	return true


func drop() -> Node:
	if _held == null:
		return null
	log.append("mutate")
	var item: Node = _held
	_held = null
	item.call("on_dropped")
	item_dropped.emit(item)
	return item
