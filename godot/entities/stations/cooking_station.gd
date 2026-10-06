class_name CookingStation
extends StaticBody3D
## Olla (porta KitchenStation + KitchenProgress). Contrato `interactable` y marca `kitchen`
## (ADR-003 §4). Acepta ingredientes crudos cocinables (pulpo, cachelos) de la mano, los deja en
## sus `AnchorPoint`, los cuece en `IngredientData.cook_time` con su `CookBar` y `%BoilAudio`,
## y los devuelve cocidos a una mano vacía por orden de finalización (FIFO: el primero
## que terminó sale primero, según `_finish_counter`).
## M3 (ADR-006 §5): un cocido que sigue en la plaza se quema. Tras `cooking_finished` el reloj de la
## plaza sigue: a `warn_time` avisa (`burn_warned`, barra visible vaciándose y parpadeando) y a
## `burn_time` lo quema (`Ingredient.set_burnt()` + `burnt`). Recogerlo a tiempo para el reloj.
## Con la mano vacía se desecha primero el quemado más antiguo (`discarded`, `queue_free`) y, si no
## hay, se da el cocido FIFO; un quemado nunca llega a la mano. `burn_time` = 0: no se quema.
## Vapor (`Model/Steam`) solo con alguna plaza cociendo y fuego (`Model/Fire`) bajo en reposo y
## vivo al cocer; las partículas se congelan con la pausa del árbol.
## Capacidad en datos: `KitchenData.capacity` (inyectado, `data/config/kitchen.tres`).
##
## Un solo reloj general o uno por plaza: se acumulan en `_physics_process`, así que la pausa
## del árbol los congela (sin el doble temporizador del prototipo). El aspecto cocido lo pone
## `Ingredient.set_cooked()`. Con cualquier otra cosa en la mano consume la pulsación sin efecto.

## Al aceptar un ingrediente crudo.
signal cooking_started(ingredient: Ingredient)
## Al cumplirse `cook_time` de su `IngredientData`.
signal cooking_finished(ingredient: Ingredient)
## Una vez por plaza al cumplirse `warn_time` desde `cooking_finished` (M3, ADR-006 §5).
signal burn_warned(ingredient: Ingredient)
## Una vez al cumplirse `burn_time`: el ingrediente ya es `BURNT` (M3, olla-que-se-pasa AC1).
signal burnt(ingredient: Ingredient)
## Al desechar un quemado con la mano vacía, antes de liberarlo; la plaza queda libre (M3).
signal discarded(ingredient: Ingredient)

## Tolerancia de coma flotante al acumular `delta` (50 × 0,1 ≠ 5,0 exacto).
const TIME_EPSILON: float = 0.0001

## Separación horizontal entre plazas ocupadas.
const SLOT_SPACING: float = 0.3

## Parpadeo de la barra en el aviso de quemado: semiperiodo (s de juego) y tinte alterno (casi
## transparente: la barra se enciende y se apaga sin cambiar su color de relleno).
const BLINK_HALF_PERIOD: float = 0.2
const BLINK_COLOR: Color = Color(1.0, 1.0, 1.0, 0.15)

## Fuego del fogón: fracción de partículas en reposo y al cocer.
const FIRE_IDLE_RATIO: float = 0.3
const FIRE_COOKING_RATIO: float = 1.0

@export var data: KitchenData


class SlotData:
	extends RefCounted
	var ingredient: Ingredient
	var cooking: bool = false
	var elapsed: float = 0.0
	var cook_time: float = 0.0
	var saved_layer: int = 0
	var saved_freeze: bool = false
	var finished_at: int = 0
	## Segundos desde `cooking_finished` con el ingrediente aún en la plaza.
	var since_finished: float = 0.0
	var burn_time: float = 0.0
	var warn_time: float = 0.0
	var warned: bool = false
	var burnt: bool = false
	var anchor: Node3D
	var bar: WorldProgressBar

	func get_ingredient() -> Ingredient:
		if not is_instance_valid(ingredient) or ingredient.is_queued_for_deletion():
			ingredient = null
		elif ingredient.get_parent() != anchor:
			ingredient = null
		return ingredient


var _slots: Array[SlotData] = []
## Contador monótono de finalizaciones: define el orden FIFO de devolución.
var _finish_counter: int = 0

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
@onready var _steam: GPUParticles3D = $Model/Steam
@onready var _fire: GPUParticles3D = $Model/Fire
@onready var _feedback: FeedbackPlayer = get_node_or_null(^"%Feedback") as FeedbackPlayer


func _ready() -> void:
	_bar_base.visible = false
	var slot_count: int = data.capacity if data != null else 1
	var total_width := float(slot_count - 1) * SLOT_SPACING
	var start_x := -total_width / 2.0
	for i: int in slot_count:
		var slot_data := SlotData.new()
		var curr_x := start_x + float(i) * SLOT_SPACING
		if i == 0:
			slot_data.anchor = _anchor_base
			slot_data.bar = _bar_base
		else:
			slot_data.anchor = _anchor_base.duplicate() as Node3D
			add_child(slot_data.anchor)
			slot_data.bar = _bar_base.duplicate() as WorldProgressBar
			add_child(slot_data.bar)
			slot_data.bar.visible = false

		# Anclas simétricas y barras apiladas en Y (una por plaza).
		slot_data.anchor.position.x = curr_x
		slot_data.bar.position.y += float(i) * 0.35
		_slots.append(slot_data)
	_update_effects()
	_connect_feedback()


func _physics_process(delta: float) -> void:
	for slot: SlotData in _slots:
		if not slot.cooking:
			_tick_burn(slot, delta)
			continue
		if slot.get_ingredient() == null:
			_stop_cooking(slot)
			_reposition_anchors()
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
	_update_effects()


func is_cooking() -> bool:
	for slot: SlotData in _slots:
		if slot.cooking and slot.get_ingredient() != null:
			return true
	return false


## Hay algún quemado esperando a desecharse.
func has_burnt() -> bool:
	return _get_burnt_slot() != null


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

	if _get_burnt_slot() != null:
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
		return _discard() or _give(holder)
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


## Plaza con el cocido (no quemado) que antes terminó.
func _get_finished_slot() -> SlotData:
	var oldest: SlotData = null
	for slot: SlotData in _slots:
		if slot.get_ingredient() != null and not slot.cooking and not slot.burnt:
			if oldest == null or slot.finished_at < oldest.finished_at:
				oldest = slot
	return oldest


## Plaza con el quemado que antes terminó (el más antiguo).
func _get_burnt_slot() -> SlotData:
	var oldest: SlotData = null
	for slot: SlotData in _slots:
		if slot.burnt and slot.get_ingredient() != null:
			if oldest == null or slot.finished_at < oldest.finished_at:
				oldest = slot
	return oldest


func _start(holder: Holder, slot: SlotData) -> void:
	var ingredient: Ingredient = holder.drop() as Ingredient
	if ingredient == null:
		return
	_store(ingredient, slot)
	slot.cook_time = ingredient.data.cook_time
	slot.burn_time = ingredient.data.burn_time
	slot.warn_time = ingredient.data.warn_time
	slot.elapsed = 0.0
	slot.since_finished = 0.0
	slot.warned = false
	slot.burnt = false
	slot.cooking = true
	slot.bar.set_progress(0.0)
	slot.bar.visible = true
	_reposition_anchors()
	if not _boil_audio.playing:
		_boil_audio.play()
	cooking_started.emit(ingredient)


func _finish(slot: SlotData) -> void:
	var ingredient: Ingredient = slot.ingredient
	_stop_cooking(slot)
	_finish_counter += 1
	slot.finished_at = _finish_counter
	ingredient.set_cooked()
	cooking_finished.emit(ingredient)


func _stop_cooking(slot: SlotData) -> void:
	slot.cooking = false
	slot.bar.visible = false


## Reloj de quemado de una plaza con un cocido (ADR-006 §5). Si el ingrediente ya no está (lo
## recogieron o se liberó), la plaza vuelve a reposo y el reloj se para.
func _tick_burn(slot: SlotData, delta: float) -> void:
	if slot.burnt or slot.burn_time <= 0.0 or slot.ingredient == null:
		return
	var ingredient: Ingredient = slot.get_ingredient()
	if ingredient == null:
		_reset_burn(slot)
		return
	slot.since_finished += delta
	if slot.since_finished >= slot.burn_time - TIME_EPSILON:
		_burn(slot, ingredient)
		return
	if not slot.warned and slot.since_finished >= slot.warn_time - TIME_EPSILON:
		slot.warned = true
		slot.bar.visible = true
		burn_warned.emit(ingredient)
	if slot.warned:
		var window: float = maxf(slot.burn_time - slot.warn_time, TIME_EPSILON)
		slot.bar.set_progress((slot.burn_time - slot.since_finished) / window)
		var phase: int = int((slot.since_finished - slot.warn_time) / BLINK_HALF_PERIOD)
		slot.bar.modulate = BLINK_COLOR if phase % 2 == 0 else Color.WHITE


func _burn(slot: SlotData, ingredient: Ingredient) -> void:
	slot.burnt = true
	slot.bar.visible = false
	slot.bar.modulate = Color.WHITE
	ingredient.set_burnt()
	burnt.emit(ingredient)


func _reset_burn(slot: SlotData) -> void:
	slot.since_finished = 0.0
	slot.warned = false
	slot.burnt = false
	slot.bar.visible = false
	slot.bar.modulate = Color.WHITE


## Desecha el quemado más antiguo: emite `discarded`, lo libera y deja la plaza libre.
func _discard() -> bool:
	var slot := _get_burnt_slot()
	if slot == null:
		return false
	var ingredient: Ingredient = slot.get_ingredient()
	discarded.emit(ingredient)
	slot.ingredient = null
	_reset_burn(slot)
	ingredient.queue_free()
	_reposition_anchors()
	return true


## Sonido y respuesta visual de cada hecho de la olla en `%Feedback` (ADR-006 §4): `POP` de la
## olla al empezar y desechar, del ingrediente al terminar, `SHAKE` de la olla al quemarse; el
## aviso ya lo muestra la barra parpadeando.
func _connect_feedback() -> void:
	if _feedback == null:
		return
	cooking_started.connect(_on_feedback.bind(&"cook_start", false))
	cooking_finished.connect(_on_feedback.bind(&"cook_done", true))
	burn_warned.connect(_on_feedback.bind(&"burn_warning", false))
	burnt.connect(_on_feedback.bind(&"burnt", false))
	discarded.connect(_on_feedback.bind(&"discard", false))


func _on_feedback(ingredient: Ingredient, cue: StringName, on_ingredient: bool) -> void:
	_feedback.play_cue(cue, ingredient if on_ingredient else null)


## Vapor solo con alguna plaza cociendo; fuego bajo en reposo y vivo al cocer.
func _update_effects() -> void:
	var cooking := is_cooking()
	_steam.emitting = cooking
	_fire.amount_ratio = FIRE_COOKING_RATIO if cooking else FIRE_IDLE_RATIO


## Devuelve un ingrediente cocido a la mano (FIFO por orden de finalización).
func _give(holder: Holder) -> bool:
	var slot := _get_finished_slot()
	if slot == null:
		return false

	var ingredient: Ingredient = slot.get_ingredient()
	_restore(ingredient, slot)
	if holder.pick_up(ingredient):
		slot.ingredient = null
		_reset_burn(slot)
		_reposition_anchors()
		return true
	_store(ingredient, slot)
	return false


## Centra las plazas ocupadas: con una sola pieza queda en el centro de la olla.
func _reposition_anchors() -> void:
	var occupied: Array[SlotData] = []
	for slot: SlotData in _slots:
		if slot.get_ingredient() != null:
			occupied.append(slot)
	var total_width := float(occupied.size() - 1) * SLOT_SPACING
	var start_x := -total_width / 2.0
	for i: int in occupied.size():
		occupied[i].anchor.position.x = start_x + float(i) * SLOT_SPACING


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
