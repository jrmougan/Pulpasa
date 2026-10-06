extends GutTest
## PUL-008: escala y orientación de los modelos (1 unidad = 1 m, frente en -Z).

const TOLERANCE: float = 0.2
const PLACEHOLDERS: Dictionary = {
	"table_square": Vector3(1.37, 1.14, 1.37),
	# Caja: bounds del mesh del FBX × transforms del prefab × escala de Visual.
	"box_small": Vector3(0.338, 0.284, 0.320),
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


func test_ac2_every_placeholder_exists_with_plausible_size() -> void:
	for id: String in PLACEHOLDERS:
		var scene: PackedScene = load(PLACEHOLDER_DIR + id + ".tscn")
		assert_not_null(scene, id)
		var inst: Node = scene.instantiate()
		add_child_autofree(inst)
		_assert_size_close(_aabb_of(inst).size, PLACEHOLDERS[id] as Vector3, id)


func _assert_faces_minus_z(inst: Node3D, id: String, markers: Array[String]) -> void:
	var root_back: Vector3 = inst.global_transform.basis.z
	assert_almost_eq(root_back.distance_to(Vector3.BACK), 0.0, 0.001, "%s: raíz girada" % id)
	for marker_name: String in markers:
		var marker: Node3D = inst.get_node_or_null(marker_name) as Node3D
		assert_not_null(marker, "%s sin %s" % [id, marker_name])
		if marker != null:
			var dir: Vector3 = marker.global_position - inst.global_position
			assert_lt(dir.z, 0.0, "%s: %s debe estar en -Z global" % [id, marker_name])


func test_ac2_placeholders_face_minus_z() -> void:
	for id: String in PLACEHOLDERS:
		var inst: Node3D = (load(PLACEHOLDER_DIR + id + ".tscn") as PackedScene).instantiate()
		add_child_autofree(inst)
		_assert_faces_minus_z(inst, id, ["Front"] as Array[String])


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
	for id: String in ["BoxSmall", "TableSquare"]:
		assert_not_null(inst.get_node_or_null(id), id)
