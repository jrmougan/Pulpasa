class_name Player
extends CharacterBody3D
## Personaje 3D (scene-tree.md §3). Porta el movimiento de PlayerController: input del jugador
## que lo controla, mapeado al suelo según la cámara, con giro suave. Solo se mueve durante la
## ronda, que conoce por `EventBus` (`round_started` / `round_finished`), sin consultar sistemas.
## Sin jugador que lo controle (`controlled_by == 0`, ADR-004 §3) se queda quieto, sin input y
## con lo que lleve en la mano. D26: el activo lleva un aro sólido del color de su jugador
## (`%ActiveIndicator`) y el marcador ▼ (`%ActiveMarker`); el inactivo, un aro gris fino y
## discontinuo (`%InactiveIndicator`, `inactive_material`) sin marcador. El rechazo de una pulsación
## suena aquí (`rejected`, un solo cue para todos los motivos) y el cambio de personaje, `switch`.

## Números de movimiento (PlayerConfig.tres).
@export var config: PlayerConfig
## Cámara que define "derecha" y "arriba" de pantalla; si falta, la activa del viewport.
@export var camera: Camera3D
## Nodo `Items` del nivel, donde la mano deja lo que suelta (ADR-003 §6).
@export var items_root: Node
## Material del aro `%ActiveIndicator` por jugador: índice 0 = J1, 1 = J2.
@export var indicator_materials: Array[Material] = []
## Material del aro `%InactiveIndicator` (D26.6): gris, discontinuo y fino (<= 3 px a 1080).
@export var inactive_material: Material
## Lado del marcador ▼ del activo en px de pantalla a 1080 de alto (>= 24, D26.6).
@export var marker_px_1080: float = 28.0

## Velocidad horizontal actual (m/s), para el futuro AnimationTree (PUL-013).
var speed: float = 0.0
## Si lleva algo en la mano, para el futuro AnimationTree (PUL-013).
var is_holding: bool = false

var _bus: Node
var _round_active: bool = false
## `switch` no suena en la asignación del arranque de ronda: se arma al acabar ese frame.
var _switch_armed: bool = false

@onready var _control: ControlComponent = %Control
@onready var _hold: HoldComponent = %HoldComponent
@onready var _indicator: GeometryInstance3D = %ActiveIndicator
@onready var _inactive_indicator: GeometryInstance3D = %InactiveIndicator
@onready var _marker: Sprite3D = %ActiveMarker
@onready var _interaction: InteractionComponent = %InteractionComponent
@onready var _feedback: FeedbackPlayer = get_node_or_null(^"%Feedback") as FeedbackPlayer


func _ready() -> void:
	if config == null:
		config = PlayerConfig.new()
	if items_root != null:
		_hold.items_root = items_root
	if _bus == null:
		_bus = EventBus
	_bus.round_started.connect(_on_round_started)
	_bus.round_finished.connect(_on_round_finished)
	_bus.character_switched.connect(_on_character_switched)
	_control.control_changed.connect(_on_control_changed)
	if _inactive_indicator != null and inactive_material != null:
		_inactive_indicator.material_override = inactive_material
	if _feedback != null:
		_interaction.interaction_resolved.connect(_on_interaction_resolved)
		_hold.item_picked_up.connect(_on_item_picked_up)
		_hold.item_dropped.connect(_on_item_dropped)
	_on_control_changed(_control.controlled_by)


func _process(_delta: float) -> void:
	_size_marker()


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


func _on_control_changed(controlled_by: int) -> void:
	var slot: int = controlled_by - 1
	_indicator.visible = slot >= 0
	_inactive_indicator.visible = slot < 0
	_marker.visible = slot >= 0
	if slot >= 0 and slot < indicator_materials.size():
		_indicator.material_override = indicator_materials[slot]
		var ring: StandardMaterial3D = indicator_materials[slot] as StandardMaterial3D
		if ring != null:
			_marker.modulate = ring.albedo_color
	_size_marker()


## El ▼ mide `marker_px_1080` px a 1080 de alto en pantalla (con mínimo de 24 px), en px reales.
func _size_marker() -> void:
	if _marker.texture == null or not _marker.visible:
		return
	var height: float = ActionPrompt.real_size_of(get_viewport()).y
	var px: float = maxf(marker_px_1080 * height / 1080.0, 24.0)
	_marker.pixel_size = (
		px * ActionPrompt.meters_per_pixel_of(self) / float(_marker.texture.get_width())
	)


## Coger: sonido y `POP` del objeto cogido (ADR-006 §4, audio-y-fx AC5).
func _on_item_picked_up(item: Node) -> void:
	_feedback.play_cue(&"pick_up", item as Node3D)


func _on_item_dropped(_item: Node) -> void:
	_feedback.play_cue(&"drop")


## Rechazo (D26.3): un único cue `rejected` para cualquier motivo; `SHAKE` del objetivo, o del
## propio personaje al soltar contra la barra o la pared. Con `OK` suena el cue del efecto.
func _on_interaction_resolved(target: Node, hint: ActionHint) -> void:
	if hint.state == ActionHint.State.BLOCKED:
		var goal: Node3D = target as Node3D if is_instance_valid(target) else null
		_feedback.play_cue(&"rejected", goal)


## Cambio de personaje (ADR-006 §4.1): suena en el que recibe el control, no al arrancar la ronda.
func _on_character_switched(_player_index: int, character_index: int) -> void:
	if _feedback != null and _switch_armed and character_index == _control.player_index:
		_feedback.play_cue(&"switch", self)


func _arm_switch() -> void:
	_switch_armed = true


func _on_round_started(_duration: float) -> void:
	_round_active = true
	_switch_armed = false
	_arm_switch.call_deferred()


func _on_round_finished(_result: RoundResult) -> void:
	_round_active = false
	_switch_armed = false
