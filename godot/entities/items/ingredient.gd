class_name Ingredient
extends RigidBody3D
## Pulpo (porta Ingredient.cs): crudo, cocido o quemado (M3, lo quema la olla), con una cantidad
## que se gasta al cortarlo sobre una caja. Contrato `pickable` e `interactable` (ADR-003 §4): con
## la mano vacía, interactuar lo coge; con la mano llena no es objetivo (D26).
## Al agotarse se libera solo, tenga o no barra (B9).

## Cada corte, con la cantidad que queda.
signal amount_changed(remaining: float)

## Resto por debajo del cual el ingrediente cuenta como agotado (error de coma flotante).
const EMPTY_EPSILON: float = 0.001

@export var data: IngredientData
## Material del cuerpo en crudo: las mallas que lo usan cambian a `cooked_material` al cocerse.
## Solo si `Model` no trae mallas hermanas por estado (ver `_apply_state_variants`).
@export var raw_material: Material
## Material del cuerpo cuando está cocido (modelo de un solo estado, p. ej. un placeholder).
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


## Quemado en la olla tras `burn_time` (ADR-006 §5): deja de contar como cocido, así que la caja
## lo rechaza al cortar y el cuenco no lo acepta. Muestra la malla `*_burnt` si el modelo la trae.
func set_burnt() -> void:
	state = IngredientData.CookingState.BURNT
	_apply_state_visual()


## Gasta hasta `amount`; devuelve lo gastado. A 0 se libera (B9).
func take(amount: float) -> float:
	if remaining <= EMPTY_EPSILON or amount <= 0.0:
		return 0.0
	var taken: float = minf(amount, remaining)
	remaining -= taken
	amount_changed.emit(remaining)
	_update_bar()
	if remaining <= EMPTY_EPSILON:
		remaining = 0.0
		queue_free()
	return taken


## Qué haría la pulsación (ADR-003 §11.2): coger con la mano vacía (`A4`); con la mano llena no es
## objetivo.
func get_action_hint(actor: InteractionComponent) -> ActionHint:
	return _resolve(actor.holder if actor != null else null)


func can_interact(actor: InteractionComponent) -> bool:
	return get_action_hint(actor).is_target()


func interact(actor: InteractionComponent) -> bool:
	var hint: ActionHint = get_action_hint(actor)
	if hint.state != ActionHint.State.OK:
		return false
	return Slot.pick_up_item(actor, self)


func on_picked_up(_holder: Holder) -> void:
	is_held = true


func on_dropped() -> void:
	is_held = false


## Única resolución de rama de `get_action_hint` e `interact` (ADR-003 §11.2).
func _resolve(holder: Holder) -> ActionHint:
	if holder == null or is_held:
		return ActionHint.none()
	var can_hold: bool = holder.get_held_item() == null and holder.can_hold(self)
	return ActionRules.for_loose_item(HeldKind.of(holder.get_held_item()), can_hold)


func _update_bar() -> void:
	if not is_instance_valid(_amount_bar) or data == null:
		return
	_amount_bar.visible = remaining > 0.0 and remaining < data.total_capacity
	_amount_bar.set_progress(remaining / data.total_capacity)


func _apply_state_visual() -> void:
	if _model == null or _apply_state_variants():
		return
	if raw_material == null or cooked_material == null or not is_cooked():
		return
	for node: Node in _model.find_children("*", "MeshInstance3D"):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh.material_override == raw_material:
			mesh.material_override = cooked_material


## Modelo con una malla por estado (art-bible §2.4: `<asset>_raw`, `<asset>_cooked` y, si existe,
## `<asset>_burnt` bajo `Model`): solo se ve la del estado actual; quemado sin malla propia usa la
## de cocido. Devuelve false si el modelo no trae a la vez `_raw` y `_cooked`.
func _apply_state_variants() -> bool:
	var raw: Array[Node] = _model.find_children("*_raw", "Node3D")
	var cooked: Array[Node] = _model.find_children("*_cooked", "Node3D")
	if raw.is_empty() or cooked.is_empty():
		return false
	var burnt: Array[Node] = _model.find_children("*_burnt", "Node3D")
	var shown: Array[Node] = raw
	if state == IngredientData.CookingState.COOKED:
		shown = cooked
	elif state == IngredientData.CookingState.BURNT:
		shown = cooked if burnt.is_empty() else burnt
	for node: Node in raw + cooked + burnt:
		(node as Node3D).visible = shown.has(node)
	return true
