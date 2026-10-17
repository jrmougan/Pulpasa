extends SceneTree
## PUL-185: capturas de evidencia del tema v3 (HUD, ticket) y de las pegatinas con anillo INK
## (ticket y billboard 3D sobre caja y suelo), con zoom a la pegatina del picante (P4).
## Uso (desde la raíz):
##   xvfb-run -a godot --path godot --audio-driver Dummy --resolution 1280x720 \
##     -s ../docs/evidence/PUL-185/capture_pul185.gd
## El montaje va en `capture_pul185_node.gd`, cargado en diferido: los scripts que usan
## `EventBus` no compilan antes de que existan los autoloads.


func _initialize() -> void:
	_mount.call_deferred()


func _mount() -> void:
	var node: Node = Node.new()
	var dir: String = (get_script() as Script).resource_path.get_base_dir()
	node.set_script(load(dir.path_join("capture_pul185_node.gd")))
	root.add_child(node)
