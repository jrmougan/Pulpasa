extends SceneTree
## Arranque de `capture_minimal.gd` (adaptado de `docs/evidence/PUL-152/capture_boot.gd`):
## un script `-s` se compila antes de que existan los autoloads. Este cargador espera al
## primer diferido y añade `capture_minimal.gd` como nodo hijo de `root`.


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	var path: String = (get_script() as Script).resource_path.get_base_dir() + "/capture_minimal.gd"
	var node: Node = Node.new()
	node.set_script(load(path))
	root.add_child(node)
