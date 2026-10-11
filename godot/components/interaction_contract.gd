class_name InteractionContract
extends RefCounted
## Comprobaciones del contrato de interacción (ADR-003 §4): grupo + métodos con firma fija.
## Común: solo mira nombres de grupos y de métodos, no tipos de mundo.

const GROUP_INTERACTABLE: StringName = &"interactable"
const GROUP_PICKABLE: StringName = &"pickable"

## Consulta de acción (ADR-003 §11.2): `get_action_hint(actor: InteractionComponent) ->
## ActionHint`. Opcional hasta la oleada de montaje de D26: el detector tolera su ausencia.
const HINT_METHOD: StringName = &"get_action_hint"
const INTERACTABLE_METHODS: PackedStringArray = ["can_interact", "interact"]
## Métodos opcionales de `interactable` (ADR-003 §8.1): si existen, el detector los consulta.
## `is_reachable_from(floor_position: Vector2, holder: Holder) -> bool`.
const INTERACTABLE_OPTIONAL_METHODS: PackedStringArray = ["is_reachable_from"]
const PICKABLE_METHODS: PackedStringArray = ["on_picked_up", "on_dropped"]
const PICKABLE_PROPERTIES: PackedStringArray = ["is_held"]


## Incumplimientos de `node` respecto a los grupos a los que pertenece; vacío si cumple.
static func violations(node: Node) -> Array[String]:
	var found: Array[String] = []
	if node.is_in_group(GROUP_INTERACTABLE):
		for method: String in INTERACTABLE_METHODS:
			if not node.has_method(method):
				found.append("%s (interactable): falta %s()" % [node.name, method])
	if node.is_in_group(GROUP_PICKABLE):
		found.append_array(pickable_violations(node))
	return found


## Qué haría la pulsación de `actor` sobre `entity` (ADR-003 §11.2-§11.3). Con
## `get_action_hint`, lo que devuelva (`null` cuenta como `NONE`). Equivalencia transitoria para
## entidades sin migrar: `ok(&"")` (objetivo heredado, sin verbo) si `can_interact` es `true`, y
## `none()` si no. No mira el lado (`is_reachable_from` se evalúa antes, por quien llama).
static func hint_of(entity: Node, actor: InteractionComponent) -> ActionHint:
	if entity.has_method(HINT_METHOD):
		var hint: ActionHint = entity.call(HINT_METHOD, actor) as ActionHint
		return hint if hint != null else ActionHint.none()
	if entity.has_method(&"can_interact") and bool(entity.call(&"can_interact", actor)):
		return ActionHint.ok(ActionVerb.NONE)
	return ActionHint.none()


## Incumplimientos de los métodos y propiedades `pickable` de `node`, esté o no en el grupo.
## Única comprobación del contrato `pickable` (la reutiliza `PickableContract`).
static func pickable_violations(node: Node) -> Array[String]:
	var found: Array[String] = []
	for method: String in PICKABLE_METHODS:
		if not node.has_method(method):
			found.append("%s (pickable): falta %s()" % [node.name, method])
	for property: String in PICKABLE_PROPERTIES:
		if not property in node:
			found.append("%s (pickable): falta la propiedad %s" % [node.name, property])
	return found


## Incumplimientos de `root` y todos sus descendientes.
static func scan_tree(root: Node) -> Array[String]:
	var found: Array[String] = violations(root)
	for child: Node in root.get_children():
		found.append_array(scan_tree(child))
	return found
