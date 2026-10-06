extends GutTest
## PUL-016 AC3: el pulpo se libera al agotarse aunque no tenga barra (B9).
## PUL-045: una malla por estado (octopus_raw / octopus_cooked) bajo `Model`.

const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")


func _octopus() -> Ingredient:
	var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
	add_child_autofree(octopus)
	return octopus


func test_ac3_freed_when_depleted_without_bar() -> void:
	var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
	octopus.get_node("%AmountBar").free()
	add_child_autofree(octopus)
	assert_eq(octopus.take(60.0), 60.0)
	assert_false(octopus.is_queued_for_deletion())
	assert_eq(octopus.take(60.0), 40.0, "solo da lo que queda")
	assert_eq(octopus.remaining, 0.0)
	assert_true(octopus.is_queued_for_deletion())


func test_ac3_freed_when_depleted_with_bar() -> void:
	var octopus: Ingredient = _octopus()
	octopus.take(100.0)
	assert_true(octopus.is_queued_for_deletion())


func test_ac3_starts_with_100_and_emits_amount_changed() -> void:
	var octopus: Ingredient = _octopus()
	assert_eq(octopus.remaining, 100.0)
	watch_signals(octopus)
	octopus.take(10.0)
	assert_signal_emitted_with_parameters(octopus, "amount_changed", [90.0])


func test_ac3_take_after_depleted_gives_nothing() -> void:
	var octopus: Ingredient = _octopus()
	octopus.take(100.0)
	assert_eq(octopus.take(5.0), 0.0)


func test_amount_bar_hidden_until_cut() -> void:
	var octopus: Ingredient = _octopus()
	var bar: Node3D = octopus.get_node("%AmountBar")
	assert_false(bar.visible)
	octopus.take(10.0)
	assert_true(bar.visible)


func test_cooked_state_shows_the_cooked_mesh() -> void:
	# PUL-045: el .glb trae octopus_raw y octopus_cooked; solo se ve la del estado actual.
	var octopus: Ingredient = _octopus()
	var raw: Node3D = octopus.get_node("Model").find_child("octopus_raw") as Node3D
	var cooked: Node3D = octopus.get_node("Model").find_child("octopus_cooked") as Node3D
	assert_not_null(raw)
	assert_not_null(cooked)
	assert_false(octopus.is_cooked())
	assert_true(raw.visible, "en crudo se ve la malla cruda")
	assert_false(cooked.visible)
	octopus.set_cooked()
	assert_true(octopus.is_cooked())
	assert_eq(octopus.state, IngredientData.CookingState.COOKED)
	assert_false(raw.visible)
	assert_true(cooked.visible, "al cocerse se ve la malla cocida")


func test_burnt_state_uses_burnt_mesh_or_falls_back_to_cooked() -> void:
	for with_burnt: bool in [true, false]:
		var names: Array[String] = ["thing_raw", "thing_cooked"]
		if with_burnt:
			names.append("thing_burnt")
		var ingredient: Ingredient = _variant_ingredient(names)
		ingredient.state = IngredientData.CookingState.BURNT
		ingredient._apply_state_visual()
		var model: Node = ingredient.get_node("Model")
		assert_false((model.get_node("thing_raw") as Node3D).visible)
		assert_eq((model.get_node("thing_cooked") as Node3D).visible, not with_burnt)
		if with_burnt:
			assert_true((model.get_node("thing_burnt") as Node3D).visible)


func test_model_without_state_meshes_keeps_material_swap() -> void:
	# Sin mallas hermanas `_raw`/`_cooked` (un modelo de un solo estado) se cambia el material.
	var raw_material: StandardMaterial3D = StandardMaterial3D.new()
	var cooked_material: StandardMaterial3D = StandardMaterial3D.new()
	var ingredient: Ingredient = _variant_ingredient(["body"], raw_material)
	ingredient.raw_material = raw_material
	ingredient.cooked_material = cooked_material
	ingredient.set_cooked()
	var body: MeshInstance3D = ingredient.get_node("Model/body")
	assert_eq(body.material_override, cooked_material, "el cuerpo usa el material de cocido")


func _variant_ingredient(mesh_names: Array[String], material: Material = null) -> Ingredient:
	var ingredient: Ingredient = Ingredient.new()
	var model: Node3D = Node3D.new()
	model.name = "Model"
	ingredient.add_child(model)
	for mesh_name: String in mesh_names:
		var mesh: MeshInstance3D = MeshInstance3D.new()
		mesh.name = mesh_name
		mesh.material_override = material
		model.add_child(mesh)
		mesh.owner = ingredient
	add_child_autofree(ingredient)
	return ingredient
