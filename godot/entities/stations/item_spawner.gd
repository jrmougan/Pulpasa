class_name ItemSpawner
extends Node
## Spawner genérico (ADR-003 §6): con la mano vacía, instancia `scene` directamente en la mano del
## actor. Sustituye a OctopusSpawner (nevera) y al modo spawner de Box (estantería de cajas).
## Con la mano llena no es objetivo (D26: ya no consume la pulsación en silencio). Contrato
## `interactable` (ADR-003 §4); va en la raíz de un cuerpo.

## Objeto que se genera (cogible).
@export var scene: PackedScene
## Datos opcionales que se asignan a la propiedad `data` del objeto antes de que entre al árbol
## (p. ej. la `BoxData` S/M/L). `null` deja los de la escena.
@export var data: Resource


## A1–A3: coger de la nevera, la cachelera o el rack con la mano vacía (`ActionRules.for_spawner`).
func get_action_hint(actor: InteractionComponent) -> ActionHint:
	return _resolve(actor.holder if actor != null else null)


func can_interact(actor: InteractionComponent) -> bool:
	return get_action_hint(actor).is_target()


func interact(actor: InteractionComponent) -> bool:
	var hint: ActionHint = get_action_hint(actor)
	if hint.state != ActionHint.State.OK:
		return false
	_spawn_into(actor.holder)
	return true


## Única resolución de rama de `get_action_hint` e `interact` (ADR-003 §11.2).
func _resolve(holder: Holder) -> ActionHint:
	if holder == null or scene == null:
		return ActionHint.none()
	return ActionRules.for_spawner(HeldKind.of(holder.get_held_item()))


func _spawn_into(holder: Holder) -> void:
	var item: Node = scene.instantiate()
	if data != null and &"data" in item:
		item.set(&"data", data)
	if not holder.pick_up(item):
		item.free()
