extends SceneTree
## Arranque de `capture_pul138.gd`: un script `-s` se compila antes que los autoloads; este no
## referencia nada del proyecto y carga la captura como nodo de la raíz cuando ya existen. Igual
## que `docs/evidence/PUL-136/probe_boot.gd`.


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	var path: String = (get_script() as Script).resource_path.get_base_dir() + "/capture_pul138.gd"
	var node: Node = Node.new()
	node.set_script(load(path))
	root.add_child(node)
