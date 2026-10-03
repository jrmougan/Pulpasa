class_name FakeInteractable
extends Node
## Doble del contrato `interactable` (ADR-003 §4). Cuenta las llamadas a `interact`.

var accepts: bool = true
var consumes: bool = true
var interact_count: int = 0
var last_actor: InteractionComponent


func can_interact(_actor: InteractionComponent) -> bool:
	return accepts


func interact(actor: InteractionComponent) -> bool:
	interact_count += 1
	last_actor = actor
	return consumes
