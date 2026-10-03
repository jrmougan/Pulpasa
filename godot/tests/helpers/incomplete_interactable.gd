extends Node
## Incumple el contrato `interactable`: tiene `can_interact` pero no `interact`.


func can_interact(_actor: InteractionComponent) -> bool:
	return true
