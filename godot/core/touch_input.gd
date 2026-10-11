class_name TouchInput
extends RefCounted
## Reglas puras de los controles táctiles (ADR-004 §6.3). Sin árbol ni `Input`.

## Última fuente de entrada vista. `NONE` = ninguna todavía.
enum Source { NONE, TOUCH, KEYS, JOYPAD }

## Acciones que alimenta el stick virtual (J1).
const MOVE_LEFT: StringName = &"p1_move_left"
const MOVE_RIGHT: StringName = &"p1_move_right"
const MOVE_UP: StringName = &"p1_move_up"
const MOVE_DOWN: StringName = &"p1_move_down"
const MOVE_ACTIONS: Array[StringName] = [MOVE_LEFT, MOVE_RIGHT, MOVE_UP, MOVE_DOWN]


## De dónde viene un evento. Ratón (también el emulado desde táctil) e `InputEventAction` (los que
## inyectan los propios controles) no cambian la fuente: `NONE`. Un eje de mando por debajo de
## `joy_deadzone` (`InputConfig.deadzone`) tampoco cuenta.
static func source_of(event: InputEvent, joy_deadzone: float) -> Source:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		return Source.TOUCH
	if event is InputEventKey:
		return Source.KEYS
	if event is InputEventJoypadButton:
		return Source.JOYPAD
	var motion: InputEventJoypadMotion = event as InputEventJoypadMotion
	if motion != null and absf(motion.axis_value) > joy_deadzone:
		return Source.JOYPAD
	return Source.NONE


## Los controles se ven solo en el perfil táctil, en Individual y mientras el último mando no haya
## sido un mando. El teclado no los oculta.
static func controls_visible(
	profile: PlatformProfile.Kind, mode: GameMode.Mode, last: Source
) -> bool:
	return (
		profile == PlatformProfile.Kind.MOBILE
		and mode == GameMode.Mode.SINGLE
		and last != Source.JOYPAD
	)


## Vector del stick: `(point - center) / radius` limitado a longitud 1 y cero por debajo de la zona
## muerta.
static func stick_vector(
	center: Vector2, point: Vector2, radius: float, deadzone: float
) -> Vector2:
	if radius <= 0.0:
		return Vector2.ZERO
	var raw: Vector2 = (point - center) / radius
	if raw.length() < deadzone:
		return Vector2.ZERO
	return raw.limit_length(1.0)


## Centro de la base cuando el dedo pasa del radio: la base lo sigue y el dedo queda en el borde.
static func follow_center(center: Vector2, point: Vector2, radius: float) -> Vector2:
	var offset: Vector2 = point - center
	if offset.length() <= radius:
		return center
	return point - offset.normalized() * radius


## Centro de una base de radio `base_radius` lo más cerca posible de `point` que la deje entera
## dentro de `area`. Si el área es menor que la base, queda centrada en el área.
static func clamp_center(point: Vector2, base_radius: float, area: Rect2) -> Vector2:
	var inner: Rect2 = area.grow(-base_radius)
	if inner.size.x <= 0.0 or inner.size.y <= 0.0:
		return area.get_center()
	return Vector2(
		clampf(point.x, inner.position.x, inner.end.x),
		clampf(point.y, inner.position.y, inner.end.y)
	)


## Fuerza de cada acción de movimiento para un vector de stick (x a la derecha, y hacia abajo).
## Siempre trae las cuatro acciones; la opuesta de cada eje vale 0.
static func axis_strengths(vector: Vector2) -> Dictionary[StringName, float]:
	return {
		MOVE_LEFT: maxf(-vector.x, 0.0),
		MOVE_RIGHT: maxf(vector.x, 0.0),
		MOVE_UP: maxf(-vector.y, 0.0),
		MOVE_DOWN: maxf(vector.y, 0.0),
	}
