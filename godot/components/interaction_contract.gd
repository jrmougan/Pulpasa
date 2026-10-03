class_name InteractionContract
extends RefCounted
## Comprobaciones del contrato de interacción (ADR-003 §4): grupo + métodos con firma fija.
## Común: solo mira nombres de grupos y de métodos, no tipos de mundo.

const GROUP_INTERACTABLE: StringName = &"interactable"
const GROUP_PICKABLE: StringName = &"pickable"

const INTERACTABLE_METHODS: PackedStringArray = ["can_interact", "interact"]
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
