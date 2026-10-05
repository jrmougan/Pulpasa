class_name InteractionDetector
extends Area3D
## Detector de objetivo del jugador, 3D (ADR-003 §3; porta InteractionDetector.cs). Uno por
## jugador (B7). Ve solo la capa `interactable`, con el radio de `PlayerConfig`.
##
## Cada tick de física construye un `Candidate` por entidad cercana (dirección en el suelo,
## distancia 3D desde el portador + `detector_origin_height`), delega la elección en
## `InteractionScoring.pick_best` y emite `target_changed` solo cuando cambia. Como
## InteractionDetector.cs:57, un slot ocupado se sustituye por su objeto guardado (con la posición
## del slot para puntuar), con la mano vacía o llena, y ese objeto compite como cualquier otro: él
## decide qué hacer con la mano (la caja corta o condimenta). Enciende el `Highlightable` del
## objetivo y apaga el anterior: nunca hay dos.

## Objetivo nuevo; ambos pueden ser `null` (signals.md).
signal target_changed(previous: Node, current: Node)

## Capa de física `interactable` (ADR-003 §5).
const INTERACTABLE_LAYER: int = 1 << 2
## Equivale al tag `Kitchen` del prototipo: recibe `detector_kitchen_bonus`.
const KITCHEN_GROUP: StringName = &"kitchen"

## Radio y parámetros de puntuación.
@export var config: PlayerConfig
## Mano del jugador: decide si cuentan los cogibles y los slots ocupados.
@export var holder: Holder
## Cuerpo que mira; por defecto, el padre.
@export var carrier: Node3D

var _target: Node
## Si hay un objetivo publicado: sobrevive a que se libere, para publicar la transición a `null`.
var _has_target: bool = false
var _lit: Highlightable


func _ready() -> void:
	if config == null:
		config = PlayerConfig.new()
	if carrier == null:
		carrier = get_parent() as Node3D
	collision_layer = 0
	collision_mask = INTERACTABLE_LAYER
	for child: Node in get_children():
		if child is CollisionShape3D:
			# Forma propia por instancia: el radio sale de la config de cada jugador.
			var sphere: SphereShape3D = SphereShape3D.new()
			sphere.radius = config.detector_radius
			(child as CollisionShape3D).shape = sphere


## Al salir del árbol (jugador liberado) suelta su resaltado: no deja propietarios colgados.
func _exit_tree() -> void:
	_set_lit(null)


func _physics_process(_delta: float) -> void:
	refresh()


## Objetivo actual, o `null`.
func get_target() -> Node:
	if not _is_alive(_target):
		_target = null
	return _target


## Reevalúa el objetivo y el resaltado con los cuerpos que solapan ahora.
func refresh() -> void:
	var holding: bool = holder != null and holder.get_held_item() != null
	var entities: Array[Node3D] = []
	var candidates: Array[InteractionScoring.Candidate] = []
	var eye: Vector3 = carrier.global_position + Vector3.UP * config.detector_origin_height
	for body: Node3D in get_overlapping_bodies():
		var entity: Node3D = _entity_of(body)
		if entity == null or not _is_alive(entity) or entity in entities:
			continue
		var pos: Vector3 = entity.global_position
		if entity is Slot and (entity as Slot).has_item():
			entity = (entity as Slot).get_item()
		candidates.append(
			InteractionScoring.Candidate.new(
				Vector2(pos.x, pos.z),
				pos.distance_to(eye),
				entity.is_in_group(InteractionContract.GROUP_PICKABLE),
				entity.is_in_group(InteractionContract.GROUP_INTERACTABLE),
				entity.is_in_group(KITCHEN_GROUP)
			)
		)
		entities.append(entity)
	var forward: Vector3 = -carrier.global_basis.z
	var best: int = InteractionScoring.pick_best(
		Vector2(carrier.global_position.x, carrier.global_position.z),
		Vector2(forward.x, forward.z),
		candidates,
		holding,
		config.detector_cone_half_angle,
		config.detector_near_distance,
		config.detector_kitchen_bonus
	)
	_set_target(entities[best] if best >= 0 else null)
	_set_lit(_highlightable_of(_target))


## Raíz de la entidad del contrato a la que pertenece `body` (él mismo o su padre directo).
func _entity_of(body: Node3D) -> Node3D:
	if _in_contract(body):
		return body
	var parent: Node3D = body.get_parent() as Node3D
	if parent != null and _in_contract(parent):
		return parent
	return null


func _in_contract(node: Node) -> bool:
	return (
		node.is_in_group(InteractionContract.GROUP_INTERACTABLE)
		or node.is_in_group(InteractionContract.GROUP_PICKABLE)
	)


## Publica el objetivo nuevo. Si el anterior se liberó (o va a liberarse), `previous` es `null`:
## nunca se emite un objeto liberado, pero la transición se publica igual (una vez).
func _set_target(current: Node) -> void:
	var previous: Node = get_target()
	if current == previous and _has_target == (current != null):
		return
	_target = current
	_has_target = current != null
	target_changed.emit(previous, current)


## Válido y no en cola de borrado. `Variant`: un parámetro `Node` rechaza objetos liberados.
func _is_alive(node: Variant) -> bool:
	return is_instance_valid(node) and not node.is_queued_for_deletion()


## `Highlightable` hijo directo de `target`, o `null`.
func _highlightable_of(target: Node) -> Highlightable:
	if not _is_alive(target):
		return null
	for child: Node in target.get_children():
		if child is Highlightable:
			return child as Highlightable
	return null


## Pide el resaltado de `highlight` y suelta el anterior. El `Highlightable` lleva la cuenta de
## los detectores que lo apuntan: con dos jugadores, que uno se vaya no apaga el del otro.
func _set_lit(highlight: Highlightable) -> void:
	if not is_instance_valid(_lit):
		_lit = null
	elif _lit.is_queued_for_deletion():
		_lit.release(self)
		_lit = null
	if highlight == _lit:
		return
	if _lit != null:
		_lit.release(self)
	_lit = highlight
	if _lit != null:
		_lit.acquire(self)
