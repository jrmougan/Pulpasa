# Compila todos los scripts del proyecto y falla si alguno no compila, aunque ningún test lo cargue.
# Uso, desde godot/: godot --headless -s res://../tools/check_scripts.gd
# Un script `-s` se compila antes de los autoloads: este archivo no referencia nada del proyecto.
# Sale con 0 y la línea final `check_scripts: OK` si todo compila, y con 1 en cualquier otro caso.
extends SceneTree

const EXCLUDED_DIRS: PackedStringArray = ["res://addons", "res://.godot", "res://.mcp"]


func _initialize() -> void:
	var paths: PackedStringArray = _collect_scripts("res://")
	# Un recorrido vacío no prueba nada: se trata como fallo para no dar un verde falso.
	if paths.is_empty():
		printerr("check_scripts: no se ha encontrado ningún script.")
		quit(1)
		return
	var failed: PackedStringArray = []
	for path: String in paths:
		var script: Script = load(path) as Script
		if script == null or not script.can_instantiate():
			failed.append(path)
	for path: String in failed:
		printerr("check_scripts: no compila: %s" % path)
	if not failed.is_empty():
		printerr("check_scripts: %d de %d scripts no compilan." % [failed.size(), paths.size()])
		quit(1)
		return
	print("check_scripts: OK (%d scripts)" % paths.size())
	quit(0)


func _collect_scripts(dir_path: String) -> PackedStringArray:
	var found: PackedStringArray = []
	for file_name: String in DirAccess.get_files_at(dir_path):
		if file_name.get_extension() == "gd":
			found.append(dir_path.path_join(file_name))
	for sub_name: String in DirAccess.get_directories_at(dir_path):
		var sub_path: String = dir_path.path_join(sub_name)
		if sub_path not in EXCLUDED_DIRS:
			found.append_array(_collect_scripts(sub_path))
	return found
