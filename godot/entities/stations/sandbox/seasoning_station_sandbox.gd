extends Node3D
## Sandbox de PUL-058/097: la estación de condimentos al paso con un jugador en el lado de
## condimentar. Arranca una ronda como `level.gd` para que el jugador se mueva y prepara la escena
## por las rutas reales de interacción: un cachelo cocido en el cuenco (2 raciones) y una caja llena
## en la mano del jugador, con picante, sal y aceite.
##
## `mcp_bridge` reenvía `p1_interact` sondeado (el `simulate_input` del MCP no genera
## `_unhandled_input`); apagado por defecto, como en `stations_sandbox.gd`.

@export var round_config: RoundConfig
@export var order_catalog: OrderCatalog
@export var station: SeasoningStation
@export var player: Player
@export var items_root: Node3D
@export var box_scene: PackedScene
@export var box_data: BoxData
@export var cachelos_scene: PackedScene
## Dispensadores que se pulsan al preparar la caja (rutas dentro de `station`).
@export var staged_dispensers: Array[NodePath] = []
## Cachelos cocidos que se echan al cuenco al preparar (2 raciones cada uno).
@export var staged_cachelos: int = 1
@export var mcp_bridge: bool = false

var _actor: InteractionComponent


func _ready() -> void:
	OrderService.setup(order_catalog)
	var slot_ids: Array[int] = []
	RoundManager.start_round(round_config, slot_ids)
	_actor = player.get_node(^"%InteractionComponent") as InteractionComponent
	_stage()


func _process(_delta: float) -> void:
	if mcp_bridge and _actor != null and Input.is_action_just_pressed(&"p1_interact"):
		_actor.interact_pressed()


func _stage() -> void:
	var bowl: CachelosBowl = station.get_node(^"CachelosBowl") as CachelosBowl
	for _item: int in staged_cachelos:
		var cachelos: Ingredient = cachelos_scene.instantiate() as Ingredient
		items_root.add_child(cachelos)
		cachelos.set_cooked()
		_actor.holder.pick_up(cachelos)
		bowl.interact(_actor)
	var box: Box = box_scene.instantiate() as Box
	box.data = box_data
	items_root.add_child(box)
	box.fill = 1.0
	_actor.holder.pick_up(box)
	for path: NodePath in staged_dispensers:
		var dispenser: SeasoningDispenser = station.get_node(path) as SeasoningDispenser
		dispenser.interact(_actor)
