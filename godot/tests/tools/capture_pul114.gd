extends Node3D
## PUL-114: escena de captura (AC4) de la estación con los 2 dispensadores de aliño. Acerca la
## cámara a la línea y alterna cada 0,8 s el aliño dulce y el picante con la caja del jugador en
## la mano, para que una captura pille el gesto visual (sal gorda, aceite y pimentón).
## Uso: godot --path godot res://tests/tools/capture_pul114.tscn  (y captura con el MCP).

const CAMERA_SIZE: float = 4.2
const PERIOD: float = 0.8

@export var sandbox: Node3D

var _elapsed: float = 0.0
var _next: float = 0.6
var _use_hot: bool = false


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var station: SeasoningStation = sandbox.get("station") as SeasoningStation
	var player: Player = sandbox.get("player") as Player
	# Para que el personaje no tape ni resalte la línea, se aparta a su derecha con la caja en la
	# mano (se suelta y se vuelve a coger para que la caja viaje con él) y se oculta.
	var hold: Holder = player.get_node(^"%HoldComponent") as Holder
	var box: Node = hold.drop()
	player.global_position = Vector3(station.global_position.x + 2.9, 0.0, 1.6)
	await get_tree().physics_frame
	hold.pick_up(box)
	(player.get_node(^"Model") as Node3D).visible = false
	(player.get_node(^"ActiveIndicator") as Node3D).visible = false
	var rig: Camera3D = sandbox.get_node("CameraRig") as Camera3D
	rig.size = CAMERA_SIZE
	# La cámara mira al suelo a ~3,7 m por detrás de la estación: se desplaza para centrarla.
	rig.global_position += Vector3(station.global_position.x - 0.7, 0.0, 3.5)


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < _next:
		return
	_next += PERIOD
	var station: SeasoningStation = sandbox.get("station") as SeasoningStation
	var player: Player = sandbox.get("player") as Player
	if station == null or player == null:
		return
	var actor: InteractionComponent = player.get_node(^"%InteractionComponent")
	var name_to_press: String = "HotDressing" if _use_hot else "SweetDressing"
	_use_hot = not _use_hot
	(station.get_node("Dispensers/" + name_to_press) as SeasoningDispenser).interact(actor)
