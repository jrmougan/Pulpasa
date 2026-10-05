extends GutTest
## PUL-043: cada .glb de assets/models (salvo placeholders/) cumple art-bible §2: importa, escala
## aplicada y en rango, origen en la base, frente −Z (marcador Anchor_Front) y ajustes de import.
## Las medidas se toman en el espacio del padre de la instancia: la transformación de la raíz
## del .glb cuenta (una raíz escalada o girada falla). Los casos negativos generan escenas en
## memoria y comprueban que el validador las rechaza.

const MODELS_DIR := "res://assets/models/"
const EXCLUDED_DIRS: Array[String] = ["placeholders"]
const SMOKE_CUBE := "res://assets/models/_pipeline/test_cube/test_cube.glb"
const FRONT_ANCHOR := "Anchor_Front"
const SCALE_EPS := 0.001
const FRONT_MAX_ANGLE_DEG := 1.0
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
	var aabb: AABB = _mesh_aabb(instance)
	assert_almost_eq(aabb.size.y, 1.0, 0.01, "alto del cubo")
	assert_almost_eq(aabb.size.x, 1.0, 0.01, "ancho del cubo")


func test_ac3_cada_glb_importa_y_cumple_reglas() -> void:
	var glbs: Array[String] = _find_glbs(MODELS_DIR)
	assert_gt(glbs.size(), 0, "no hay .glb en assets/models")
	for path: String in glbs:
		assert_eq(_import_errors(path), [] as Array[String], "%s: ajustes de import" % path)
		var instance: Node3D = _instantiate(path)
		if instance != null:
			assert_eq(_model_errors(instance), [] as Array[String], "%s: reglas de modelo" % path)


func test_validador_acepta_modelo_correcto() -> void:
	var model: Node3D = autofree(_fake_model())
	assert_eq(_model_errors(model), [] as Array[String])


func test_validador_rechaza_raiz_escalada_y_girada() -> void:
	# Caso del revisor: bounds y frente locales correctos, pero en mundo mide 2 m y mira a +Z.
	var model: Node3D = autofree(_fake_model())
	model.transform = Transform3D(Basis(Vector3.UP, PI).scaled(Vector3.ONE * 2.0), Vector3.ZERO)
	var errors: Array[String] = _model_errors(model)
	assert_true(_has_error(errors, "escala"), "debe detectar la escala de la raíz: %s" % [errors])
	assert_true(_has_error(errors, "frente"), "debe detectar el frente a +Z: %s" % [errors])


func test_validador_rechaza_raiz_girada() -> void:
	var model: Node3D = autofree(_fake_model())
	model.rotate_y(PI)
	assert_true(_has_error(_model_errors(model), "frente"))


func test_validador_rechaza_frente_ladeado() -> void:
	var model: Node3D = autofree(_fake_model())
	model.rotate_y(deg_to_rad(30.0))
	assert_true(_has_error(_model_errors(model), "frente"))


func test_validador_rechaza_hijo_escalado() -> void:
	var model: Node3D = autofree(_fake_model())
	(model.get_node("Body") as Node3D).scale = Vector3(1.0, 2.0, 1.0)
	assert_true(_has_error(_model_errors(model), "escala"))


func test_validador_rechaza_origen_fuera_de_la_base() -> void:
	var model: Node3D = autofree(_fake_model())
	(model.get_node("Body") as Node3D).position.y = 0.0
	assert_true(_has_error(_model_errors(model), "base"))


func test_validador_rechaza_sin_marcador_de_frente() -> void:
	var model: Node3D = autofree(_fake_model())
	var anchor: Node = model.get_node(FRONT_ANCHOR)
	model.remove_child(anchor)
	anchor.free()
	assert_true(_has_error(_model_errors(model), FRONT_ANCHOR))


func test_validador_rechaza_camaras_y_luces() -> void:
	var model: Node3D = autofree(_fake_model())
	model.add_child(Camera3D.new())
	model.add_child(OmniLight3D.new())
	var errors: Array[String] = _model_errors(model)
	assert_true(_has_error(errors, "cámara"))
	assert_true(_has_error(errors, "luz"))


## Modelo correcto en memoria: cubo de 1 m con la base en y = 0 y Anchor_Front en −Z.
func _fake_model() -> Node3D:
	var root := Node3D.new()
	root.name = "fake_model"
	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = BoxMesh.new()
	body.position = Vector3(0.0, 0.5, 0.0)
	root.add_child(body)
	var anchor := Node3D.new()
	anchor.name = FRONT_ANCHOR
	anchor.position = Vector3(0.0, 0.0, -0.5)
	root.add_child(anchor)
	return root


func _has_error(errors: Array[String], fragment: String) -> bool:
	for error: String in errors:
		if error.contains(fragment):
			return true
	return false


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
		autofree(instance)
	return instance


func _import_errors(path: String) -> Array[String]:
	var errors: Array[String] = []
	var config := ConfigFile.new()
	if config.load(path + ".import") != OK:
		errors.append("sin .import")
		return errors
	var root_scale: float = config.get_value("params", "nodes/root_scale", 0.0)
	if absf(root_scale - 1.0) > SCALE_EPS:
		errors.append("nodes/root_scale = %s, debe ser 1" % root_scale)
	if config.get_value("params", "nodes/use_name_suffixes", true):
		errors.append("sufijos de nombre (colisiones) activados")
	if config.get_value("params", "materials/extract", -1) != 0:
		errors.append("materiales extraídos; deben ir embebidos")
	return errors


## Errores de art-bible §2 de un modelo instanciado (vacío si cumple). Todo se mide en el espacio
## del padre de [param root], incluida la transformación de la propia raíz.
func _model_errors(root: Node3D) -> Array[String]:
	var errors: Array[String] = []
	var nodes: Array[Node3D] = [root]
	nodes.append_array(_descendants_3d(root))
	for node: Node3D in nodes:
		var scale: Vector3 = node.transform.basis.get_scale()
		if (scale - Vector3.ONE).length() > SCALE_EPS:
			errors.append("%s: escala %s sin aplicar" % [node.name, scale])
		if node is Camera3D:
			errors.append("%s: trae cámara" % node.name)
		if node is Light3D:
			errors.append("%s: trae luz" % node.name)
	var aabb: AABB = _mesh_aabb(root)
	if aabb.size == Vector3.ZERO:
		errors.append("sin mallas")
	else:
		if aabb.size.y < MIN_SIZE or aabb.size.y > MAX_HEIGHT:
			errors.append("alto %.3f m fuera de rango" % aabb.size.y)
		var footprint: float = maxf(aabb.size.x, aabb.size.z)
		if footprint < MIN_SIZE or footprint > MAX_FOOTPRINT:
			errors.append("planta %.3f m fuera de rango" % footprint)
		if absf(aabb.position.y) > BASE_EPS:
			errors.append("origen fuera de la base (y mín = %.3f)" % aabb.position.y)
	errors.append_array(_front_errors(root))
	return errors


func _front_errors(root: Node3D) -> Array[String]:
	var errors: Array[String] = []
	var anchor: Node3D = root.find_child(FRONT_ANCHOR, true, false) as Node3D
	if anchor == null:
		errors.append("sin marcador %s" % FRONT_ANCHOR)
		return errors
	var pos: Vector3 = _to_parent_space(root, anchor).origin
	var flat := Vector2(pos.x, pos.z)
	if flat.length() < SCALE_EPS:
		errors.append("frente indefinido: %s sobre el origen" % FRONT_ANCHOR)
		return errors
	var angle: float = rad_to_deg(flat.angle_to(Vector2(0.0, -1.0)))
	if absf(angle) > FRONT_MAX_ANGLE_DEG:
		errors.append("frente desviado %.1f° de -Z (%s en %s)" % [angle, FRONT_ANCHOR, pos])
	return errors


## Transformación de [param node] en el espacio del padre de [param root] (incluye root).
func _to_parent_space(root: Node3D, node: Node3D) -> Transform3D:
	var xform: Transform3D = node.transform
	var current: Node = node.get_parent()
	while node != root and current != null:
		if current is Node3D:
			xform = (current as Node3D).transform * xform
		if current == root:
			break
		current = current.get_parent()
	return xform


func _descendants_3d(node: Node) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for child: Node in node.get_children():
		if child is Node3D:
			result.append(child as Node3D)
		result.append_array(_descendants_3d(child))
	return result


func _mesh_aabb(root: Node3D) -> AABB:
	var aabb := AABB()
	var first := true
	for child: Node3D in _descendants_3d(root):
		var mesh_instance: MeshInstance3D = child as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var box: AABB = _to_parent_space(root, mesh_instance) * mesh_instance.mesh.get_aabb()
		aabb = box if first else aabb.merge(box)
		first = false
	return aabb
