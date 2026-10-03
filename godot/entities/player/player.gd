class_name Player
extends CharacterBody3D
## Personaje 3D (scene-tree.md §3). Porta el movimiento de PlayerController: input del jugador
## que lo controla, mapeado al suelo según la cámara, con giro suave. Solo se mueve durante la
## ronda, que conoce por `EventBus` (`round_started` / `round_finished`), sin consultar sistemas.

## Números de movimiento (PlayerConfig.tres).
@export var config: PlayerConfig
## Cámara que define "derecha" y "arriba" de pantalla; si falta, la activa del viewport.
@export var camera: Camera3D
## Nodo `Items` del nivel, donde la mano deja lo que suelta (ADR-003 §6).
@export var items_root: Node

## Velocidad horizontal actual (m/s), para el futuro AnimationTree (PUL-013).
var speed: float = 0.0
## Si lleva algo en la mano, para el futuro AnimationTree (PUL-013).
var is_holding: bool = false

var _bus: Node
var _round_active: bool = false

@onready var _control: ControlComponent = %Control
@onready var _hold: HoldComponent = %HoldComponent


func _ready() -> void:
	if config == null:
		config = PlayerConfig.new()
	if items_root != null:
		_hold.items_root = items_root
	if _bus == null:
		_bus = EventBus
	_bus.round_started.connect(_on_round_started)
	_bus.round_finished.connect(_on_round_finished)


func _physics_process(delta: float) -> void:
	is_holding = _hold.get_held_item() != null
	var direction: Vector3 = _move_direction() if _round_active else Vector3.ZERO
	velocity = direction * config.speed
	speed = velocity.length()
	if direction != Vector3.ZERO:
		var target_yaw: float = atan2(-direction.x, -direction.z)
		var weight: float = clampf(config.rotation_speed * delta, 0.0, 1.0)
		rotation.y = lerp_angle(rotation.y, target_yaw, weight)
	move_and_slide()
	# Hueco de PUL-013: aquí se pasarán `speed` e `is_holding` al AnimationTree.


## Inyecta el bus (tests). Llamar antes de añadir el nodo al árbol; por defecto, el autoload.
func set_bus(bus: Node) -> void:
	_bus = bus


## Dirección en el suelo (XZ) para el input de pantalla: x a la derecha, y hacia la cámara.
func _move_direction() -> Vector3:
	var input: PlayerInput = _control.get_player_input()
	if input == null:
		return Vector3.ZERO
	var stick: Vector2 = input.get_move_vector()
	if stick == Vector2.ZERO:
		return Vector3.ZERO
	var right: Vector3 = Vector3.RIGHT
	var back: Vector3 = Vector3.BACK
	var view: Camera3D = camera if camera != null else get_viewport().get_camera_3d()
	if view != null:
		right = _flat(view.global_basis.x, Vector3.RIGHT)
		back = right.cross(Vector3.UP)
	return (right * stick.x + back * stick.y).normalized()


func _flat(v: Vector3, fallback: Vector3) -> Vector3:
	var flat: Vector3 = Vector3(v.x, 0.0, v.z)
	return flat.normalized() if flat.length_squared() > 0.0001 else fallback


func _on_round_started(_duration: float) -> void:
	_round_active = true


func _on_round_finished(_result: RoundResult) -> void:
	_round_active = false
