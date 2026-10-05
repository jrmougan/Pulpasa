class_name Box
extends RigidBody3D
## Caja de pulpo (porta Box.cs sin el modo spawner). Receptor de la interacción contextual
## (ADR-003 §4): con pulpo cocido en la mano, cada pulsación corta y llena `fill_per_press`
## (D1/D13); con un condimento y la caja llena, lo aplica una vez por tipo; con un ingrediente
## cocido cuyo `IngredientData.as_seasoning` no es nulo (p. ej. cachelos cocidos, D10), lo aplica
## como condimento y lo consume; con la mano vacía, se coge. Con cualquier otra cosa en la mano
## consume la pulsación sin efecto (paridad Unity).
## La entrega lee `get_contents()`.
## Estación de condimentos (D18, ADR-003 §8.3): dispensadores y cuenco alternan condimentos con
## `toggle_seasoning()` y `remove_seasoning()`. Las ramas de bote y cachelos de `interact()` se
## retiran en PUL-061.

## Cada corte (D1).
signal fill_changed(fill: float)
## Al aplicar un condimento nuevo.
signal seasoned(seasoning: SeasoningData)
## Al quitar un condimento (alternar uno que ya lleva, intercambio de exclusivos o
## `remove_seasoning`). En el intercambio se emite antes que el `seasoned` del nuevo.
signal seasoning_removed(seasoning: SeasoningData)

## Tolerancia de coma flotante al sumar `fill_per_press` (0,1 × 10 ≠ 1,0 exacto).
const FULL_EPSILON: float = 0.0001

@export var data: BoxData

var is_held: bool = false
## Llenado 0–1.
var fill: float = 0.0

var _ingredient: IngredientData
var _seasonings: Array[SeasoningData] = []
var _is_open: bool = false

@onready var _fill_bar: WorldProgressBar = get_node_or_null(^"%FillBar") as WorldProgressBar
@onready var _animation: AnimationPlayer = get_node_or_null(^"%AnimationPlayer") as AnimationPlayer
@onready var _cut_audio: AudioStreamPlayer3D = get_node_or_null(^"%CutAudio") as AudioStreamPlayer3D
@onready
var _season_audio: AudioStreamPlayer3D = get_node_or_null(^"%SeasonAudio") as AudioStreamPlayer3D


func _ready() -> void:
	if _fill_bar != null:
		_fill_bar.visible = false


func is_full() -> bool:
	return fill >= 1.0


func has_seasoning(seasoning: SeasoningData) -> bool:
	return SeasoningRules.find(_seasonings, seasoning) != null


func has_seasoning_in_group(group: StringName) -> bool:
	return SeasoningRules.find_in_group(_seasonings, group) != null


func can_season(seasoning: SeasoningData) -> bool:
	if seasoning == null or not is_full():
		return false
	if has_seasoning(seasoning):
		return false
	if (
		not seasoning.exclusivity_group.is_empty()
		and has_seasoning_in_group(seasoning.exclusivity_group)
	):
		return false
	return true


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
		if _season_audio != null:
			_season_audio.play()
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
	elif (
		held is Ingredient
		and is_full()
		and (held as Ingredient).is_cooked()
		and (held as Ingredient).data != null
		and (held as Ingredient).data.as_seasoning != null
	):
		var seasoning: SeasoningData = (held as Ingredient).data.as_seasoning
		if can_season(seasoning):
			var ing: Ingredient = actor.holder.drop() as Ingredient
			if ing != null:
				_season(seasoning)
				ing.queue_free()
	elif held is SeasoningItem and is_full() and (held as SeasoningItem).data != null:
		_season((held as SeasoningItem).data)
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


## Un corte: llena `fill_per_press` y gasta `fill_per_press * amount_per_full_box` de pulpo.
func _cut(ingredient: Ingredient) -> void:
	_set_open(true)
	var source: IngredientData = ingredient.data
	fill = minf(fill + data.fill_per_press, 1.0)
	if fill >= 1.0 - FULL_EPSILON:
		fill = 1.0
		_ingredient = source
	ingredient.take(data.fill_per_press * source.amount_per_full_box)
	if _cut_audio != null:
		_cut_audio.play()
	if is_instance_valid(_fill_bar):
		_fill_bar.visible = fill > 0.0 and not is_full()
		_fill_bar.set_progress(fill)
	fill_changed.emit(fill)


## Una vez por tipo (Box.CanReceiveSeasoning); repetir no tiene efecto (idempotente).
## Grupos de exclusividad: pimentón dulce y picante son excluyentes (D4).
func _season(seasoning: SeasoningData) -> void:
	if not can_season(seasoning):
		return
	_seasonings.append(seasoning)
	if _season_audio != null:
		_season_audio.play()
	seasoned.emit(seasoning)


func _set_open(open: bool) -> void:
	if _is_open == open:
		return
	_is_open = open
	if _animation != null:
		_animation.play(&"box_open" if open else &"box_close")
