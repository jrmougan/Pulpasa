class_name TicketEntry
extends HBoxContainer
## Talla de caja, receta en texto y una pegatina por condimento en orden canónico
## (M1, PUL-030/031; PUL-060; talla: PUL-099).

## Mismo estilo que la fila de pegatinas de la caja: tamaño y marca de llama (D18).
const BADGE_STYLE: BoxBadgeStyle = preload("res://data/config/box_badges.tres")
## Fracción de la pegatina que ocupa el icono (blanco, o `StickerInk.INK` en discos claros).
const ICON_FRACTION: float = 0.7
## Fracción de la pegatina que ocupa la marca de llama.
const MARK_FRACTION: float = 0.5


func setup(data: OrderData) -> void:
	%Recipe.text = ""
	%SizeBadge.visible = false
	for child: Node in %SeasoningIcons.get_children():
		%SeasoningIcons.remove_child(child)
		child.queue_free()
	if data == null:
		return
	if data.recipe != null:
		%Recipe.text = _translated(data.recipe.translation_key, data.recipe.display_name)
		_show_size(data.recipe.box)
	for seasoning: SeasoningData in SeasoningRules.canonical_order(data.seasonings):
		%SeasoningIcons.add_child(_make_seasoning_widget(seasoning))


## Silueta y letra de talla del mismo `BoxData` que el rack (R10).
func _show_size(box: BoxData) -> void:
	if box == null or (box.icon == null and box.short_label.is_empty()):
		return
	%SizeIcon.texture = box.icon
	%SizeIcon.visible = box.icon != null
	## El icono ya lleva la letra grabada: el texto es solo el respaldo sin icono.
	%SizeLabel.text = box.short_label
	%SizeLabel.visible = box.icon == null and not box.short_label.is_empty()
	%SizeBadge.visible = true


func _make_seasoning_widget(seasoning: SeasoningData) -> Control:
	var name_text: String = _translated(seasoning.translation_key, seasoning.display_name)
	if seasoning.icon == null:
		var label: Label = Label.new()
		label.text = name_text
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return label
	var side: float = float(BADGE_STYLE.badge_icon_px)
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
