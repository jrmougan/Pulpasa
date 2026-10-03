class_name TicketEntry
extends HBoxContainer
## Receta y condimentos en texto; los iconos pertenecen a M1.


func setup(data: OrderData) -> void:
	%Recipe.text = ""
	%Seasonings.text = ""
	if data == null:
		return
	if data.recipe != null:
		%Recipe.text = _translated(data.recipe.translation_key, data.recipe.display_name)
	var names: PackedStringArray = []
	for seasoning: SeasoningData in data.seasonings:
		names.append(_translated(seasoning.translation_key, seasoning.display_name))
	%Seasonings.text = "\n".join(names)


func _translated(key: String, fallback: String) -> String:
	if key.is_empty():
		return fallback
	var translated: String = tr(key)
	return fallback if translated == key else translated
