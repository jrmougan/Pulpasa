extends Node
## PUL-186: captura `level_01` con encimeras y estaciones v3 y tres primeros planos con la
## orientación de la cámara del nivel: estación de condimentos (dispensadores con placa D26.7),
## olla cociendo (vapor `Steam`) y estantería de cajas (sin cartones ni paneles).

const LEVEL_SCENE: PackedScene = preload("res://scenes/levels/level_01.tscn")
const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const OUT_DIR: String = "res://../docs/evidence/PUL-186/"
const CLOSEUPS: Dictionary[String, Array] = {
	"seasoning_station.png": ["Stations/SeasoningStation", 3.2, Vector3(0, 1.0, 0)],
	"kitchen_steam.png": ["Stations/Kitchen", 3.0, Vector3(0, 1.0, 0)],
	"box_shelf.png": ["Stations/BoxShelf", 3.0, Vector3(0, 0.5, 0)],
}


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	get_tree().root.size = Vector2i(1920, 1080)
	get_node("/root/RoundManager").set_process(false)
	var level: Node = LEVEL_SCENE.instantiate()
	get_tree().root.add_child(level)
	await _frames(8)
	_save("level_01.png")
	_cook(level)
	await get_tree().create_timer(1.6).timeout
	var level_camera: Camera3D = get_viewport().get_camera_3d()
	var camera: Camera3D = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	level.add_child(camera)
	camera.current = true
	for file: String in CLOSEUPS:
		var spec: Array = CLOSEUPS[file]
		var target: Node3D = level.get_node(spec[0] as String) as Node3D
		camera.size = spec[1] as float
		var focus: Vector3 = target.global_position + (spec[2] as Vector3)
		var back: Vector3 = level_camera.global_basis.z * 20.0
		camera.global_transform = Transform3D(level_camera.global_basis, focus + back)
		await _frames(4)
		_save(file)
	get_tree().quit()


## Mete un pulpo crudo en la olla con un jugador fuera de plano, como `test_burn.gd`.
func _cook(level: Node3D) -> void:
	var player: Node3D = PLAYER_SCENE.instantiate()
	level.add_child(player)
	player.position = Vector3(40, 0, 40)
	var hold: HoldComponent = player.get_node("%HoldComponent")
	hold.items_root = level
	var octopus: Node3D = OCTOPUS_SCENE.instantiate()
	level.add_child(octopus)
	hold.pick_up(octopus)
	var kitchen: CookingStation = level.get_node("Stations/Kitchen") as CookingStation
	kitchen.interact(player.get_node("%InteractionComponent") as InteractionComponent)
	print("cociendo: ", kitchen.is_cooking())


func _frames(count: int) -> void:
	for i: int in count:
		await RenderingServer.frame_post_draw


func _save(file: String) -> void:
	var image: Image = get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT_DIR + file))
	print("captura: ", file)
