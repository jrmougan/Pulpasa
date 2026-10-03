extends GutTest
## Test trivial para validar que GUT corre en headless.


func test_engine_is_4_7() -> void:
	var info: Dictionary = Engine.get_version_info()
	assert_eq(info["major"], 4)
	assert_eq(info["minor"], 7)


func test_main_menu_scene_loads() -> void:
	var scene: PackedScene = load("res://ui/menus/main_menu.tscn")
	assert_not_null(scene)
	var node: Node = scene.instantiate()
	add_child_autofree(node)
	assert_true(node is Control)
