extends SceneTree
## PUL-101: level_01 completo con la camara real a 1080p (AC4): 6 pasaplatos marcados, estacion al paso,
## hueco de la barra a x 3,4 con umbral, kioscos en y=0. Deja tres cajas en pasaplatos para ver la marca en uso.
## Uso (desde godot/): timeout 300 godot --audio-driver Dummy --resolution 1920x1080 -s ../docs/evidence/PUL-101/capture_level.gd -- <dir absoluto>

const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var level: Node3D = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(level)
	current_scene = level
	for i: int in 30:
		await process_frame
	var service: Node = root.get_node("OrderService")
	service.board.set_active_slots([1, 2, 3, 4] as Array[int])
	service.board.fill_slots([1, 2, 3, 4] as Array[int])
	var items: Node = level.get_node("Items")
	var player: Node = level.get_node("Characters/Player1")
	var hold: Node = player.get_node("%HoldComponent")
	var actor: Node = player.get_node("%InteractionComponent")
	var small: Resource = load("res://data/boxes/small.tres")
	var medium: Resource = load("res://data/boxes/medium.tres")
	for pair: Array in [["PassSlot02", small], ["PassSlot05", medium]]:
		var box: Node = BOX_SCENE.instantiate()
		box.data = pair[1]
		items.add_child(box)
		hold.pick_up(box)
		level.get_node("Stations/" + (pair[0] as String)).interact(actor)
	for i: int in 20:
		await physics_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	image.save_png(out + "/level_1080.png")
	image.get_region(Rect2i(380, 600, 1320, 230)).save_png(out + "/bar_zoom.png")
	quit()
