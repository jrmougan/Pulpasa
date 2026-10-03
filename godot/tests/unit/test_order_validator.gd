extends GutTest
## PUL-006 AC2: OrderValidator es puro y aplica la regla M0 (especias ⊆, B15).

const ORDER_1_PATH: String = "res://data/orders/order_1.tres"
const SMALL_BOX_PATH: String = "res://data/boxes/small.tres"
const PAPRIKA_PATH: String = "res://data/seasonings/paprika.tres"
const OIL_PATH: String = "res://data/seasonings/oil.tres"

var _order: OrderData


func before_each() -> void:
	_order = load(ORDER_1_PATH) as OrderData


func _valid_contents(order: OrderData) -> BoxContents:
	return BoxContents.new(
		order.recipe.box,
		order.recipe.ingredient,
		IngredientData.CookingState.COOKED,
		1.0,
		order.seasonings.duplicate()
	)


func test_ac2_correct_box_matches() -> void:
	assert_true(OrderValidator.matches(_order, _valid_contents(_order)))


func test_ac2_wrong_box_does_not_match() -> void:
	var contents: BoxContents = _valid_contents(_order)
	contents.box = load(SMALL_BOX_PATH) as BoxData
	assert_false(OrderValidator.matches(_order, contents))


func test_ac2_missing_box_does_not_match() -> void:
	var contents: BoxContents = _valid_contents(_order)
	contents.box = null
	assert_false(OrderValidator.matches(_order, contents))


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
	contents.seasonings.append(load(PAPRIKA_PATH) as SeasoningData)
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
	assert_eq(contents.box, _order.recipe.box)


func test_ac2_exact_validation_with_oil() -> void:
	var oil: SeasoningData = load(OIL_PATH) as SeasoningData
	_order.seasonings.append(oil)
	var contents: BoxContents = _valid_contents(_order)
	assert_true(OrderValidator.matches(_order, contents))
	contents.seasonings.erase(oil)
	assert_false(OrderValidator.matches(_order, contents))
