class_name TicketEntry
extends HBoxContainer
## Receta y condimentos en texto; los iconos pertenecen a M1.


func setup(data: OrderData) -> void:
	%Recipe.text = ""
	%Seasonings.text = ""
	if data == null:
		return
	if data.recipe != null:
		%Recipe.text = _data_text(data.recipe, "RECIPE_")
	var names: PackedStringArray = []
	for seasoning: SeasoningData in data.seasonings:
		names.append(_data_text(seasoning, "SEASONING_"))
	%Seasonings.text = "\n".join(names)


func _data_text(data: Resource, prefix: String) -> String:
	var key: String = prefix + data.resource_path.get_file().get_basename().to_upper()
	var translated: String = tr(key)
	return data.display_name if translated == key else translated
