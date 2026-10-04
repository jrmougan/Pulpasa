class_name DeviceAssignment
extends RefCounted
## Reparto de mandos entre jugadores (ADR-004 §2). Regla pura: sin árbol ni `Input`.
## Una asignación es un `Array[int]` con un valor por jugador (índice 0 = J1): un id de mando
## (>= 0), `ANY` (cualquier mando, solo J1 en SINGLE) o `NONE` (solo teclado).

## Cualquier mando (= `device` comodín de Godot). Solo J1 en `SINGLE`.
const ANY: int = -1
## Ningún mando: el jugador solo usa su teclado.
const NONE: int = -2
const PLAYER_COUNT: int = 2


## Reparto al empezar un nivel según el modo y los mandos conectados (en su orden).
static func initial(mode: GameMode.Mode, joypads: Array[int]) -> Array[int]:
	if mode == GameMode.Mode.SINGLE:
		return [ANY, NONE]
	match joypads.size():
		0:
			return [NONE, NONE]
		1:
			return [NONE, joypads[0]]
		_:
			return [joypads[0], joypads[1]]


## Jugador (1..n) que tiene asignado exactamente ese mando; 0 si ninguno.
static func player_with(devices: Array[int], device: int) -> int:
	if device < 0:
		return 0
	var index: int = devices.find(device)
	return index + 1 if index >= 0 else 0


## Jugador afectado por la desconexión de `device`; 0 si no afecta a nadie.
## `remaining` son los mandos que siguen conectados. J1 con `ANY` (SINGLE) solo se ve afectado
## cuando ya no queda ningún mando; conserva `ANY` (al volver a conectar, ya lo acepta).
static func on_disconnected(devices: Array[int], device: int, remaining: Array[int]) -> int:
	var player: int = player_with(devices, device)
	if player > 0:
		return player
	var any_index: int = devices.find(ANY)
	if any_index >= 0 and remaining.is_empty():
		return any_index + 1
	return 0


## Jugador (1..n) que recibe un mando recién conectado; 0 si queda sin asignar.
## `lost_by`: id de mando perdido -> jugador que lo tenía.
## `SINGLE`: si J1 (con `ANY`) se quedó sin mandos, cualquier mando lo recupera (sigue en `ANY`).
## `COOP_2P`: al que lo perdió si sigue en `NONE`; si no, al primer jugador en `NONE`.
## Un id nunca se asigna a dos jugadores.
static func on_connected(
	devices: Array[int], mode: GameMode.Mode, device: int, lost_by: Dictionary
) -> int:
	if device < 0:
		return 0
	if mode == GameMode.Mode.SINGLE:
		for player: int in lost_by.values():
			if player > 0 and player <= devices.size() and devices[player - 1] == ANY:
				return player
		return 0
	if mode != GameMode.Mode.COOP_2P or player_with(devices, device) > 0:
		return 0
	var previous: int = lost_by.get(device, 0)
	if previous > 0 and previous <= devices.size() and devices[previous - 1] == NONE:
		return previous
	var free_index: int = devices.find(NONE)
	return free_index + 1 if free_index >= 0 else 0
