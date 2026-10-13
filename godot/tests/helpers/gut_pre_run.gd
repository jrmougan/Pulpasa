extends GutHookScript
## Hook previo de GUT (`.gutconfig.json`, `pre_run_script`; PUL-154): el panel de salida de GUT
## (`TestOutput` y el resto de su GUI, también el compacto) cubre la ventana en su capa 128 y se
## queda con el puntero, también en headless, así que ningún test podría hacer clic real en un
## `Control`. Pone `MOUSE_FILTER_IGNORE` a todos los `Control` de esa capa. Solo cambia la entrada:
## la salida de consola y el `junit.xml` no cambian. El panel GUT del editor usa su propia config.


func run() -> void:
	var layer: Node = (gut as Node).get_parent()
	if layer == null:
		return
	for node: Node in layer.find_children("*", "Control", true, false):
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
