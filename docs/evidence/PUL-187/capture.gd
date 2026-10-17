extends Node
## PUL-187: captura `level_01` con los materiales v3 de entorno, comida, cajas y cocineros y una
## fila de primer plano con los tres estados de pulpo y cachelos, la caja llena con cachelos y
## los dos cocineros (J1 azul, J2 ámbar).

const LEVEL_SCENE: PackedScene = preload("res://scenes/levels/level_01.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const CACHELOS_SCENE: PackedScene = preload("res://entities/items/cachelos.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const COOK_MODEL: PackedScene = preload("res://assets/models/characters/cook/cook.glb")
const TENT_MODEL: PackedScene = preload("res://assets/models/environment/romeria_v2/tent.glb")
const CACHELOS: SeasoningData = preload("res://data/seasonings/cachelos.tres")
const FLOOR: Color = Color("#C4A882")
const OUT_DIR: String = "res://../docs/evidence/PUL-187/"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	get_tree().root.size = Vector2i(1920, 1080)
	get_node("/root/RoundManager").set_process(false)
	var level: Node = LEVEL_SCENE.instantiate()
	get_tree().root.add_child(level)
	await _frames(8)
	_save("level_01.png")
	level.queue_free()
	await _frames(2)
	var world: Node3D = _stage()
	_lineup(world)
	await _frames(8)
	_save("items_v3.png")
	get_tree().quit()


func _stage() -> Node3D:
	var world: Node3D = Node3D.new()
	get_tree().root.add_child(world)
	var camera: Camera3D = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 4.2
	camera.rotation_degrees = Vector3(-35, 0, 0)
	camera.position = Vector3(0, 4.5, 6.5)
	world.add_child(camera)
	camera.current = true
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 25, 0)
	world.add_child(sun)
	var ground: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(40, 40)
	var floor_material: StandardMaterial3D = StandardMaterial3D.new()
	floor_material.albedo_color = FLOOR
	plane.material = floor_material
	ground.mesh = plane
	world.add_child(ground)
	return world


func _lineup(world: Node3D) -> void:
	for index: int in 3:
		for row: int in 2:
			var scene: PackedScene = OCTOPUS_SCENE if row == 0 else CACHELOS_SCENE
			var item: Ingredient = scene.instantiate() as Ingredient
			item.freeze = true
			item.position = Vector3(-3.0 + index * 0.7, 0.26, -0.3 + row * 0.9)
			world.add_child(item)
			if index == 1:
				item.set_cooked()
			elif index == 2:
				item.set_burnt()
	var box: Box = BOX_SCENE.instantiate() as Box
	box.freeze = true
	box.position = Vector3(-0.3, 0.17, 0.3)
	world.add_child(box)
	box.fill = 1.0
	box.fill_changed.emit(1.0)
	box.apply_seasoning(CACHELOS)
	for index: int in 2:
		var cook: Node3D = COOK_MODEL.instantiate() as Node3D
		cook.position = Vector3(0.7 + index * 0.8, 0, 0.2)
		world.add_child(cook)
		for suffix: String in ["body", "hat"]:
			(cook.find_child("cook_%s_j1" % suffix, true, false) as Node3D).visible = index == 0
			(cook.find_child("cook_%s_j2" % suffix, true, false) as Node3D).visible = index == 1
	var tent: Node3D = TENT_MODEL.instantiate() as Node3D
	tent.position = Vector3(1.2, 0, -3.5)
	tent.scale = Vector3.ONE * 0.6
	world.add_child(tent)


func _frames(count: int) -> void:
	for i: int in count:
		await RenderingServer.frame_post_draw


func _save(file: String) -> void:
	var image: Image = get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT_DIR + file))
	print("captura: ", file)
