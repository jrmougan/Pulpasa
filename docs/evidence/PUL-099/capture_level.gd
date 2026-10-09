extends SceneTree
## level_01 con la cámara real y las comandas vivas, para ver que los tickets no tapan puestos.
## Uso (desde godot/): godot --audio-driver Dummy --resolution 1920x1080 -s ../docs/evidence/PUL-099/capture_level.gd -- <dir absoluto>


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var level: Node = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	for i: int in 30:
		await process_frame
	var service: Node = root.get_node("OrderService")
	service.board.set_active_slots([1, 2, 3, 4] as Array[int])
	service.board.fill_slots([1, 2, 3, 4] as Array[int])
	for i: int in 10:
		await process_frame
	print("active orders: ", service.get_active_orders().size())
	await RenderingServer.frame_post_draw
	var shot: Image = root.get_texture().get_image()
	shot.save_png(out + "/level_tickets_1080.png")
	quit()
