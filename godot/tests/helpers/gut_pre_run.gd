extends GutHookScript
## Hook previo de GUT (`.gutconfig.json`, `pre_run_script`; PUL-154): en headless
## (`tools/verify.sh`) la GUI de GUT (`TestOutput` y el resto del panel) se estira a toda la
## ventana en su capa 128 y se queda con el puntero, así que ningún test podría hacer clic real en
## un `Control`. Pone `MOUSE_FILTER_IGNORE` a todos los `Control` de esa capa, botones incluidos:
## con el panel estirado, el tirador de tamaño y los botones Compact y Continue caen en los bordes
## y esquinas que clican los tests. Con ventana no hace nada: el runner conserva el ratón
## (Continue cierra `pause_before_teardown`). Solo cambia la entrada: la salida de consola y el
## `junit.xml` no cambian. El panel GUT del editor usa su propia config.


func run() -> void:
	if DisplayServer.get_name() != "headless":
		return
	var layer: Node = (gut as Node).get_parent()
	if layer == null:
		return
	for node: Node in layer.find_children("*", "Control", true, false):
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
