extends SceneTree
## Arranque de `capture.gd` (como `docs/evidence/PUL-183/capture_boot.gd`): un script `-s` se
## compila antes que los autoloads; se añade `capture.gd` como nodo tras el primer diferido.


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	var path: String = (get_script() as Script).resource_path.get_base_dir() + "/capture.gd"
	var node: Node = Node.new()
	node.set_script(load(path))
	root.add_child(node)
