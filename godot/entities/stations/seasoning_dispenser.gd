class_name SeasoningDispenser
extends StaticBody3D
## Dispensador fijo de un condimento en la estación (D18, ADR-003 §8; scene-tree.md §3). Con la
## mano vacía y desde el lado de condimentar, alterna su condimento en la caja de la bandeja
## (`Box.toggle_seasoning`; con `paprika_swap`, intercambia el pimentón). Siempre consume la
## pulsación: al rechazar emite `rejected` sin cambiar nada (ADR-003 §8.2).
##
## Antirrebote: tras un cambio, otra pulsación antes de `toggle_guard` s se consume en silencio.
## El reloj es inyectable (`clock`) para probarlo sin esperar.

## Pulsación consumida sin cambios (signals.md §4). No se emite por el antirrebote.
signal rejected(reason: SeasoningRules.Rejection)

## Lado mayor del icono sobre el bote, en m (los SVG de iconos tienen tamaños distintos).
const ICON_SIZE: float = 0.22

@export var seasoning: SeasoningData
@export var station: SeasoningStation

## Segundos actuales; por defecto, el reloj monotónico del motor.
var clock: Callable = SeasoningDispenser.engine_seconds

var _last_change: float = -INF

@onready var _body: MeshInstance3D = get_node_or_null(^"%Body") as MeshInstance3D
@onready var _icon: Sprite3D = get_node_or_null(^"%Icon") as Sprite3D


static func engine_seconds() -> float:
	return Time.get_ticks_usec() / 1_000_000.0


func _ready() -> void:
	if seasoning == null:
		return
	if _body != null:
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = seasoning.color
		_body.material_override = material
	if _icon != null and seasoning.icon != null:
		_icon.texture = seasoning.icon
		var longest: float = maxf(seasoning.icon.get_width(), seasoning.icon.get_height())
		_icon.pixel_size = ICON_SIZE / maxf(longest, 1.0)


## Lado de condimentar (o los dos con `operator_side_only` = false). ADR-003 §8.1.
func is_reachable_from(floor_position: Vector2, _holder: Holder) -> bool:
	if station == null:
		return false
	if not station.data.operator_side_only:
		return true
	return station.side_of(floor_position) == StationSide.Side.OPERATOR


func can_interact(actor: InteractionComponent) -> bool:
	return actor != null and actor.holder != null


func interact(actor: InteractionComponent) -> bool:
	if not can_interact(actor):
		return false
	if station == null or seasoning == null:
		return true
	if clock.call() - _last_change < station.data.toggle_guard:
		return true
	var result: SeasoningRules.Rejection = _toggle(actor.holder)
	if result == SeasoningRules.Rejection.NONE:
		_last_change = clock.call()
	else:
		rejected.emit(result)
	return true


## Alterna el condimento en la caja de la bandeja; `NONE` si cambió algo.
func _toggle(holder: Holder) -> SeasoningRules.Rejection:
	if holder.get_held_item() != null:
		return SeasoningRules.Rejection.HAND_BUSY
	var box: Box = station.get_box()
	if box == null:
		return SeasoningRules.Rejection.NO_BOX
	return box.toggle_seasoning(seasoning, station.data.paprika_swap)
