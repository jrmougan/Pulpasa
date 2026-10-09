class_name CachelosBowl
extends StaticBody3D
## Cuenco de cachelos de la estación al paso (D10, D23; scene-tree.md §3). Guarda raciones
## (`stock`, máximo `cachelos_stock_max`). Con cachelos cocidos en la mano, desde cualquier lado, se
## echan (+`cachelos_portions_per_item`, recortado al máximo; con el cuenco lleno se rechaza). Con
## una caja en la mano y desde el lado de condimentar, alterna cachelos en esa caja (poner gasta 1
## ración, quitar la devuelve; la caja no se suelta). Con la mano vacía o cualquier otra cosa no es
## objetivo. Siempre consume la pulsación: al rechazar emite `rejected` sin cambiar nada
## (ADR-003 §8.2). Al alternar tiene el mismo antirrebote que un dispensador (`toggle_guard`,
## reloj inyectable). Quitar con el cuenco lleno se rechaza (`BOWL_FULL`).
## El modelo trae `Portions0..4` (estados exclusivos): solo se ve el de `stock`.

## Pulsación consumida sin cambios (signals.md §4).
signal rejected(reason: SeasoningRules.Rejection)
## Raciones nuevas; también una vez en `_ready()`.
signal stock_changed(stock: int)

## Estados de raciones del modelo: `Portions0..4`.
const PORTION_STATES: int = 5
const DEFAULT_SEASONING: SeasoningData = preload("res://data/seasonings/cachelos.tres")

@export var seasoning: SeasoningData = DEFAULT_SEASONING
@export var station: SeasoningStation

## Raciones en el cuenco (0..`cachelos_stock_max`).
var stock: int = 0
## Segundos actuales; por defecto, el reloj monotónico del motor.
var clock: Callable = SeasoningDispenser.engine_seconds

var _last_change: float = -INF

## Estados del modelo (`Portions0` = fondo vacío … `Portions4`), uno visible a la vez.
@onready var _portions: Array[Node3D] = _find_portions()


func _ready() -> void:
	var config: SeasoningStationData = _data()
	_set_stock(clampi(config.cachelos_initial_stock, 0, config.cachelos_stock_max))


## Con cachelos cocidos, desde cualquier lado; con una caja, solo desde el lado de condimentar
## (o los dos con `operator_side_only` = false). Con la mano vacía u otra cosa, no es objetivo.
func is_reachable_from(floor_position: Vector2, holder: Holder) -> bool:
	if station == null or holder == null:
		return false
	var held: Node = holder.get_held_item()
	if _is_cooked_cachelos(held as Ingredient):
		return true
	if not held is Box:
		return false
	if not station.data.operator_side_only:
		return true
	return station.side_of(floor_position) == StationSide.Side.OPERATOR


func can_interact(actor: InteractionComponent) -> bool:
	if actor == null or actor.holder == null:
		return false
	var held: Node = actor.holder.get_held_item()
	return held is Box or _is_cooked_cachelos(held as Ingredient)


func interact(actor: InteractionComponent) -> bool:
	if not can_interact(actor):
		return false
	var held: Node = actor.holder.get_held_item()
	if held is Box:
		_toggle(held as Box)
	else:
		_restock(actor.holder)
	return true


func _restock(holder: Holder) -> void:
	var config: SeasoningStationData = _data()
	if not SeasoningRules.can_restock(stock, config.cachelos_stock_max):
		rejected.emit(SeasoningRules.Rejection.BOWL_FULL)
		return
	var dropped: Node = holder.drop()
	if dropped != null:
		dropped.queue_free()
	_set_stock(
		SeasoningRules.restocked(
			stock, config.cachelos_portions_per_item, config.cachelos_stock_max
		)
	)


func _toggle(box: Box) -> void:
	var config: SeasoningStationData = _data()
	if clock.call() - _last_change < config.toggle_guard:
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
	var shown: int = clampi(stock, 0, _portions.size() - 1)
	for index: int in _portions.size():
		_portions[index].visible = index == shown
	stock_changed.emit(stock)


func _find_portions() -> Array[Node3D]:
	var found: Array[Node3D] = []
	for index: int in PORTION_STATES:
		var node: Node3D = find_child("Portions%d" % index, true, false) as Node3D
		if node != null:
			found.append(node)
	return found


func _data() -> SeasoningStationData:
	if station != null and station.data != null:
		return station.data
	return SeasoningStation.DEFAULT_DATA
