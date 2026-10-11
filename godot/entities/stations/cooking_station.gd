class_name CookingStation
extends StaticBody3D
## Olla (porta KitchenStation + KitchenProgress). Contrato `interactable` y marca `kitchen`
## (ADR-003 §4). Acepta ingredientes crudos cocinables (pulpo, cachelos) de la mano, los deja en
## sus `AnchorPoint`, los cuece en `IngredientData.cook_time` con su `%CookRing` y `%BoilAudio`,
## y los devuelve cocidos a una mano vacía por orden de finalización (FIFO: el primero
## que terminó sale primero, según `_finish_counter`).
## M3 (ADR-006 §5): un cocido que sigue en la plaza se quema. Tras `cooking_finished` el reloj de la
## plaza sigue: a `warn_time` avisa (`burn_warned`, barra visible vaciándose y parpadeando) y a
## `burn_time` lo quema (`Ingredient.set_burnt()` + `burnt`). Recogerlo a tiempo para el reloj.
## D26.6: el `%CookRing` de cada plaza muestra el estado (cociendo, listo, aviso, quemado) y el cue
## `burn_warning` se repite cada `warn_repeat_interval` hasta `warn_repeat_count` veces en total.
## Con la mano vacía se desecha primero el quemado más antiguo (`discarded`, `queue_free`) y, si no
## hay, se da el cocido FIFO; un quemado nunca llega a la mano. `burn_time` = 0: no se quema.
## Vapor (`Model/Steam`) solo con alguna plaza cociendo y fuego (`Model/Fire`) bajo en reposo y
## vivo al cocer; las partículas se congelan con la pausa del árbol.
## Capacidad en datos: `KitchenData.capacity` (inyectado, `data/config/kitchen.tres`).
##
## Un solo reloj general o uno por plaza: se acumulan en `_physics_process`, así que la pausa
## del árbol los congela (sin el doble temporizador del prototipo). El aspecto cocido lo pone
## `Ingredient.set_cooked()`. D26 (ADR-003 §11.2): `get_action_hint` y `interact` comparten
## `_resolve` (`ActionRules.for_pot`); con lo que no cuece la olla no es objetivo.

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

## Separación de los anillos, en diámetros (para que no se tapen entre plazas).
const RING_SPACING_RATIO: float = 1.05

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
	## Veces que aún debe repetirse `burn_warning` y el `since_finished` de la próxima.
	var repeats_left: int = 0
	var next_repeat_at: float = 0.0
	var anchor: Node3D
	var ring: WorldProgressRing

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
@onready var _ring_base: WorldProgressRing = %CookRing
@onready var _boil_audio: AudioStreamPlayer3D = %BoilAudio
@onready var _steam: GPUParticles3D = $Model/Steam
@onready var _fire: GPUParticles3D = $Model/Fire
@onready var _feedback: FeedbackPlayer = get_node_or_null(^"%Feedback") as FeedbackPlayer


func _ready() -> void:
	if data == null:
		data = KitchenData.new()
		data.capacity = 1
	_ring_base.visible = false
	var slot_count: int = data.capacity
	_ring_base.configure(data.ring_diameter_px, data.ring_thickness_px, data.warn_blink_hz)
	var total_width := float(slot_count - 1) * SLOT_SPACING
	var start_x := -total_width / 2.0
	for i: int in slot_count:
		var slot_data := SlotData.new()
		var curr_x := start_x + float(i) * SLOT_SPACING
		if i == 0:
			slot_data.anchor = _anchor_base
			slot_data.ring = _ring_base
		else:
			slot_data.anchor = _anchor_base.duplicate() as Node3D
			add_child(slot_data.anchor)
			slot_data.ring = _ring_base.duplicate() as WorldProgressRing
			add_child(slot_data.ring)
			slot_data.ring.set_state(WorldProgressRing.State.HIDDEN)

		# Anclas simétricas y anillos en fila sobre la olla (uno por plaza).
		slot_data.anchor.position.x = curr_x
		_slots.append(slot_data)
	_layout_rings()
	_ring_base.metrics_changed.connect(_layout_rings)
	_update_effects()
	_connect_feedback()


## Anillos en fila sobre la olla (uno por plaza), separados `RING_SPACING_RATIO` diámetros con el
## tamaño de la cámara activa (se repite si el perfil de cámara cambia el zoom).
func _layout_rings() -> void:
	var spacing: float = (
		_ring_base.diameter_px * RING_SPACING_RATIO * _ring_base.get_meters_per_px()
	)
	for i: int in _slots.size():
		_slots[i].ring.position.x = (float(i) - float(_slots.size() - 1) / 2.0) * spacing


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
		slot.ring.set_progress(slot.elapsed / slot.cook_time if slot.cook_time > 0.0 else 1.0)
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


## Anillo de cada plaza (`%CookRing` y sus copias), en el orden de las plazas.
func get_rings() -> Array[WorldProgressRing]:
	var rings: Array[WorldProgressRing] = []
	for slot: SlotData in _slots:
		rings.append(slot.ring)
	return rings


## Devuelve el primer ingrediente que encuentre (para tests y compatibilidad).
func get_ingredient() -> Ingredient:
	for slot: SlotData in _slots:
		var ing: Ingredient = slot.get_ingredient()
		if ing != null:
			return ing
	return null


## Qué haría la pulsación (ADR-003 §11.2, fila C): retirar el quemado (`TIRAR`) o el cocido
## (`COGER`) con la mano vacía; cocer un crudo si hay plaza (`COCER`) o `BUSY` si no.
func get_action_hint(actor: InteractionComponent) -> ActionHint:
	return _resolve(actor.holder if actor != null else null)


func can_interact(actor: InteractionComponent) -> bool:
	return get_action_hint(actor).is_target()


func interact(actor: InteractionComponent) -> bool:
	var hint: ActionHint = get_action_hint(actor)
	if hint.state != ActionHint.State.OK:
		return hint.state == ActionHint.State.BLOCKED
	var holder: Holder = actor.holder
	match hint.verb:
		ActionVerb.TRASH:
			return _discard()
		ActionVerb.PICK_UP:
			return _give(holder)
		ActionVerb.COOK:
			var slot: SlotData = _get_empty_slot()
			if slot == null:
				return false
			_start(holder, slot)
			return true
	return false


## Única resolución de rama de `get_action_hint` e `interact` (ADR-003 §11.2).
func _resolve(holder: Holder) -> ActionHint:
	if holder == null:
		return ActionHint.none()
	var item: Node = holder.get_held_item()
	var held: ActionRules.Held = HeldKind.of(item)
	if item is Ingredient and not _accepts(item as Ingredient):
		held = ActionRules.Held.OTHER
	var finished: SlotData = _get_finished_slot()
	var has_ready: bool = finished != null and holder.can_hold(finished.get_ingredient())
	return ActionRules.for_pot(held, _free_places(), has_burnt(), has_ready)


func _free_places() -> int:
	var free: int = 0
	for slot: SlotData in _slots:
		if slot.get_ingredient() == null and not slot.cooking:
			free += 1
	return free


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
	slot.ring.set_progress(0.0)
	slot.ring.set_state(WorldProgressRing.State.COOKING)
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
	slot.ring.set_progress(1.0)
	slot.ring.set_state(WorldProgressRing.State.READY)
	cooking_finished.emit(ingredient)


func _stop_cooking(slot: SlotData) -> void:
	slot.cooking = false
	slot.ring.set_state(WorldProgressRing.State.HIDDEN)


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
		slot.repeats_left = maxi(data.warn_repeat_count - 1, 0)
		slot.next_repeat_at = slot.warn_time + data.warn_repeat_interval
		slot.ring.set_state(WorldProgressRing.State.WARNING)
		burn_warned.emit(ingredient)
	if slot.warned:
		var window: float = maxf(slot.burn_time - slot.warn_time, TIME_EPSILON)
		slot.ring.set_progress((slot.burn_time - slot.since_finished) / window)
		slot.ring.set_warning_time(slot.since_finished - slot.warn_time)
		_repeat_warning(slot)


## Repite `burn_warning` cada `warn_repeat_interval` mientras dure el aviso (un aviso sostenido:
## única excepción a «un cue por señal», ADR-006 §4.1).
func _repeat_warning(slot: SlotData) -> void:
	while slot.repeats_left > 0 and slot.since_finished >= slot.next_repeat_at - TIME_EPSILON:
		slot.repeats_left -= 1
		slot.next_repeat_at += data.warn_repeat_interval
		if _feedback != null:
			_feedback.play_cue(&"burn_warning")


func _burn(slot: SlotData, ingredient: Ingredient) -> void:
	slot.burnt = true
	slot.ring.set_state(WorldProgressRing.State.BURNT)
	ingredient.set_burnt()
	burnt.emit(ingredient)


func _reset_burn(slot: SlotData) -> void:
	slot.since_finished = 0.0
	slot.warned = false
	slot.burnt = false
	slot.repeats_left = 0
	slot.ring.set_state(WorldProgressRing.State.HIDDEN)


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
## aviso ya lo muestra el anillo parpadeando.
func _connect_feedback() -> void:
	if _feedback == null:
		return
	cooking_started.connect(_on_feedback.bind(&"cook_start", false))
	cooking_finished.connect(_on_feedback.bind(&"cook_ready", true))
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
