# gdlint: disable=max-public-methods
extends GutTest
## PUL-071: música, ambiente y feedback de las acciones (`features/audio-y-fx.md`, ADR-006).
## AC1 BG/FOL en `Music`/`Ambience` (`LevelAudio`); AC2 un FX por señal (se cuentan los `played`
## de cada `%Feedback`; con ADR-006 §3 "su señal" es la de `EventBus` o la local); AC5 sonido y
## respuesta visual ≥ 0,3 s, correcta ≠ errónea; AC3 `AudioDirector` baja `Music` y `Ambience`
## en pausa. Ningún reproductor del juego queda en `Master`.

const EventBusScript: GDScript = preload("res://autoload/event_bus.gd")
const OrderServiceScript: GDScript = preload("res://autoload/order_service.gd")
const AudioDirectorScript: GDScript = preload("res://autoload/audio_director.gd")
const RoundManagerScript: GDScript = preload("res://autoload/round_manager.gd")
const ROUND_CONFIG: RoundConfig = preload("res://data/config/round_config.tres")
const MAP: AudioFeedbackMap = preload("res://data/audio/feedback_map.tres")
const LEVEL: PackedScene = preload("res://scenes/levels/level_01.tscn")
const LEVEL_AUDIO_SCENE: PackedScene = preload("res://entities/environment/level_audio.tscn")
const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const KITCHEN_SCENE: PackedScene = preload("res://entities/stations/kitchen.tscn")
const STAND_SCENE: PackedScene = preload("res://entities/stations/order_stand.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const CATALOG: OrderCatalog = preload("res://data/orders/order_catalog.tres")
const SALT: SeasoningData = preload("res://data/seasonings/salt.tres")
const SMALL: BoxData = preload("res://data/boxes/small.tres")
const SLOT_ID: int = 3
const STEP: float = 0.1
const DUCK_MIN_DB: float = 12.0
## Duración mínima de la respuesta visual (AC5).
const MIN_VISUAL_TIME: float = 0.3
## Claves cerradas del mapa (ADR-006 §4).
const CUES: Array[StringName] = [
	&"pick_up",
	&"drop",
	&"cut",
	&"cook_start",
	&"cook_done",
	&"season",
	&"unseason",
	&"season_error",
	&"deliver_ok",
	&"deliver_error",
	&"order_new",
	&"order_expired",
	&"burn_warning",
	&"burnt",
	&"discard",
	&"phase_up",
]
## Acciones de AC5: cue con sonido y respuesta visual.
const AC5_CUES: Array[StringName] = [
	&"pick_up", &"cook_start", &"cook_done", &"season", &"deliver_ok", &"deliver_error"
]
## Carpetas cuyas escenas no pueden dejar un reproductor en `Master`.
const SCENE_DIRS: Array[String] = ["res://entities", "res://scenes", "res://ui"]

var _bus: Node
var _level: Node3D
var _player: Player
var _hold: HoldComponent
var _actor: InteractionComponent
## Cues reproducidas por cada `%Feedback` vigilado, por nombre de su escena.
var _played: Dictionary[String, Array] = {}


func before_each() -> void:
	_played.clear()
	_bus = add_child_autofree(EventBusScript.new())
	_level = add_child_autofree(Node3D.new())
	_player = PLAYER_SCENE.instantiate()
	_player.set_bus(_bus)
	_level.add_child(_player)
	_hold = _player.get_node("%HoldComponent")
	_hold.items_root = _level
	_actor = _player.get_node("%InteractionComponent")
	_watch("player", _player)


func after_each() -> void:
	get_tree().paused = false


## Registra las cues que reproduce el `%Feedback` de `owner_node` en `_played[key]`.
func _watch(key: String, owner_node: Node) -> FeedbackPlayer:
	var feedback: FeedbackPlayer = owner_node.get_node("%Feedback") as FeedbackPlayer
	assert_not_null(feedback, "%s tiene %%Feedback" % key)
	var entries: Array = []
	_played[key] = entries
	feedback.played.connect(func(cue: StringName) -> void: entries.append(cue))
	return feedback


func _cues(key: String) -> Array:
	return _played[key]


func _octopus(cooked: bool = false) -> Ingredient:
	var item: Ingredient = OCTOPUS_SCENE.instantiate()
	_level.add_child(item)
	if cooked:
		item.set_cooked()
	return item


func _kitchen() -> CookingStation:
	var kitchen: CookingStation = KITCHEN_SCENE.instantiate()
	_level.add_child(kitchen)
	kitchen.position = Vector3(0, 0, -1.2)
	_watch("kitchen", kitchen)
	return kitchen


func _stand() -> OrderStand:
	var service: Node = OrderServiceScript.new()
	service.set_bus(_bus)
	add_child_autofree(service)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	service.setup(CATALOG, rng)
	var stand: OrderStand = STAND_SCENE.instantiate()
	stand.slot_id = SLOT_ID
	stand.set_bus(_bus)
	stand.set_service(service)
	_level.add_child(stand)
	_watch("stand", stand)
	return stand


func _box() -> Box:
	var box: Box = BOX_SCENE.instantiate()
	box.data = SMALL
	_level.add_child(box)
	box.position = Vector3(2, 0, 0)
	_watch("box", box)
	return box


## Comprueba la respuesta visual en curso sobre `target`: dura ≥ 0,3 s (sigue moviéndose justo
## antes) y deja el nodo en reposo al terminar. Devuelve si cambió la escala (`POP`) o la
## posición (`SHAKE`).
func _assert_visual(feedback: FeedbackPlayer, target: Node3D, cue: StringName) -> String:
	var tween: Tween = feedback.get_visual_tween(target)
	assert_not_null(tween, "%s: respuesta visual" % cue)
	if tween == null:
		return ""
	var node: Node3D = target.get_node_or_null(^"Model") as Node3D
	if node == null:
		node = target
	var rest_scale: Vector3 = node.scale
	var rest_position: Vector3 = node.position
	var time: float = MAP.get_cue(cue).visual_time
	assert_true(time >= MIN_VISUAL_TIME, "%s: ≥ 0,3 s" % cue)
	tween.pause()
	tween.custom_step(time * 0.25)
	var kind: String = ""
	if not node.scale.is_equal_approx(rest_scale):
		kind = "pop"
	elif not node.position.is_equal_approx(rest_position):
		kind = "shake"
	assert_ne(kind, "", "%s: el nodo se mueve" % cue)
	tween.custom_step(MIN_VISUAL_TIME - time * 0.25 - 0.01)
	assert_true(tween.is_valid(), "%s: sigue a los 0,29 s" % cue)
	tween.custom_step(time)
	assert_true(node.scale.is_equal_approx(rest_scale), "%s: escala en reposo" % cue)
	assert_true(node.position.is_equal_approx(rest_position), "%s: posición en reposo" % cue)
	assert_null(feedback.get_visual_tween(target), "%s: terminó" % cue)
	return kind


# --- Datos y buses ---


func test_map_has_every_cue_with_a_stream() -> void:
	for cue: StringName in CUES:
		var data: AudioCue = MAP.get_cue(cue)
		assert_not_null(data, "cue %s" % cue)
		if data != null:
			assert_not_null(data.stream, "%s: stream" % cue)
			assert_true(data.visual_time >= MIN_VISUAL_TIME, "%s: visual_time" % cue)
	assert_eq(MAP.cues.size(), CUES.size(), "sin claves de más")


func test_ac5_map_actions_have_visual_and_deliveries_differ() -> void:
	for cue: StringName in AC5_CUES:
		assert_ne(MAP.get_cue(cue).visual, AudioCue.Visual.NONE, "%s: visual" % cue)
	var ok: AudioCue = MAP.get_cue(&"deliver_ok")
	var error: AudioCue = MAP.get_cue(&"deliver_error")
	assert_ne(ok.stream, error.stream, "suenan distinto")
	assert_ne(ok.visual, error.visual, "se ven distinto")
	assert_almost_eq(MAP.get_cue(&"order_new").delay, 0.5, 0.001, "order_new con retardo")


func test_bus_layout_has_music_ambience_and_sfx() -> void:
	for bus: StringName in AudioMix.BUSES:
		var index: int = AudioServer.get_bus_index(bus)
		assert_true(index > 0, "existe %s" % bus)
		assert_eq(AudioServer.get_bus_send(index), &"Master")


func test_no_scene_player_left_on_master() -> void:
	var checked: int = 0
	for path: String in _scene_paths():
		var scene: PackedScene = load(path) as PackedScene
		var root: Node = scene.instantiate()
		for node: Node in _all_nodes(root):
			var bus: Variant = null
			if node is AudioStreamPlayer or node is AudioStreamPlayer3D:
				bus = node.get(&"bus")
			elif node is AudioStreamPlayer2D:
				bus = node.get(&"bus")
			if bus != null:
				checked += 1
				assert_ne(bus, &"Master", "%s · %s en Master" % [path, node.name])
		root.free()
	assert_true(checked >= 6, "revisa los reproductores del juego (%d)" % checked)


func _scene_paths() -> Array[String]:
	var paths: Array[String] = []
	var pending: Array[String] = SCENE_DIRS.duplicate()
	while not pending.is_empty():
		var dir_path: String = pending.pop_back()
		if dir_path.ends_with("/sandbox"):
			continue
		for sub: String in DirAccess.get_directories_at(dir_path):
			pending.append(dir_path.path_join(sub))
		for file: String in DirAccess.get_files_at(dir_path):
			if file.ends_with(".tscn"):
				paths.append(dir_path.path_join(file))
	return paths


func _all_nodes(root: Node) -> Array[Node]:
	var nodes: Array[Node] = [root]
	var index: int = 0
	while index < nodes.size():
		nodes.append_array(nodes[index].get_children(true))
		index += 1
	return nodes


# --- AC1 ---


func test_ac1_level_01_has_level_audio() -> void:
	var level: Node = LEVEL.instantiate()
	assert_true(level.get_node_or_null(^"LevelAudio") is LevelAudio)
	level.free()


func test_ac1_music_and_ambience_play_on_their_buses_after_round_start() -> void:
	var audio: LevelAudio = LEVEL_AUDIO_SCENE.instantiate()
	audio.set_bus(_bus)
	add_child_autofree(audio)
	var music: AudioStreamPlayer = audio.get_node("%Music")
	var ambience: AudioStreamPlayer = audio.get_node("%Ambience")
	assert_false(music.playing, "nada antes de la ronda")
	_bus.round_started.emit(300.0)
	await wait_seconds(1.0)
	assert_true(music.playing, "BG suena")
	assert_true(ambience.playing, "FOL suena")
	assert_eq(music.bus, &"Music")
	assert_eq(ambience.bus, &"Ambience")
	for player: AudioStreamPlayer in [music, ambience]:
		assert_true((player.stream as AudioStreamOggVorbis).loop, "%s en bucle" % player.name)
	assert_eq(audio.process_mode, Node.PROCESS_MODE_ALWAYS)
	get_tree().paused = true
	assert_true(music.can_process(), "en pausa sigue sonando (atenuada)")
	assert_true(ambience.can_process())


func test_phase_cue_only_from_phase_two() -> void:
	var audio: LevelAudio = LEVEL_AUDIO_SCENE.instantiate()
	audio.set_bus(_bus)
	add_child_autofree(audio)
	var cue: AudioStreamPlayer = audio.get_node("%PhaseCue")
	assert_eq(cue.bus, &"SFX")
	_bus.phase_changed.emit(1)
	assert_false(cue.playing, "fase 1: silencio")
	_bus.phase_changed.emit(2)
	assert_true(cue.playing, "fase 2: suena")
	assert_eq(cue.stream, MAP.get_cue(&"phase_up").stream)


## Extremo a extremo con PUL-070: `RoundManager` con las fases reales reenvía `phase_changed` al
## bus y `LevelAudio` toca `phase_up` al entrar en la fase 2 (no en la 1, que llega al arrancar).
func test_round_manager_phase_two_plays_phase_cue() -> void:
	assert_gte(ROUND_CONFIG.phases.size(), 2, "round_config.tres trae fases")
	var audio: LevelAudio = LEVEL_AUDIO_SCENE.instantiate()
	audio.set_bus(_bus)
	add_child_autofree(audio)
	var cue: AudioStreamPlayer = audio.get_node("%PhaseCue")
	var service: Node = OrderServiceScript.new()
	service.set_bus(_bus)
	add_child_autofree(service)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 11
	service.setup(CATALOG, rng, ROUND_CONFIG)
	var manager: Node = RoundManagerScript.new()
	manager.set_bus(_bus)
	manager.set_order_service(service)
	add_child_autofree(manager)
	manager.set_physics_process(false)
	watch_signals(_bus)
	manager.start_round(ROUND_CONFIG, [1, 2, 3, 4] as Array[int])
	assert_signal_emit_count(_bus, "phase_changed", 1)
	assert_false(cue.playing, "fase 1: silencio")
	var start: float = ROUND_CONFIG.phases[1].start_fraction * ROUND_CONFIG.duration
	var round_state: RoundState = manager.round_state
	round_state.advance(start - STEP)
	assert_false(cue.playing, "aún en fase 1")
	round_state.advance(STEP)
	assert_signal_emit_count(_bus, "phase_changed", 2)
	assert_eq(get_signal_parameters(_bus, "phase_changed", 1), [2])
	assert_true(cue.playing, "fase 2: suena phase_up")
	assert_eq(cue.stream, MAP.get_cue(&"phase_up").stream)


# --- AC2: un FX por señal ---


func test_ac2_pick_up_and_drop_one_sound_each() -> void:
	var item: Ingredient = _octopus()
	assert_true(_hold.pick_up(item))
	assert_eq(_cues("player"), [&"pick_up"])
	_hold.drop()
	assert_eq(_cues("player"), [&"pick_up", &"drop"])


func test_ac2_cut_one_sound_per_cut() -> void:
	var box: Box = _box()
	var octopus: Ingredient = _octopus(true)
	assert_true(_hold.pick_up(octopus))
	assert_true(box.interact(_actor))
	assert_true(box.interact(_actor))
	assert_eq(_cues("box"), [&"cut", &"cut"])


func test_ac2_pot_one_sound_on_cooking_start() -> void:
	var kitchen: CookingStation = _kitchen()
	assert_true(_hold.pick_up(_octopus()))
	_cues("player").clear()
	assert_true(kitchen.interact(_actor))
	assert_eq(_cues("kitchen"), [&"cook_start"])
	assert_eq(_cues("player"), [&"drop"], "soltar en la olla suena aparte (ADR-006 §4)")


func test_ac2_order_events_one_sound_each_only_for_own_slot() -> void:
	var stand: OrderStand = _stand()
	var feedback: FeedbackPlayer = stand.get_node("%Feedback")
	_bus.order_generated.emit(ActiveOrder.new(1, null, SLOT_ID + 1))
	_bus.order_completed.emit(ActiveOrder.new(1, null, SLOT_ID + 1), 0)
	_bus.order_expired.emit(ActiveOrder.new(1, null, SLOT_ID + 1), 0)
	feedback.advance(1.0)
	assert_eq(_cues("stand"), [], "otros puestos: nada")
	_bus.order_generated.emit(ActiveOrder.new(2, null, SLOT_ID))
	assert_eq(_cues("stand"), [], "nueva comanda espera su retardo")
	feedback.advance(0.4)
	assert_eq(_cues("stand"), [])
	feedback.advance(0.1)
	assert_eq(_cues("stand"), [&"order_new"])
	_bus.order_completed.emit(ActiveOrder.new(2, null, SLOT_ID), 0)
	_bus.order_generated.emit(ActiveOrder.new(3, null, SLOT_ID))
	_bus.order_expired.emit(ActiveOrder.new(3, null, SLOT_ID), 0)
	feedback.advance(1.0)
	assert_eq(_cues("stand"), [&"order_new", &"deliver_ok", &"order_expired", &"order_new"])


func test_ac2_delayed_cue_freezes_with_pause() -> void:
	var stand: OrderStand = _stand()
	var feedback: FeedbackPlayer = stand.get_node("%Feedback")
	_bus.order_generated.emit(ActiveOrder.new(2, null, SLOT_ID))
	assert_eq(feedback.pending_count(), 1)
	get_tree().paused = true
	assert_false(feedback.can_process(), "la cola no avanza en pausa")
	get_tree().paused = false
	await wait_seconds(0.7)
	assert_eq(_cues("stand"), [&"order_new"])


# --- AC5: sonido + respuesta visual ≥ 0,3 s ---


func test_ac5_pick_up_pops_the_item() -> void:
	var item: Ingredient = _octopus()
	assert_true(_hold.pick_up(item))
	var feedback: FeedbackPlayer = _player.get_node("%Feedback")
	assert_true(feedback.playing, "suena")
	assert_eq(feedback.stream, MAP.get_cue(&"pick_up").stream)
	assert_eq(_assert_visual(feedback, item, &"pick_up"), "pop")


func test_ac5_cooking_pops_pot_and_cooked_ingredient() -> void:
	var kitchen: CookingStation = _kitchen()
	var feedback: FeedbackPlayer = kitchen.get_node("%Feedback")
	var item: Ingredient = _octopus()
	assert_true(_hold.pick_up(item))
	assert_true(kitchen.interact(_actor))
	assert_eq(feedback.stream, MAP.get_cue(&"cook_start").stream)
	assert_eq(_assert_visual(feedback, kitchen, &"cook_start"), "pop")
	simulate(kitchen, roundi(item.data.cook_time / STEP) + 1, STEP)
	assert_true(item.is_cooked())
	assert_eq(_cues("kitchen"), [&"cook_start", &"cook_done"])
	assert_eq(feedback.stream, MAP.get_cue(&"cook_done").stream)
	assert_eq(_assert_visual(feedback, item, &"cook_done"), "pop")


func test_ac5_seasoning_pops_the_box() -> void:
	var box: Box = _box()
	box.fill = 1.0
	assert_eq(box.toggle_seasoning(SALT, true), SeasoningRules.Rejection.NONE)
	assert_eq(_cues("box"), [&"season"])
	var feedback: FeedbackPlayer = box.get_node("%Feedback")
	assert_eq(feedback.stream, MAP.get_cue(&"season").stream)
	assert_eq(_assert_visual(feedback, box, &"season"), "pop")
	box.toggle_seasoning(SALT, true)
	assert_eq(_cues("box"), [&"season", &"unseason"])


func test_ac5_correct_and_wrong_delivery_sound_and_look_different() -> void:
	var stand: OrderStand = _stand()
	var feedback: FeedbackPlayer = stand.get_node("%Feedback")
	_bus.order_completed.emit(ActiveOrder.new(1, null, SLOT_ID), 0)
	assert_eq(_cues("stand"), [&"deliver_ok"])
	var ok_stream: AudioStream = feedback.stream
	var ok_kind: String = _assert_visual(feedback, stand, &"deliver_ok")
	_bus.delivery_rejected.emit(SLOT_ID, 1, 0)
	assert_eq(_cues("stand"), [&"deliver_ok", &"deliver_error"])
	var error_kind: String = _assert_visual(feedback, stand, &"deliver_error")
	assert_ne(feedback.stream, ok_stream, "suenan distinto")
	assert_eq(ok_kind, "pop")
	assert_eq(error_kind, "shake", "se ven distinto")


func test_ac5_order_label_pops_on_new_and_shakes_on_expired() -> void:
	var stand: OrderStand = _stand()
	var feedback: FeedbackPlayer = stand.get_node("%Feedback")
	var label: Label3D = stand.get_node("%OrderLabel")
	_bus.order_generated.emit(ActiveOrder.new(4, null, SLOT_ID))
	feedback.advance(0.5)
	assert_eq(_assert_visual(feedback, label, &"order_new"), "pop")
	_bus.order_expired.emit(ActiveOrder.new(4, null, SLOT_ID), 0)
	assert_eq(_assert_visual(feedback, label, &"order_expired"), "shake")


func test_visual_freezes_with_pause() -> void:
	var stand: OrderStand = _stand()
	var feedback: FeedbackPlayer = stand.get_node("%Feedback")
	_bus.delivery_rejected.emit(SLOT_ID, 1, 0)
	var model: Node3D = stand.get_node("Model")
	get_tree().paused = true
	var before: Vector3 = model.position
	await wait_process_frames(5)
	assert_eq(model.position, before, "congelado en pausa")
	assert_not_null(feedback.get_visual_tween(stand))


func test_unknown_cue_does_nothing() -> void:
	var feedback: FeedbackPlayer = _player.get_node("%Feedback")
	feedback.play_cue(&"no_existe")
	assert_eq(_cues("player"), [])
	assert_false(feedback.playing)


func test_feedback_player_defaults() -> void:
	var feedback: FeedbackPlayer = _player.get_node("%Feedback")
	assert_eq(feedback.bus, &"SFX")
	assert_true(feedback.max_polyphony >= 2)
	assert_eq(feedback.map, MAP)


# --- AC3 ---


func test_ac3_director_ducks_music_and_ambience_on_pause_and_restores() -> void:
	var director: Node = AudioDirectorScript.new()
	director.set_bus(_bus)
	add_child_autofree(director)
	assert_eq(director.process_mode, Node.PROCESS_MODE_ALWAYS)
	var before: Dictionary[StringName, float] = _bus_db()
	_bus.pause_changed.emit(true)
	var paused: Dictionary[StringName, float] = _bus_db()
	assert_true(paused[&"Music"] <= before[&"Music"] - DUCK_MIN_DB, "Music baja")
	assert_true(paused[&"Ambience"] <= before[&"Ambience"] - DUCK_MIN_DB, "Ambience baja")
	assert_almost_eq(paused[&"SFX"], before[&"SFX"], 0.01, "SFX no cambia")
	_bus.pause_changed.emit(false)
	var resumed: Dictionary[StringName, float] = _bus_db()
	for bus: StringName in AudioMix.BUSES:
		assert_almost_eq(resumed[bus], before[bus], 0.01, "%s vuelve" % bus)


func test_ac3_real_pause_ducks_through_game_state() -> void:
	var director: Node = get_tree().root.get_node_or_null(^"AudioDirector")
	assert_not_null(director, "autoload AudioDirector")
	var before: Dictionary[StringName, float] = _bus_db()
	GameState.set_paused(true)
	var paused: Dictionary[StringName, float] = _bus_db()
	GameState.set_paused(false)
	assert_true(paused[&"Music"] <= before[&"Music"] - DUCK_MIN_DB)
	assert_true(paused[&"Ambience"] <= before[&"Ambience"] - DUCK_MIN_DB)
	assert_almost_eq(_bus_db()[&"Music"], before[&"Music"], 0.01)


func _bus_db() -> Dictionary[StringName, float]:
	var db: Dictionary[StringName, float] = {}
	for bus: StringName in AudioMix.BUSES:
		db[bus] = AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus))
	return db
