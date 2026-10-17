extends Node
## PUL-183: captura `level_01` con la luz v3 y, después, solo `Environment` con la cámara del
## nivel, para comprobar que no hay viñeta ni manchas de luz puntual (AC4).

const LEVEL_SCENE: PackedScene = preload("res://scenes/levels/level_01.tscn")
const OUT_DIR: String = "res://../docs/evidence/PUL-183/"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	get_tree().root.size = Vector2i(1920, 1080)
	get_node("/root/RoundManager").set_process(false)
	var level: Node = LEVEL_SCENE.instantiate()
	get_tree().root.add_child(level)
	await _frames(8)
	_save("level_01.png")
	for child: Node in level.get_children():
		if child.name in ["Environment", "CameraRig"]:
			continue
		if "visible" in child:
			child.set("visible", false)
	await _frames(4)
	_save("environment.png")
	get_tree().quit()


func _frames(count: int) -> void:
	for i: int in count:
		await RenderingServer.frame_post_draw


func _save(file: String) -> void:
	var image: Image = get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT_DIR + file))
	print("captura: ", file)
