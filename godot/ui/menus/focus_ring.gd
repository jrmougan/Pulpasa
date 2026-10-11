class_name FocusRing
extends RefCounted
## Navegación cíclica entre los controles visibles de un menú (teclado y mando): enlaza arriba,
## abajo, izquierda, derecha, siguiente y anterior. Un único control se apunta a sí mismo.


static func link(controls: Array[Control]) -> void:
	var visible_controls: Array[Control] = []
	for control: Control in controls:
		if control.visible:
			visible_controls.append(control)
	var count: int = visible_controls.size()
	for i: int in count:
		var current: Control = visible_controls[i]
		var previous: NodePath = current.get_path_to(visible_controls[(i + count - 1) % count])
		var next: NodePath = current.get_path_to(visible_controls[(i + 1) % count])
		current.focus_neighbor_top = previous
		current.focus_neighbor_left = previous
		current.focus_previous = previous
		current.focus_neighbor_bottom = next
		current.focus_neighbor_right = next
		current.focus_next = next
