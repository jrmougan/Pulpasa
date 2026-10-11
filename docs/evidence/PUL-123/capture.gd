extends SceneTree
## Capturas de PUL-123: rack y caja sin letras S/M/L, en la cámara real de `level_01`.
## Uso (con ventana), desde `godot/`:
##   godot --resolution 1280x720 -s ../docs/evidence/PUL-123/capture.gd -- <directorio absoluto>


func _init() -> void:
	var dir: String = OS.get_cmdline_user_args()[0]
	var level: Node = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
	root.add_child(level)
	for i: int in 10:
		await process_frame
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var shelf: Node3D = level.get_node("Stations/BoxShelf")
	var box: Node3D = (load("res://entities/items/box.tscn") as PackedScene).instantiate()
	level.add_child(box)
	box.global_position = shelf.global_position + Vector3(-3.0, 0.0, 6.0)
	var base_size: float = cam.size
	var base_xform: Transform3D = cam.global_transform
	var forward: Vector3 = -base_xform.basis.z
	# Rack: centrar la cámara en la estantería (misma orientación, tamaño reducido).
	cam.size = base_size * 0.3
	cam.global_position = shelf.global_position + Vector3(0, 0.3, 0) - forward * 20.0
	await _shot(dir + "/rack_in_game.png")
	cam.global_position = box.global_position + Vector3(0, 0.1, 0) - forward * 20.0
	cam.size = base_size * 0.1
	await _shot(dir + "/box_in_game.png")
	quit()


func _shot(path: String) -> void:
	for i: int in 5:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(path)
