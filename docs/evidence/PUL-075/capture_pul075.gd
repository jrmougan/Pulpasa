extends SceneTree
## Capturas de PUL-075 desde la cámara de level_01 (no forma parte del juego). Desde la raíz:
## xvfb-run -a godot --audio-driver Dummy --path godot --resolution 1920x1080 \
##   -s "$PWD/docs/evidence/PUL-075/capture_pul075.gd" -- <prefijo> "$PWD/docs/evidence/PUL-075"
## Luz actual del nivel (la final de PUL-073 llega en paralelo). Saca: `<prefijo>_spawn.png`
## (posiciones de level_01, de cara a la cámara, J1 con pulpo cocido y el resaltado del detector) y
## `<prefijo>_{front,back,three_quarter}.png` (J1 y J2 juntos en el centro, J1 con pulpo, J2 con
## bandeja grande llena).


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)


func _give(level: Node3D, player: Node3D, kind: String) -> void:
	var hold: Node = player.get_node("%HoldComponent")
	var held: Node = hold.call("get_held_item")
	if held != null:
		hold.call("drop")
		held.queue_free()
	if kind == "":
		return
	var item: Node3D
	if kind == "octopus":
		item = (load("res://entities/items/octopus.tscn") as PackedScene).instantiate()
	else:
		item = (load("res://entities/items/box.tscn") as PackedScene).instantiate()
		item.set("data", load("res://data/boxes/large.tres"))
	level.get_node("Items").add_child(item)
	await _frames(1)
	# Sin tipos de clase: el script vive fuera de res:// y no ve los class_name.
	if item.has_method("set_cooked"):
		item.call("set_cooked")
	if kind == "plate":
		item.set("fill", 1.0)
		item.emit_signal("fill_changed", 1.0)
	hold.call("pick_up", item)


## Enciende el contorno de interacción del objeto resaltable más cercano a `player` (el detector
## solo apunta en partida; aquí se fuerza para ver el resaltado junto al personaje nuevo).
func _light_nearest(level: Node, player: Node3D) -> void:
	var best: Node = null
	var best_d: float = INF
	for node: Node in level.find_children("*", "Node", true, false):
		if not node.has_method("acquire") or not node.has_method("is_highlighted"):
			continue
		var owner_3d: Node3D = node.get_parent() as Node3D
		if owner_3d == null:
			continue
		var d: float = owner_3d.global_position.distance_to(player.global_position)
		if d < best_d:
			best_d = d
			best = node
	if best != null:
		best.call("show")


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var prefix: String = args[0]
	var out: String = args[1]
	var level: Node3D = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
	root.add_child(level)
	(level.get_node("UI") as CanvasLayer).visible = false
	level.get_node("Characters/Player2/Control").set("controlled_by", 2)
	var players: Array[Node3D] = [level.get_node("Characters/Player1"), level.get_node("Characters/Player2")]
	await _frames(10)
	for p: Node3D in players:
		p.rotation.y = PI
	await _give(level, players[0], "octopus")
	await _frames(60)
	await _shot("%s/%s_spawn.png" % [out, prefix])
	for facing: Array in [["front", PI], ["back", 0.0], ["three_quarter", PI * 0.75]]:
		for i in 2:
			await _give(level, players[i], "")
			players[i].global_position = Vector3(-0.6 + 2.2 * i, 0.005, 1.6)
			players[i].rotation.y = facing[1]
		await _frames(5)
		await _give(level, players[0], "octopus")
		await _give(level, players[1], "plate")
		_light_nearest(level, players[0])
		await _frames(60)
		await _shot("%s/%s_%s.png" % [out, prefix, facing[0]])
	print("DONE")
	quit()
