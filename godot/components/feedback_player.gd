class_name FeedbackPlayer
extends AudioStreamPlayer3D
## Feedback de una escena (ADR-006 §4; capa específica, en 2D sería `AudioStreamPlayer2D`): la
## escena conecta sus señales (locales o de `EventBus` filtradas por su id) a `play_cue()`, que
## reproduce **un** sonido posicional del mapa en el bus `SFX` y lanza la respuesta visual de la
## cue (`POP` o `SHAKE`) sobre el objetivo. Nada sube al bus.
##
## La parte visual anima el `Model` del objetivo si lo tiene (escalar un cuerpo físico no es
## seguro) o el propio objetivo, con un `Tween` ligado a ese nodo: se congela con la pausa y muere
## con él. Las cues con `delay` esperan en una cola que avanza en `_process` (también congelada).

## Una vez por `play_cue()` con cue conocida, al llamar a `play()` (gancho de tests, AC2/AC5).
signal played(cue: StringName)

const DEFAULT_MAP: AudioFeedbackMap = preload("res://data/audio/feedback_map.tres")
const BUS: StringName = &"SFX"
const POLYPHONY: int = 4
## Idas y vueltas del `SHAKE` (la amplitud es de la cue).
const SHAKE_STEPS: int = 4
## Fracción de `visual_time` en que el `POP` crece; el resto vuelve a reposo.
const POP_RISE: float = 0.35
## Metadatos del nodo animado: tween en curso y valores de reposo.
const META_TWEEN: StringName = &"feedback_tween"
const META_REST_SCALE: StringName = &"feedback_rest_scale"
const META_REST_POSITION: StringName = &"feedback_rest_position"

@export var map: AudioFeedbackMap = DEFAULT_MAP
## Objetivo visual por defecto; si falta, el padre.
@export var pulse_target: Node3D

## Cues en espera: `{cue, target, left}`.
var _pending: Array[Dictionary] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init() -> void:
	bus = BUS
	max_polyphony = POLYPHONY


func _ready() -> void:
	if map == null:
		map = DEFAULT_MAP


func _process(delta: float) -> void:
	advance(delta)


## Reproduce `cue` sobre `target` (o `pulse_target`/padre). Con `delay` > 0 espera en la cola.
func play_cue(cue: StringName, target: Node3D = null) -> void:
	var data: AudioCue = map.get_cue(cue) if map != null else null
	if data == null:
		push_warning("FeedbackPlayer: cue desconocida %s" % cue)
		return
	if data.delay > 0.0:
		_pending.append({&"cue": cue, &"target": target, &"left": data.delay})
		return
	_play_now(cue, data, target)


## Avanza `delta` s la cola de cues retrasadas (lo llama `_process`; los tests, a mano).
func advance(delta: float) -> void:
	if _pending.is_empty():
		return
	var due: Array[Dictionary] = []
	for entry: Dictionary in _pending:
		entry[&"left"] = float(entry[&"left"]) - delta
		if float(entry[&"left"]) <= 0.0:
			due.append(entry)
	for entry: Dictionary in due:
		_pending.erase(entry)
		var cue: StringName = entry[&"cue"]
		var target: Node3D = entry[&"target"] as Node3D
		if entry[&"target"] != null and not is_instance_valid(entry[&"target"]):
			target = null
		_play_now(cue, map.get_cue(cue), target)


## Cues en espera (tests).
func pending_count() -> int:
	return _pending.size()


## Respuesta visual en curso sobre `target` (o su `Model`), o `null`.
func get_visual_tween(target: Node3D) -> Tween:
	var node: Node3D = _visual_node(target)
	if node == null or not node.has_meta(META_TWEEN):
		return null
	var tween: Tween = node.get_meta(META_TWEEN) as Tween
	return tween if tween != null and tween.is_valid() else null


func _play_now(cue: StringName, data: AudioCue, target: Node3D) -> void:
	stream = data.stream
	volume_db = data.volume_db
	pitch_scale = 1.0 + _rng.randf_range(-data.pitch_jitter, data.pitch_jitter)
	play()
	played.emit(cue)
	var goal: Node3D = target
	if goal == null:
		goal = pulse_target if pulse_target != null else get_parent() as Node3D
	_animate(_visual_node(goal), data)


## `Model` de `target` si lo tiene; si no, `target`.
func _visual_node(target: Node3D) -> Node3D:
	if target == null or not is_instance_valid(target):
		return null
	var model: Node3D = target.get_node_or_null(^"Model") as Node3D
	return model if model != null else target


func _animate(node: Node3D, data: AudioCue) -> void:
	if node == null or data.visual == AudioCue.Visual.NONE or not node.is_inside_tree():
		return
	_stop_visual(node)
	var rest_scale: Vector3 = node.scale
	var rest_position: Vector3 = node.position
	node.set_meta(META_REST_SCALE, rest_scale)
	node.set_meta(META_REST_POSITION, rest_position)
	var tween: Tween = node.create_tween()
	var time: float = data.visual_time
	if data.visual == AudioCue.Visual.POP:
		var peak: Vector3 = rest_scale * (1.0 + data.pop_scale)
		tween.tween_property(node, ^"scale", peak, time * POP_RISE).set_trans(Tween.TRANS_BACK)
		tween.tween_property(node, ^"scale", rest_scale, time * (1.0 - POP_RISE))
	else:
		var step: float = time / float(SHAKE_STEPS + 1)
		var side: Vector3 = Vector3.RIGHT * data.shake_amplitude
		for i: int in SHAKE_STEPS:
			var offset: Vector3 = side if i % 2 == 0 else -side
			tween.tween_property(node, ^"position", rest_position + offset, step)
		tween.tween_property(node, ^"position", rest_position, step)
	tween.finished.connect(_clear_visual.bind(node))
	node.set_meta(META_TWEEN, tween)


## Corta la respuesta en curso de `node` y lo deja en reposo (la nueva parte de ahí).
func _stop_visual(node: Node3D) -> void:
	if not node.has_meta(META_TWEEN):
		return
	var tween: Tween = node.get_meta(META_TWEEN) as Tween
	if tween != null and tween.is_valid():
		tween.kill()
	node.scale = node.get_meta(META_REST_SCALE, node.scale)
	node.position = node.get_meta(META_REST_POSITION, node.position)
	_clear_visual(node)


func _clear_visual(node: Node3D) -> void:
	if not is_instance_valid(node):
		return
	node.remove_meta(META_TWEEN)
	node.remove_meta(META_REST_SCALE)
	node.remove_meta(META_REST_POSITION)
