# gdlint: disable=max-public-methods
extends GutTest
## PUL-069: olla que se pasa (`features/olla-que-se-pasa.md`, ADR-006 §5). Un cocido que sigue en
## la olla avisa a `warn_time` (barra parpadeando) y se quema a `burn_time`; quemado no se corta y
## la mano vacía lo desecha liberando la plaza; la pausa congela el reloj (AC1–AC4).
## AC5: vapor solo con plazas cociendo y fuego vivo al cocer, congelados en pausa.

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const KITCHEN_SCENE: PackedScene = preload("res://entities/stations/kitchen.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const CACHELOS_SCENE: PackedScene = preload("res://entities/items/cachelos.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const OCTOPUS: IngredientData = preload("res://data/ingredients/octopus.tres")
const CACHELOS: IngredientData = preload("res://data/ingredients/cachelos.tres")
const SMALL: BoxData = preload("res://data/boxes/small.tres")
const STEP: float = 0.1

var _level: Node3D
var _hold: HoldComponent
var _actor: InteractionComponent
var _kitchen: CookingStation


func before_each() -> void:
	_level = add_child_autofree(Node3D.new())
	var player: Player = PLAYER_SCENE.instantiate()
	_level.add_child(player)
	_hold = player.get_node("%HoldComponent")
	_hold.items_root = _level
	_actor = player.get_node("%InteractionComponent")
	_kitchen = KITCHEN_SCENE.instantiate()
	_level.add_child(_kitchen)
	_kitchen.position = Vector3(0, 0, -1.2)


func after_each() -> void:
	get_tree().paused = false


func _in_hand(scene: PackedScene = OCTOPUS_SCENE) -> Ingredient:
	var item: Ingredient = scene.instantiate()
	_level.add_child(item)
	assert_true(_hold.pick_up(item))
	return item


## Mete un crudo en la olla desde la mano.
func _put_in_pot(scene: PackedScene = OCTOPUS_SCENE) -> Ingredient:
	var item: Ingredient = _in_hand(scene)
	assert_true(_kitchen.interact(_actor))
	return item


## Avanza `seconds` de juego en pasos de física de `STEP`.
func _advance(seconds: float) -> void:
	simulate(_kitchen, roundi(seconds / STEP), STEP)


func _bar() -> WorldProgressBar:
	return _kitchen.get_node("%CookBar") as WorldProgressBar


func _steam() -> GPUParticles3D:
	return _kitchen.get_node("Model/Steam") as GPUParticles3D


func _fire() -> GPUParticles3D:
	return _kitchen.get_node("Model/Fire") as GPUParticles3D


func test_data_burn_and_warn_times_come_from_tres() -> void:
	for data: IngredientData in [OCTOPUS, CACHELOS]:
		assert_eq(data.burn_time, 10.0, "%s: burn_time" % data.display_name)
		assert_eq(data.warn_time, 7.0, "%s: warn_time" % data.display_name)
		# Invariante de ADR-006 §5.
		assert_gt(data.warn_time, 0.0)
		assert_gte(data.burn_time - data.warn_time, 3.0, "aviso con >= 3 s de antelación")


func test_ac1_burns_after_burn_time_once() -> void:
	var octopus: Ingredient = _put_in_pot()
	watch_signals(_kitchen)
	_advance(OCTOPUS.cook_time)
	assert_true(octopus.is_cooked())
	_advance(9.9)
	assert_true(octopus.is_cooked(), "a 9,9 s sigue cocido")
	assert_signal_not_emitted(_kitchen, "burnt")
	_advance(0.1)
	assert_eq(octopus.state, IngredientData.CookingState.BURNT)
	assert_false(octopus.is_cooked())
	assert_signal_emit_count(_kitchen, "burnt", 1)
	assert_signal_emitted_with_parameters(_kitchen, "burnt", [octopus])
	_advance(20.0)
	assert_signal_emit_count(_kitchen, "burnt", 1, "una sola vez")
	assert_eq(_kitchen.get_ingredient(), octopus, "sigue en la olla hasta desecharlo")
	assert_true(_kitchen.has_burnt())


func test_ac1_burnt_shows_burnt_mesh() -> void:
	var octopus: Ingredient = _put_in_pot()
	_advance(OCTOPUS.cook_time + OCTOPUS.burn_time)
	var model: Node = octopus.get_node("Model")
	assert_true((model.find_child("octopus_burnt") as Node3D).visible)
	assert_false((model.find_child("octopus_cooked") as Node3D).visible)
	assert_false((model.find_child("octopus_raw") as Node3D).visible)


func test_ac1_cachelos_also_burn() -> void:
	var cachelos: Ingredient = _put_in_pot(CACHELOS_SCENE)
	_advance(CACHELOS.cook_time + CACHELOS.burn_time)
	assert_eq(cachelos.state, IngredientData.CookingState.BURNT)
	assert_true((cachelos.get_node("Model").find_child("cachelos_burnt") as Node3D).visible)


func test_ac1_zero_burn_time_never_burns() -> void:
	var octopus: Ingredient = _in_hand()
	var data: IngredientData = OCTOPUS.duplicate()
	data.burn_time = 0.0
	data.warn_time = 0.0
	octopus.data = data
	watch_signals(_kitchen)
	_kitchen.interact(_actor)
	_advance(data.cook_time + 30.0)
	assert_true(octopus.is_cooked(), "variante de paridad: no se quema")
	assert_signal_not_emitted(_kitchen, "burn_warned")
	assert_signal_not_emitted(_kitchen, "burnt")
	assert_false(_bar().visible)


func test_ac2_warns_at_warn_time_with_blinking_bar() -> void:
	var octopus: Ingredient = _put_in_pot()
	watch_signals(_kitchen)
	_advance(OCTOPUS.cook_time)
	assert_false(_bar().visible, "sin barra tras cocer")
	_advance(6.9)
	assert_signal_not_emitted(_kitchen, "burn_warned")
	assert_false(_bar().visible)
	_advance(0.1)
	assert_signal_emit_count(_kitchen, "burn_warned", 1)
	assert_signal_emitted_with_parameters(_kitchen, "burn_warned", [octopus])
	assert_true(_bar().visible, "la barra avisa")
	# Parpadea: el color alterna con el reloj de la plaza.
	var colors: Array[Color] = []
	for i: int in 8:
		colors.append(_bar().modulate)
		_advance(STEP)
	assert_true(colors.has(Color.WHITE) and colors.has(CookingStation.BLINK_COLOR), "parpadea")
	assert_lt(_bar().get_progress(), 1.0, "la barra se vacía hacia el quemado")
	assert_false(octopus.state == IngredientData.CookingState.BURNT, "aviso antes de quemar")
	_advance(OCTOPUS.burn_time - OCTOPUS.warn_time)
	assert_signal_emit_count(_kitchen, "burn_warned", 1, "una vez por plaza")
	assert_eq(octopus.state, IngredientData.CookingState.BURNT)
	assert_false(_bar().visible, "sin barra una vez quemado")


func test_ac3_burnt_octopus_is_rejected_when_cutting() -> void:
	var box: Box = BOX_SCENE.instantiate()
	box.data = SMALL
	_level.add_child(box)
	var octopus: Ingredient = _in_hand()
	octopus.set_burnt()
	assert_true(box.interact(_actor), "consume la pulsación")
	assert_false(box.is_full())
	assert_eq(box.get_contents().fill, 0.0, "no se corta")
	assert_eq(octopus.remaining, OCTOPUS.total_capacity, "no se gasta")


func test_ac3_empty_hand_discards_burnt_and_frees_the_slot() -> void:
	var octopus: Ingredient = _put_in_pot()
	_advance(OCTOPUS.cook_time + OCTOPUS.burn_time)
	watch_signals(_kitchen)
	assert_true(_kitchen.can_interact(_actor))
	assert_true(_kitchen.interact(_actor))
	assert_signal_emitted_with_parameters(_kitchen, "discarded", [octopus])
	assert_null(_hold.get_held_item(), "un quemado nunca llega a la mano")
	assert_true(octopus.is_queued_for_deletion())
	assert_null(_kitchen.get_ingredient())
	assert_false(_kitchen.has_burnt())
	await wait_physics_frames(1)
	# Las dos plazas vuelven a estar libres.
	_put_in_pot()
	_put_in_pot()
	assert_true(_kitchen.is_cooking())


func test_ac3_discards_oldest_burnt_before_giving_a_cooked() -> void:
	var first: Ingredient = _put_in_pot()
	_advance(OCTOPUS.cook_time + 6.0)
	var second: Ingredient = _put_in_pot()
	_advance(OCTOPUS.cook_time)
	assert_eq(first.state, IngredientData.CookingState.BURNT)
	assert_true(second.is_cooked())
	watch_signals(_kitchen)
	assert_true(_kitchen.interact(_actor))
	assert_signal_emitted_with_parameters(_kitchen, "discarded", [first])
	assert_null(_hold.get_held_item())
	assert_true(_kitchen.interact(_actor))
	assert_eq(_hold.get_held_item(), second, "después da el cocido")


func test_ac3_picking_up_in_time_stops_the_clock() -> void:
	var octopus: Ingredient = _put_in_pot()
	_advance(OCTOPUS.cook_time + 8.0)
	assert_true(_bar().visible, "en aviso")
	watch_signals(_kitchen)
	assert_true(_kitchen.interact(_actor))
	assert_eq(_hold.get_held_item(), octopus)
	assert_false(_bar().visible, "al recogerlo se apaga el aviso")
	_advance(30.0)
	assert_true(octopus.is_cooked(), "en la mano no se quema")
	assert_signal_not_emitted(_kitchen, "burnt")
	assert_null(_kitchen.get_ingredient(), "plaza libre")


func test_ac4_pause_freezes_the_burn_clock() -> void:
	var octopus: Ingredient = _put_in_pot()
	_advance(OCTOPUS.cook_time + 9.9)
	assert_true(octopus.is_cooked())
	get_tree().paused = true
	for i: int in 30:
		await get_tree().physics_frame
	assert_true(octopus.is_cooked(), "congelado en pausa")
	get_tree().paused = false
	await wait_seconds(0.3)
	assert_eq(octopus.state, IngredientData.CookingState.BURNT, "sigue al reanudar")


func test_ac5_steam_only_while_cooking_and_fire_alive() -> void:
	assert_false(_steam().emitting, "sin vapor en reposo")
	assert_almost_eq(
		_fire().amount_ratio, CookingStation.FIRE_IDLE_RATIO, 0.001, "fuego bajo en reposo"
	)
	_put_in_pot()
	_advance(STEP)
	assert_true(_steam().emitting, "vapor al cocer")
	assert_almost_eq(
		_fire().amount_ratio, CookingStation.FIRE_COOKING_RATIO, 0.001, "fuego vivo al cocer"
	)
	_advance(OCTOPUS.cook_time)
	assert_false(_steam().emitting, "sin vapor con la plaza cocida")
	assert_almost_eq(_fire().amount_ratio, CookingStation.FIRE_IDLE_RATIO, 0.001)


func test_ac5_effects_freeze_in_pause() -> void:
	_put_in_pot()
	_advance(STEP)
	assert_true(_steam().can_process())
	get_tree().paused = true
	assert_false(_steam().can_process(), "el vapor se congela")
	assert_false(_fire().can_process(), "el fuego se congela")
	assert_true(_steam().emitting, "no se apaga: queda congelado")


func test_feedback_node_ready_for_pul071() -> void:
	var feedback: Node = _kitchen.get_node("%Feedback")
	assert_true(feedback is AudioStreamPlayer3D)
