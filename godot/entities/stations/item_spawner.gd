class_name ItemSpawner
extends Node
## Spawner genérico (ADR-003 §6): con la mano vacía, instancia `scene` directamente en la mano del
## actor. Sustituye a OctopusSpawner (nevera) y al modo spawner de Box (estantería de cajas).
## Con la mano llena consume la pulsación sin hacer nada, como `OctopusSpawner.Interact`: así no
## se suelta lo que se lleva. Contrato `interactable` (ADR-003 §4); va en la raíz de un cuerpo.

## Objeto que se genera (cogible).
@export var scene: PackedScene
## Datos opcionales que se asignan a la propiedad `data` del objeto antes de que entre al árbol
## (p. ej. la `BoxData` S/M/L). `null` deja los de la escena.
@export var data: Resource


func can_interact(actor: InteractionComponent) -> bool:
	return scene != null and actor != null and actor.holder != null


func interact(actor: InteractionComponent) -> bool:
	if not can_interact(actor):
		return false
	if actor.holder.get_held_item() == null:
		_spawn_into(actor.holder)
	return true


func _spawn_into(holder: Holder) -> void:
	var item: Node = scene.instantiate()
	if data != null and &"data" in item:
		item.set(&"data", data)
	if not holder.pick_up(item):
		item.free()
