extends GutTest
## PUL-016 AC3: el pulpo se libera al agotarse aunque no tenga barra (B9).

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


func test_cooked_state_uses_cooked_material_from_data() -> void:
	var octopus: Ingredient = _octopus()
	assert_false(octopus.is_cooked())
	assert_not_null(octopus.cooked_material)
	octopus.set_cooked()
	assert_true(octopus.is_cooked())
	assert_eq(octopus.state, IngredientData.CookingState.COOKED)
	var meshes: Array[Node] = octopus.get_node("Model").find_children("*", "MeshInstance3D")
	assert_gt(meshes.size(), 0)
	var cooked: int = 0
	for mesh: Node in meshes:
		if (mesh as MeshInstance3D).material_override == octopus.cooked_material:
			cooked += 1
	assert_gt(cooked, 0, "el cuerpo usa el material de cocido")
