extends SceneTree
## Capturas de PUL-069 desde la cámara de level_01 (registro reproducible; no es parte del juego).
## Uso, desde la raíz del repo:
##   xvfb-run -a godot --path godot --resolution 1920x1080 \
##     -s "$PWD/docs/evidence/PUL-069/capture_burn.gd" -- <out_dir>
## Mete un pulpo y unos cachelos crudos en `Stations/Kitchen` y avanza el reloj de la olla con
## `_physics_process`: cociendo (vapor y fuego vivo), cocido, aviso (barra parpadeando) y quemado.

var _level: Node
var _kitchen: CookingStation
var _out: String


func _initialize() -> void:
	_out = OS.get_cmdline_user_args()[0]
	_level = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
	root.add_child(_level)
	current_scene = _level
	for i in 10:
		await process_frame
	_kitchen = _level.get_node("Stations/Kitchen") as CookingStation
	# El reloj solo avanza con `_advance` (las capturas lentas harían saltar la física real).
	_kitchen.set_physics_process(false)
	var player := _level.get_node("Characters/Player1") as Node3D
	var hold := player.get_node("%HoldComponent") as HoldComponent
	var actor := player.get_node("%InteractionComponent") as InteractionComponent
	for path: String in ["res://entities/items/octopus.tscn", "res://entities/items/cachelos.tscn"]:
		var item := (load(path) as PackedScene).instantiate() as Ingredient
		_level.add_child(item)
		hold.pick_up(item)
		_kitchen.interact(actor)
	player.global_position = _kitchen.global_position + Vector3(1.2, 0.0, 1.0)

	_advance(2.0)
	await _shot("cooking")
	_advance(3.0)
	await _shot("cooked")
	_advance(7.1)
	await _shot("warning")
	_advance(0.2)
	await _shot("warning_blink")
	_advance(3.0)
	await _shot("burnt")
	quit()


func _advance(seconds: float) -> void:
	for i in roundi(seconds / 0.05):
		_kitchen._physics_process(0.05)


func _shot(name: String) -> void:
	for i in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(_out + "/level_camera_%s.png" % name)
	var a := root.get_camera_3d().unproject_position(_kitchen.global_position + Vector3(0, 1.0, 0))
	var rect := Rect2i(int(a.x) - 260, int(a.y) - 220, 520, 400)
	var crop := img.get_region(rect.intersection(Rect2i(Vector2i.ZERO, img.get_size())))
	crop.resize(crop.get_width() * 2, crop.get_height() * 2, Image.INTERPOLATE_NEAREST)
	crop.save_png(_out + "/level_camera_%s_zoom.png" % name)
