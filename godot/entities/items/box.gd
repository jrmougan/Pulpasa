class_name Box
extends RigidBody3D
## Caja de pulpo (porta Box.cs sin el modo spawner). Receptor de la interacción contextual
## (ADR-003 §4): con pulpo cocido en la mano, cada pulsación corta y llena `1 / presses_to_fill`
## (D1/D13); con la mano vacía, se coge. D26 (§11.2): `get_action_hint` e `interact` comparten
## `_resolve` (`ActionRules.for_box`): con pulpo crudo o con la caja llena la pulsación se
## rechaza con motivo (`BLOCKED`) y con cualquier otra cosa en la mano no es objetivo (fuera de la
## estación no se condimenta, D18). `%CutCounter` muestra los cortes `N/total` (D26.6).
## La entrega lee `get_contents()`.
## Estación de condimentos (D18, D25; ADR-003 §10.2): los dispensadores aplican aliño con
## `apply_seasoning()`, el cuenco alterna cachelos con `toggle_seasoning()`; son los únicos que
## cambian sus condimentos.

## Cada corte (D1).
signal fill_changed(fill: float)
## Al aplicar un condimento nuevo.
signal seasoned(seasoning: SeasoningData)
## Al quitar un condimento (alternar cachelos, sustituir un aliño o `remove_seasoning`). Al
## sustituir se emite antes que el `seasoned` del nuevo.
signal seasoning_removed(seasoning: SeasoningData)

## Segundos que se ve `total/total` en el corte que llena antes de ocultarse el contador.
const COUNTER_FULL_TIME: float = 0.5

@export var data: BoxData

var is_held: bool = false
## Llenado 0–1. Estado derivado de `_presses`; `_cut` resincroniza `_presses` desde él por si
## `fill` o `data` cambiaron por fuera.
var fill: float = 0.0

var _presses: int = 0

var _ingredient: IngredientData
var _seasonings: Array[SeasoningData] = []
var _is_open: bool = false
## Segundos que quedan de mostrar el contador lleno.
var _counter_left: float = 0.0

@onready var _fill_bar: WorldProgressBar = get_node_or_null(^"%FillBar") as WorldProgressBar
@onready var _animation: AnimationPlayer = get_node_or_null(^"%AnimationPlayer") as AnimationPlayer
@onready var _feedback: FeedbackPlayer = get_node_or_null(^"%Feedback") as FeedbackPlayer
@onready var _cut_counter: Node3D = get_node_or_null(^"%CutCounter") as Node3D
@onready var _cut_bar: WorldProgressBar = get_node_or_null(^"%CutBar") as WorldProgressBar
@onready var _cut_numeral: Label3D = get_node_or_null(^"%CutNumeral") as Label3D


func _ready() -> void:
	set_physics_process(false)
	# `%FillBar` queda oculta: la sustituye `%CutCounter` (la exige el contrato de items).
	if _fill_bar != null:
		_fill_bar.visible = false
	if _cut_counter != null:
		_cut_counter.visible = false
		if _cut_bar != null and data != null:
			_cut_bar.set_segments(data.presses_to_fill)
	if _feedback != null:
		fill_changed.connect(_on_fill_changed)
		seasoned.connect(_on_feedback.bind(&"season").unbind(1))
		seasoning_removed.connect(_on_feedback.bind(&"unseason").unbind(1))


## Con el contador lleno visible, lo oculta pasado `COUNTER_FULL_TIME`.
func _physics_process(delta: float) -> void:
	_counter_left -= delta
	if _counter_left <= 0.0:
		_counter_left = 0.0
		_cut_counter.visible = false
		set_physics_process(false)


func is_full() -> bool:
	return fill >= 1.0


func has_seasoning(seasoning: SeasoningData) -> bool:
	return SeasoningRules.find(_seasonings, seasoning) != null


func has_seasoning_in_group(group: StringName) -> bool:
	return SeasoningRules.find_in_group(_seasonings, group) != null


## D25: aplica un aliño (`SeasoningRules.apply`). Con `NONE` emite `seasoning_removed(viejo)` (solo
## al sustituir el otro aliño) antes que `seasoned(nuevo)`. Con otro valor (`BOX_NOT_FULL`,
## `ALREADY_APPLIED`) no cambia nada ni emite.
func apply_seasoning(seasoning: SeasoningData) -> SeasoningRules.Rejection:
	return _commit(SeasoningRules.apply(_seasonings, seasoning, is_full()))


## Alterna `seasoning` (SeasoningRules.toggle): lo quita si ya lo lleva, si no lo añade. Solo lo
## llama el cuenco (cachelos). `NONE` = cambió algo; otro valor = rechazo sin cambios ni señales.
func toggle_seasoning(seasoning: SeasoningData) -> SeasoningRules.Rejection:
	return _commit(SeasoningRules.toggle(_seasonings, seasoning, is_full()))


## Quita `seasoning` si lo lleva y emite `seasoning_removed`; `false` si no lo llevaba.
func remove_seasoning(seasoning: SeasoningData) -> bool:
	var existing: SeasoningData = SeasoningRules.find(_seasonings, seasoning)
	if existing == null:
		return false
	_seasonings = SeasoningRules.remove(_seasonings, existing)
	seasoning_removed.emit(existing)
	return true


## Cortes dados (pulsaciones enteras de `presses_to_fill`).
func get_presses() -> int:
	if data == null:
		return 0
	return maxi(_presses, floori(fill * data.presses_to_fill + 0.0001))


## Copia de lo que lleva la caja, para `OrderService.try_deliver`.
func get_contents() -> BoxContents:
	var state: IngredientData.CookingState = IngredientData.CookingState.RAW
	if _ingredient != null:
		state = IngredientData.CookingState.COOKED
	return BoxContents.new(data, _ingredient, state, fill, _seasonings)


## Qué haría la pulsación (ADR-003 §11.2, fila B): coger con la mano vacía; con pulpo cocido,
## cortar (`progress` = llenado); con pulpo crudo o la caja llena, rechazo con motivo.
func get_action_hint(actor: InteractionComponent) -> ActionHint:
	return _resolve(actor.holder if actor != null else null)


func can_interact(actor: InteractionComponent) -> bool:
	return get_action_hint(actor).is_target()


func interact(actor: InteractionComponent) -> bool:
	var hint: ActionHint = get_action_hint(actor)
	if hint.state != ActionHint.State.OK:
		return hint.state == ActionHint.State.BLOCKED
	match hint.verb:
		ActionVerb.PICK_UP:
			return Slot.pick_up_item(actor, self)
		ActionVerb.CUT:
			_cut(actor.holder.get_held_item() as Ingredient)
	return true


func on_picked_up(_holder: Holder) -> void:
	is_held = true
	_set_open(false)


func on_dropped() -> void:
	is_held = false


## Única resolución de rama de `get_action_hint` e `interact` (ADR-003 §11.2).
func _resolve(holder: Holder) -> ActionHint:
	if holder == null or is_held:
		return ActionHint.none()
	var item: Node = holder.get_held_item()
	var held: ActionRules.Held = HeldKind.of(item)
	if held == ActionRules.Held.NOTHING and not holder.can_hold(self):
		return ActionHint.none()
	# Sin datos de caja no se puede cortar: el pulpo en la mano no cuenta.
	if data == null or (item is Ingredient and (item as Ingredient).data == null):
		held = ActionRules.Held.OTHER
	return ActionRules.for_box(held, is_full(), fill)


func _commit(result: SeasoningRules.Toggle) -> SeasoningRules.Rejection:
	if result.rejection != SeasoningRules.Rejection.NONE:
		return result.rejection
	_seasonings = result.seasonings
	if result.removed != null:
		seasoning_removed.emit(result.removed)
	if result.added != null:
		seasoned.emit(result.added)
	return SeasoningRules.Rejection.NONE


## Un corte: sube una pulsación entera, llena `fill_after(_presses)` y gasta la diferencia de
## llenado por `amount_per_full_box`: N cortes llenan exactamente y gastan lo mismo que una caja.
func _cut(ingredient: Ingredient) -> void:
	_set_open(true)
	var source: IngredientData = ingredient.data
	var previous: float = fill
	_presses = get_presses() + 1
	fill = data.fill_after(_presses)
	if _presses >= data.presses_to_fill:
		_ingredient = source
	ingredient.take((fill - previous) * source.amount_per_full_box)
	_update_counter()
	fill_changed.emit(fill)


## `%CutCounter` (D26.6): `N/total` con 0 < N < total; en el corte que llena, `total/total`
## `COUNTER_FULL_TIME` s y se oculta.
func _update_counter() -> void:
	if _cut_counter == null or data == null:
		return
	var presses: int = get_presses()
	var total: int = data.presses_to_fill
	_cut_counter.visible = presses > 0
	if _cut_bar != null:
		_cut_bar.set_progress(float(presses) / float(total))
	if _cut_numeral != null:
		_cut_numeral.text = "%d/%d" % [mini(presses, total), total]
	if presses >= total:
		_counter_left = COUNTER_FULL_TIME
		set_physics_process(true)


## Cada corte suena `cut`; el que llena, `box_full` en su lugar (ADR-006 §4.1).
func _on_fill_changed(_fill: float) -> void:
	_feedback.play_cue(&"box_full" if is_full() else &"cut")


## Condimento y su retirada suenan en `%Feedback` (ADR-006 §4).
func _on_feedback(cue: StringName) -> void:
	_feedback.play_cue(cue)


func _set_open(open: bool) -> void:
	if _is_open == open:
		return
	_is_open = open
	if _animation != null:
		_animation.play(&"box_open" if open else &"box_close")
