class_name FakeDetector
extends Node
## Doble del detector: las señales `target_changed` y `hint_changed` y `get_hint()` (signals.md §4).

signal target_changed(previous: Node, current: Node)
signal hint_changed(target: Node, hint: ActionHint)

var hint: ActionHint = ActionHint.none()


func get_hint() -> ActionHint:
	return hint
