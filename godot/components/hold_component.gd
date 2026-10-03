class_name HoldComponent
extends Holder
## Mano 3D (ADR-003 §3, §6): coge el objeto en `hold_point` y lo suelta en `items_root`.
## Porta PlayerHoldSystem sin B4 (siempre `on_picked_up`/`on_dropped`) ni B5 (valida antes
## de mutar).

## Capa de física `held` (ADR-003 §5): sin colisión con el portador.
const HELD_LAYER: int = 1 << 3

## Punto de sujeción del portador (`%HoldPoint`).
@export var hold_point: Node3D
## Cuerpo que lleva la mano: de él salen "delante" y la posición al soltar.
@export var carrier: Node3D
## Nodo `Items` del nivel donde quedan los objetos soltados (override de referencia del nivel).
@export var items_root: Node
## Desplazamientos al soltar.
@export var config: PlayerConfig

var _held: Node3D
var _saved_layer: int = 0
var _saved_mask: int = 0
var _saved_freeze: bool = false


func get_held_item() -> Node:
	return _current_held()


func can_hold(item: Node) -> bool:
	if _current_held() != null or hold_point == null:
		return false
	if not PickableContract.is_valid_pickable(item) or not item is Node3D:
		return false
	return not bool(item.get("is_held"))


func pick_up(item: Node) -> bool:
	if not can_hold(item):
		return false
	var body: Node3D = item as Node3D
	_held = body
	_freeze(body)
	if body.is_inside_tree():
		body.reparent(hold_point, false)
	else:
		if body.get_parent() != null:
			body.get_parent().remove_child(body)
		hold_point.add_child(body)
	body.transform = Transform3D.IDENTITY
	body.call("on_picked_up", self)
	item_picked_up.emit(body)
	return true


func drop() -> Node:
	var body: Node3D = _current_held()
	if body == null:
		return null
	_held = null
	var target: Vector3 = _drop_position()
	var basis: Basis = body.global_basis
	var root: Node = items_root if items_root != null else carrier.get_parent()
	body.reparent(root, false)
	body.global_transform = Transform3D(basis, target)
	_unfreeze(body)
	body.call("on_dropped")
	item_dropped.emit(body)
	return body


## Objeto en la mano, o `null`; si se liberó (o va a liberarse) estando en la mano, olvida la
## referencia para no dejar estado obsoleto y poder coger otro.
func _current_held() -> Node3D:
	if not is_instance_valid(_held) or _held.is_queued_for_deletion():
		_held = null
	return _held


## 0,6 m delante y 0,6 m arriba del portador (PlayerConfig), con "delante" en el suelo.
func _drop_position() -> Vector3:
	var cfg: PlayerConfig = config if config != null else PlayerConfig.new()
	var origin: Vector3 = carrier.global_position if carrier != null else hold_point.global_position
	var forward: Vector3 = Vector3.FORWARD
	if carrier != null:
		forward = -carrier.global_basis.z
	forward.y = 0.0
	forward = forward.normalized() if forward.length_squared() > 0.0 else Vector3.FORWARD
	return origin + forward * cfg.drop_forward_offset + Vector3.UP * cfg.drop_up_offset


func _freeze(body: Node3D) -> void:
	if body is CollisionObject3D:
		var collider: CollisionObject3D = body as CollisionObject3D
		_saved_layer = collider.collision_layer
		_saved_mask = collider.collision_mask
		collider.collision_layer = HELD_LAYER
		collider.collision_mask = 0
	if body is RigidBody3D:
		var rigid: RigidBody3D = body as RigidBody3D
		_saved_freeze = rigid.freeze
		rigid.linear_velocity = Vector3.ZERO
		rigid.angular_velocity = Vector3.ZERO
		rigid.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		rigid.freeze = true


func _unfreeze(body: Node3D) -> void:
	if body is CollisionObject3D:
		var collider: CollisionObject3D = body as CollisionObject3D
		collider.collision_layer = _saved_layer
		collider.collision_mask = _saved_mask
	if body is RigidBody3D:
		var rigid: RigidBody3D = body as RigidBody3D
		rigid.freeze = _saved_freeze
		rigid.linear_velocity = Vector3.ZERO
		rigid.angular_velocity = Vector3.ZERO
