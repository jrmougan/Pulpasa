extends Node
## Incumple el contrato `pickable`: solo `on_picked_up`, sin `on_dropped` ni `is_held`.

var picked_up_called: bool = false


func on_picked_up(_holder: Holder) -> void:
	picked_up_called = true
