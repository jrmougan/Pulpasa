class_name SeasoningItem
extends RigidBody3D
## Bote de condimento (porta SeasoningItem.cs). Solo se coge y se suelta: condimentar es cosa de la
## caja (una sola ruta, B6) y el bote no se consume. Contrato `pickable` e `interactable`.

@export var data: SeasoningData

var is_held: bool = false

@onready var _cap: MeshInstance3D = get_node_or_null(^"Model/Cap") as MeshInstance3D


func _ready() -> void:
	if _cap != null and data != null:
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = data.color
		_cap.material_override = material


func can_interact(actor: InteractionComponent) -> bool:
	return not is_held and actor != null and actor.holder != null and actor.holder.can_hold(self)


func interact(actor: InteractionComponent) -> bool:
	return can_interact(actor) and Slot.pick_up_item(actor, self)


func on_picked_up(_holder: Holder) -> void:
	is_held = true


func on_dropped() -> void:
	is_held = false
