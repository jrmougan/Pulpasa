class_name CachelosBowl
extends StaticBody3D
## Cuenco de cachelos de la estación (D10, D18; scene-tree.md §3). Guarda raciones (`stock`):
## con cachelos cocidos en la mano, desde cualquier lado, se echan (+`cachelos_portions_per_item`);
## con la mano vacía, desde el lado de condimentar, alterna cachelos en la caja de la bandeja
## (poner gasta 1 ración, quitar la devuelve). Siempre consume la pulsación: al rechazar emite
## `rejected` sin cambiar nada (ADR-003 §8.2). Al alternar tiene el mismo antirrebote que un
## dispensador (`toggle_guard`, reloj inyectable). Quitar con el cuenco lleno se rechaza
## (`BOWL_FULL`): el stock nunca pasa de `cachelos_stock_max`.

## Pulsación consumida sin cambios (signals.md §4).
signal rejected(reason: SeasoningRules.Rejection)
## Raciones nuevas; también una vez en `_ready()`.
signal stock_changed(stock: int)

const DEFAULT_SEASONING: SeasoningData = preload("res://data/seasonings/cachelos.tres")

@export var seasoning: SeasoningData = DEFAULT_SEASONING
@export var station: SeasoningStation

## Raciones en el cuenco (0..`cachelos_stock_max`).
var stock: int = 0
## Segundos actuales; por defecto, el reloj monotónico del motor.
var clock: Callable = SeasoningDispenser.engine_seconds

var _last_change: float = -INF

@onready var _portions: Node3D = get_node_or_null(^"%Portions") as Node3D


func _ready() -> void:
	var config: SeasoningStationData = _data()
	_set_stock(clampi(config.cachelos_initial_stock, 0, config.cachelos_stock_max))


## Desde cualquier lado con algo en la mano (reponer); con la mano vacía, como un dispensador.
func is_reachable_from(floor_position: Vector2, holder: Holder) -> bool:
	if station == null:
		return false
	if holder != null and holder.get_held_item() != null:
		return true
	if not station.data.operator_side_only:
		return true
	return station.side_of(floor_position) == StationSide.Side.OPERATOR


func can_interact(actor: InteractionComponent) -> bool:
	return actor != null and actor.holder != null


func interact(actor: InteractionComponent) -> bool:
	if not can_interact(actor):
		return false
	var held: Node = actor.holder.get_held_item()
	if held != null:
		_restock(actor.holder, held)
	else:
		_toggle()
	return true


func _restock(holder: Holder, held: Node) -> void:
	var ingredient: Ingredient = held as Ingredient
	if not _is_cooked_cachelos(ingredient):
		rejected.emit(SeasoningRules.Rejection.NOT_ACCEPTED)
		return
	var config: SeasoningStationData = _data()
	if stock >= config.cachelos_stock_max:
		rejected.emit(SeasoningRules.Rejection.BOWL_FULL)
		return
	var dropped: Node = holder.drop()
	if dropped != null:
		dropped.queue_free()
	_set_stock(mini(stock + config.cachelos_portions_per_item, config.cachelos_stock_max))


func _toggle() -> void:
	var config: SeasoningStationData = _data()
	if clock.call() - _last_change < config.toggle_guard:
		return
	var box: Box = station.get_box() if station != null else null
	if box == null:
		rejected.emit(SeasoningRules.Rejection.NO_BOX)
		return
	if not box.is_full():
		rejected.emit(SeasoningRules.Rejection.BOX_NOT_FULL)
		return
	var removing: bool = box.has_seasoning(seasoning)
	if removing and stock >= config.cachelos_stock_max:
		rejected.emit(SeasoningRules.Rejection.BOWL_FULL)
		return
	if not removing and stock <= 0:
		rejected.emit(SeasoningRules.Rejection.BOWL_EMPTY)
		return
	var result: SeasoningRules.Rejection = box.toggle_seasoning(seasoning, config.paprika_swap)
	if result != SeasoningRules.Rejection.NONE:
		rejected.emit(result)
		return
	_last_change = clock.call()
	_set_stock(stock + 1 if removing else stock - 1)


func _is_cooked_cachelos(ingredient: Ingredient) -> bool:
	return (
		ingredient != null
		and ingredient.is_cooked()
		and ingredient.data != null
		and ingredient.data.as_seasoning != null
		and ingredient.data.as_seasoning.same_as(seasoning)
	)


func _set_stock(value: int) -> void:
	stock = value
	if _portions != null:
		var index: int = 0
		for child: Node in _portions.get_children():
			if child is Node3D:
				(child as Node3D).visible = index < stock
				index += 1
	stock_changed.emit(stock)


func _data() -> SeasoningStationData:
	if station != null and station.data != null:
		return station.data
	return SeasoningStation.DEFAULT_DATA
