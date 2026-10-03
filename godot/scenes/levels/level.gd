extends Node
## Raíz común de los niveles (ADR-003 §2): inyecta el catálogo en `OrderService` y arranca la
## ronda en `RoundManager` con los `slot_id` de los puestos. Sin más lógica. Una sola vez por
## instancia (B10/B11): Reintentar recarga la escena, que crea un nodo nuevo y un tablero nuevo.
##
## Común a 3D y 2D: los puestos son `Node` y de ellos solo se lee `slot_id`.

## Ronda del nivel (duración, umbrales).
@export var round_config: RoundConfig
## Comandas posibles del nivel.
@export var order_catalog: OrderCatalog
## Puestos de entrega (`OrderStand`), en orden de `slot_id`.
@export var stands: Array[Node] = []


func _ready() -> void:
	if round_config == null or order_catalog == null:
		push_error("Level: faltan round_config u order_catalog")
		return
	OrderService.setup(order_catalog)
	RoundManager.start_round(round_config, get_slot_ids())


## `slot_id` de cada puesto, en el orden de `stands`.
func get_slot_ids() -> Array[int]:
	var ids: Array[int] = []
	for stand: Node in stands:
		var slot_id: Variant = stand.get(&"slot_id")
		if slot_id == null:
			push_error("Level: el puesto %s no tiene slot_id" % stand.name)
			continue
		ids.append(slot_id as int)
	return ids
