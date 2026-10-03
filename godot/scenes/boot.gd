extends Node3D
## Escena provisional de arranque: valida motor, MCP y capturas.
## Se sustituirá por main_menu.tscn en la fase 7 de M0.


func _ready() -> void:
	print("Pulpasa boot OK — Godot ", Engine.get_version_info().string)
