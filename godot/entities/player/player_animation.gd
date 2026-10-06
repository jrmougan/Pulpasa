class_name PlayerAnimation
extends AnimationTree
## `%AnimationTree` del personaje (PUL-044, scene-tree.md §3). La StateMachine de `player.tscn`
## cambia de estado por expresión sobre `speed` e `is_holding`, que este nodo copia del `Player`
## en cada tick: Idle/Walk con la mano vacía, IdleHolding/WalkWhileHolding con algo en la mano.
## `Pick` suena al coger (`item_picked_up` del `Holder`) y `Cut` en cada corte del pulpo que se
## lleva en la mano (`amount_changed`, D13: un golpe por pulsación); ambos vuelven solos al acabar.
## También elige la variante del modelo (J1/J2) por `player_index` del `%Control`: muestra las
## mallas `*_j<n>` del `.glb` y oculta las demás.

## Velocidad por encima de la cual se anda (m/s); por debajo, reposo.
const WALK_THRESHOLD: float = 0.1
const VARIANTS: int = 2

## Personaje del que se leen `speed` e `is_holding`.
@export var player: Player
## Mano del personaje (señales `item_picked_up` / `item_dropped`).
@export var holder: Holder
## Identidad del personaje (`player_index` elige la variante J1/J2).
@export var control: ControlComponent
## Instancia de `cook.glb` (`Model`).
@export var model: Node3D

## Espejo de `Player.speed` para las expresiones de la StateMachine.
var speed: float = 0.0
## Espejo de `Player.is_holding` para las expresiones de la StateMachine.
var is_holding: bool = false

var _variant: int = 0
var _cut_source: Node


func _ready() -> void:
	advance_expression_base_node = get_path()
	if holder != null:
		holder.item_picked_up.connect(_on_item_picked_up)
		holder.item_dropped.connect(_on_item_dropped)
	_sync()


func _physics_process(_delta: float) -> void:
	_sync()


## Variante mostrada: 1 = J1, 2 = J2.
func get_variant() -> int:
	return _variant


## Estado actual de la StateMachine (`Idle`, `Walk`, `Pick`…).
func get_state() -> StringName:
	return _playback().get_current_node()


func _sync() -> void:
	if player != null:
		speed = player.speed
		is_holding = player.is_holding
	var index: int = control.player_index if control != null else 1
	var variant: int = clampi(index, 1, VARIANTS)
	if variant != _variant:
		_apply_variant(variant)


func _apply_variant(variant: int) -> void:
	_variant = variant
	if model == null:
		return
	var suffix: String = "_j%d" % variant
	for node: Node in model.find_children("*_j?", "MeshInstance3D", true, false):
		(node as MeshInstance3D).visible = node.name.ends_with(suffix)


func _playback() -> AnimationNodeStateMachinePlayback:
	return get(&"parameters/playback") as AnimationNodeStateMachinePlayback


func _on_item_picked_up(item: Node) -> void:
	is_holding = true
	_playback().start(&"Pick")
	_watch_cuts(item)


func _on_item_dropped(_item: Node) -> void:
	is_holding = false
	_watch_cuts(null)


## Cada corte gasta pulpo del ingrediente que se lleva (`Box._cut` → `Ingredient.take`).
func _watch_cuts(item: Node) -> void:
	if is_instance_valid(_cut_source) and _cut_source.is_connected(&"amount_changed", _on_cut):
		_cut_source.disconnect(&"amount_changed", _on_cut)
	_cut_source = item if item != null and item.has_signal(&"amount_changed") else null
	if _cut_source != null:
		_cut_source.connect(&"amount_changed", _on_cut)


func _on_cut(_remaining: float) -> void:
	_playback().start(&"Cut")
