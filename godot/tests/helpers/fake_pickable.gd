class_name FakePickable
extends Node
## Doble del contrato `pickable` (ADR-003 §4).

var is_held: bool = false
var holder: Holder


func on_picked_up(new_holder: Holder) -> void:
	is_held = true
	holder = new_holder


func on_dropped() -> void:
	is_held = false
	holder = null
