class_name TrashBin
extends StaticBody3D
## Cubo de basura (D25, ADR-003 §10.3; scene-tree.md §3). Solo es objetivo con algo en la mano
## (`TrashRules.can_trash`), sin regla de lado. Pulsar interactuar vacía la mano con
## `Holder.drop()`, emite `trashed` y libera el objeto. No suma ni resta recaudación.

## Una vez por tirada, tras vaciar la mano y antes de `queue_free` (signals.md §4).
signal trashed(item: Node)

const DEFAULT_DATA: TrashBinData = preload("res://data/config/trash_bin.tres")
const CUE_TRASH: StringName = &"trash"

@export var data: TrashBinData = DEFAULT_DATA

@onready var _feedback: FeedbackPlayer = get_node_or_null(^"%Feedback") as FeedbackPlayer


func _ready() -> void:
	if data == null:
		data = DEFAULT_DATA
	if data.trash_penalty != 0:
		push_warning("TrashBin: trash_penalty != 0 no se aplica sin enmienda de contrato (D25)")
	if _feedback != null:
		trashed.connect(_on_trashed)


func is_reachable_from(_floor_position: Vector2, holder: Holder) -> bool:
	return holder != null and TrashRules.can_trash(holder.get_held_item())


## A6: tirar lo que se lleva (`ActionRules.for_trash`); con la mano vacía no es objetivo.
func get_action_hint(actor: InteractionComponent) -> ActionHint:
	return _resolve(actor.holder if actor != null else null)


func can_interact(actor: InteractionComponent) -> bool:
	return get_action_hint(actor).is_target()


func interact(actor: InteractionComponent) -> bool:
	var hint: ActionHint = get_action_hint(actor)
	if hint.state != ActionHint.State.OK:
		return false
	var item: Node = actor.holder.drop()
	if item == null:
		return false
	trashed.emit(item)
	item.queue_free()
	return true


## Única resolución de rama de `get_action_hint` e `interact` (ADR-003 §11.2).
func _resolve(holder: Holder) -> ActionHint:
	if holder == null:
		return ActionHint.none()
	var item: Node = holder.get_held_item()
	return ActionRules.for_trash(HeldKind.of(item), TrashRules.can_trash(item))


func _on_trashed(_item: Node) -> void:
	_feedback.play_cue(CUE_TRASH)
