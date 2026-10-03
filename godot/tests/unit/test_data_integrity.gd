extends GutTest
## AC3: todos los .tres de data/ cargan con su tipo y sin referencias rotas.

const DATA_DIR: String = "res://data"


func _collect(dir_path: String, out: Array[String]) -> void:
	for file: String in DirAccess.get_files_at(dir_path):
		if file.ends_with(".tres"):
			out.append(dir_path.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir_path):
		_collect(dir_path.path_join(sub), out)


func test_ac3_all_tres_load() -> void:
	var paths: Array[String] = []
	_collect(DATA_DIR, paths)
	assert_eq(paths.size(), 15)
	for path: String in paths:
		var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		assert_not_null(res, path)


func test_ac3_no_missing_dependencies() -> void:
	var paths: Array[String] = []
	_collect(DATA_DIR, paths)
	for path: String in paths:
		for dep: String in ResourceLoader.get_dependencies(path):
			var dep_path: String = dep.get_slice("::", 2) if "::" in dep else dep
			assert_true(ResourceLoader.exists(dep_path), "%s -> %s" % [path, dep])


func test_ac3_references_are_filled() -> void:
	for id: String in ["individual", "combo_duo", "familiar"]:
		var recipe: RecipeData = load("res://data/recipes/%s.tres" % id) as RecipeData
		assert_not_null(recipe.ingredient, id)
		assert_not_null(recipe.box, id)
