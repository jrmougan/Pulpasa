class_name CameraFollow
extends RefCounted
## Seguimiento de cámara en el plano del suelo (ADR-005 E5). Puro: solo `Vector2`, `Rect2` y
## números. El foco es el punto del suelo (x, z) al que mira la cámara.
##
## `follow` mueve el foco con amortiguación crítica (sin oscilación ni rebasar el objetivo);
## `pan_to` lo lleva al nuevo objetivo con ease-out en un tiempo fijo y después sigue.

## Foco actual (x, z).
var position: Vector2 = Vector2.ZERO
## Velocidad del foco (m/s).
var velocity: Vector2 = Vector2.ZERO

var _panning: bool = false
var _pan_start: Vector2 = Vector2.ZERO
var _pan_duration: float = 0.0
var _pan_elapsed: float = 0.0


## Coloca el foco sin transición y cancela cualquier paneo.
func snap_to(target: Vector2) -> void:
	position = target
	velocity = Vector2.ZERO
	_panning = false


func is_panning() -> bool:
	return _panning


## Empieza un paneo ease-out de `duration` s desde el foco actual. Mientras dura, `follow` lleva el
## foco hacia el `target` que reciba (el objetivo puede moverse); `duration <= 0` salta al instante.
func pan_to(target: Vector2, duration: float) -> void:
	if duration <= 0.0:
		snap_to(target)
		return
	_panning = true
	_pan_start = position
	_pan_duration = duration
	_pan_elapsed = 0.0
	velocity = Vector2.ZERO


## Avanza `delta` s hacia `target` y devuelve el foco. Con paneo activo usa ease-out cúbico; si no,
## amortiguación crítica con `smooth_time` (s para recorrer ~95 %; 0 = sin suavizado).
func follow(target: Vector2, smooth_time: float, delta: float) -> Vector2:
	if _panning:
		_pan_elapsed += delta
		var t: float = clampf(_pan_elapsed / _pan_duration, 0.0, 1.0)
		var eased: float = 1.0 - pow(1.0 - t, 3.0)
		position = _pan_start.lerp(target, eased)
		if t >= 1.0:
			_panning = false
			velocity = Vector2.ZERO
		return position
	if smooth_time <= 0.0001:
		snap_to(target)
		return position
	if delta <= 0.0:
		return position
	# Amortiguación crítica (SmoothDamp de Unity): estable y sin sobrepaso.
	var omega: float = 2.0 / smooth_time
	var x: float = omega * delta
	var decay: float = 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	var change: Vector2 = position - target
	var temp: Vector2 = (velocity + omega * change) * delta
	velocity = (velocity - omega * temp) * decay
	var result: Vector2 = target + (change + temp) * decay
	# Evita rebasar el objetivo por redondeo.
	if (target - position).dot(result - target) > 0.0:
		result = target
		velocity = Vector2.ZERO
	position = result
	return position


## Recorta el foco para que la vista (medias dimensiones `half_extents` en el suelo) no salga más de
## `margin` m de [area_min, area_max]. Si la vista es mayor que el área ampliada, centra en ese eje.
static func clamp_focus(
	focus: Vector2, half_extents: Vector2, area_min: Vector2, area_max: Vector2, margin: float
) -> Vector2:
	return Vector2(
		_clamp_axis(focus.x, half_extents.x, area_min.x, area_max.x, margin),
		_clamp_axis(focus.y, half_extents.y, area_min.y, area_max.y, margin)
	)


## Foco que deja al objetivo en el centro de la parte visible cuando una banda de `top_cover_m` m
## (medidos sobre el suelo) tapa el borde superior de la vista: el foco queda medio tramo al norte.
static func covered_focus(target: Vector2, top_cover_m: float) -> Vector2:
	return Vector2(target.x, target.y - top_cover_m * 0.5)


## Como `clamp_focus`, pero con una banda de `top_cover_m` m que tapa el borde superior de la vista
## (HUD, tickets y safe area) y un alcance `top_reach_m` m: lo que mide de alto lo que
## debe verse sobre un punto del borde norte (anillo, prompt, cabeza). La parte visible puede salir
## `margin + top_reach_m` m del límite norte; el resto de bordes, solo `margin`.
static func clamp_focus_covered(
	focus: Vector2,
	half_extents: Vector2,
	area_min: Vector2,
	area_max: Vector2,
	margin: float,
	top_cover_m: float,
	top_reach_m: float
) -> Vector2:
	var low: float = area_min.y - margin - top_reach_m + half_extents.y - top_cover_m
	var high: float = area_max.y + margin - half_extents.y
	var y: float = (area_min.y + area_max.y) * 0.5 if low > high else clampf(focus.y, low, high)
	return Vector2(_clamp_axis(focus.x, half_extents.x, area_min.x, area_max.x, margin), y)


## Y del suelo (m) del borde superior de la parte visible: bajo la banda que tapa `top_cover_m`.
static func visible_top(focus_y: float, half_height: float, top_cover_m: float) -> float:
	return focus_y - half_height + top_cover_m


## Punto de la flecha de borde: donde el rayo del centro de `bounds` hacia `target` corta el
## borde de `bounds`; si cae dentro de `avoid` (más `gap`) para un icono de `arrow_size`, se
## desliza por el borde fuera de esa zona. Si `target` está dentro de `bounds`, lo devuelve.
static func edge_point(
	target: Vector2, bounds: Rect2, avoid: Rect2, arrow_size: Vector2, gap: float
) -> Vector2:
	var center: Vector2 = bounds.get_center()
	var half: Vector2 = bounds.size * 0.5
	var dir: Vector2 = target - center
	if dir.length_squared() < 0.0001:
		return center
	var sx: float = INF if absf(dir.x) < 0.0001 else half.x / absf(dir.x)
	var sy: float = INF if absf(dir.y) < 0.0001 else half.y / absf(dir.y)
	var point: Vector2 = center + dir * minf(minf(sx, sy), 1.0)
	if avoid.size.x <= 0.0 or avoid.size.y <= 0.0:
		return point
	var zone: Rect2 = avoid.grow(gap)
	var arrow: Rect2 = Rect2(point - arrow_size * 0.5, arrow_size)
	if not arrow.intersects(zone):
		return point
	var up: Vector2 = Vector2(point.x, zone.position.y - arrow_size.y * 0.5)
	var left: Vector2 = Vector2(zone.position.x - arrow_size.x * 0.5, point.y)
	up.y = maxf(up.y, bounds.position.y)
	left.x = maxf(left.x, bounds.position.x)
	return up if point.distance_to(up) <= point.distance_to(left) else left


static func _clamp_axis(
	value: float, half: float, area_min: float, area_max: float, margin: float
) -> float:
	var low: float = area_min - margin + half
	var high: float = area_max + margin - half
	if low > high:
		return (area_min + area_max) * 0.5
	return clampf(value, low, high)
