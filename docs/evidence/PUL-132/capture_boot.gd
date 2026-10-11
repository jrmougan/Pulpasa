extends SceneTree
## Arranque de `capture_d26.gd`: un script `-s` se compila antes de que existan los autoloads, y el
## juego los usa. Este no referencia nada del proyecto; cuando los autoloads ya están, carga la
## herramienta de capturas como un nodo de la raíz. Ver el uso en `capture_d26.gd`.


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	var path: String = (get_script() as Script).resource_path.get_base_dir() + "/capture_d26.gd"
	var node: Node = Node.new()
	node.set_script(load(path))
	root.add_child(node)
