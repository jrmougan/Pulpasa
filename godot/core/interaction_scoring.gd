class_name InteractionScoring
extends RefCounted
## Elección de objetivo de interacción (InteractionDetector.cs). Pura, sobre el plano del suelo.
##
## La DIRECCIÓN (cono) usa el plano del suelo (`Vector2`); la DISTANCIA es un escalar que
## calcula el adaptador específico: en Unity es 3D desde la posición del jugador + 0,8 m de
## altura hasta el cuerpo (`InteractionDetector.cs:37-49`). Esa altura 0,8 la aporta el
## adaptador (irá a `PlayerConfig` en PUL-015); aquí no se conoce.
##
## Los números (cono, distancia mínima, bonus de cocina) llegan por parámetro desde el
## detector (que los lee de `PlayerConfig`). El detector resuelve antes los casos de slot
## (slot vacío, slot ocupado con la mano llena) y construye un `Candidate` por cuerpo.
##
## Prioridad de cogible (PUL-063): con la mano vacía, un cogible suelto gana a cualquier
## interactuable del cono, como en Unity. Un objeto **guardado en un slot** (`in_slot`) no tiene esa
## prioridad: compite por puntuación con los interactuables. Así, en la estación de condimentos, la
## caja de la bandeja no roba el objetivo al dispensador que el jugador tiene delante, y un objeto
## en un pasaplatos no se lo roba a lo que está mejor apuntado. Con la mano llena no cambia nada.

## Mínimo de distancia en `score` para no dividir por cero (`Mathf.Max(dist, 0.1f)`).
const MIN_SCORE_DISTANCE: float = 0.1


## Un cuerpo candidato, ya proyectado al plano del suelo.
class Candidate:
	extends RefCounted
	## Posición en el plano del suelo (solo para la dirección del cono).
	var position: Vector2
	## Distancia 3D desde el punto de mira del jugador (la calcula el adaptador).
	var distance: float
	var is_pickable: bool
	var is_interactable: bool
	## Equivale al tag `Kitchen` del prototipo.
	var is_kitchen: bool
	## Objeto guardado en un slot: sin prioridad de cogible (compite por puntuación).
	var in_slot: bool

	func _init(
		new_position: Vector2 = Vector2.ZERO,
		new_distance: float = 0.0,
		pickable: bool = false,
		interactable: bool = true,
		kitchen: bool = false,
		stored: bool = false
	) -> void:
		position = new_position
		distance = new_distance
		is_pickable = pickable
		is_interactable = interactable
		is_kitchen = kitchen
		in_slot = stored


## `dot * 2 + 1 / max(dist, 0.1)`.
static func score(dot: float, dist: float) -> float:
	return dot * 2.0 + 1.0 / maxf(dist, MIN_SCORE_DISTANCE)


## Índice del mejor candidato o -1 (`InteractionDetector.cs:99`). Con la mano vacía el mejor
## cogible suelto gana sobre cualquier interactuable, pero solo si además es interactuable
## (`bestPickable as IInteractable`); si no, se usa el mejor interactuable (con `kitchen_bonus`
## a la cocina) o -1. Un cogible `in_slot` compite como interactuable. Con la mano llena solo
## cuentan los interactuables, sin bonus.
##
## Histéresis (D26.4, ADR-003 §11.3): `current` es el índice del objetivo publicado si sigue siendo
## candidato (si no, -1). Si sigue dentro del cono y otro candidato lo supera, se mantiene salvo que
## (a) el nuevo tenga prioridad de cogible y `current` no, o (b) su puntuación (con
## `kitchen_bonus`) supere `score(current) + hysteresis_margin × |score(current)|`. Con margen 0
## no hay histéresis. Pasar de OK a BLOQUEADO no invalida al actual: eso no se mira aquí.
static func pick_best(
	origin: Vector2,
	forward: Vector2,
	candidates: Array[Candidate],
	holding: bool,
	cone_half_angle_deg: float,
	near_distance: float,
	kitchen_bonus: float,
	current: int = -1,
	hysteresis_margin: float = 0.0
) -> int:
	var cos_limit: float = cos(deg_to_rad(cone_half_angle_deg))
	var fwd: Vector2 = forward.normalized()
	var best_pickable: int = -1
	var best_pickable_score: float = -INF
	var best_interactable: int = -1
	var best_interactable_score: float = -INF
	# Puntuación final y si compite por la prioridad de cogible; NAN = fuera del cono.
	var scores: Array[float] = []
	var priority: Array[bool] = []

	for i: int in candidates.size():
		scores.append(NAN)
		priority.append(false)
		var cand: Candidate = candidates[i]
		if not cand.is_pickable and not cand.is_interactable:
			continue
		var to_target: Vector2 = cand.position - origin
		var dist: float = cand.distance
		var dot: float = fwd.dot(to_target.normalized())  # normalized() de cero es cero
		if dist > near_distance and dot < cos_limit:
			continue
		var cand_score: float = score(dot, dist)
		if cand.is_pickable and not holding and not cand.in_slot:
			scores[i] = cand_score
			priority[i] = cand.is_interactable
			if cand_score > best_pickable_score:
				best_pickable = i
				best_pickable_score = cand_score
		elif cand.is_interactable:
			if not holding and cand.is_kitchen:
				cand_score += kitchen_bonus
			scores[i] = cand_score
			if cand_score > best_interactable_score:
				best_interactable = i
				best_interactable_score = cand_score

	var best: int = best_interactable
	if best_pickable != -1 and candidates[best_pickable].is_interactable:
		best = best_pickable
	if hysteresis_margin <= 0.0 or best == current or current < 0 or current >= scores.size():
		return best
	var current_score: float = scores[current]
	if is_nan(current_score) or not candidates[current].is_interactable:
		return best  # el actual dejó de ser válido: se cambia en este tick
	if best < 0:
		return best
	if priority[best] and not priority[current]:
		return best  # regla categórica de PUL-063
	if scores[best] > current_score + hysteresis_margin * absf(current_score):
		return best
	return current
