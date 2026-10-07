extends SceneTree
## Arranque de `target_map.gd` (PUL-090). Carga el medidor cuando los autoloads ya existen.


func _initialize() -> void:
	var path: String = (get_script() as Script).resource_path.get_base_dir().path_join(
		"target_map.gd"
	)
	var node: Node = (load(path) as GDScript).new()
	root.add_child.call_deferred(node)
