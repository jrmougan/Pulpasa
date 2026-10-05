extends GutTest
## PUL-043: cada .glb de assets/models (salvo placeholders/) cumple art-bible §2: importa, escala
## aplicada y en rango, origen en la base, frente −Z (marcador Anchor_Front) y ajustes de import.

const MODELS_DIR := "res://assets/models/"
const EXCLUDED_DIRS: Array[String] = ["placeholders"]
const SMOKE_CUBE := "res://assets/models/_pipeline/test_cube/test_cube.glb"
const FRONT_ANCHOR := "Anchor_Front"
const SCALE_EPS := 0.001
const MIN_SIZE := 0.05
const MAX_HEIGHT := 6.0
const MAX_FOOTPRINT := 12.0
const BASE_EPS := 0.05


func test_ac3_cubo_de_prueba_existe() -> void:
	assert_has(_find_glbs(MODELS_DIR), SMOKE_CUBE, "falta el cubo de humo de PUL-043")


func test_ac3_cubo_de_prueba_mide_1_m() -> void:
	var instance: Node3D = _instantiate(SMOKE_CUBE)
	if instance == null:
		return
	var aabb: AABB = _mesh_aabb(instance, instance)
	assert_almost_eq(aabb.size.y, 1.0, 0.01, "alto del cubo")
	assert_almost_eq(aabb.size.x, 1.0, 0.01, "ancho del cubo")


func test_ac3_cada_glb_importa_y_cumple_reglas() -> void:
	var glbs: Array[String] = _find_glbs(MODELS_DIR)
	assert_gt(glbs.size(), 0, "no hay .glb en assets/models")
	for path: String in glbs:
		_check_import_params(path)
		var instance: Node3D = _instantiate(path)
		if instance == null:
			continue
		_check_scale(path, instance)
		_check_bounds(path, instance)
		_check_front(path, instance)
		_check_no_cameras_or_lights(path, instance)


func _find_glbs(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return found
	for sub: String in dir.get_directories():
		if dir_path == MODELS_DIR and sub in EXCLUDED_DIRS:
			continue
		found.append_array(_find_glbs(dir_path + sub + "/"))
	for file_name: String in dir.get_files():
		if file_name.get_extension() == "glb":
			found.append(dir_path + file_name)
	return found


func _instantiate(path: String) -> Node3D:
	var scene: PackedScene = load(path) as PackedScene
	assert_not_null(scene, "no importa %s" % path)
	if scene == null:
		return null
	var instance: Node3D = scene.instantiate() as Node3D
	assert_not_null(instance, "la raíz de %s no es Node3D" % path)
	if instance != null:
		add_child_autofree(instance)
	return instance


func _check_import_params(path: String) -> void:
	var config := ConfigFile.new()
	assert_eq(config.load(path + ".import"), OK, "%s sin .import" % path)
	var root_scale: float = config.get_value("params", "nodes/root_scale", 0.0)
	assert_almost_eq(root_scale, 1.0, SCALE_EPS, "%s: nodes/root_scale debe ser 1" % path)
	var suffixes: bool = config.get_value("params", "nodes/use_name_suffixes", true)
	assert_false(suffixes, "%s: sufijos de nombre (colisiones) deben estar desactivados" % path)
	var extract: int = config.get_value("params", "materials/extract", -1)
	assert_eq(extract, 0, "%s: los materiales van embebidos en el .glb" % path)


func _check_scale(path: String, instance: Node3D) -> void:
	for node: Node3D in _descendants_3d(instance):
		var scale: Vector3 = node.transform.basis.get_scale()
		var ok: bool = (
			scale.is_equal_approx(Vector3.ONE) or (scale - Vector3.ONE).length() < SCALE_EPS
		)
		assert_true(ok, "%s: %s con escala %s sin aplicar" % [path, node.name, scale])


func _check_bounds(path: String, instance: Node3D) -> void:
	var aabb: AABB = _mesh_aabb(instance, instance)
	assert_gt(aabb.size.length(), 0.0, "%s sin mallas" % path)
	assert_between(aabb.size.y, MIN_SIZE, MAX_HEIGHT, "%s: alto fuera de rango" % path)
	var footprint: float = maxf(aabb.size.x, aabb.size.z)
	assert_between(footprint, MIN_SIZE, MAX_FOOTPRINT, "%s: planta fuera de rango" % path)
	assert_almost_eq(aabb.position.y, 0.0, BASE_EPS, "%s: el origen no está en la base" % path)


func _check_front(path: String, instance: Node3D) -> void:
	var anchor: Node3D = instance.find_child(FRONT_ANCHOR, true, false) as Node3D
	assert_not_null(anchor, "%s sin marcador %s" % [path, FRONT_ANCHOR])
	if anchor == null:
		return
	var pos: Vector3 = instance.global_transform.affine_inverse() * anchor.global_position
	assert_lt(pos.z, 0.0, "%s: el frente debe mirar a -Z (Anchor_Front en %s)" % [path, pos])
	assert_lt(absf(pos.x), -pos.z, "%s: Anchor_Front ladeado (%s)" % [path, pos])


func _check_no_cameras_or_lights(path: String, instance: Node3D) -> void:
	for node: Node3D in _descendants_3d(instance):
		assert_false(node is Camera3D, "%s: trae cámara %s" % [path, node.name])
		assert_false(node is Light3D, "%s: trae luz %s" % [path, node.name])


func _descendants_3d(node: Node) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for child: Node in node.get_children():
		if child is Node3D:
			result.append(child as Node3D)
		result.append_array(_descendants_3d(child))
	return result


func _mesh_aabb(root: Node3D, node: Node) -> AABB:
	var aabb := AABB()
	var first := true
	var to_root: Transform3D = root.global_transform.affine_inverse()
	for child: Node3D in _descendants_3d(node):
		var mesh_instance: MeshInstance3D = child as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var box: AABB = (to_root * mesh_instance.global_transform) * mesh_instance.mesh.get_aabb()
		aabb = box if first else aabb.merge(box)
		first = false
	return aabb
