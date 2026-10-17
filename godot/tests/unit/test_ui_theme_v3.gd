extends GutTest
## PUL-185: tema de UI, tinta de pegatinas y anillo delimitador con la paleta v3 (biblia §6.2,
## §6.2.1 y §7). Contrastes WCAG 2.1 con `StickerInk.contrast`.

const THEME: Theme = preload("res://ui/theme/default_theme.tres")
const ENTRY_SCENE: PackedScene = preload("res://ui/tickets/ticket_entry.tscn")
const HOT: SeasoningData = preload("res://data/seasonings/hot_dressing.tres")
const CACHELOS: SeasoningData = preload("res://data/seasonings/cachelos.tres")
const SWEET: SeasoningData = preload("res://data/seasonings/sweet_dressing.tres")

const NAVY: Color = Color("#1D3557")
const BURNT: Color = Color("#2A2320")
const SURFACE_TOP: Color = Color("#EDE8DF")
const CREAM: Color = Color("#F7F4EC")
const AMBER: Color = Color("#F2C230")
const BOX_RED: Color = Color("#C8402F")
const FLOOR: Color = Color("#C4A882")
## Discos de §6.2.1 que deben contrastar ≥ 3.24 : 1 con el anillo (sal y aceite sin `.tres`).
const LIGHT_DISCS: Array[Color] = [
	Color("#D6361F"), Color("#F2D56B"), Color("#F2C230"), Color("#F7F4EC")
]


func _panel(type: StringName) -> StyleBoxFlat:
	return THEME.get_stylebox(&"panel", type) as StyleBoxFlat


func _assert_border(box: StyleBoxFlat, width: int, color: Color, label: String) -> void:
	for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		assert_eq(box.get_border_width(side), width, "%s: borde %d px" % [label, width])
	assert_eq(box.border_color, color, "%s: borde #EDE8DF" % label)


func test_ac1_ui_panel_is_opaque_navy_with_light_border() -> void:
	var panel: StyleBoxFlat = _panel(&"UiPanel")
	assert_eq(panel.bg_color, NAVY)
	assert_eq(panel.bg_color.a, 1.0, "sin transparencia")
	_assert_border(panel, 2, SURFACE_TOP, "UiPanel")
	for corner: int in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_RIGHT, CORNER_BOTTOM_LEFT]:
		assert_eq(panel.get_corner_radius(corner), 4)
	assert_eq(panel.shadow_size, 3)
	assert_eq(panel.shadow_color, Color(0.07, 0.13, 0.22, 0.35))


func test_ac1_header_and_display_well_use_burnt_wells() -> void:
	for type: StringName in [&"UiHeader", &"DisplayWell"]:
		var well: StyleBoxFlat = _panel(type)
		assert_eq(well.bg_color, BURNT, type)
		_assert_border(well, 1, SURFACE_TOP, type)
		assert_eq(well.get_corner_radius(CORNER_TOP_LEFT), 3, type)


func test_ac2_text_colors_reach_aaa_on_panels_and_wells() -> void:
	var text: Color = THEME.get_color(&"font_color", &"Label")
	assert_eq(text, CREAM, "texto principal")
	for type: StringName in [&"FigureLabel", &"DisplayLabel"]:
		assert_eq(THEME.get_color(&"font_color", type), AMBER, "cifras en %s" % type)
	assert_eq(THEME.get_color(&"digits_color", &"OrderTicket"), AMBER)
	var expected: Dictionary[String, float] = {
		"crema/navy": 11.24, "crema/burnt": 14.05, "ámbar/navy": 7.38, "ámbar/burnt": 9.22
	}
	var actual: Dictionary[String, float] = {
		"crema/navy": StickerInk.contrast(CREAM, NAVY),
		"crema/burnt": StickerInk.contrast(CREAM, BURNT),
		"ámbar/navy": StickerInk.contrast(AMBER, NAVY),
		"ámbar/burnt": StickerInk.contrast(AMBER, BURNT),
	}
	for key: String in expected:
		assert_gte(actual[key], 7.37, key)
		assert_almost_eq(actual[key], expected[key], 0.01, key)


func test_ac3_ink_is_state_burnt_and_ring_separates_from_world() -> void:
	assert_eq(StickerInk.INK, BURNT)
	assert_almost_eq(StickerInk.luminance(StickerInk.INK), 0.0180, 0.0001)
	assert_gte(StickerInk.contrast(StickerInk.INK, BOX_RED), 3.10, "anillo sobre caja")
	assert_gte(StickerInk.contrast(StickerInk.INK, FLOOR), 6.80, "anillo sobre suelo")
	for disc: Color in LIGHT_DISCS:
		assert_gte(StickerInk.contrast(StickerInk.INK, disc), 3.24, "disco %s" % disc.to_html())
		assert_eq(StickerInk.icon_color(disc), StickerInk.INK)


func test_ac3_hot_sticker_is_octagonal_with_cream_icon() -> void:
	assert_true(StickerInk.is_hot(HOT))
	assert_eq(StickerInk.ring_color(HOT), StickerInk.HOT_RING, "anillo del picante en un punto")
	assert_eq(StickerInk.icon_color(HOT.color), CREAM)
	assert_almost_eq(StickerInk.contrast(CREAM, HOT.color), 8.21, 0.01)
	var octagon: Image = BadgeRow.shape_texture(true, false).get_image()
	var circle: Image = BadgeRow.shape_texture(false, false).get_image()
	## Junto a un vértice del octógono (cerca del borde derecho, algo bajo el centro): dentro del
	## octógono, fuera del círculo inscrito.
	var probe: Vector2i = Vector2i(octagon.get_width() - 2, octagon.get_height() * 11 / 16)
	assert_gt(octagon.get_pixelv(probe).a, 0.5, "octógono")
	assert_eq(circle.get_pixelv(probe).a, 0.0, "círculo")


func test_ac3_every_ticket_sticker_has_ink_ring() -> void:
	for seasoning: SeasoningData in [SWEET, HOT, CACHELOS]:
		var entry: TicketEntry = ENTRY_SCENE.instantiate()
		add_child_autofree(entry)
		var data: OrderData = OrderData.new()
		data.seasonings = [seasoning] as Array[SeasoningData]
		entry.setup(data)
		var sticker: Control = entry.get_node("%SeasoningIcons").get_child(0)
		var box: StyleBoxFlat = (sticker.get_node("Disc") as Panel).get_theme_stylebox("panel")
		assert_gt(box.border_width_left, 0, seasoning.display_name)
		assert_eq(box.border_color, StickerInk.INK, seasoning.display_name)
		assert_eq(box.corner_detail == 1, seasoning == HOT, "solo el picante es octogonal")
		var icon: TextureRect = sticker.get_node("Icon")
		assert_eq(icon.self_modulate, StickerInk.icon_color(seasoning.color))
