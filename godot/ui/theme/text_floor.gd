class_name TextFloor
extends RefCounted
## Mínimo de texto por perfil (ADR-005 E3, diseño AC14): sube a `min_units` los tamaños de fuente
## de Label, Button y RichTextLabel bajo `root`, tanto los del tema como los overrides de escena.
## Es reversible: guarda el override de partida en un meta y se puede volver a aplicar al cambiar el
## alto del lienzo. Con `min_units <= 0` restaura los tamaños originales.

const META_BASE: StringName = &"text_floor_base"


static func apply(root: Node, min_units: float) -> void:
	for node: Node in root.find_children("*", "Control", true, false):
		var font_name: StringName = _font_name_of(node)
		if font_name == &"":
			continue
		var control: Control = node as Control
		if control.has_meta(META_BASE):
			_restore(control, font_name)
		var base: int = control.get_theme_font_size(font_name)
		var wanted: int = ceili(min_units)
		if min_units > 0.0 and base < wanted:
			# El meta guarda el override de escena previo (-1 si el tamaño venía del tema).
			var previous: int = base if control.has_theme_font_size_override(font_name) else -1
			control.set_meta(META_BASE, previous)
			control.add_theme_font_size_override(font_name, wanted)


## Tamaño efectivo de la fuente de un control con texto (0 si no tiene).
static func font_size_of(control: Control) -> int:
	var font_name: StringName = _font_name_of(control)
	return control.get_theme_font_size(font_name) if font_name != &"" else 0


static func _restore(control: Control, font_name: StringName) -> void:
	var previous: int = control.get_meta(META_BASE)
	control.remove_meta(META_BASE)
	control.remove_theme_font_size_override(font_name)
	if previous >= 0:
		control.add_theme_font_size_override(font_name, previous)


static func _font_name_of(node: Node) -> StringName:
	if node is RichTextLabel:
		return &"normal_font_size"
	if node is Label or node is Button:
		return &"font_size"
	return &""
