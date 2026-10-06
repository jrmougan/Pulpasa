extends GutTest
## PUL-044: personaje de Blender en `player.tscn`. `Model` es `cook.glb` con los clips de la
## biblia de arte (§2.4, §4: Idle en bucle de 1–2 s, Cut corto, D13); `%AnimationTree` cambia de
## estado por `speed` e `is_holding`, toca Pick al coger y Cut en cada corte; la variante J1/J2
## sale de `player_index`; `%HoldPoint` está en `Anchor_Hold` y no entra en la cápsula.

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const CAMERA_SCENE: PackedScene = preload("res://entities/camera/camera_rig.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const ITEM_SCENE: PackedScene = preload("res://entities/player/sandbox/sandbox_item.tscn")
const EventBusScript: GDScript = preload("res://autoload/event_bus.gd")
const CLIPS: Array[StringName] = [&"Idle", &"Walk", &"Pick", &"WalkWhileHolding", &"Cut"]
const TICK: float = 1.0 / 60.0

var _bus: Node
var _level: Node3D
var _player: Player
var _anim: PlayerAnimation


func before_each() -> void:
	_level = add_child_autofree(Node3D.new())
	_bus = autofree(EventBusScript.new())
	var camera: Node3D = CAMERA_SCENE.instantiate()
	_level.add_child(camera)
	_player = PLAYER_SCENE.instantiate()
	_player.set_bus(_bus)
	_level.add_child(_player)
	_anim = _player.get_node(^"%AnimationTree") as PlayerAnimation


func after_each() -> void:
	Input.action_release(&"p1_move_right")


func _model() -> Node3D:
	return _player.get_node(^"Model") as Node3D


func _anim_player() -> AnimationPlayer:
	return _model().get_node(^"AnimationPlayer") as AnimationPlayer


func _mesh(mesh_name: String) -> MeshInstance3D:
	return _model().find_child(mesh_name, true, false) as MeshInstance3D


func _hold() -> HoldComponent:
	return _player.get_node(^"%HoldComponent") as HoldComponent


func _wait(seconds: float) -> void:
	await wait_physics_frames(maxi(1, roundi(seconds / TICK)))


func test_model_is_cook_glb_with_skeleton() -> void:
	assert_eq(_model().scene_file_path, "res://assets/models/characters/cook/cook.glb")
	assert_not_null(_model().find_child("Skeleton3D", true, false))
	assert_not_null(_model().find_child("Anchor_Hold", true, false))


func test_clips_exist_with_bible_lengths() -> void:
	var player: AnimationPlayer = _anim_player()
	for clip: StringName in CLIPS + [&"IdleHolding"]:
		assert_true(player.has_animation(clip), "falta el clip %s" % clip)
	var idle: Animation = player.get_animation(&"Idle")
	assert_between(idle.length, 1.0, 2.0, "Idle en bucle de 1–2 s")
	for loop: StringName in [&"Idle", &"IdleHolding", &"Walk", &"WalkWhileHolding"]:
		assert_eq(player.get_animation(loop).loop_mode, Animation.LOOP_LINEAR, "%s en bucle" % loop)
	assert_lte(player.get_animation(&"Cut").length, 0.4, "Cut con ciclo corto (D13)")
	assert_eq(player.get_animation(&"Pick").loop_mode, Animation.LOOP_NONE)


func test_tree_uses_model_animation_player() -> void:
	assert_true(_anim.active)
	assert_eq(_anim.get_node(_anim.anim_player), _anim_player())
	assert_true(_anim.tree_root is AnimationNodeStateMachine)


func test_starts_idle() -> void:
	await _wait(0.1)
	assert_eq(_anim.get_state(), &"Idle")


func test_walks_when_moving_and_back_to_idle() -> void:
	_bus.round_started.emit(180.0)
	Input.action_press(&"p1_move_right")
	await _wait(0.2)
	assert_eq(_anim.get_state(), &"Walk")
	Input.action_release(&"p1_move_right")
	await _wait(0.2)
	assert_eq(_anim.get_state(), &"Idle")


func test_pick_then_holding_states() -> void:
	_bus.round_started.emit(180.0)
	var item: Node3D = ITEM_SCENE.instantiate()
	_level.add_child(item)
	assert_true(_hold().pick_up(item))
	await _wait(TICK)
	assert_eq(_anim.get_state(), &"Pick")
	await _wait(0.6)
	assert_eq(_anim.get_state(), &"IdleHolding")
	Input.action_press(&"p1_move_right")
	await _wait(0.2)
	assert_eq(_anim.get_state(), &"WalkWhileHolding")
	Input.action_release(&"p1_move_right")
	_hold().drop()
	await _wait(0.3)
	assert_eq(_anim.get_state(), &"Idle")


func test_each_cut_of_held_octopus_plays_cut() -> void:
	var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
	_level.add_child(octopus)
	assert_true(_hold().pick_up(octopus))
	await _wait(0.6)
	assert_eq(_anim.get_state(), &"IdleHolding")
	octopus.take(0.1)
	await _wait(TICK)
	assert_eq(_anim.get_state(), &"Cut")
	await _wait(0.5)
	assert_eq(_anim.get_state(), &"IdleHolding")
	octopus.take(0.1)
	await _wait(TICK)
	assert_eq(_anim.get_state(), &"Cut", "cada pulsación vuelve a cortar")


func test_dropped_octopus_no_longer_triggers_cut() -> void:
	var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
	_level.add_child(octopus)
	_hold().pick_up(octopus)
	_hold().drop()
	await _wait(0.4)
	octopus.take(0.1)
	await _wait(TICK)
	assert_ne(_anim.get_state(), &"Cut")


func test_variant_follows_player_index() -> void:
	await _wait(TICK)
	assert_eq(_anim.get_variant(), 1)
	assert_true(_mesh("cook_body_j1").visible)
	assert_true(_mesh("cook_hat_j1").visible)
	assert_false(_mesh("cook_body_j2").visible)
	assert_false(_mesh("cook_hat_j2").visible)
	(_player.get_node(^"%Control") as ControlComponent).player_index = 2
	await _wait(TICK)
	assert_eq(_anim.get_variant(), 2)
	assert_false(_mesh("cook_body_j1").visible)
	assert_true(_mesh("cook_body_j2").visible)
	assert_true(_mesh("cook_hat_j2").visible)


func test_hold_point_on_anchor_hold_outside_capsule() -> void:
	var anchor: Node3D = _model().find_child("Anchor_Hold", true, false) as Node3D
	var hold_point: Node3D = _player.get_node(^"%HoldPoint") as Node3D
	assert_lt(hold_point.global_position.distance_to(anchor.global_position), 0.01)
	var shape: CapsuleShape3D = (_player.get_node(^"CollisionShape3D") as CollisionShape3D).shape
	# El pulpo ×1,4 (≈ 0,63 m) centrado en el punto no debe meterse en la cápsula (nota de PUL-045).
	assert_gt(-hold_point.position.z - 0.63 / 2.0, shape.radius - 0.02)


func test_hold_point_centred_at_chest_height() -> void:
	var hold_point: Node3D = _player.get_node(^"%HoldPoint") as Node3D
	assert_almost_eq(hold_point.position.x, 0.0, 0.001)
	assert_between(hold_point.position.y, 1.0, 1.3)


func test_indicator_colours_match_variant_palette() -> void:
	var colours: Array[Color] = []
	for material: Material in _player.indicator_materials:
		colours.append((material as StandardMaterial3D).albedo_color)
	assert_eq(colours.size(), 2)
	assert_eq(colours[0].to_html(false), "2f6fb5", "J1 azul (art-bible §2.6)")
	assert_eq(colours[1].to_html(false), "e0a02e", "J2 ámbar (art-bible §2.6)")


func test_active_indicator_still_visible() -> void:
	var indicator: GeometryInstance3D = _player.get_node(^"%ActiveIndicator") as GeometryInstance3D
	assert_true(indicator.visible)
	assert_true(indicator.is_visible_in_tree())
