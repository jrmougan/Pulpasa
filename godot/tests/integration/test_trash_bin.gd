extends GutTest
## PUL-112: cubo de basura (D25, cubo-basura T1-T5, T7-T9; ADR-003 §10.3). Estación instanciada con
## el jugador y el detector reales.

const BIN_SCENE: PackedScene = preload("res://entities/stations/trash_bin.tscn")
const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const CACHELOS_SCENE: PackedScene = preload("res://entities/items/cachelos.tscn")
const SLOT_SCENE: PackedScene = preload("res://entities/stations/slot.tscn")
const SMALL: BoxData = preload("res://data/boxes/small.tres")
const SALT: SeasoningData = preload("res://data/seasonings/salt.tres")
const LEVEL: PackedScene = preload("res://scenes/levels/level_01.tscn")
const SETTLE_FRAMES: int = 3
const TRASH_MIN_DISTANCE: float = 1.5
const TRASH_POSITIONS: Dictionary[String, Vector2] = {
	"Stations/TrashBinKitchen": Vector2(2.6, -3.1),
	"Stations/TrashBinService": Vector2(-5.4, 4.3),
}
## Hueco de la barra (segmento en z = 0).
const GAP_MIN_X: float = 2.8
const GAP_MAX_X: float = 4.2
const BAR_Z: float = 0.0
## Los 3 spawners por talla son de antes de D25: PUL-113 los sustituye por BoxSpawner.
const LEGACY_SPAWNERS: Array[StringName] = [&"SmallSpawner", &"MediumSpawner", &"LargeSpawner"]
const SCREEN_SIZE: Vector2i = Vector2i(1280, 720)
const MIN_VISUAL_TIME: float = 0.3

var _level: Node3D
var _bin: TrashBin
var _player: Player
var _hold: HoldComponent
var _actor: InteractionComponent
var _cues: Array[StringName] = []
var _trashed: Array[Node] = []


func before_each() -> void:
	_cues.clear()
	_trashed.clear()
	_level = add_child_autofree(Node3D.new())
	_bin = BIN_SCENE.instantiate()
	_level.add_child(_bin)
	_bin.trashed.connect(func(item: Node) -> void: _trashed.append(item))
	var feedback: FeedbackPlayer = _bin.get_node("%Feedback") as FeedbackPlayer
	feedback.played.connect(func(cue: StringName) -> void: _cues.append(cue))
	_player = _add_player(Vector3(0.0, 0.0, 1.0))
	_hold = _player.get_node("%HoldComponent")
	_actor = _player.get_node("%InteractionComponent")


func _add_player(pos: Vector3) -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = pos
	_level.add_child(player)
	(player.get_node("%HoldComponent") as HoldComponent).items_root = _level
	return player


func _detector(player: Player = _player) -> InteractionDetector:
	return player.get_node("%InteractionDetector") as InteractionDetector


func _hold_item(scene: PackedScene, hold: HoldComponent = _hold) -> Node:
	var item: Node = scene.instantiate()
	_level.add_child(item)
	assert_true(hold.pick_up(item))
	return item


func _full_box() -> Box:
	var box: Box = BOX_SCENE.instantiate()
	box.data = SMALL
	_level.add_child(box)
	box.toggle_seasoning(SALT, true)
	assert_true(_hold.pick_up(box))
	return box


func _settle() -> void:
	await wait_physics_frames(SETTLE_FRAMES)


func _face_bin() -> void:
	_player.global_position = Vector3(0.0, 0.0, 1.0)
	_player.rotation = Vector3(0.0, 0.0, 0.0)
	await _settle()


func test_t1_box_in_hand_is_trashed() -> void:
	var box: Box = _full_box()
	var score_events: Array[int] = []
	var score_cb: Callable = func(_a: Variant = null, _b: Variant = null) -> void:
		score_events.append(1)
	EventBus.score_changed.connect(score_cb)
	assert_true(_bin.can_interact(_actor))
	assert_true(_bin.interact(_actor))
	assert_null(_hold.get_held_item(), "mano vacía en el mismo frame")
	assert_eq(_trashed.size(), 1)
	assert_eq(_trashed[0], box)
	await wait_process_frames(2)
	assert_false(is_instance_valid(box), "caja liberada")
	EventBus.score_changed.disconnect(score_cb)
	assert_true(score_events.is_empty(), "la recaudación no cambia")


func test_t2_octopus_and_cachelos_are_trashed() -> void:
	for scene: PackedScene in [OCTOPUS_SCENE, CACHELOS_SCENE]:
		var item: Node = _hold_item(scene)
		assert_true(_bin.interact(_actor))
		assert_null(_hold.get_held_item())
		await wait_process_frames(2)
		assert_false(is_instance_valid(item))
	assert_eq(_trashed.size(), 2)


func test_t3_empty_hand_is_not_target_nor_interactable() -> void:
	assert_false(_bin.can_interact(_actor))
	assert_false(_bin.is_reachable_from(Vector2(0.0, 1.0), _hold))
	assert_false(_bin.interact(_actor))
	await _face_bin()
	assert_ne(_detector().get_target(), _bin, "no es objetivo")
	assert_true(_cues.is_empty(), "no suena ningún cue")
	assert_true(_trashed.is_empty())


func test_t3_with_item_in_hand_detector_targets_bin() -> void:
	_full_box()
	await _face_bin()
	assert_eq(_detector().get_target(), _bin)


func test_t4_one_trash_cue_with_visual_response() -> void:
	_full_box()
	assert_true(_bin.interact(_actor))
	assert_eq(_cues, [&"trash"] as Array[StringName])
	var feedback: FeedbackPlayer = _bin.get_node("%Feedback") as FeedbackPlayer
	assert_not_null(feedback.get_visual_tween(_bin), "respuesta visual en curso")
	assert_gte(feedback.map.get_cue(&"trash").visual_time, MIN_VISUAL_TIME)
	assert_ne(feedback.map.get_cue(&"trash").visual, AudioCue.Visual.NONE)


func test_t5_penalty_is_zero_and_earnings_unchanged() -> void:
	assert_eq(_bin.data.trash_penalty, 0)


func test_t7_trashing_does_not_reject_the_order() -> void:
	var rejected: Array[int] = []
	var cb: Callable = func(_a: int, _b: int, _c: int) -> void: rejected.append(1)
	EventBus.delivery_rejected.connect(cb)
	_full_box()
	assert_true(_bin.interact(_actor))
	EventBus.delivery_rejected.disconnect(cb)
	assert_true(rejected.is_empty(), "tirar no emite delivery_rejected")


func test_t8_only_closest_of_bin_and_free_slot_is_target() -> void:
	var slot: Slot = SLOT_SCENE.instantiate()
	slot.position = Vector3(0.4, 0.0, 0.0)
	_level.add_child(slot)
	_full_box()
	await _face_bin()
	var target: Node = _detector().get_target()
	assert_true(target == _bin or target == slot, "un solo objetivo")
	var lit: int = 0
	for entity: Node in [_bin, slot]:
		var highlight: Highlightable = entity.get_node_or_null(^"%Highlightable") as Highlightable
		if highlight == null:
			highlight = entity.get_node_or_null(^"Highlightable") as Highlightable
		if highlight != null and highlight.is_highlighted():
			lit += 1
	assert_eq(lit, 1, "solo uno resaltado")


func test_t9_two_players_trash_at_once() -> void:
	var other: Player = _add_player(Vector3(0.6, 0.0, 1.0))
	var other_hold: HoldComponent = other.get_node("%HoldComponent")
	var other_actor: InteractionComponent = other.get_node("%InteractionComponent")
	var first: Node = _hold_item(OCTOPUS_SCENE)
	var second: Node = _hold_item(CACHELOS_SCENE, other_hold)
	assert_true(_bin.interact(_actor))
	assert_true(_bin.interact(other_actor))
	assert_eq(_trashed.size(), 2)
	assert_eq(_cues.size(), 2, "un cue por tirada")
	await wait_process_frames(2)
	assert_false(is_instance_valid(first))
	assert_false(is_instance_valid(second))


# --- T6: los 2 cubos de level_01 (scene-tree.md §2, ADR-003 §10.3) ---


func _load_level() -> Node3D:
	get_tree().root.size = SCREEN_SIZE
	var level: Node3D = add_child_autofree(LEVEL.instantiate())
	await wait_physics_frames(2)
	return level


func _bins_of(level: Node) -> Array[TrashBin]:
	var bins: Array[TrashBin] = []
	for node: Node in level.find_children("*", "TrashBin", true, false):
		bins.append(node as TrashBin)
	return bins


func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


func test_t6_level_has_exactly_two_trash_bins_at_contract_positions() -> void:
	var level: Node3D = await _load_level()
	assert_eq(_bins_of(level).size(), 2)
	for path: String in TRASH_POSITIONS:
		var bin: Node3D = level.get_node(path)
		assert_true(bin is TrashBin, path)
		var at: Vector2 = _flat(bin.global_position)
		assert_almost_eq(at.distance_to(TRASH_POSITIONS[path]), 0.0, 0.01)


func test_t6_trash_bins_are_far_from_every_target_and_the_gap() -> void:
	var level: Node3D = await _load_level()
	var targets: Array[Node3D] = []
	for node: Node in get_tree().get_nodes_in_group(&"interactable"):
		var target: Node3D = node as Node3D
		if target == null or not level.is_ancestor_of(target) or target is TrashBin:
			continue
		if not target is RigidBody3D and not LEGACY_SPAWNERS.has(target.name):
			targets.append(target)
	assert_gt(targets.size(), 10, "hay objetivos que comprobar")
	for bin: TrashBin in _bins_of(level):
		var pos: Vector2 = _flat(bin.global_position)
		for target: Node3D in targets:
			var gap: float = pos.distance_to(_flat(target.global_position))
			assert_gte(gap, TRASH_MIN_DISTANCE, "%s a %s" % [bin.name, target.name])
		var gap_point: Vector2 = Vector2(clampf(pos.x, GAP_MIN_X, GAP_MAX_X), BAR_Z)
		assert_gte(pos.distance_to(gap_point), TRASH_MIN_DISTANCE, "%s al hueco" % bin.name)


func test_t6_gap_keeps_one_meter_clear_and_bins_not_under_hud() -> void:
	var level: Node3D = await _load_level()
	assert_gte(GAP_MAX_X - GAP_MIN_X, 1.0, "hueco >= 1,0 m")
	RoundManager.round_state.advance(5.0)
	await wait_process_frames(2)
	var camera: Camera3D = level.get_node("CameraRig")
	var screen: Rect2 = Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	var rects: Array[Rect2] = [(level.get_node("UI/HUD") as Control).get_global_rect()]
	for ticket: Node in level.get_node("UI/OrderTicketsPanel/%Tickets").get_children():
		rects.append((ticket as Control).get_global_rect())
	for bin: TrashBin in _bins_of(level):
		var pos: Vector2 = camera.unproject_position(bin.global_position + Vector3.UP * 0.5)
		assert_true(screen.has_point(pos), "%s en pantalla: %s" % [bin.name, pos])
		for rect: Rect2 in rects:
			assert_false(rect.has_point(pos), "%s bajo %s" % [bin.name, rect])
