class_name OrderCatalog
extends Resource
## Catálogo de comandas que reparte `OrderBoard` (sustituye a Resources.LoadAll).

@export var orders: Array[OrderData] = []
@export var max_active_orders: int = 4
