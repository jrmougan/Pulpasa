extends RefCounted
## Ayudante de los tests que juegan `level_01.tscn` con el teclado (PUL-039, PUL-061): mueve al
## personaje activo con las teclas de su jugador, rodea la barra de la planta B por el hueco de la
## columna 14 y pulsa interactuar delante de un objetivo con el detector real. Nunca llama a
## `interact()` ni publica `target_changed` a mano.

## Distancia a la que se considera alcanzado un punto del camino (m).
const ARRIVED: float = 0.12
## Frames máximos para recorrer un tramo.
const WALK_FRAMES: int = 400
## Frames empujando hacia un objetivo para quedar de cara a él.
const FACE_FRAMES: int = 8
## Barra de la fila 4 (planta B): z de su centro, medio fondo y paso por el hueco de la col. 14.
const BAR_Z: float = 0.0
const BAR_HALF_DEPTH: float = 0.5
const GAP_X: float = 7.7
## Distancia a la barra de los puntos de paso a cada lado del hueco (m).
const GAP_CLEARANCE: float = 0.9
## Puntos de uso de la estación de condimentos (PUL-061): distancia al centro del mostrador en z.
## Con una caja en la bandeja, mirar de frente a Sal o Pimentón picante hace que el detector elija
## la caja (prioridad de cogibles, `InteractionScoring`); se usan en diagonal, apartándose
## `DISPENSER_SIDESTEP` m hacia la bandeja (medido en
## `docs/evidence/PUL-061/sonda-detector-dispensadores.txt`). Pendiente de PUL-063.
const STATION_ACCESS: float = 1.0
const DISPENSER_SIDESTEP: float = 0.7
## Teclas de cada jugador: arriba, abajo, izquierda, derecha, interactuar.
const KEYS: Dictionary[int, Array] = {
	1: [KEY_W, KEY_S, KEY_A, KEY_D, KEY_E],
	2: [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_ENTER],
}

## Personaje que se mueve (el que controla `player_index`).
var character: Player
## Jugador cuyas teclas se pulsan (1 o 2).
var player_index: int = 1

var _tree: SceneTree
## Teclas pulsadas ahora (physical keycode → true).
var _down: Dictionary = {}


func _init(tree: SceneTree, moved: Player, index: int = 1) -> void:
	_tree = tree
	character = moved
	player_index = index


static func xz(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


## Punto desde el que se usa una pieza de la estación por un lado (−1 pase, +1 condimentar).
static func station_stand(part: Vector2, station_z: float, side: float) -> Vector2:
	return Vector2(part.x, station_z + side * STATION_ACCESS)


## Punto desde el que se pulsa un dispensador (lado de condimentar), en diagonal: ver
## `DISPENSER_SIDESTEP`.
static func dispenser_stand(dispenser: Vector2, tray: Vector2, station_z: float) -> Vector2:
	var away: float = signf(dispenser.x - tray.x)
	return Vector2(dispenser.x - away * DISPENSER_SIDESTEP, station_z + STATION_ACCESS)


## −1 si `point` está en la cocina (detrás de la barra), +1 en el servicio.
static func side_of(point: Vector2) -> float:
	return -1.0 if point.y < BAR_Z else 1.0


func detector() -> InteractionDetector:
	return character.get_node("%InteractionDetector") as InteractionDetector


func holder() -> Holder:
	return character.get_node("%HoldComponent") as Holder


func position() -> Vector2:
	return xz(character.global_position)


## Anda hasta `target`; si está al otro lado de la barra, pasa por el hueco.
func walk_to(target: Vector2) -> void:
	var here: float = side_of(position())
	var there: float = side_of(target)
	if here != there:
		var offset: float = BAR_HALF_DEPTH + GAP_CLEARANCE
		await _walk_straight(Vector2(GAP_X, BAR_Z + here * offset))
		await _walk_straight(Vector2(GAP_X, BAR_Z + there * offset))
	await _walk_straight(target)


## Anda hasta `stand`, se gira hacia `aim` (empujando `face_frames`) y pulsa interactuar. Devuelve
## el objetivo que tenía el detector justo antes de pulsar.
func use(aim: Vector2, stand: Vector2, face_frames: int = FACE_FRAMES) -> Node:
	await walk_to(stand)
	await push_towards(aim, face_frames)
	var target: Node = detector().get_target()
	await tap_interact()
	return target


## Empuja hacia `target` unos frames para girarse hacia él.
func face(target: Vector2) -> void:
	await push_towards(target, FACE_FRAMES)


func push_towards(target: Vector2, frames: int) -> void:
	for _i: int in frames:
		_hold_keys(target - position(), 0.05)
		await _tree.physics_frame
	await release_keys()
	await _frames(2)


## Pulsa y suelta interactuar como el teclado (llega a `_unhandled_input`).
func tap_interact() -> void:
	await tap(KEYS[player_index][4])


func tap(keycode: Key) -> void:
	Input.parse_input_event(_key_event(keycode, true))
	Input.flush_buffered_events()
	await _frames(2)
	Input.parse_input_event(_key_event(keycode, false))
	Input.flush_buffered_events()
	await _frames(2)


func release_keys() -> void:
	for keycode: Key in KEYS[player_index].slice(0, 4):
		_set_key(keycode, false)
	Input.flush_buffered_events()
	await _tree.physics_frame


func _walk_straight(target: Vector2) -> void:
	for _i: int in WALK_FRAMES:
		var delta: Vector2 = target - position()
		if delta.length() <= ARRIVED:
			break
		_hold_keys(delta, ARRIVED * 0.5)
		await _tree.physics_frame
	await release_keys()
	await _tree.physics_frame


## Pulsa las teclas de dirección de `delta` (ejes con |valor| > `dead`) y suelta las demás.
func _hold_keys(delta: Vector2, dead: float) -> void:
	var dir: Vector2 = delta.normalized()
	var limit: float = dead / maxf(delta.length(), 0.0001)
	var keys: Array = KEYS[player_index]
	_set_key(keys[3], dir.x > limit and dir.x > 0.38)
	_set_key(keys[2], dir.x < -limit and dir.x < -0.38)
	_set_key(keys[1], dir.y > limit and dir.y > 0.38)
	_set_key(keys[0], dir.y < -limit and dir.y < -0.38)
	Input.flush_buffered_events()


func _set_key(keycode: Key, pressed: bool) -> void:
	if bool(_down.get(keycode, false)) == pressed:
		return
	_down[keycode] = pressed
	Input.parse_input_event(_key_event(keycode, pressed))


func _key_event(keycode: Key, pressed: bool) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = pressed
	return event


func _frames(count: int) -> void:
	for _i: int in count:
		await _tree.physics_frame
