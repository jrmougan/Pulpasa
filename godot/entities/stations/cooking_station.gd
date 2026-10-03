class_name CookingStation
extends StaticBody3D
## Olla (porta KitchenStation + KitchenProgress). Contrato `interactable` y marca `kitchen`
## (ADR-003 §4). Acepta un pulpo crudo cocinable de la mano, lo deja en `%AnchorPoint`, lo cuece
## en `IngredientData.cook_time` con `%CookBar` y `%BoilAudio`, y lo devuelve cocido a una mano
## vacía. Capacidad 1; sin quemado (M1).
##
## Un solo reloj: se acumula en `_physics_process`, así que la pausa del árbol lo congela (sin el
## doble temporizador del prototipo). El aspecto cocido lo pone `Ingredient.set_cooked()` (material
## en datos, no el color literal de Kitchen.cs:60-63). Con cualquier otra cosa en la mano consume
## la pulsación sin efecto, como el prototipo: no se suelta delante de la olla.

## Al aceptar un pulpo crudo.
signal cooking_started(ingredient: Ingredient)
## Al cumplirse `cook_time` de su `IngredientData`.
signal cooking_finished(ingredient: Ingredient)

## Tolerancia de coma flotante al acumular `delta` (50 × 0,1 ≠ 5,0 exacto).
const TIME_EPSILON: float = 0.0001

var _ingredient: Ingredient
var _cooking: bool = false
var _elapsed: float = 0.0
var _cook_time: float = 0.0
var _saved_layer: int = 0
var _saved_freeze: bool = false

@onready var _anchor: Node3D = %AnchorPoint
@onready var _bar: WorldProgressBar = %CookBar
@onready var _boil_audio: AudioStreamPlayer3D = %BoilAudio


func _ready() -> void:
	_bar.visible = false


func _physics_process(delta: float) -> void:
	if not _cooking:
		return
	if get_ingredient() == null:
		_stop_cooking()
		return
	_elapsed += delta
	_bar.set_progress(_elapsed / _cook_time if _cook_time > 0.0 else 1.0)
	if _elapsed >= _cook_time - TIME_EPSILON:
		_finish()


func is_cooking() -> bool:
	return _cooking and get_ingredient() != null


## Pulpo de la olla (crudo o ya cocido), o `null`; también si se liberó.
func get_ingredient() -> Ingredient:
	if not is_instance_valid(_ingredient) or _ingredient.is_queued_for_deletion():
		_ingredient = null
	elif _ingredient.get_parent() != _anchor:
		_ingredient = null
	return _ingredient


func can_interact(actor: InteractionComponent) -> bool:
	var holder: Holder = actor.holder if actor != null else null
	if holder == null:
		return false
	if holder.get_held_item() != null:
		return true
	var ingredient: Ingredient = get_ingredient()
	return ingredient != null and not is_cooking() and holder.can_hold(ingredient)


func interact(actor: InteractionComponent) -> bool:
	if not can_interact(actor):
		return false
	var holder: Holder = actor.holder
	var held: Node = holder.get_held_item()
	if held == null:
		return _give(holder)
	if get_ingredient() == null and held is Ingredient and _accepts(held as Ingredient):
		_start(holder)
	return true


func _accepts(ingredient: Ingredient) -> bool:
	var ingredient_data: IngredientData = ingredient.data
	return (
		not ingredient.is_cooked()
		and ingredient_data != null
		and ingredient_data.is_cookable
		and ingredient_data.type == IngredientData.IngredientType.OCTOPUS
	)


func _start(holder: Holder) -> void:
	var ingredient: Ingredient = holder.drop() as Ingredient
	if ingredient == null:
		return
	_store(ingredient)
	_cook_time = ingredient.data.cook_time
	_elapsed = 0.0
	_cooking = true
	_bar.set_progress(0.0)
	_bar.visible = true
	_boil_audio.play()
	cooking_started.emit(ingredient)


func _finish() -> void:
	var ingredient: Ingredient = _ingredient
	_stop_cooking()
	ingredient.set_cooked()
	cooking_finished.emit(ingredient)


func _stop_cooking() -> void:
	_cooking = false
	_bar.visible = false
	_boil_audio.stop()


## Devuelve el pulpo cocido a la mano; si la mano lo rechaza, sigue en la olla.
func _give(holder: Holder) -> bool:
	var ingredient: Ingredient = get_ingredient()
	_restore(ingredient)
	if holder.pick_up(ingredient):
		_ingredient = null
		return true
	_store(ingredient)
	return false


## Deja el pulpo en `%AnchorPoint`, congelado y fuera de la capa `interactable` (el detector ve
## la olla), como `Slot`.
func _store(ingredient: Ingredient) -> void:
	_ingredient = ingredient
	if ingredient.get_parent() != _anchor:
		ingredient.reparent(_anchor, false)
	ingredient.transform = _anchor_offset(ingredient).affine_inverse()
	_saved_layer = ingredient.collision_layer
	ingredient.collision_layer = 0
	_saved_freeze = ingredient.freeze
	ingredient.linear_velocity = Vector3.ZERO
	ingredient.angular_velocity = Vector3.ZERO
	ingredient.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	ingredient.freeze = true


func _restore(ingredient: Ingredient) -> void:
	ingredient.collision_layer = _saved_layer
	ingredient.freeze = _saved_freeze


## Transformación del `%AnchorPoint` del pulpo respecto a su raíz (identidad si no tiene).
func _anchor_offset(ingredient: Ingredient) -> Transform3D:
	var anchor_point: Node3D = ingredient.get_node_or_null(^"%AnchorPoint") as Node3D
	return anchor_point.transform if anchor_point != null else Transform3D.IDENTITY
