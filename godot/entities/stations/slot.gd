class_name Slot
extends StaticBody3D
## Mesa o hueco que guarda un objeto (scene-tree.md §3). Sustituye a InteractableSlot +
## SnappingHelper: deja lo que lleva la mano con su `%AnchorPoint` sobre `%Anchor` y se lo
## devuelve a una mano vacía. Contrato `interactable` (ADR-003 §4).
##
## Mientras está guardado, el objeto se congela y sale de su capa de física: el detector ve el
## slot y lo sustituye por el objeto guardado (InteractionDetector.cs:57). Al devolverlo se
## restaura todo antes de que la mano lo coja, para que esta guarde y restaure el estado original
## al soltarlo. Los cogibles se cogen siempre con `Slot.pick_up_item` (como
## `Box.OnPickedUp` → `ForceClearSlot`), que pasa por aquí si el objeto está guardado.

## Objeto con el que empieza el slot (p. ej. el bote de cada especia).
@export var initial_item: PackedScene
## Datos opcionales del objeto inicial (p. ej. la `SeasoningData` de cada especia): se asignan a su
## propiedad `data` antes de que entre al árbol. `null` deja los de la escena.
@export var initial_item_data: Resource
## Grupo que acepta al dejar (ADR-003 §8.2). Vacío = cualquier objeto; si no, lo que no esté en el
## grupo se rechaza consumiendo la pulsación (no se guarda ni se suelta). La bandeja usa `&"box"`.
@export var accepted_group: StringName = &""

var _item: Node3D
var _saved_layer: int = 0
var _saved_freeze: bool = false

@onready var _anchor: Node3D = %Anchor


## Slot que guarda `item`, o `null`.
static func slot_of(item: Node) -> Slot:
	if item == null or not is_instance_valid(item):
		return null
	var anchor: Node = item.get_parent()
	var slot: Slot = anchor.get_parent() as Slot if anchor != null else null
	if slot != null and slot.get_item() == item:
		return slot
	return null


## Único camino para que un cogible se ponga en la mano de `actor`: si está guardado en un slot,
## el slot lo devuelve (restaurando capa y `freeze`); si no, la mano lo coge directamente.
static func pick_up_item(actor: InteractionComponent, item: Node) -> bool:
	if actor == null or actor.holder == null:
		return false
	var slot: Slot = slot_of(item)
	if slot != null:
		return slot.interact(actor)
	return actor.holder.pick_up(item)


## Transformación del `%AnchorPoint` del objeto respecto a su raíz (identidad si no tiene).
## Compartida por todo lo que coloca objetos por su ancla (slots, olla).
static func anchor_offset(item: Node3D) -> Transform3D:
	var anchor_point: Node3D = item.get_node_or_null(^"%AnchorPoint") as Node3D
	if anchor_point == null:
		anchor_point = item.get_node_or_null(^"AnchorPoint") as Node3D
	if anchor_point == null:
		return Transform3D.IDENTITY
	return item.global_transform.affine_inverse() * anchor_point.global_transform


func _ready() -> void:
	if initial_item != null:
		var item: Node3D = initial_item.instantiate() as Node3D
		if item != null:
			if initial_item_data != null and &"data" in item:
				item.set(&"data", initial_item_data)
			_anchor.add_child(item)
			_store(item)


func can_interact(actor: InteractionComponent) -> bool:
	var holder: Holder = actor.holder if actor != null else null
	if holder == null:
		return false
	var held: Node = holder.get_held_item()
	if has_item():
		return held == null
	return held is Node3D


func interact(actor: InteractionComponent) -> bool:
	if not can_interact(actor):
		return false
	var holder: Holder = actor.holder
	if has_item():
		return _give(holder)
	if not accepts(holder.get_held_item()):
		return true
	var item: Node3D = holder.drop() as Node3D
	if item == null:
		return false
	_store(item)
	return true


## Si `item` se puede dejar aquí según `accepted_group`.
func accepts(item: Node) -> bool:
	return item != null and (accepted_group.is_empty() or item.is_in_group(accepted_group))


func has_item() -> bool:
	return get_item() != null


## Objeto guardado, o `null` (también si se liberó o alguien lo sacó del slot).
func get_item() -> Node3D:
	if not is_instance_valid(_item) or _item.is_queued_for_deletion():
		_item = null
	elif _item.get_parent() != _anchor:
		_item = null
	return _item


## Alinea `item` por su `%AnchorPoint` (o su origen) a `%Anchor`, congelado y sin capa.
func _store(item: Node3D) -> void:
	_item = item
	if item.get_parent() != _anchor:
		item.reparent(_anchor, false)
	item.transform = Slot.anchor_offset(item).affine_inverse()
	if item is CollisionObject3D:
		var collider: CollisionObject3D = item as CollisionObject3D
		_saved_layer = collider.collision_layer
		collider.collision_layer = 0
	if item is RigidBody3D:
		var rigid: RigidBody3D = item as RigidBody3D
		_saved_freeze = rigid.freeze
		rigid.linear_velocity = Vector3.ZERO
		rigid.angular_velocity = Vector3.ZERO
		rigid.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		rigid.freeze = true


## Devuelve el objeto a la mano; si la mano lo rechaza, sigue guardado tal cual.
func _give(holder: Holder) -> bool:
	var item: Node3D = get_item()
	if not holder.can_hold(item):
		return false
	_restore(item)
	if holder.pick_up(item):
		_item = null
		return true
	_store(item)
	return false


func _restore(item: Node3D) -> void:
	if item is CollisionObject3D:
		(item as CollisionObject3D).collision_layer = _saved_layer
	if item is RigidBody3D:
		(item as RigidBody3D).freeze = _saved_freeze
