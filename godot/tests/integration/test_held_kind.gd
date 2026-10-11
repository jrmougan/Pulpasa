extends GutTest
## PUL-121 (ADR-003 §11.1): `HeldKind.of` traduce el objeto de la mano a `ActionRules.Held` con las
## escenas reales (caja, pulpo, cachelos).

const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const CACHELOS_SCENE: PackedScene = preload("res://entities/items/cachelos.tscn")
const BOX: BoxData = preload("res://data/boxes/box.tres")


func _box(fill: float) -> Box:
	var box: Box = BOX_SCENE.instantiate()
	box.data = BOX
	add_child_autofree(box)
	box.fill = fill
	return box


func _ingredient(scene: PackedScene) -> Ingredient:
	return add_child_autofree(scene.instantiate()) as Ingredient


func test_nothing_in_hand() -> void:
	assert_eq(HeldKind.of(null), ActionRules.Held.NOTHING)


func test_octopus_by_cooking_state() -> void:
	var octopus: Ingredient = _ingredient(OCTOPUS_SCENE)
	assert_eq(HeldKind.of(octopus), ActionRules.Held.OCTOPUS_RAW)
	octopus.set_cooked()
	assert_eq(HeldKind.of(octopus), ActionRules.Held.OCTOPUS_COOKED)


func test_cachelos_by_cooking_state() -> void:
	var cachelos: Ingredient = _ingredient(CACHELOS_SCENE)
	assert_eq(HeldKind.of(cachelos), ActionRules.Held.CACHELOS_RAW)
	cachelos.set_cooked()
	assert_eq(HeldKind.of(cachelos), ActionRules.Held.CACHELOS_COOKED)


func test_burnt_ingredient_is_other() -> void:
	var octopus: Ingredient = _ingredient(OCTOPUS_SCENE)
	octopus.set_burnt()
	assert_eq(HeldKind.of(octopus), ActionRules.Held.OTHER)


func test_ingredient_without_data_is_other() -> void:
	var octopus: Ingredient = _ingredient(OCTOPUS_SCENE)
	octopus.data = null
	assert_eq(HeldKind.of(octopus), ActionRules.Held.OTHER)


func test_box_by_fill() -> void:
	assert_eq(HeldKind.of(_box(0.0)), ActionRules.Held.BOX_EMPTY)
	assert_eq(HeldKind.of(_box(0.5)), ActionRules.Held.BOX_PARTIAL)
	assert_eq(HeldKind.of(_box(0.99)), ActionRules.Held.BOX_PARTIAL)
	assert_eq(HeldKind.of(_box(1.0)), ActionRules.Held.BOX_FULL)


func test_box_goes_empty_partial_full_with_real_cuts() -> void:
	var box: Box = _box(0.0)
	var octopus: Ingredient = _ingredient(OCTOPUS_SCENE)
	octopus.set_cooked()
	var holder: FakeHolder = add_child_autofree(FakeHolder.new())
	var actor: InteractionComponent = add_child_autofree(InteractionComponent.new())
	actor.holder = holder
	assert_true(holder.pick_up(octopus))
	assert_true(box.interact(actor))
	assert_eq(HeldKind.of(box), ActionRules.Held.BOX_PARTIAL)
	for _i: int in BOX.presses_to_fill - 1:
		box.interact(actor)
	assert_eq(HeldKind.of(box), ActionRules.Held.BOX_FULL)


func test_anything_else_is_other() -> void:
	var node: Node3D = add_child_autofree(Node3D.new())
	assert_eq(HeldKind.of(node), ActionRules.Held.OTHER)
	assert_eq(HeldKind.of(add_child_autofree(FakePickable.new())), ActionRules.Held.OTHER)
