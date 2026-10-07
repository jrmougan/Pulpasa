extends SceneTree
## Review harness only: stages PUL-097 integration without editing gameplay scenes.
const BASE := "res://assets/models/stations/seasoning_station/"
const VARIANTS: Array[String] = ["paprika_sweet", "paprika_hot", "salt", "oil"]
var out: String
var stage: Node3D
var camera: Camera3D
var bowl: Node3D


func _initialize() -> void:
	out = OS.get_cmdline_user_args()[0]
	call_deferred("run")


func instance(file: String, parent: Node3D, pos: Vector3) -> Node3D:
	var node: Node3D = (load(BASE + file + ".glb") as PackedScene).instantiate()
	parent.add_child(node)
	node.position = pos
	return node


func portions(node: Node3D, count: int) -> void:
	for i: int in range(5):
		(node.find_child("Portions%d" % i, true, false) as Node3D).visible = i == count


func assemble(parent: Node3D) -> Node3D:
	var line := Node3D.new()
	parent.add_child(line)
	instance("seasoning_station", line, Vector3.ZERO)
	for i: int in range(4):
		var dispenser: Node3D = instance("seasoning_dispenser", line, Vector3(i - 2, 1.1, 0))
		for variant: String in VARIANTS:
			(dispenser.find_child(variant, true, false) as Node3D).visible = variant == VARIANTS[i]
	bowl = instance("cachelos_bowl", line, Vector3(2, 1.1, 0))
	portions(bowl, 4)
	return line


func shot(name: String) -> void:
	for i: int in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.save_png(out + "/" + name + ".png")


func run() -> void:
	var level: Node3D = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	var old: Node3D = level.get_node("Stations/SeasoningStation")
	var pos: Vector3 = old.position
	old.queue_free()
	await process_frame
	var line: Node3D = assemble(level)
	line.position = pos
	level.get_node("UI").set("visible", false)
	camera = level.get_node("CameraRig") as Camera3D
	await shot("01_game_camera_1080")
	# Isolated review keeps the real camera basis and size, same lights/environment.
	stage = Node3D.new()
	root.add_child(stage)
	var env: Node = level.find_child("WorldEnvironment", true, false).duplicate()
	stage.add_child(env)
	for child: Node in level.find_children("*", "DirectionalLight3D", true, false):
		if child is DirectionalLight3D:
			stage.add_child(child.duplicate())
	var review_cam: Camera3D = camera.duplicate() as Camera3D
	stage.add_child(review_cam)
	var basis: Basis = camera.basis
	level.queue_free()
	await process_frame
	camera = review_cam
	camera.current = true
	camera.position = Vector3(0, .65, 0) + basis.z * 12
	line = assemble(stage)
	await shot("02_native_1080")
	var environment: Environment = (env as WorldEnvironment).environment
	var saturation: float = environment.adjustment_saturation
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.0
	await shot("02_native_1080_gray")
	environment.adjustment_saturation = saturation
	camera.size = 6.0
	await shot("03_detail_1080")
	# Opposite side, same elevation; demonstrates kitchen/service distinction.
	camera.position = Vector3(0, .65, 0) + Vector3(0, basis.z.y, -basis.z.z) * 12
	camera.look_at(Vector3(0, .65, 0))
	await shot("04_kitchen_side")
	camera.basis = basis
	camera.position = Vector3(0, .25, 0) + basis.z * 12
	line.queue_free()
	await process_frame
	for count: int in range(5):
		var state: Node3D = instance("cachelos_bowl", stage, Vector3((count - 2) * 1.0, 0, 0))
		portions(state, count)
	camera.size = 4.0
	await shot("05_portions_0_to_4")
	for node: Node in stage.get_children():
		if node is Node3D and node != camera and not node is Light3D:
			var hull: Node3D = node.find_child("OutlineHull", true, false) as Node3D
			if hull != null:
				var highlight := Highlightable.new()
				node.add_child(highlight)
				highlight.root = hull
				highlight.show()
	await shot("06_outline_hull")
	quit()
