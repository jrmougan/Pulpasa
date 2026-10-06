class_name BoxModel
extends Node3D
## Vista del plato de la caja (PUL-047, art-bible §3.4): nodo `Model` de `box.tscn`. Lee la `Box`
## padre y no cambia su estado. Muestra la variante del tamaño (`box_small/medium/large` de
## `box.glb`), el relleno progresivo con las capas de rodajas de `octopus_pieces.glb` y, si la caja
## lleva el condimento `cachelos`, los trozos de `cachelos_pieces.glb` encima. Las pegatinas 3D del
## `.glb` (`sticker`) van ocultas: la fila de condimentos en juego es `%BadgeRow` (PUL-059).
## Se rehace en `_ready` (el `ItemSpawner` asigna `data` antes de entrar al árbol) y al oír
## `fill_changed`, `seasoned` y `seasoning_removed`; quien cambie `data` después llama a
## `refresh()`.

## Variante si `data` no es uno de los tres `.tres` de `data/boxes/`.
const DEFAULT_SIZE: StringName = &"medium"
const SIZES: Array[StringName] = [&"small", &"medium", &"large"]
## Capas de rodajas visibles por nivel de relleno (0 vacía, 1 empezada, 2 a medias, 3 llena).
const OCTOPUS_LAYERS: Array[StringName] = [
	&"octopus_pieces_a", &"octopus_pieces_b", &"octopus_pieces_c"
]
const CACHELOS_LAYERS: Array[StringName] = [&"cachelos_pieces_a", &"cachelos_pieces_b"]
const HALF_FILL: float = 0.5
## Altura de los cachelos sobre el suelo del plato, × escala del tamaño (encima de las rodajas).
const CACHELOS_LIFT: float = 0.04

## Condimento que añade los trozos de cachelos (D18).
@export var cachelos: SeasoningData
## Escala de las rodajas y los trozos por tamaño (el `.glb` de piezas está hecho para ≈ 0,3 m).
@export
var fill_scale: Dictionary[StringName, float] = {&"small": 0.95, &"medium": 1.15, &"large": 1.35}
## Caja de colisión por tamaño: la del modelo del plato (art-bible §2.1), no una única talla.
@export var collision_size: Dictionary[StringName, Vector3] = {
	&"small": Vector3(0.338, 0.284, 0.320),
	&"medium": Vector3(0.396, 0.333, 0.375),
	&"large": Vector3(0.491, 0.414, 0.466),
}
## Escala extra de los trozos de cachelos (su `.glb` mide ≈ 0,34 m de ancho).
@export var cachelos_scale: float = 0.55

var _box: Box
var _own_shape: BoxShape3D

@onready var _plate: Node3D = $Plate as Node3D
@onready var _octopus: Node3D = $Octopus as Node3D
@onready var _cachelos: Node3D = $Cachelos as Node3D


## Clave de tamaño estable de `data`: nombre de su `.tres` (`small`, `medium`, `large`).
static func size_key(data: BoxData) -> StringName:
	if data == null:
		return DEFAULT_SIZE
	var key: StringName = StringName(data.resource_path.get_file().get_basename())
	return key if key in SIZES else DEFAULT_SIZE


## Nivel de relleno visible: 0 vacía, 1 empezada, 2 a medias (≥ 0,5), 3 llena.
static func fill_level(fill: float) -> int:
	if fill <= 0.0:
		return 0
	if fill >= 1.0:
		return 3
	return 2 if fill >= HALF_FILL else 1


func _ready() -> void:
	_box = get_parent() as Box
	var sticker: Node3D = _plate.find_child("sticker", true, false) as Node3D
	if sticker != null:
		sticker.visible = false
	if _box != null:
		_box.fill_changed.connect(_on_fill_changed)
		_box.seasoned.connect(_on_seasoning_changed)
		_box.seasoning_removed.connect(_on_seasoning_changed)
	refresh()


## Tamaño mostrado (para tests).
func get_size() -> StringName:
	return size_key(_box.data if _box != null else null)


func refresh() -> void:
	var size: StringName = get_size()
	for key: StringName in SIZES:
		var variant: Node3D = _plate.find_child("box_" + key, true, false) as Node3D
		if variant != null:
			variant.visible = key == size
	_fit_collision(size)
	var anchor: Node3D = _plate.find_child("Anchor_Fill_" + size, true, false) as Node3D
	var floor_y: float = anchor.position.y if anchor != null else 0.0
	var s: float = fill_scale.get(size, 1.0)
	_octopus.scale = Vector3.ONE * s
	_octopus.position.y = floor_y
	_cachelos.scale = Vector3.ONE * s * cachelos_scale
	_cachelos.position.y = floor_y + CACHELOS_LIFT * s
	var level: int = fill_level(_box.fill if _box != null else 0.0)
	for i: int in OCTOPUS_LAYERS.size():
		_set_layer(_octopus, OCTOPUS_LAYERS[i], level > i)
	var with_cachelos: bool = _box != null and cachelos != null and _box.has_seasoning(cachelos)
	_cachelos.visible = with_cachelos
	for layer: StringName in CACHELOS_LAYERS:
		_set_layer(_cachelos, layer, with_cachelos)


## Forma propia por instancia (la del `.tscn` es un subrecurso compartido) con el tamaño del plato.
func _fit_collision(size: StringName) -> void:
	if _box == null or not collision_size.has(size):
		return
	var body: CollisionShape3D = _box.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if body == null:
		return
	if _own_shape == null:
		_own_shape = BoxShape3D.new()
	_own_shape.size = collision_size[size]
	body.shape = _own_shape


func _set_layer(pile: Node3D, layer: StringName, shown: bool) -> void:
	var node: Node3D = pile.find_child(layer, true, false) as Node3D
	if node != null:
		node.visible = shown


func _on_fill_changed(_fill: float) -> void:
	refresh()


func _on_seasoning_changed(_seasoning: SeasoningData) -> void:
	refresh()
