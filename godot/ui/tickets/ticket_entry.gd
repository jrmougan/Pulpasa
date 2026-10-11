class_name TicketEntry
extends HBoxContainer
## Receta en texto y una pegatina por condimento en orden canónico
## (M1, PUL-030/031; PUL-060). Sin talla de caja (D25, PUL-113).

## Mismo estilo que la fila de pegatinas de la caja: tamaño y marca de llama (D18).
const BADGE_STYLE: BoxBadgeStyle = preload("res://data/config/box_badges.tres")
## Fracción de la pegatina que ocupa el icono (blanco, o `StickerInk.INK` en discos claros).
const ICON_FRACTION: float = 0.7
## Fracción de la pegatina que ocupa la marca de llama.
const MARK_FRACTION: float = 0.5

## Lado de la pegatina en unidades de lienzo (el de la caja; MOBILE lo cambia, PUL-129).
var icon_px: float = float(BADGE_STYLE.badge_icon_px)
var _data: OrderData


## Fila bajo la receta, a la derecha de las pegatinas: el ticket móvil mete aquí id y reloj.
func extras() -> HBoxContainer:
	return %Extras


## Receta y fila de pegatinas sin hueco entre ellas (ticket móvil, PUL-129).
func compact() -> void:
	$Details.add_theme_constant_override(&"separation", 0)


## Cambia el lado de las pegatinas y las vuelve a montar con la misma comanda.
func set_icon_px(side: float) -> void:
	if is_equal_approx(side, icon_px):
		return
	icon_px = side
	setup(_data)


func setup(data: OrderData) -> void:
	_data = data
	%Recipe.text = ""
	for child: Node in %SeasoningIcons.get_children():
		%SeasoningIcons.remove_child(child)
		child.queue_free()
	if data == null:
		return
	if data.recipe != null:
		%Recipe.text = _translated(data.recipe.translation_key, data.recipe.display_name)
	for seasoning: SeasoningData in SeasoningRules.canonical_order(data.seasonings):
		%SeasoningIcons.add_child(_make_seasoning_widget(seasoning))


func _make_seasoning_widget(seasoning: SeasoningData) -> Control:
	var name_text: String = _translated(seasoning.translation_key, seasoning.display_name)
	if seasoning.icon == null:
		var label: Label = Label.new()
		label.text = name_text
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return label
	var side: float = icon_px
	var sticker: Control = Control.new()
	sticker.name = "Sticker"
	sticker.custom_minimum_size = Vector2(side, side)
	sticker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sticker.tooltip_text = name_text
	var disc: Panel = Panel.new()
	disc.name = "Disc"
	disc.set_anchors_preset(Control.PRESET_FULL_RECT)
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = seasoning.color if seasoning.color.a > 0.0 else Color.GRAY
	style.set_corner_radius_all(int(side / 2.0))
	if StickerInk.is_light(style.bg_color):
		style.border_color = StickerInk.INK
		style.set_border_width_all(maxi(roundi(side * StickerInk.RING_FRACTION), 1))
	disc.add_theme_stylebox_override("panel", style)
	sticker.add_child(disc)
	var icon: TextureRect = TextureRect.new()
	icon.name = "Icon"
	icon.texture = seasoning.icon
	icon.self_modulate = StickerInk.icon_color(style.bg_color)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_side: float = side * ICON_FRACTION
	icon.size = Vector2(icon_side, icon_side)
	icon.position = Vector2(side - icon_side, side - icon_side) / 2.0
	sticker.add_child(icon)
	if BADGE_STYLE.has_hot_mark(seasoning) and BADGE_STYLE.hot_mark != null:
		var mark_side: float = side * MARK_FRACTION
		var mark: TextureRect = TextureRect.new()
		mark.name = "HotMark"
		mark.texture = BADGE_STYLE.hot_mark
		mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark.size = Vector2(mark_side, mark_side)
		mark.position = Vector2(side - mark_side, side - mark_side)
		sticker.add_child(mark)
	return sticker


func _translated(key: String, fallback: String) -> String:
	if key.is_empty():
		return fallback
	var translated: String = tr(key)
	return fallback if translated == key else translated
