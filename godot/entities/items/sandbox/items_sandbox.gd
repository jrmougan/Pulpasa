extends Node3D
## Sandbox de PUL-016: pulpo ya cocido (aún no hay cocina), una mesa con una caja pequeña y dos
## condimentos en el suelo. Arranca una ronda como `level.gd` para que el jugador se mueva.
##
## Una sola ruta de input: `InteractionComponent._unhandled_input`. El `simulate_input` del MCP no
## genera `_unhandled_input`, así que para capturas se activa `mcp_bridge` en caliente (p. ej. con
## `run_script`), que reenvía `p1_interact` sondeado; está apagado por defecto para que con
## teclado una pulsación sea un corte.

@export var round_config: RoundConfig
@export var order_catalog: OrderCatalog
@export var cooked_octopus: Ingredient
@export var interaction: InteractionComponent
@export var mcp_bridge: bool = false


func _ready() -> void:
	OrderService.setup(order_catalog)
	var slot_ids: Array[int] = []
	RoundManager.start_round(round_config, slot_ids)
	if cooked_octopus != null:
		cooked_octopus.set_cooked()


func _process(_delta: float) -> void:
	if mcp_bridge and interaction != null and Input.is_action_just_pressed(&"p1_interact"):
		interaction.interact_pressed()
