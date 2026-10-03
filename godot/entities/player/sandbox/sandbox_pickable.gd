class_name SandboxPickable
extends RigidBody3D
## Objeto mínimo que cumple el contrato `pickable` (ADR-003 §4) para el sandbox del jugador.

var is_held: bool = false
var holder: Holder


func on_picked_up(new_holder: Holder) -> void:
	is_held = true
	holder = new_holder


func on_dropped() -> void:
	is_held = false
	holder = null
