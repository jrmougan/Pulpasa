class_name ActionHint
extends RefCounted
## Qué haría la pulsación de interactuar sobre un objetivo, antes de pulsar (ADR-003 §11.1, D26).
## Valor inmutable por convención: se crea con `none()`, `ok()` o `blocked()`.

## Los valores son fijos: viajan como `int` por el bus (`signals.md` §2).
enum State { NONE = 0, OK = 1, BLOCKED = 2 }

var verb: StringName = ActionVerb.NONE
var state: State = State.NONE
var reason: StringName = ActionReason.NONE
## ALIÑAR que sustituye al otro aliño (insignia del prompt).
var replaces: bool = false
## 0–1, o −1 = sin progreso.
var progress: float = -1.0


## Sin objetivo: la pulsación no haría nada y no hay motivo útil que enseñar.
static func none() -> ActionHint:
	return ActionHint.new()


## La pulsación cambia el juego. `verb` vacío solo para el objetivo heredado (ADR-003 §11.3).
static func ok(new_verb: StringName, new_progress: float = -1.0) -> ActionHint:
	var hint: ActionHint = ActionHint.new()
	hint.verb = new_verb
	hint.state = State.OK
	hint.progress = new_progress
	return hint


## La pulsación no cambia nada, pero el motivo es útil.
static func blocked(new_verb: StringName, new_reason: StringName) -> ActionHint:
	var hint: ActionHint = ActionHint.new()
	hint.verb = new_verb
	hint.state = State.BLOCKED
	hint.reason = new_reason
	return hint


## `true` si hay objetivo (`state != NONE`).
func is_target() -> bool:
	return state != State.NONE


## Igualdad para publicar cambios: compara `verb`, `state`, `reason` y `replaces`; ignora
## `progress` (cambia cada corte y no debe emitir `hint_changed`).
func same_as(other: ActionHint) -> bool:
	return (
		other != null
		and verb == other.verb
		and state == other.state
		and reason == other.reason
		and replaces == other.replaces
	)
