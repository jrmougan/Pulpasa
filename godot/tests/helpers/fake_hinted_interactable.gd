class_name FakeHintedInteractable
extends FakeInteractable
## Doble del contrato `interactable` con consulta de acción (ADR-003 §11.2). `hint` es lo que
## publica; `interact` lo ejecuta tal cual (cuenta las llamadas) y registra si era `OK`.

var hint: ActionHint = ActionHint.none()
## Veces que `interact` se llamó con un hint `OK` (el efecto "cambió el mundo").
var effect_count: int = 0
var hint_queries: int = 0


func get_action_hint(_actor: InteractionComponent) -> ActionHint:
	hint_queries += 1
	return hint


func can_interact(actor: InteractionComponent) -> bool:
	return get_action_hint(actor).is_target()


func interact(actor: InteractionComponent) -> bool:
	if not hint.is_target():
		return false
	interact_count += 1
	last_actor = actor
	if hint.state == ActionHint.State.OK:
		effect_count += 1
	return true
