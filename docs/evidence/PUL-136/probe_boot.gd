extends SceneTree
## Arranque de `probe_pul136.gd` (o de `reach_pul136.gd` con `--reach`): un script `-s` se compila
## antes de que existan los autoloads, y el juego los usa. Este no referencia nada del proyecto;
## cuando los autoloads ya están, carga la sonda como un nodo de la raíz. Igual que
## `docs/evidence/PUL-134/capture_boot.gd`.


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	var tool: String = "/probe_pul136.gd"
	if "--reach" in OS.get_cmdline_user_args():
		tool = "/reach_pul136.gd"
	var path: String = (get_script() as Script).resource_path.get_base_dir() + tool
	var node: Node = Node.new()
	node.set_script(load(path))
	root.add_child(node)
