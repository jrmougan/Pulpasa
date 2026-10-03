class_name PickableContract
extends RefCounted
## Validación común del contrato `pickable` (ADR-003 §4) antes de coger nada (B5).
## Común: solo mira el grupo y los nombres de métodos y propiedades, no tipos de mundo.


## `true` si `item` está en el grupo `pickable` y tiene `on_picked_up`, `on_dropped` e `is_held`.
static func is_valid_pickable(item: Node) -> bool:
	if item == null or not is_instance_valid(item):
		return false
	if not item.is_in_group(InteractionContract.GROUP_PICKABLE):
		return false
	for method: String in InteractionContract.PICKABLE_METHODS:
		if not item.has_method(method):
			return false
	for property: String in InteractionContract.PICKABLE_PROPERTIES:
		if not property in item:
			return false
	return true
