class_name CookingStation
extends StaticBody3D
## Olla (porta KitchenStation + KitchenProgress). Contrato `interactable` y marca `kitchen`
## (ADR-003 §4). Acepta ingredientes crudos cocinables (pulpo, cachelos) de la mano, los deja en
## sus `AnchorPoint`, los cuece en `IngredientData.cook_time` con su `CookBar` y `%BoilAudio`,
## y los devuelve cocidos a una mano vacía por orden de finalización.
## Capacidad según `capacity`. Sin quemado (M1).
##
## Un solo reloj general o uno por plaza: se acumulan en `_physics_process`, así que la pausa
## del árbol los congela (sin el doble temporizador del prototipo). El aspecto cocido lo pone
## `Ingredient.set_cooked()`. Con cualquier otra cosa en la mano consume la pulsación sin efecto.

## Al aceptar un ingrediente crudo.
signal cooking_started(ingredient: Ingredient)
## Al cumplirse `cook_time` de su `IngredientData`.
signal cooking_finished(ingredient: Ingredient)

## Tolerancia de coma flotante al acumular `delta` (50 × 0,1 ≠ 5,0 exacto).
const TIME_EPSILON: float = 0.0001

@export var capacity: int = 2


class SlotData:
	extends RefCounted
	var ingredient: Ingredient
	var cooking: bool = false
	var elapsed: float = 0.0
	var cook_time: float = 0.0
	var saved_layer: int = 0
	var saved_freeze: bool = false
	var anchor: Node3D
	var bar: WorldProgressBar

	func get_ingredient() -> Ingredient:
		if not is_instance_valid(ingredient) or ingredient.is_queued_for_deletion():
			ingredient = null
		elif ingredient.get_parent() != anchor:
			ingredient = null
		return ingredient


var _slots: Array[SlotData] = []

var _elapsed: float:
	get:
		if _slots.is_empty():
			return 0.0
		return _slots[0].elapsed
	set(value):
		if not _slots.is_empty():
			_slots[0].elapsed = value

@onready var _anchor_base: Node3D = %AnchorPoint
@onready var _bar_base: WorldProgressBar = %CookBar
@onready var _boil_audio: AudioStreamPlayer3D = %BoilAudio


func _ready() -> void:
	_bar_base.visible = false
	var total_width := float(capacity - 1) * 0.3
	var start_x := -total_width / 2.0
	for i in capacity:
		var slot_data := SlotData.new()
		var curr_x := start_x + float(i) * 0.3
		if i == 0:
			slot_data.anchor = _anchor_base
			slot_data.bar = _bar_base
		else:
			slot_data.anchor = _anchor_base.duplicate() as Node3D
			add_child(slot_data.anchor)
			slot_data.bar = _bar_base.duplicate() as WorldProgressBar
			add_child(slot_data.bar)
			slot_data.bar.visible = false

		# set local x assuming cooking station is root
		slot_data.anchor.position.x = curr_x
		slot_data.bar.position.x = curr_x
		_slots.append(slot_data)


func _physics_process(delta: float) -> void:
	for slot: SlotData in _slots:
		if not slot.cooking:
			continue
		if slot.get_ingredient() == null:
			_stop_cooking(slot)
			continue
		slot.elapsed += delta
		slot.bar.set_progress(slot.elapsed / slot.cook_time if slot.cook_time > 0.0 else 1.0)
		if slot.elapsed >= slot.cook_time - TIME_EPSILON:
			_finish(slot)

	if is_cooking():
		if not _boil_audio.playing:
			_boil_audio.play()
	else:
		if _boil_audio.playing:
			_boil_audio.stop()


func is_cooking() -> bool:
	for slot: SlotData in _slots:
		if slot.cooking and slot.get_ingredient() != null:
			return true
	return false


## Devuelve el primer ingrediente que encuentre (para tests y compatibilidad).
func get_ingredient() -> Ingredient:
	for slot: SlotData in _slots:
		var ing: Ingredient = slot.get_ingredient()
		if ing != null:
			return ing
	return null


func can_interact(actor: InteractionComponent) -> bool:
	var holder: Holder = actor.holder if actor != null else null
	if holder == null:
		return false
	var held: Node = holder.get_held_item()
	if held != null:
		return true

	var finished_slot := _get_finished_slot()
	if finished_slot != null and holder.can_hold(finished_slot.get_ingredient()):
		return true
	return false


func interact(actor: InteractionComponent) -> bool:
	if not can_interact(actor):
		return false
	var holder: Holder = actor.holder
	var held: Node = holder.get_held_item()
	if held == null:
		return _give(holder)
	if held is Ingredient and _accepts(held as Ingredient):
		var slot := _get_empty_slot()
		if slot != null:
			_start(holder, slot)
	return true


func _accepts(ingredient: Ingredient) -> bool:
	var data: IngredientData = ingredient.data
	return (
		not ingredient.is_cooked()
		and data != null
		and data.is_cookable
		and (
			data.type == IngredientData.IngredientType.OCTOPUS
			or data.type == IngredientData.IngredientType.CACHELOS
		)
	)


func _get_empty_slot() -> SlotData:
	for slot: SlotData in _slots:
		if slot.get_ingredient() == null and not slot.cooking:
			return slot
	return null


func _get_finished_slot() -> SlotData:
	for slot: SlotData in _slots:
		if slot.get_ingredient() != null and not slot.cooking:
			return slot
	return null


func _start(holder: Holder, slot: SlotData) -> void:
	var ingredient: Ingredient = holder.drop() as Ingredient
	if ingredient == null:
		return
	_store(ingredient, slot)
	slot.cook_time = ingredient.data.cook_time
	slot.elapsed = 0.0
	slot.cooking = true
	slot.bar.set_progress(0.0)
	slot.bar.visible = true
	_boil_audio.play()
	cooking_started.emit(ingredient)


func _finish(slot: SlotData) -> void:
	var ingredient: Ingredient = slot.ingredient
	_stop_cooking(slot)
	ingredient.set_cooked()
	cooking_finished.emit(ingredient)


func _stop_cooking(slot: SlotData) -> void:
	slot.cooking = false
	slot.bar.visible = false


## Devuelve un ingrediente cocido a la mano (el primero que encuentre).
func _give(holder: Holder) -> bool:
	var slot := _get_finished_slot()
	if slot == null:
		return false

	var ingredient: Ingredient = slot.get_ingredient()
	_restore(ingredient, slot)
	if holder.pick_up(ingredient):
		slot.ingredient = null
		return true
	_store(ingredient, slot)
	return false


func _store(ingredient: Ingredient, slot: SlotData) -> void:
	slot.ingredient = ingredient
	if ingredient.get_parent() != slot.anchor:
		ingredient.reparent(slot.anchor, false)
	ingredient.transform = Slot.anchor_offset(ingredient).affine_inverse()
	slot.saved_layer = ingredient.collision_layer
	ingredient.collision_layer = 0
	slot.saved_freeze = ingredient.freeze
	ingredient.linear_velocity = Vector3.ZERO
	ingredient.angular_velocity = Vector3.ZERO
	ingredient.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	ingredient.freeze = true


func _restore(ingredient: Ingredient, slot: SlotData) -> void:
	ingredient.collision_layer = slot.saved_layer
	ingredient.freeze = slot.saved_freeze
