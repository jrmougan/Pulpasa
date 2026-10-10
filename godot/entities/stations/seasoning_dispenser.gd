class_name SeasoningDispenser
extends StaticBody3D
## Dispensador fijo de un aliño completo en la estación al paso (D25, ADR-003 §10.2; scene-tree.md
## §3). Con una caja en la mano y desde el lado de condimentar aplica su aliño en esa caja
## (`Box.apply_seasoning`): llena sin aliño lo añade, con el otro aliño lo sustituye, con el
## mismo no
## hace nada (silencio). La caja no se suelta. Con la mano vacía o con cualquier otra cosa no es
## objetivo. Siempre consume la pulsación: caja a medio cortar emite `rejected(BOX_NOT_FULL)`.
## Sin antirrebote: aplicar es idempotente.

## Pulsación consumida sin cambios (signals.md §4). Solo `BOX_NOT_FULL`.
signal rejected(reason: SeasoningRules.Rejection)

@export var seasoning: SeasoningData
@export var station: SeasoningStation

## Gesto visual de sal gorda, aceite y pimentón (>= 0,3 s); `%Gesture` es el pimentón y sus hijos
## `Salt` y `Oil` la sal gorda y el aceite. Opcional en escenas de prueba.
@onready var _gesture: GPUParticles3D = get_node_or_null(^"%Gesture") as GPUParticles3D


func _ready() -> void:
	_tint_paprika()


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
	var box: Box = actor.holder.get_held_item() as Box
	var result: SeasoningRules.Rejection = box.apply_seasoning(seasoning)
	match result:
		SeasoningRules.Rejection.NONE:
			_play_gesture()
		SeasoningRules.Rejection.ALREADY_APPLIED:
			pass
		_:
			rejected.emit(result)
	return true


## Lanza el `%Gesture` (y sal y aceite) desde el principio.
func _play_gesture() -> void:
	if _gesture == null:
		return
	_gesture.restart()
	for child: Node in _gesture.get_children():
		var particles: GPUParticles3D = child as GPUParticles3D
		if particles != null:
			particles.restart()


## El pimentón del gesto sale del color del aliño (dulce rojo, picante oscuro).
func _tint_paprika() -> void:
	if _gesture == null or seasoning == null:
		return
	var mesh: SphereMesh = _gesture.draw_pass_1 as SphereMesh
	if mesh == null or not mesh.material is StandardMaterial3D:
		return
	var paint: StandardMaterial3D = (mesh.material as StandardMaterial3D).duplicate()
	paint.albedo_color = seasoning.color
	_gesture.material_override = paint


static func _holds_box(holder: Holder) -> bool:
	return holder != null and holder.get_held_item() is Box
