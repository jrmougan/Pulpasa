extends SceneTree
## Capturas de PUL-078 desde la cámara de level_01 (registro reproducible; no es parte del juego).
## Uso, desde la raíz del repo (o de un worktree con el estado «antes»):
##   xvfb-run -a godot --audio-driver Dummy --path godot --resolution 1920x1080 \
##     -s "$PWD/docs/evidence/PUL-078/capture_pot.gd" \
##     -- <out_dir> <prefijo> <empty|states|highlight>
## `states`: Kitchen con pulpo crudo cociendo y cachelos cocidos; Kitchen2 con pulpo cocido y
## pulpo quemado. `highlight`: Kitchen resaltada (contorno de interacción), Kitchen2 en reposo.
## Luz: la actual del nivel (la final llega con PUL-073). Con un 4.º argumento `sky` se aclara el
## cielo procedural (suelo y horizonte ≈ ambiente de art-bible §1.3) solo para la captura: muestra
## cuánto depende el acero metálico de lo que refleja.

const OCTOPUS_SCENE := "res://entities/items/octopus.tscn"
const CACHELOS_SCENE := "res://entities/items/cachelos.tscn"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0]
	var prefix: String = args[1]
	var mode: String = args[2] if args.size() > 2 else "empty"
	var level: Node = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	for i in 10:
		await process_frame
	if args.size() > 3 and args[3] == "sky":
		_light_sky(level)
		mode += "_sky"
	var kitchens: Array = [level.get_node("Stations/Kitchen"), level.get_node("Stations/Kitchen2")]
	if mode.begins_with("states"):
		_cook(kitchens[0], [OCTOPUS_SCENE, CACHELOS_SCENE], [&"raw", &"cooked"])
		_cook(kitchens[1], [OCTOPUS_SCENE, OCTOPUS_SCENE], [&"cooked", &"burnt"])
	elif mode.begins_with("highlight"):
		(kitchens[0].get_node("%Highlightable") as Highlightable).show()
	for i in 60:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var tag := "%s_%s" % [prefix, mode]
	img.save_png(out_dir + "/level_camera_%s.png" % tag)
	var cam := root.get_camera_3d()
	var a := cam.unproject_position((kitchens[0] as Node3D).global_position + Vector3(0, 1, 0))
	var b := cam.unproject_position((kitchens[1] as Node3D).global_position + Vector3(0, 1, 0))
	var rect := Rect2i(int(a.x) - 150, int(min(a.y, b.y)) - 200, int(b.x - a.x) + 300, 340)
	rect = rect.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	var crop := img.get_region(rect)
	crop.resize(crop.get_width() * 2, crop.get_height() * 2, Image.INTERPOLATE_NEAREST)
	crop.save_png(out_dir + "/level_camera_%s_zoom.png" % tag)
	quit()


## Mete un ingrediente por plaza y lo deja en el estado pedido (raw = cociendo, sin terminar).
func _cook(kitchen: Node, scenes: Array, states: Array) -> void:
	var holder := FakeHolder.new()
	kitchen.get_parent().add_child(holder)
	var slots: Array = kitchen.get("_slots")
	for i: int in scenes.size():
		var ing: Node = (load(scenes[i]) as PackedScene).instantiate()
		kitchen.get_parent().add_child(ing)
		holder.pick_up(ing)
		var slot: Object = slots[i]
		kitchen.call("_start", holder, slot)
		if states[i] == &"raw":
			slot.set("cook_time", 1000.0)
			slot.set("elapsed", 2.0)
			continue
		kitchen.call("_finish", slot)
		if states[i] == &"burnt":
			kitchen.call("_burn", slot, slot.get("ingredient"))


func _light_sky(level: Node) -> void:
	var env_node: WorldEnvironment = level.find_child("WorldEnvironment", true, false)
	var sky_mat := env_node.environment.sky.sky_material as ProceduralSkyMaterial
	sky_mat.ground_bottom_color = Color("#9AA6A8")
	sky_mat.ground_horizon_color = Color("#C9CFD0")
	sky_mat.sky_horizon_color = Color("#D5DADB")
