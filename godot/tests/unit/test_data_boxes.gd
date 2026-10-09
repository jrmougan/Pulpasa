extends GutTest
## PUL-098 AC1/AC2: cortes por talla (R9) y etiqueta/icono de tamaño (R10).

const BOXES: Dictionary = {
	"small": {"presses": 4, "label": "S", "icon": "size_s"},
	"medium": {"presses": 6, "label": "M", "icon": "size_m"},
	"large": {"presses": 10, "label": "L", "icon": "size_l"},
}


func test_ac1_presses_to_fill_gives_4_6_10_presses() -> void:
	for id: String in BOXES:
		var box: BoxData = load("res://data/boxes/%s.tres" % id) as BoxData
		assert_not_null(box, id)
		if box:
			var presses: int = (BOXES[id] as Dictionary)["presses"]
			assert_eq(box.presses_to_fill, presses, id)
			assert_eq(box.fill_after(presses), 1.0, "%s llena exacto en %d" % [id, presses])
			assert_lt(box.fill_after(presses - 1), 1.0, "%s no llena antes" % id)
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
