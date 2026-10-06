extends SceneTree
## Capturas de PUL-048 desde la cámara de level_01 (registro reproducible; no es parte del juego).
## Uso, desde la raíz del repo:
##   xvfb-run -a godot --path godot --resolution 1920x1080 \
##     -s "$PWD/docs/evidence/PUL-048/capture_pot.gd" -- <out_dir> <empty|cooking>
## `cooking`: Kitchen con pulpo y cachelos crudos cociendo (dos barras); Kitchen2 con cachelos
## cocidos (terminados) y un pulpo crudo cociendo.

const OCTOPUS_SCENE := "res://entities/items/octopus.tscn"
const CACHELOS_SCENE := "res://entities/items/cachelos.tscn"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0]
	var mode: String = args[1] if args.size() > 1 else "empty"
	var level: Node = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	for i in 10:
		await process_frame
	var kitchens: Array = [level.get_node("Stations/Kitchen"), level.get_node("Stations/Kitchen2")]
	if mode == "cooking":
		_cook(kitchens[0], [OCTOPUS_SCENE, CACHELOS_SCENE], false)
		_cook(kitchens[1], [CACHELOS_SCENE, OCTOPUS_SCENE], true)
		for i in 90:
			await physics_frame
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out_dir + "/level_camera_%s.png" % mode)
	var cam := root.get_camera_3d()
	var a := cam.unproject_position((kitchens[0] as Node3D).global_position + Vector3(0, 1, 0))
	var b := cam.unproject_position((kitchens[1] as Node3D).global_position + Vector3(0, 1, 0))
	var rect := Rect2i(int(a.x) - 150, int(min(a.y, b.y)) - 230, int(b.x - a.x) + 300, 360)
	rect = rect.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	var crop := img.get_region(rect)
	crop.resize(crop.get_width() * 2, crop.get_height() * 2, Image.INTERPOLATE_NEAREST)
	crop.save_png(out_dir + "/level_camera_%s_zoom.png" % mode)
	quit()


func _cook(kitchen: Node, scenes: Array, finish_first: bool) -> void:
	var holder := FakeHolder.new()
	kitchen.get_parent().add_child(holder)
	var first := true
	for path: String in scenes:
		var ing: Node = (load(path) as PackedScene).instantiate()
		kitchen.get_parent().add_child(ing)
		holder.pick_up(ing)
		kitchen.call("_start", holder, kitchen.call("_get_empty_slot"))
		if first and finish_first:
			var slot: Object = (kitchen.get("_slots") as Array)[0]
			slot.set("elapsed", 1000.0)
		first = false
