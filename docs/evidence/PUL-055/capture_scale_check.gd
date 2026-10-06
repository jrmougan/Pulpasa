extends SceneTree
## Captura de escala de PUL-055 frente a `scenes/scale_check.tscn` (registro reproducible; no es parte del juego).
## Uso, desde la raíz del repo:
##   xvfb-run -a godot --path godot --resolution 1920x1080 \
##     -s "$PWD/docs/evidence/PUL-055/capture_scale_check.gd" -- <out_dir>
## Instancia scale_check, oculta los placeholders salvo el cubo de 1 m y el personaje de 1,8 m, y coloca la
## carpa y una franja de decoración girada 180° (como `DecorWest` en environment.tscn) junto a ellos.

const DIR := "res://assets/models/environment/romeria/"


func _initialize() -> void:
	var out_dir: String = OS.get_cmdline_user_args()[0]
	var check: Node3D = (load("res://scenes/scale_check.tscn") as PackedScene).instantiate()
	root.add_child(check)
	current_scene = check
	for child: Node in check.get_children():
		if child is Node3D and child.scene_file_path != "" and child.name != "Character":
			(child as Node3D).visible = false
	var turned := Basis(Vector3.UP, PI)
	_add(check, "tent", Transform3D(turned, Vector3(0.7, 0, -6.0)))
	_add(check, "decor", Transform3D(turned, Vector3(-6.5, 0, 1.0)))
	_add(check, "ground", Transform3D(turned, Vector3(4.2, 0, 1.0)))
	(check.get_node("Character") as Node3D).position = Vector3(-5.6, 0, 1.6)
	(check.get_node("ScaleCube") as Node3D).position = Vector3(-4.6, 0.5, 1.6)
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir + "/scale_check.png")
	quit()


func _add(parent: Node, piece: String, xform: Transform3D) -> void:
	var node: Node3D = (load(DIR + piece + ".glb") as PackedScene).instantiate()
	node.transform = xform
	parent.add_child(node)
