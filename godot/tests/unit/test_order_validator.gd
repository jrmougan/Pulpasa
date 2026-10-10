extends GutTest
## PUL-006 / PUL-028 AC2: OrderValidator es puro y aplica igualdad exacta (D4/D17).

const ORDER_PATH: String = "res://data/orders/con_cachelos.tres"
const A_FEIRA_PATH: String = "res://data/orders/a_feira.tres"
const HOT_PATH: String = "res://data/seasonings/hot_dressing.tres"
const BOX: BoxData = preload("res://data/boxes/box.tres")

var _order: OrderData


func before_each() -> void:
	_order = (load(ORDER_PATH) as OrderData).duplicate(true)


func _valid_contents(order: OrderData) -> BoxContents:
	return BoxContents.new(
		BOX,
		order.recipe.ingredient,
		IngredientData.CookingState.COOKED,
		1.0,
		order.seasonings.duplicate()
	)


func test_ac2_correct_box_matches() -> void:
	assert_true(OrderValidator.matches(_order, _valid_contents(_order)))


func test_pul113_any_box_with_right_contents_matches() -> void:
	## D25: la caja no se compara; vale cualquier BoxData (o ninguna) con el contenido correcto.
	var other: BoxData = BoxData.new()
	other.presses_to_fill = 3
	var contents: BoxContents = _valid_contents(_order)
	contents.box = other
	assert_true(OrderValidator.matches(_order, contents))
	contents.box = null
	assert_true(OrderValidator.matches(_order, contents))


func test_ac2_no_ingredient_does_not_match() -> void:
	var contents: BoxContents = _valid_contents(_order)
	contents.ingredient = null
	assert_false(OrderValidator.matches(_order, contents))


func test_ac2_uncooked_ingredient_does_not_match() -> void:
	var contents: BoxContents = _valid_contents(_order)
	contents.ingredient_state = IngredientData.CookingState.RAW
	assert_false(OrderValidator.matches(_order, contents))


func test_ac2_missing_seasoning_does_not_match() -> void:
	var contents: BoxContents = _valid_contents(_order)
	contents.seasonings.pop_back()
	assert_false(OrderValidator.matches(_order, contents))


func test_ac2_extra_seasoning_is_rejected_in_m1() -> void:
	var contents: BoxContents = _valid_contents(_order)
	contents.seasonings.append(load(HOT_PATH) as SeasoningData)
	assert_false(OrderValidator.matches(_order, contents))


func test_ac2_seasoning_order_does_not_matter() -> void:
	var contents: BoxContents = _valid_contents(_order)
	contents.seasonings.reverse()
	assert_true(OrderValidator.matches(_order, contents))


func test_ac2_null_contents_do_not_match() -> void:
	assert_false(OrderValidator.matches(_order, null))


func test_ac2_matches_does_not_mutate_contents() -> void:
	var contents: BoxContents = _valid_contents(_order)
	var before: int = contents.seasonings.size()
	OrderValidator.matches(_order, contents)
	assert_eq(contents.seasonings.size(), before)
	assert_eq(contents.box, BOX)


func test_pul114_wrong_dressing_does_not_match() -> void:
	# D25: la caja errónea es de contenido; el aliño picante no vale para «Á feira».
	var a_feira: OrderData = load(A_FEIRA_PATH) as OrderData
	var contents: BoxContents = _valid_contents(a_feira)
	assert_true(OrderValidator.matches(a_feira, contents))
	contents.seasonings = [load(HOT_PATH) as SeasoningData]
	assert_false(OrderValidator.matches(a_feira, contents))


func test_pul114_cachelos_missing_or_extra_does_not_match() -> void:
	var a_feira: OrderData = load(A_FEIRA_PATH) as OrderData
	var with_cachelos: BoxContents = _valid_contents(_order)
	assert_false(OrderValidator.matches(a_feira, with_cachelos), "cachelos de más")
	var without: BoxContents = _valid_contents(a_feira)
	assert_false(OrderValidator.matches(_order, without), "faltan cachelos")
