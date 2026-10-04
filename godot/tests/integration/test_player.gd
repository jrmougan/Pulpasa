extends GutTest
## PUL-012 AC1/AC2: movimiento del jugador relativo a la cámara, bloqueado fuera de ronda.
## PUL-035 AC1/AC3/AC4: dos personajes con CharacterSwitcher; el no controlado no se mueve ni
## suelta lo que lleva, y `%ActiveIndicator` sigue a `controlled_by`.
## El tiempo avanza en ticks reales de física (move_and_slide fuera de un tick usaría el delta
## de proceso); la distancia esperada se calcula con los ticks transcurridos.

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const CAMERA_SCENE: PackedScene = preload("res://entities/camera/camera_rig.tscn")
const SWITCHER_SCENE: PackedScene = preload("res://entities/player/character_switcher.tscn")
const ITEM_SCENE: PackedScene = preload("res://entities/player/sandbox/sandbox_item.tscn")
const EventBusScript: GDScript = preload("res://autoload/event_bus.gd")
const TICK: float = 1.0 / 60.0
const TOLERANCE: float = 0.05

var _bus: Node
var _camera: Camera3D
var _level: Node3D
var _player: Player
var _switcher: CharacterSwitcher
var _elapsed: float = 0.0


func before_each() -> void:
	_level = add_child_autofree(Node3D.new())
	_bus = autofree(EventBusScript.new())
	_camera = CAMERA_SCENE.instantiate()
	_level.add_child(_camera)
	_player = _add_player(1, Vector3.ZERO)


func after_each() -> void:
	Input.action_release(&"p1_move_right")
	Input.action_release(&"p2_move_right")


func _add_player(index: int, at: Vector3) -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	player.set_bus(_bus)
	player.camera = _camera
	player.position = at
	_level.add_child(player)
	_control_of(player).player_index = index
	return player


func _control_of(player: Player) -> ControlComponent:
	return player.get_node(^"%Control") as ControlComponent


func _indicator_of(player: Player) -> MeshInstance3D:
	return player.get_node(^"%ActiveIndicator") as MeshInstance3D


## Segundo personaje y switcher en `mode`; arranca la ronda (el switcher asigna el control).
func _start_two_characters(mode: GameMode.Mode) -> Player:
	var second: Player = _add_player(2, Vector3(3.0, 0.0, 0.0))
	_switcher = SWITCHER_SCENE.instantiate()
	_switcher.set_bus(_bus)
	_switcher.set_mode(mode)
	_switcher.characters = [_control_of(_player), _control_of(second)]
	_level.add_child(_switcher)
	_bus.round_started.emit(180.0)
	return second


## Espera `seconds` en ticks de física y devuelve los segundos simulados de verdad.
func _simulate(seconds: float) -> float:
	var start: int = Engine.get_physics_frames()
	await wait_physics_frames(roundi(seconds / TICK))
	return (Engine.get_physics_frames() - start) * TICK


func _horizontal(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


## Derecha de pantalla proyectada en el suelo.
func _screen_right() -> Vector3:
	return _horizontal(_camera.global_basis.x).normalized()


func _move_right_for_one_second() -> Vector3:
	var start: Vector3 = _player.global_position
	Input.action_press(&"p1_move_right")
	_elapsed = await _simulate(1.0)
	return _horizontal(_player.global_position - start)


func test_ac1_move_right_one_second_travels_five_meters() -> void:
	_bus.round_started.emit(180.0)
	var moved: Vector3 = await _move_right_for_one_second()
	assert_almost_eq(_player.config.speed, 5.0, 0.001, "PlayerConfig.speed")
	assert_almost_eq(_elapsed, 1.0, 1.0 * TOLERANCE, "segundos simulados")
	assert_almost_eq(moved.length(), 5.0, 5.0 * TOLERANCE)


func test_ac1_move_right_goes_to_screen_right() -> void:
	_bus.round_started.emit(180.0)
	var moved: Vector3 = await _move_right_for_one_second()
	assert_gt(moved.normalized().dot(_screen_right()), 0.999)


func test_ac1_move_right_follows_camera_yaw() -> void:
	_camera.rotate_y(PI / 2.0)
	_bus.round_started.emit(180.0)
	var moved: Vector3 = await _move_right_for_one_second()
	assert_gt(moved.normalized().dot(_screen_right()), 0.999)
	assert_almost_eq(moved.length(), 5.0, 5.0 * TOLERANCE)


func test_ac1_player_faces_movement_direction() -> void:
	_bus.round_started.emit(180.0)
	await _move_right_for_one_second()
	var facing: Vector3 = _horizontal(-_player.global_basis.z).normalized()
	assert_gt(facing.dot(_screen_right()), 0.999)


func test_ac1_turn_is_smooth_not_instant() -> void:
	_bus.round_started.emit(180.0)
	Input.action_press(&"p1_move_right")
	await _simulate(TICK)
	var facing: Vector3 = _horizontal(-_player.global_basis.z).normalized()
	assert_lt(facing.dot(_screen_right()), 0.999)


func test_ac1_exposes_speed_and_is_holding() -> void:
	_bus.round_started.emit(180.0)
	assert_eq(_player.speed, 0.0)
	assert_false(_player.is_holding)
	Input.action_press(&"p1_move_right")
	await _simulate(TICK)
	assert_almost_eq(_player.speed, 5.0, 0.001)


func test_ac2_no_movement_before_round_started() -> void:
	var moved: Vector3 = await _move_right_for_one_second()
	assert_eq(moved, Vector3.ZERO)
	assert_eq(_player.speed, 0.0)


func test_ac2_no_movement_after_round_finished() -> void:
	_bus.round_started.emit(180.0)
	_bus.round_finished.emit(RoundResult.new())
	var moved: Vector3 = await _move_right_for_one_second()
	assert_eq(moved, Vector3.ZERO)


func test_ac2_round_finished_stops_player_mid_movement() -> void:
	_bus.round_started.emit(180.0)
	Input.action_press(&"p1_move_right")
	await _simulate(0.5)
	_bus.round_finished.emit(RoundResult.new())
	var stop: Vector3 = _player.global_position
	await _simulate(0.5)
	assert_eq(_player.global_position, stop)
	assert_eq(_player.speed, 0.0)


func test_pul035_ac1_coop_p1_input_moves_only_character_one() -> void:
	var second: Player = _start_two_characters(GameMode.Mode.COOP_2P)
	assert_eq(_control_of(second).controlled_by, 2)
	var start_second: Vector3 = second.global_position
	var moved: Vector3 = await _move_right_for_one_second()
	assert_almost_eq(moved.length(), 5.0, 5.0 * TOLERANCE)
	assert_eq(_horizontal(second.global_position - start_second), Vector3.ZERO)
	assert_eq(second.speed, 0.0)


func test_pul035_ac1_coop_p2_input_moves_only_character_two() -> void:
	var second: Player = _start_two_characters(GameMode.Mode.COOP_2P)
	var start_first: Vector3 = _player.global_position
	var start_second: Vector3 = second.global_position
	Input.action_press(&"p2_move_right")
	await _simulate(0.5)
	assert_gt(_horizontal(second.global_position - start_second).length(), 2.0)
	assert_eq(_horizontal(_player.global_position - start_first), Vector3.ZERO)


func test_pul035_ac3_uncontrolled_stays_still_for_five_seconds() -> void:
	var second: Player = _start_two_characters(GameMode.Mode.SINGLE)
	assert_eq(_control_of(second).controlled_by, 0)
	var start: Vector3 = second.global_position
	Input.action_press(&"p1_move_right")
	var max_speed: float = 0.0
	for i: int in 50:
		await _simulate(0.1)
		max_speed = maxf(max_speed, _horizontal(second.velocity).length())
	assert_eq(max_speed, 0.0)
	assert_eq(_horizontal(second.global_position - start), Vector3.ZERO)
	assert_gt(_horizontal(_player.global_position).length(), 1.0, "el controlado sí se mueve")


func test_pul035_ac3_switched_out_character_stops_mid_movement() -> void:
	var second: Player = _start_two_characters(GameMode.Mode.SINGLE)
	Input.action_press(&"p1_move_right")
	await _simulate(0.25)
	assert_true(_switcher.switch_pressed())
	await _simulate(TICK)
	var stop: Vector3 = _player.global_position
	await _simulate(0.5)
	assert_eq(_player.global_position, stop)
	assert_eq(_player.speed, 0.0)
	assert_gt(second.speed, 0.0, "el nuevo se mueve en el siguiente tick")


func test_pul035_ac4_uncontrolled_keeps_held_item() -> void:
	var second: Player = _start_two_characters(GameMode.Mode.SINGLE)
	var item: Node3D = ITEM_SCENE.instantiate()
	_level.add_child(item)
	var hold: HoldComponent = _player.get_node(^"%HoldComponent") as HoldComponent
	assert_true(hold.pick_up(item))
	assert_true(_switcher.switch_pressed())
	assert_eq(_control_of(second).controlled_by, 1)
	var interaction: InteractionComponent = (
		_player.get_node(^"%InteractionComponent") as InteractionComponent
	)
	var press: InputEventAction = InputEventAction.new()
	press.action = &"p1_interact"
	press.pressed = true
	interaction._unhandled_input(press)
	await _simulate(0.5)
	assert_eq(hold.get_held_item(), item)
	assert_true(_player.is_holding)


func test_pul035_indicator_follows_controlled_by() -> void:
	var second: Player = _start_two_characters(GameMode.Mode.COOP_2P)
	var first_ring: MeshInstance3D = _indicator_of(_player)
	var second_ring: MeshInstance3D = _indicator_of(second)
	assert_true(first_ring.visible)
	assert_true(second_ring.visible)
	assert_ne(first_ring.material_override, second_ring.material_override, "J1 y J2 distintos")
	_control_of(second).controlled_by = 0
	assert_false(second_ring.visible)
	_control_of(second).controlled_by = 1
	assert_true(second_ring.visible)
	assert_eq(second_ring.material_override, first_ring.material_override)
