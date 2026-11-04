extends SceneTree
## Lanzador de repro_entrega_tras_caducidad.gd (PUL-196). Desde la raíz del repo:
##   REPRO_LEAD=1 godot --headless --path godot --script "$PWD/docs/evidence/PUL-196/repro_lanzador.gd"


func _initialize() -> void:
	var path: String = (get_script() as Script).resource_path.get_base_dir()
	var harness: Node = (load(path + "/repro_entrega_tras_caducidad.gd") as GDScript).new()
	root.add_child.call_deferred(harness)
