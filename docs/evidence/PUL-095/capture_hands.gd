extends SceneTree
## Real level camera and HoldComponent, three sizes held by both players.

var level: Node3D
var out: String


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	out = OS.get_cmdline_user_args()[0]
	level = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(level)
	current_scene = level
	for i: int in 10:
		await process_frame
	# Freeze simulation so review captures do not depend on movement or order timers.
	level.process_mode = Node.PROCESS_MODE_DISABLED
	var players: Array[Node3D] = [
		level.get_node("Characters/Player1") as Node3D,
		level.get_node("Characters/Player2") as Node3D,
	]
	players[0].global_position = Vector3(-2.8, .005, 2)
	players[1].global_position = Vector3(.8, .005, 2)
	for player: Node3D in players:
		player.rotation.y = PI
	for size: String in ["small", "medium", "large"]:
		var held: Array[Node3D] = []
		for player: Node3D in players:
			var item: Node3D = (load("res://entities/items/box.tscn") as PackedScene).instantiate() as Node3D
			item.set("data", load("res://data/boxes/%s.tres" % size))
			level.add_child(item)
			item.set("fill", 1.0)
			item.emit_signal("fill_changed", 1.0)
			player.get_node("%HoldComponent").call("pick_up", item)
			held.append(item)
		for i: int in 10:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out + "/hands_%s_1080.png" % size)
		for player: Node3D in players:
			player.get_node("%HoldComponent").call("drop")
		for item: Node3D in held:
			item.queue_free()
		await process_frame
	print("CAPTURE HANDS OK: ", out)
	quit()
