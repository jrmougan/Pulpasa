class_name InteractionComponent
extends Node
## Despacha la pulsación de interactuar (ADR-003 §3, §11.4). Común a 3D y 2D.
##
## Guarda el objetivo que publica el detector (`target_changed`, conectado por nombre). Al pulsar
## `p<n>_interact` da **una sola respuesta** (D26.3): con objetivo, el hint vigente decide y
## `target.interact()` lo ejecuta; sin objetivo y con la mano llena, suelta al suelo (`drop` OK) o
## no hace nada (`drop` BLOQUEADO `busy`). Cada respuesta sale como `interaction_resolved` local y
## en el bus. Mantener pulsado repite el corte (`HoldRepeat`). Es el emisor único de
## `EventBus.action_hint_changed` e `interaction_resolved` del jugador que lo controla.
## La lógica contextual (cortar, condimentar) vive en el receptor (ADR-003 §4), no aquí.

## Una pulsación con respuesta. `target` es `null` al soltar al suelo; `hint` es el resuelto
## **antes** del efecto (`OK` = cambió algo, `BLOCKED` = rechazada con motivo).
signal interaction_resolved(target: Node, hint: ActionHint)

@export var control: ControlComponent
@export var holder: Holder
## Cualquier nodo con la señal `target_changed(previous, current)`; si además tiene
## `hint_changed(target, hint)` y `get_hint()`, el hint se reenvía al bus.
@export var detector: Node

var _target: Node
var _repeat: HoldRepeat
## Objetivo sobre el que se armó el corte al mantener.
var _repeat_target: Node
## Jugador al que se anunció el último hint (0 = nadie), para el `NONE` al perder el control.
var _announced_player: int = 0


func _ready() -> void:
	var config: InputConfig = control.config if control != null else null
	if config == null:
		config = InputConfig.new()
	_repeat = HoldRepeat.new(config.cut_repeat_interval)
	if detector != null:
		detector.connect(&"target_changed", _on_target_changed)
		if detector.has_signal(&"hint_changed"):
			detector.connect(&"hint_changed", _on_hint_changed)
	if control != null:
		control.control_changed.connect(_on_control_changed)
		_announced_player = control.controlled_by


func _unhandled_input(event: InputEvent) -> void:
	var player_input: PlayerInput = control.get_player_input() if control != null else null
	if player_input == null or not player_input.is_interact_event(event):
		return
	interact_pressed()
	get_viewport().set_input_as_handled()


## Cortar al mantener: mientras la acción siga pulsada, el objetivo sea el mismo y su hint siga
## siendo un verbo repetible en `OK`, repite la pulsación cada `cut_repeat_interval`; si no, se
## desarma sin pulsar (sin rechazo mientras se mantiene).
func _physics_process(delta: float) -> void:
	if not _repeat.is_armed():
		return
	if not _can_keep_repeating():
		_repeat.disarm()
		_repeat_target = null
		return
	if _repeat.advance(delta):
		_press(true)


## Una pulsación de interactuar. Devuelve `true` si hubo respuesta (éxito o rechazo).
func interact_pressed() -> bool:
	return _press(false)


func _press(from_repeat: bool) -> bool:
	# B18: el objetivo puede haberse liberado desde la última señal.
	var target: Node = _target if _is_alive(_target) else null
	var hint: ActionHint = ActionHint.none()
	if target != null:
		hint = InteractionContract.hint_of(target, self)
	if target != null and hint.is_target():
		if not bool(target.call(&"interact", self)):
			if hint.verb != ActionVerb.NONE:
				push_error("%s: get_action_hint no es NONE pero interact() devolvió false" % target)
				return false
			# Objetivo heredado (sin verbo): como antes, si no consume cae al suelo.
			target = null
			hint = _floor_hint()
			if hint.state == ActionHint.State.OK:
				holder.drop()
	elif target != null:
		# El estado cambió en este frame y ya no hay nada que hacer con el objetivo.
		target = null
		hint = _floor_hint()
		if hint.state == ActionHint.State.OK:
			holder.drop()
	else:
		hint = _floor_hint()
		if hint.state == ActionHint.State.OK:
			holder.drop()
	if not hint.is_target():
		return false
	if not from_repeat and target != null and _is_repeatable(hint):
		_repeat.arm()
		_repeat_target = target
	_resolve(target, hint)
	return true


func _resolve(target: Node, hint: ActionHint) -> void:
	interaction_resolved.emit(target, hint)
	var player: int = control.controlled_by if control != null else 0
	if player > 0:
		EventBus.interaction_resolved.emit(player, hint.verb, int(hint.state), hint.reason)


## Hint de suelo (A8–A9): mano llena y sin objetivo.
func _floor_hint() -> ActionHint:
	if holder == null or holder.get_held_item() == null:
		return ActionHint.none()
	return ActionRules.for_floor(ActionRules.Held.OTHER, holder.can_drop_freely())


func _is_repeatable(hint: ActionHint) -> bool:
	return hint.state == ActionHint.State.OK and hint.verb in ActionVerb.REPEATABLE


func _can_keep_repeating() -> bool:
	var player_input: PlayerInput = control.get_player_input() if control != null else null
	if player_input == null or not player_input.is_interact_pressed():
		return false
	if not _is_alive(_target) or _target != _repeat_target:
		return false
	return _is_repeatable(InteractionContract.hint_of(_target, self))


func _on_target_changed(_previous: Node, current: Node) -> void:
	_target = current


## Reenvía el hint del detector al bus si el personaje está controlado.
func _on_hint_changed(_target_node: Node, hint: ActionHint) -> void:
	var player: int = control.controlled_by if control != null else 0
	if player > 0:
		_announce(player, hint)


## Al perder el control anuncia una vez «sin objetivo» al jugador anterior; al ganarlo, una vez
## el hint vigente del detector (ADR-003 §11.4).
func _on_control_changed(controlled_by: int) -> void:
	_repeat.disarm()
	_repeat_target = null
	var previous: int = _announced_player
	_announced_player = controlled_by
	if previous > 0 and previous != controlled_by:
		_announce(previous, ActionHint.none())
	if controlled_by > 0:
		_announce(controlled_by, _detector_hint())


func _detector_hint() -> ActionHint:
	if detector != null and detector.has_method(&"get_hint"):
		var hint: ActionHint = detector.call(&"get_hint") as ActionHint
		if hint != null:
			return hint
	return ActionHint.none()


func _announce(player: int, hint: ActionHint) -> void:
	EventBus.action_hint_changed.emit(player, hint.verb, int(hint.state), hint.reason)


## Válido y no en cola de borrado. `Variant`: un parámetro `Node` rechaza objetos liberados.
func _is_alive(node: Variant) -> bool:
	return is_instance_valid(node) and not node.is_queued_for_deletion()
