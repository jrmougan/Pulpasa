extends GutTest
## PUL-008: escala y orientación de los modelos (1 unidad = 1 m, frente en -Z).

const TOLERANCE: float = 0.2
const FURNITURE: Dictionary = {
	# Tamaño en metros (Unity: globalScale 1, useFileScale; ejes sin espejo en Z).
	"res://assets/models/furniture/Mueblecajas.fbx": Vector3(1.143, 0.923, 1.796),
	"res://assets/models/furniture/order_stand.fbx": Vector3(1.922, 2.015, 0.767),
}
const PLACEHOLDERS: Dictionary = {
	"pot": Vector3(0.67, 0.65, 0.67),
	"stove": Vector3(0.9, 1.14, 0.78),
	"fridge": Vector3(1.61, 2.33, 0.91),
	"table_long": Vector3(2.79, 1.14, 0.77),
	"table_medium": Vector3(1.8, 1.14, 0.77),
	"table_square": Vector3(1.37, 1.14, 1.37),
	"box_small": Vector3(0.49, 0.47, 0.41),
	"box_medium": Vector3(0.57, 0.55, 0.48),
	"box_large": Vector3(0.71, 0.68, 0.6),
	"condiment_jar": Vector3(0.3, 0.48, 0.3),
	"octopus_raw": Vector3(0.63, 0.58, 0.42),
	"octopus_cooked": Vector3(0.63, 0.58, 0.42),
	"character": Vector3(0.42, 1.54, 0.5),
}
const PLACEHOLDER_DIR: String = "res://assets/models/placeholders/"


func _aabb_of(node: Node, parent_xf: Transform3D = Transform3D.IDENTITY) -> AABB:
	var xf: Transform3D = parent_xf
	if node is Node3D:
		xf = parent_xf * (node as Node3D).transform
	var box: AABB = AABB()
	var found: bool = false
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		box = xf * (node as MeshInstance3D).mesh.get_aabb()
		found = true
	for child in node.get_children():
		var sub: AABB = _aabb_of(child, xf)
		if sub.size != Vector3.ZERO:
			box = sub if not found else box.merge(sub)
			found = true
	return box


func _assert_size_close(actual: Vector3, expected: Vector3, label: String) -> void:
	for axis in 3:
		var lo: float = expected[axis] * (1.0 - TOLERANCE)
		var hi: float = expected[axis] * (1.0 + TOLERANCE)
		var msg: String = "%s eje %d: %f fuera de %f..%f" % [label, axis, actual[axis], lo, hi]
		assert_between(actual[axis], lo, hi, msg)


func test_ac1_own_fbx_import_in_plausible_meters() -> void:
	for path: String in FURNITURE:
		var scene: PackedScene = load(path)
		assert_not_null(scene, path)
		var inst: Node = scene.instantiate()
		add_child_autofree(inst)
		_assert_size_close(_aabb_of(inst).size, FURNITURE[path] as Vector3, path)


func test_ac2_every_placeholder_exists_with_plausible_size() -> void:
	for id: String in PLACEHOLDERS:
		var scene: PackedScene = load(PLACEHOLDER_DIR + id + ".tscn")
		assert_not_null(scene, id)
		var inst: Node = scene.instantiate()
		add_child_autofree(inst)
		_assert_size_close(_aabb_of(inst).size, PLACEHOLDERS[id] as Vector3, id)


func test_ac2_placeholders_face_minus_z() -> void:
	for id: String in PLACEHOLDERS:
		var inst: Node = (load(PLACEHOLDER_DIR + id + ".tscn") as PackedScene).instantiate()
		add_child_autofree(inst)
		var front: Marker3D = inst.get_node_or_null("Front") as Marker3D
		assert_not_null(front, "%s sin marcador Front" % id)
		if front != null:
			assert_lt(front.position.z, 0.0, "%s: el frente debe estar en -Z" % id)
	var character: Node = (load(PLACEHOLDER_DIR + "character.tscn") as PackedScene).instantiate()
	add_child_autofree(character)
	assert_lt((character.get_node("Nose") as Node3D).position.z, 0.0, "la nariz marca -Z")


func test_ac3_scale_check_scene_uses_unity_camera() -> void:
	var scene: PackedScene = load("res://scenes/scale_check.tscn")
	assert_not_null(scene)
	var inst: Node = scene.instantiate()
	add_child_autofree(inst)
	var cam: Camera3D = inst.get_node("Camera3D") as Camera3D
	assert_eq(cam.projection, Camera3D.PROJECTION_ORTHOGONAL)
	assert_almost_eq(cam.size, 12.74, 0.01)
	assert_almost_eq(cam.rotation_degrees.x, -38.0, 0.01)
	var cube: MeshInstance3D = inst.get_node("ScaleCube") as MeshInstance3D
	assert_eq(cube.mesh.get_aabb().size, Vector3.ONE)
	for id: String in ["Mueblecajas", "OrderStand", "Fridge", "Character", "OctopusCooked"]:
		assert_not_null(inst.get_node_or_null(id), id)
