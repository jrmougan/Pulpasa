class_name Ingredient
extends RigidBody3D
## Pulpo (porta Ingredient.cs): crudo o cocido, con una cantidad que se gasta al cortarlo sobre una
## caja. Contrato `pickable` e `interactable` (ADR-003 §4): con la mano vacía, interactuar lo coge.
## Al agotarse se libera solo, tenga o no barra (B9).

## Cada corte, con la cantidad que queda.
signal amount_changed(remaining: float)

@export var data: IngredientData
## Material del cuerpo en crudo: las mallas que lo usan cambian a `cooked_material` al cocerse.
@export var raw_material: Material
## Material del cuerpo cuando está cocido (el modelo es el placeholder crudo).
@export var cooked_material: Material

var is_held: bool = false
var state: IngredientData.CookingState = IngredientData.CookingState.RAW
var remaining: float = 0.0

@onready var _amount_bar: WorldProgressBar = get_node_or_null(^"%AmountBar") as WorldProgressBar
@onready var _model: Node3D = $Model


func _ready() -> void:
	remaining = data.total_capacity if data != null else 0.0
	if _amount_bar != null:
		_amount_bar.visible = false
	_apply_state_visual()


func is_cooked() -> bool:
	return state == IngredientData.CookingState.COOKED


func set_cooked() -> void:
	state = IngredientData.CookingState.COOKED
	_apply_state_visual()


## Gasta hasta `amount`; devuelve lo gastado. A 0 se libera (B9).
func take(amount: float) -> float:
	if remaining <= 0.0 or amount <= 0.0:
		return 0.0
	var taken: float = minf(amount, remaining)
	remaining -= taken
	amount_changed.emit(remaining)
	_update_bar()
	if remaining <= 0.0:
		remaining = 0.0
		queue_free()
	return taken


func can_interact(actor: InteractionComponent) -> bool:
	return not is_held and actor != null and actor.holder != null and actor.holder.can_hold(self)


func interact(actor: InteractionComponent) -> bool:
	return can_interact(actor) and actor.holder.pick_up(self)


func on_picked_up(_holder: Holder) -> void:
	is_held = true


func on_dropped() -> void:
	is_held = false


func _update_bar() -> void:
	if not is_instance_valid(_amount_bar) or data == null:
		return
	_amount_bar.visible = remaining > 0.0 and remaining < data.total_capacity
	_amount_bar.set_progress(remaining / data.total_capacity)


func _apply_state_visual() -> void:
	if _model == null or raw_material == null or cooked_material == null or not is_cooked():
		return
	for node: Node in _model.find_children("*", "MeshInstance3D"):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh.material_override == raw_material:
			mesh.material_override = cooked_material
