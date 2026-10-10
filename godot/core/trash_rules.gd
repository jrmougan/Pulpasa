class_name TrashRules
extends RefCounted
## Regla del cubo de basura (D25, ADR-003 §10.3): qué se puede tirar. Solo `Node` + grupo, sin tipos
## de mundo (ADR-003 §0).

const GROUP_PICKABLE: StringName = &"pickable"


## `true` si `item` es algo que se lleva en la mano (caja, pulpo, cachelos) y sigue vivo.
static func can_trash(item: Node) -> bool:
	if item == null or not is_instance_valid(item) or item.is_queued_for_deletion():
		return false
	return item.is_in_group(GROUP_PICKABLE)
