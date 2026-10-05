class_name Highlightable
extends Node
## Resaltado del objetivo de interacción (ADR-003 §3). Sustituye a HighlightController,
## OutlineHighlighter e InteractableHighlight; sin EmissionHighlighter (B3).
##
## `show()` pone el contorno (inverted hull) en `material_overlay` de las mallas de su entidad y
## enseña la retícula opcional; `hide()` lo deshace. No baja a otras entidades colgadas de la
## suya (un objeto guardado en un slot tiene su propio `Highlightable`).
##
## Varios detectores (un jugador cada uno) pueden apuntar al mismo objeto: cada uno lo pide con
## `acquire(self)` y lo suelta con `release(self)`; el contorno sigue mientras quede alguno
## (PUL-039). `show()`/`hide()` fuerzan el estado sin propietarios.

const DEFAULT_MATERIAL: Material = preload("res://shaders/highlight_outline.tres")

## Material del contorno.
@export var material: Material = DEFAULT_MATERIAL
## Raíz de las mallas a contornear; por defecto, el padre.
@export var root: Node3D
## Visual opcional que solo se ve resaltado (retícula del slot).
@export var reticle: Node3D

var _highlighted: bool = false
var _meshes: Array[GeometryInstance3D] = []
## Propietarios que lo tienen encendido (instance id → true).
var _owners: Dictionary = {}


func _ready() -> void:
	if root == null:
		root = get_parent() as Node3D
	if reticle != null:
		reticle.visible = false


func show() -> void:
	if _highlighted:
		return
	_highlighted = true
	_meshes.clear()
	if root != null:
		_collect(root, true)
	for mesh: GeometryInstance3D in _meshes:
		mesh.material_overlay = material
	if reticle != null:
		reticle.visible = true


func hide() -> void:
	if not _highlighted:
		return
	_highlighted = false
	for mesh: GeometryInstance3D in _meshes:
		if is_instance_valid(mesh) and mesh.material_overlay == material:
			mesh.material_overlay = null
	_meshes.clear()
	if reticle != null:
		reticle.visible = false


## Enciende el contorno a nombre de `requester` (idempotente por propietario).
func acquire(requester: Object) -> void:
	_owners[requester.get_instance_id()] = true
	show()


## Retira a `requester`; el contorno se apaga cuando no queda ningún propietario.
func release(requester: Object) -> void:
	_owners.erase(requester.get_instance_id())
	if _owners.is_empty():
		hide()


func is_highlighted() -> bool:
	return _highlighted


func _collect(node: Node, is_root: bool) -> void:
	if node == reticle:
		return
	if not is_root and _is_entity(node):
		return
	if node is MeshInstance3D:
		_meshes.append(node as GeometryInstance3D)
	for child: Node in node.get_children():
		_collect(child, false)


func _is_entity(node: Node) -> bool:
	return (
		node.is_in_group(InteractionContract.GROUP_INTERACTABLE)
		or node.is_in_group(InteractionContract.GROUP_PICKABLE)
	)
