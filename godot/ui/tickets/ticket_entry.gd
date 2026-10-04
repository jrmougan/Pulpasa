class_name TicketEntry
extends HBoxContainer
## Receta en texto y un icono por condimento (M1, PUL-030/PUL-031).

const ICON_SIZE: Vector2 = Vector2(28.0, 28.0)


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
		if seasoning.icon == null:
			continue
		var icon: TextureRect = TextureRect.new()
		icon.custom_minimum_size = ICON_SIZE
		icon.texture = seasoning.icon
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.tooltip_text = _translated(seasoning.translation_key, seasoning.display_name)
		%SeasoningIcons.add_child(icon)


func _translated(key: String, fallback: String) -> String:
	if key.is_empty():
		return fallback
	var translated: String = tr(key)
	return fallback if translated == key else translated
