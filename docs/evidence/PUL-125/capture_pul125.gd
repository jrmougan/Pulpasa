extends SceneTree
## PUL-125: herramienta de captura de las pruebas visuales (anillo de cocción, aviso de quemado y
## contador de corte) sobre `level_01.tscn`, a 1920x1080 con la cámara de juego.
## Uso (desde la raíz del repo, con ventana):
##   godot --path godot --audio-driver Dummy --resolution 1920x1080 \
##       -s ../docs/evidence/PUL-125/capture_pul125.gd -- <carpeta de salida>
## Guarda PNG a pantalla completa y un recorte ampliado ×2 de cada momento.

## Se carga todo en tiempo de ejecución y sin tipos del proyecto: con `-s` los autoloads
## (`EventBus`...) aún no existen cuando se compila este script.
const STATE_WARNING: int = 3
const STATE_BURNT: int = 4
const AMBER: Color = Color("#FFB020")

var _out: String = "."
var _player: Node
var _hold: Node
var _actor: Node
var _kitchen: Node
var _level: Node
var _octopus_scene: PackedScene
var _box_scene: PackedScene


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not args.is_empty():
		_out = args[0]
	DirAccess.make_dir_recursive_absolute(_out)
	_run()


func _run() -> void:
	_octopus_scene = load("res://entities/items/octopus.tscn")
	_box_scene = load("res://entities/items/box.tscn")
	_level = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
	root.add_child(_level)
	await _frames(30)
	_find_actors()
	await _cooking_and_burning()
	await _cut_counter()
	quit()


func _frames(count: int) -> void:
	for _i: int in count:
		await process_frame


func _seconds(seconds: float) -> void:
	# Tiempo de juego: ticks de física (60 por segundo), no fotogramas de pantalla.
	for _i: int in roundi(seconds * 60.0):
		await physics_frame


func _find_actors() -> void:
	for node: Node in _level.find_children("*", "Player", true, false):
		if node.get_node("%Control").controlled_by > 0:
			_player = node
	_hold = _player.get_node("%HoldComponent")
	_actor = _player.get_node("%InteractionComponent")
	_kitchen = _level.find_children("*", "CookingStation", true, false)[0]
	# Sin detector ni ruido: la captura enseña solo el estado del anillo y el contador.
	_player.get_node("%InteractionDetector").set_physics_process(false)


func _snap(name: String, center_world: Vector3, half_size: Vector2i = Vector2i(240, 135)) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	image.save_png("%s/%s.png" % [_out, name])
	var camera: Camera3D = root.get_camera_3d()
	var pixel: Vector2i = Vector2i(camera.unproject_position(center_world))
	var rect: Rect2i = Rect2i(pixel - half_size, half_size * 2).intersection(
		Rect2i(Vector2i.ZERO, image.get_size())
	)
	var crop: Image = image.get_region(rect)
	crop.resize(crop.get_width() * 2, crop.get_height() * 2, Image.INTERPOLATE_NEAREST)
	crop.save_png("%s/%s_zoom.png" % [_out, name])
	print("%s: ventana %s, anillo en %s" % [name, root.get_visible_rect().size, pixel])


func _cooking_and_burning() -> void:
	var rings: Array = _kitchen.get_rings()
	for _i: int in 2:
		var octopus: Node = _octopus_scene.instantiate()
		_level.add_child(octopus)
		_hold.pick_up(octopus)
		_kitchen.interact(_actor)
		await _seconds(1.5)
	var ring_point: Vector3 = _kitchen.global_position + Vector3(0.0, 2.1, 0.0)
	await _seconds(0.5)
	await _snap("ac4_anillo_cociendo", ring_point)
	# Listo: la primera plaza termina a los 5 s; la segunda 1,5 s después.
	await _seconds(2.0)
	await _snap("ac4_anillo_listo", ring_point)
	# Aviso de quemado: a los 7 s de quedar listo; se capturan los dos colores del parpadeo.
	while rings[0].get_state() != STATE_WARNING:
		await process_frame
	var seen: Dictionary = {}
	while seen.size() < 2 and rings[0].get_state() == STATE_WARNING:
		var color: Color = rings[0].get_ring_color()
		if not seen.has(color):
			seen[color] = true
			var tag: String = "ambar" if color == AMBER else "rojo"
			await _snap("ac5_aviso_quemado_" + tag, ring_point)
		await process_frame
	while rings[0].get_state() != STATE_BURNT:
		await process_frame
	await _seconds(0.3)
	await _snap("ac5_quemado_rojo_fijo", ring_point)


func _cut_counter() -> void:
	var held: Node = _hold.drop()
	if held != null:
		held.queue_free()
	var octopus: Node = _octopus_scene.instantiate()
	_level.add_child(octopus)
	octopus.set_cooked()
	_hold.pick_up(octopus)
	var box: Node = _box_scene.instantiate()
	_level.add_child(box)
	box.global_position = _player.global_position + Vector3(1.4, 0.4, 0.0)
	var anchor: Vector3 = box.global_position + Vector3(0.0, 0.62, 0.0)
	for k: int in range(1, 6):
		box.interact(_actor)
		await _seconds(0.1)
		if k == 1 or k == 3 or k == 5:
			await _snap("ac3_contador_%d_de_6" % k, anchor)
	box.interact(_actor)
	await _frames(2)
	await _snap("ac3_contador_6_de_6", anchor)
	await _seconds(0.7)
	await _snap("ac3_contador_oculto_tras_0_5_s", anchor)
