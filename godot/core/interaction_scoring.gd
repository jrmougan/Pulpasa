class_name InteractionScoring
extends RefCounted
## Elección de objetivo de interacción (InteractionDetector.cs). Pura, sobre el plano del suelo.
##
## Los números (cono, distancia mínima, bonus de cocina) llegan por parámetro desde el
## detector (que los lee de `PlayerConfig`). El detector resuelve antes los casos de slot
## (slot vacío, slot ocupado con la mano llena) y construye un `Candidate` por cuerpo.

## Mínimo de distancia en `score` para no dividir por cero (`Mathf.Max(dist, 0.1f)`).
const MIN_SCORE_DISTANCE: float = 0.1


## Un cuerpo candidato, ya proyectado al plano del suelo.
class Candidate:
	extends RefCounted
	var position: Vector2
	var is_pickable: bool
	var is_interactable: bool
	## Equivale al tag `Kitchen` del prototipo.
	var is_kitchen: bool

	func _init(
		new_position: Vector2 = Vector2.ZERO,
		pickable: bool = false,
		interactable: bool = true,
		kitchen: bool = false
	) -> void:
		position = new_position
		is_pickable = pickable
		is_interactable = interactable
		is_kitchen = kitchen


## `dot * 2 + 1 / max(dist, 0.1)`.
static func score(dot: float, dist: float) -> float:
	return dot * 2.0 + 1.0 / maxf(dist, MIN_SCORE_DISTANCE)


## Índice del mejor candidato o -1. Con la mano vacía gana el mejor cogible sobre cualquier
## interactuable; si no hay cogible, el mejor interactuable (con `kitchen_bonus` a la cocina).
## Con la mano llena solo cuentan los interactuables, sin bonus.
static func pick_best(
	origin: Vector2,
	forward: Vector2,
	candidates: Array[Candidate],
	holding: bool,
	cone_half_angle_deg: float,
	near_distance: float,
	kitchen_bonus: float
) -> int:
	var cos_limit: float = cos(deg_to_rad(cone_half_angle_deg))
	var fwd: Vector2 = forward.normalized()
	var best_pickable: int = -1
	var best_pickable_score: float = -INF
	var best_interactable: int = -1
	var best_interactable_score: float = -INF

	for i: int in candidates.size():
		var cand: Candidate = candidates[i]
		if not cand.is_pickable and not cand.is_interactable:
			continue
		var to_target: Vector2 = cand.position - origin
		var dist: float = to_target.length()
		var dot: float = fwd.dot(to_target.normalized())  # normalized() de cero es cero
		if dist > near_distance and dot < cos_limit:
			continue
		var cand_score: float = score(dot, dist)
		if cand.is_pickable and not holding:
			if cand_score > best_pickable_score:
				best_pickable = i
				best_pickable_score = cand_score
		elif cand.is_interactable:
			if not holding and cand.is_kitchen:
				cand_score += kitchen_bonus
			if cand_score > best_interactable_score:
				best_interactable = i
				best_interactable_score = cand_score

	return best_pickable if best_pickable != -1 else best_interactable
