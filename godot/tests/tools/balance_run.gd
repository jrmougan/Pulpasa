extends SceneTree
## Arranque de `balance_measure.gd` (PUL-164). Carga el medidor cuando existen los autoloads.


func _initialize() -> void:
	var path: String = (get_script() as Script).resource_path.get_base_dir().path_join(
		"balance_measure.gd"
	)
	var node: Node = (load(path) as GDScript).new()
	root.add_child.call_deferred(node)
