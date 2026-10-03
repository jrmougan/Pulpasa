extends GutTest
## AC2: fill_per_press de las tres cajas.

const BOXES: Dictionary = {
	"small": 0.2,
	"medium": 0.1,
	"large": 0.05,
}


func test_ac2_fill_per_press_matches_prototype() -> void:
	for id: String in BOXES:
		var box: BoxData = load("res://data/boxes/%s.tres" % id) as BoxData
		assert_not_null(box, id)
		if box:
			assert_almost_eq(box.fill_per_press, BOXES[id] as float, 0.0001, id)
			assert_eq(box.capacity, 100.0, id)
