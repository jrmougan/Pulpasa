extends GutTest
## PUL-098 AC1/AC2: cortes por talla (R9) y etiqueta/icono de tamaño (R10).

const BOXES: Dictionary = {
	"small": {"fill": 0.25, "label": "S", "icon": "size_s"},
	"medium": {"fill": 1.0 / 6.0, "label": "M", "icon": "size_m"},
	"large": {"fill": 0.1, "label": "L", "icon": "size_l"},
}


func test_ac1_fill_per_press_gives_4_6_10_presses() -> void:
	for id: String in BOXES:
		var box: BoxData = load("res://data/boxes/%s.tres" % id) as BoxData
		assert_not_null(box, id)
		if box:
			var fill: float = (BOXES[id] as Dictionary)["fill"]
			assert_almost_eq(box.fill_per_press, fill, 0.0001, id)
			assert_eq(box.capacity, 100.0, id)


func test_ac2_short_label_and_icon_filled() -> void:
	var icons: Array[Texture2D] = []
	for id: String in BOXES:
		var box: BoxData = load("res://data/boxes/%s.tres" % id) as BoxData
		assert_not_null(box, id)
		if not box:
			continue
		var expected: Dictionary = BOXES[id]
		assert_eq(box.short_label, expected["label"], id)
		assert_not_null(box.icon, id)
		if box.icon:
			assert_eq(
				box.icon.resource_path,
				"res://assets/textures/ui/box_sizes/%s.png" % expected["icon"],
				id
			)
			assert_false(icons.has(box.icon), "icono distinto por talla")
			icons.append(box.icon)
