extends Node3D
## Raíz del sandbox del jugador: arranca una ronda como lo hará `level.gd`, para que el
## jugador reciba `round_started` y se mueva. Mientras no existan InteractionDetector ni
## InteractionComponent (fase 5), `p1_interact` coge o suelta `pickable` para probar la mano.

@export var round_config: RoundConfig
@export var order_catalog: OrderCatalog
@export var holder: Holder
@export var pickable: Node

var _input: PlayerInput = PlayerInput.new(1)


func _ready() -> void:
	OrderService.setup(order_catalog)
	var slot_ids: Array[int] = []
	RoundManager.start_round(round_config, slot_ids)


func _physics_process(_delta: float) -> void:
	if holder == null or not _input.is_interact_just_pressed():
		return
	if holder.get_held_item() != null:
		holder.drop()
	else:
		holder.pick_up(pickable)
