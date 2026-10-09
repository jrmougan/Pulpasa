class_name SeasoningDispenser
extends StaticBody3D
## Dispensador fijo de un condimento en la estación al paso (D23, ADR-003 §8; scene-tree.md §3).
## Con una caja en la mano y desde el lado de condimentar, alterna su condimento en esa caja
## (`Box.toggle_seasoning`; con `paprika_swap`, intercambia el pimentón). La caja no se suelta. Con
## la mano vacía o con cualquier otra cosa no es objetivo. Siempre consume la pulsación: al
## rechazar (p. ej. caja a medio cortar) emite `rejected` sin cambiar nada (ADR-003 §8.2).
##
## Antirrebote: tras un cambio, otra pulsación antes de `toggle_guard` s se consume en silencio.
## El reloj es inyectable (`clock`) para probarlo sin esperar.

## Pulsación consumida sin cambios (signals.md §4). No se emite por el antirrebote.
signal rejected(reason: SeasoningRules.Rejection)

@export var seasoning: SeasoningData
@export var station: SeasoningStation

## Segundos actuales; por defecto, el reloj monotónico del motor.
var clock: Callable = SeasoningDispenser.engine_seconds

var _last_change: float = -INF


static func engine_seconds() -> float:
	return Time.get_ticks_usec() / 1_000_000.0


## Solo con una caja en la mano y desde el lado de condimentar (o los dos con
## `operator_side_only` = false). ADR-003 §8.1.
func is_reachable_from(floor_position: Vector2, holder: Holder) -> bool:
	if station == null or not _holds_box(holder):
		return false
	if not station.data.operator_side_only:
		return true
	return station.side_of(floor_position) == StationSide.Side.OPERATOR


## Defensa en profundidad: sin caja en la mano no consume la pulsación.
func can_interact(actor: InteractionComponent) -> bool:
	return actor != null and _holds_box(actor.holder)


func interact(actor: InteractionComponent) -> bool:
	if not can_interact(actor):
		return false
	if station == null or seasoning == null:
		return true
	if clock.call() - _last_change < station.data.toggle_guard:
		return true
	var box: Box = actor.holder.get_held_item() as Box
	var result: SeasoningRules.Rejection = box.toggle_seasoning(
		seasoning, station.data.paprika_swap
	)
	if result == SeasoningRules.Rejection.NONE:
		_last_change = clock.call()
	else:
		rejected.emit(result)
	return true


static func _holds_box(holder: Holder) -> bool:
	return holder != null and holder.get_held_item() is Box
