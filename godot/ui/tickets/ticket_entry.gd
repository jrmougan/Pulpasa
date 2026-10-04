class_name TicketEntry
extends HBoxContainer
## Receta en texto y un icono por condimento (M1, PUL-030/PUL-031).

const ICON_SIZE: Vector2 = Vector2(28.0, 28.0)
const MARK_SIZE: Vector2 = Vector2(14.0, 14.0)
## Marca de forma del picante: no depender solo del tono (daltonismo).
const HOT_MARK: Texture2D = preload("res://assets/textures/icons/small-fire.svg")


func setup(data: OrderData) -> void:
	%Recipe.text = ""
	for child: Node in %SeasoningIcons.get_children():
		%SeasoningIcons.remove_child(child)
		child.queue_free()
	if data == null:
		return
	if data.recipe != null:
		%Recipe.text = _translated(data.recipe.translation_key, data.recipe.display_name)
	for seasoning: SeasoningData in data.seasonings:
		%SeasoningIcons.add_child(_make_seasoning_widget(seasoning))


func _make_seasoning_widget(seasoning: SeasoningData) -> Control:
	var name_text: String = _translated(seasoning.translation_key, seasoning.display_name)
	if seasoning.icon == null:
		var label: Label = Label.new()
		label.text = name_text
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return label
	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = ICON_SIZE
	icon.texture = seasoning.icon
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if seasoning.color.a > 0.0:
		icon.self_modulate = seasoning.color
	if seasoning.type == SeasoningData.SeasoningType.HOT_PAPRIKA:
		var mark: TextureRect = TextureRect.new()
		mark.name = "HotMark"
		mark.texture = HOT_MARK
		mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark.custom_minimum_size = MARK_SIZE
		mark.size = MARK_SIZE
		mark.position = ICON_SIZE - MARK_SIZE
		icon.add_child(mark)
	return icon


func _translated(key: String, fallback: String) -> String:
	if key.is_empty():
		return fallback
	var translated: String = tr(key)
	return fallback if translated == key else translated
