extends GutTest
## PUL-012 AC1/AC2: movimiento del jugador relativo a la cámara, bloqueado fuera de ronda.
## El tiempo avanza en ticks reales de física (move_and_slide fuera de un tick usaría el delta
## de proceso); la distancia esperada se calcula con los ticks transcurridos.

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const CAMERA_SCENE: PackedScene = preload("res://entities/camera/camera_rig.tscn")
const EventBusScript: GDScript = preload("res://autoload/event_bus.gd")
const TICK: float = 1.0 / 60.0
const TOLERANCE: float = 0.05

var _bus: Node
var _camera: Camera3D
var _player: Player
var _elapsed: float = 0.0


func before_each() -> void:
	var level: Node3D = add_child_autofree(Node3D.new())
	_bus = autofree(EventBusScript.new())
	_camera = CAMERA_SCENE.instantiate()
	level.add_child(_camera)
	_player = PLAYER_SCENE.instantiate()
	_player.set_bus(_bus)
	_player.camera = _camera
	level.add_child(_player)


func after_each() -> void:
	Input.action_release(&"p1_move_right")


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
