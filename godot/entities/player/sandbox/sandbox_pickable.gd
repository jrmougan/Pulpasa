class_name SandboxPickable
extends RigidBody3D
## Objeto mínimo del sandbox: cumple los contratos `pickable` e `interactable` (ADR-003 §4).
## Con la mano vacía, interactuar lo coge (como la caja o el pulpo del prototipo).

var is_held: bool = false
var holder: Holder


func can_interact(actor: InteractionComponent) -> bool:
	return not is_held and actor.holder != null and actor.holder.can_hold(self)


func interact(actor: InteractionComponent) -> bool:
	return actor.holder.pick_up(self)


func on_picked_up(new_holder: Holder) -> void:
	is_held = true
	holder = new_holder


func on_dropped() -> void:
	is_held = false
	holder = null
