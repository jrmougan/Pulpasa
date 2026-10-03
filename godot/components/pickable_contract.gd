class_name PickableContract
extends RefCounted
## Validación común del contrato `pickable` (ADR-003 §4) antes de coger nada (B5).
## Común: delega la comprobación de métodos y propiedades en `InteractionContract`.


## `true` si `item` está en el grupo `pickable` y tiene `on_picked_up`, `on_dropped` e `is_held`.
static func is_valid_pickable(item: Node) -> bool:
	if item == null or not is_instance_valid(item):
		return false
	if not item.is_in_group(InteractionContract.GROUP_PICKABLE):
		return false
	return InteractionContract.pickable_violations(item).is_empty()
