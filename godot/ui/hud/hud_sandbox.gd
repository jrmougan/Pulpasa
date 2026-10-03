extends Control
## Composición de prueba: los componentes de UI nunca arrancan la ronda.

const CATALOG: OrderCatalog = preload("res://data/orders/order_catalog.tres")
const CONFIG: RoundConfig = preload("res://data/config/round_config.tres")


func _ready() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20
	OrderService.setup(CATALOG, rng)
	RoundManager.start_round(CONFIG, [1, 2, 3, 4] as Array[int])
