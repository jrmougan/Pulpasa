extends GutTest

const STATIONS: Array[String] = [
	"res://entities/stations/octopus_storage.tscn", "res://entities/stations/cachelos_storage.tscn"
]
const ENTITIES_DIR: String = "res://entities"
## Los sandboxes de desarrollo no son entidades de juego.
const SKIPPED_DIR: String = "/sandbox/"


func test_ac1_stations_are_interactable() -> void:
	for path: String in STATIONS:
		var scene: PackedScene = load(path)
		assert_not_null(scene, "scene loaded: " + path)
		var instance: Node = scene.instantiate()
		assert_true(instance.is_in_group("interactable"), path + " is in interactable group")
		instance.free()


# --- PUL-131 AC3 (D26, ADR-003 §11.2): get_action_hint obligatorio ------------------------------


## Todas las escenas de `entities/` (sin sandboxes), por ruta.
func _entity_scenes(dir_path: String = ENTITIES_DIR) -> Array[String]:
	var found: Array[String] = []
	for sub: String in DirAccess.get_directories_at(dir_path):
		if (dir_path + "/" + sub + "/").contains(SKIPPED_DIR):
			continue
		found.append_array(_entity_scenes(dir_path + "/" + sub))
	for file_name: String in DirAccess.get_files_at(dir_path):
		if file_name.ends_with(".tscn"):
			found.append(dir_path + "/" + file_name)
	return found


## Nodos `interactable` de cada escena de `entities/`, con su ruta.
func _interactables() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for path: String in _entity_scenes():
		var root: Node = (load(path) as PackedScene).instantiate()
		var nodes: Array[Node] = [root]
		nodes.append_array(root.find_children("*", "", true, false))
		for node: Node in nodes:
			if node.is_in_group(InteractionContract.GROUP_INTERACTABLE):
				found.append({"path": path, "node": node})
		add_child_autofree(root)
	return found


func test_pul131_ac3_every_interactable_of_entities_implements_get_action_hint() -> void:
	var interactables: Array[Dictionary] = _interactables()
	assert_gte(interactables.size(), 10, "hay interactables que comprobar")
	var kinds: Dictionary = {}
	for entry: Dictionary in interactables:
		var node: Node = entry["node"]
		var where: String = "%s en %s" % [node.name, entry["path"]]
		assert_true(node.has_method(InteractionContract.HINT_METHOD), where)
		assert_eq(InteractionContract.violations(node), [] as Array[String], where)
		kinds[node.get_script()] = true
	assert_gte(kinds.size(), 8, "scripts distintos: spawners, olla, pasaplatos, cubo, caja...")


func test_pul131_ac3_no_interactable_depends_on_the_verbless_equivalence() -> void:
	# La equivalencia `ok(&"")` solo es para dobles de test: ningun interactable de `entities/` la usa
	# porque todos publican su propia consulta; sin actor ni mano, ninguno inventa un objetivo.
	for entry: Dictionary in _interactables():
		var node: Node = entry["node"]
		var hint: ActionHint = node.call(InteractionContract.HINT_METHOD, null) as ActionHint
		assert_not_null(hint, "%s devuelve un ActionHint" % node.name)
		if hint != null:
			assert_false(hint.is_target(), "%s sin actor no es objetivo" % node.name)
			assert_eq(hint.verb, ActionVerb.NONE)


func test_pul131_ac3_the_stand_is_not_interactable_any_more() -> void:
	var stand: Node = (
		(load("res://entities/stations/order_stand.tscn") as PackedScene).instantiate()
	)
	add_child_autofree(stand)
	assert_false(stand.is_in_group(InteractionContract.GROUP_INTERACTABLE))
	for entry: Dictionary in _interactables():
		assert_false(entry["node"] is OrderStand, "el puesto no es interactable")
