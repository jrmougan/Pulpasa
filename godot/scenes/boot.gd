extends Node
## Entrada alternativa para herramientas que todavía abren boot.tscn.


func _ready() -> void:
	GameState.go_to_main_menu.call_deferred()
