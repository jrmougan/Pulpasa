extends Node3D
## Raíz del sandbox del jugador: arranca una ronda como lo hará `level.gd`, para que el
## jugador reciba `round_started` y se mueva. Coger, soltar y dejar en slots lo hacen
## `InteractionDetector` + `InteractionComponent` del jugador.

@export var round_config: RoundConfig
@export var order_catalog: OrderCatalog


func _ready() -> void:
	OrderService.setup(order_catalog)
	var slot_ids: Array[int] = []
	RoundManager.start_round(round_config, slot_ids)
