class_name Box
extends RigidBody3D
## Caja de pulpo (porta Box.cs sin el modo spawner). Receptor de la interacción contextual
## (ADR-003 §4): con pulpo cocido en la mano, cada pulsación corta y llena `1 / presses_to_fill`
## (D1/D13); con la mano vacía, se coge. Con cualquier otra cosa en la mano consume la pulsación
## sin efecto: fuera de la estación ya no se condimenta (D18, feature estacion-condimentos AC12).
## La entrega lee `get_contents()`.
## Estación de condimentos (D18, ADR-003 §8.3): dispensadores y cuenco alternan condimentos con
## `toggle_seasoning()` y `remove_seasoning()`; son los únicos que cambian sus condimentos.

## Cada corte (D1).
signal fill_changed(fill: float)
## Al aplicar un condimento nuevo.
signal seasoned(seasoning: SeasoningData)
## Al quitar un condimento (alternar uno que ya lleva, intercambio de exclusivos o
## `remove_seasoning`). En el intercambio se emite antes que el `seasoned` del nuevo.
signal seasoning_removed(seasoning: SeasoningData)

@export var data: BoxData

var is_held: bool = false
## Llenado 0–1.
var fill: float = 0.0

var _presses: int = 0

var _ingredient: IngredientData
var _seasonings: Array[SeasoningData] = []
var _is_open: bool = false

@onready var _fill_bar: WorldProgressBar = get_node_or_null(^"%FillBar") as WorldProgressBar
@onready var _animation: AnimationPlayer = get_node_or_null(^"%AnimationPlayer") as AnimationPlayer
@onready var _feedback: FeedbackPlayer = get_node_or_null(^"%Feedback") as FeedbackPlayer


func _ready() -> void:
	if _fill_bar != null:
		_fill_bar.visible = false
	if _feedback != null:
		fill_changed.connect(_on_feedback.bind(&"cut").unbind(1))
		seasoned.connect(_on_feedback.bind(&"season").unbind(1))
		seasoning_removed.connect(_on_feedback.bind(&"unseason").unbind(1))


func is_full() -> bool:
	return fill >= 1.0


func has_seasoning(seasoning: SeasoningData) -> bool:
	return SeasoningRules.find(_seasonings, seasoning) != null


func has_seasoning_in_group(group: StringName) -> bool:
	return SeasoningRules.find_in_group(_seasonings, group) != null


## Alterna `seasoning` (SeasoningRules.toggle): lo quita si ya lo lleva, si no lo añade; con
## `swap_exclusive` sustituye al del mismo grupo de exclusividad. `NONE` = cambió algo; otro valor
## = rechazo sin cambios ni señales.
func toggle_seasoning(seasoning: SeasoningData, swap_exclusive: bool) -> SeasoningRules.Rejection:
	var result: SeasoningRules.Toggle = SeasoningRules.toggle(
		_seasonings, seasoning, is_full(), swap_exclusive
	)
	if result.rejection != SeasoningRules.Rejection.NONE:
		return result.rejection
	_seasonings = result.seasonings
	if result.removed != null:
		seasoning_removed.emit(result.removed)
	if result.added != null:
		seasoned.emit(result.added)
	return SeasoningRules.Rejection.NONE


## Quita `seasoning` si lo lleva y emite `seasoning_removed`; `false` si no lo llevaba.
func remove_seasoning(seasoning: SeasoningData) -> bool:
	var existing: SeasoningData = SeasoningRules.find(_seasonings, seasoning)
	if existing == null:
		return false
	_seasonings = SeasoningRules.remove(_seasonings, existing)
	seasoning_removed.emit(existing)
	return true


## Copia de lo que lleva la caja, para `OrderService.try_deliver`.
func get_contents() -> BoxContents:
	var state: IngredientData.CookingState = IngredientData.CookingState.RAW
	if _ingredient != null:
		state = IngredientData.CookingState.COOKED
	return BoxContents.new(data, _ingredient, state, fill, _seasonings)


func can_interact(actor: InteractionComponent) -> bool:
	var holder: Holder = actor.holder if actor != null else null
	if holder == null or is_held:
		return false
	var held: Node = holder.get_held_item()
	if held == null:
		return holder.can_hold(self)
	# Paridad Unity (Box.Interact → TryToggleHold con la mano llena): la caja consume la
	# pulsación aunque lo que se lleva no le sirva; así no se suelta. M1: filtrar por compatibilidad.
	return true


func interact(actor: InteractionComponent) -> bool:
	if not can_interact(actor):
		return false
	var held: Node = actor.holder.get_held_item()
	if held == null:
		return Slot.pick_up_item(actor, self)
	if held is Ingredient and _can_cut(held as Ingredient):
		_cut(held as Ingredient)
	return true


func on_picked_up(_holder: Holder) -> void:
	is_held = true
	_set_open(false)


func on_dropped() -> void:
	is_held = false


func _can_cut(ingredient: Ingredient) -> bool:
	return (
		data != null
		and ingredient.is_cooked()
		and ingredient.data != null
		and not is_full()
		and ingredient.data.type == IngredientData.IngredientType.OCTOPUS
	)


## Un corte: sube una pulsación entera, llena `fill_after(_presses)` y gasta la diferencia de
## llenado por `amount_per_full_box`: N cortes llenan exactamente y gastan lo mismo que una caja.
func _cut(ingredient: Ingredient) -> void:
	_set_open(true)
	var source: IngredientData = ingredient.data
	var previous: float = fill
	_presses += 1
	fill = data.fill_after(_presses)
	if _presses >= data.presses_to_fill:
		_ingredient = source
	ingredient.take((fill - previous) * source.amount_per_full_box)
	if is_instance_valid(_fill_bar):
		_fill_bar.visible = fill > 0.0 and not is_full()
		_fill_bar.set_progress(fill)
	fill_changed.emit(fill)


## Corte, condimento y su retirada suenan en `%Feedback` (ADR-006 §4).
func _on_feedback(cue: StringName) -> void:
	_feedback.play_cue(cue)


func _set_open(open: bool) -> void:
	if _is_open == open:
		return
	_is_open = open
	if _animation != null:
		_animation.play(&"box_open" if open else &"box_close")
