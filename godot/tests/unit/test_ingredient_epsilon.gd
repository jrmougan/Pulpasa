extends GutTest
## PUL-104 AC2: el ingrediente se agota (y se libera) aunque el gasto acumulado tenga error de
## redondeo; el llenado por corte redondeado a la baja dejaba el pulpo en ~1e-5.

const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
## `1/6` truncado a la baja: 12 cortes de M gastan 99,99996 de 100.
const ROUNDED_DOWN_FILL: float = 0.1666666


func _octopus() -> Ingredient:
	var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
	add_child_autofree(octopus)
	return octopus


func test_ac2_rounded_down_cuts_still_exhaust_and_free() -> void:
	var octopus: Ingredient = _octopus()
	for i: int in 12:
		octopus.take(ROUNDED_DOWN_FILL * octopus.data.amount_per_full_box)
	assert_true(octopus.is_queued_for_deletion(), "agotado con épsilon se libera")
	assert_eq(octopus.remaining, 0.0)


func test_ac2_without_epsilon_the_residue_would_remain() -> void:
	var spent: float = 0.0
	for i: int in 12:
		spent += ROUNDED_DOWN_FILL * 50.0
	assert_gt(100.0 - spent, 0.0, "el residuo existe y es menor que el épsilon")
	assert_lt(100.0 - spent, Ingredient.EMPTY_EPSILON)


func test_ac2_clearly_non_empty_is_not_freed() -> void:
	var octopus: Ingredient = _octopus()
	octopus.take(99.0)
	assert_false(octopus.is_queued_for_deletion())
	assert_almost_eq(octopus.remaining, 1.0, 0.0001)
