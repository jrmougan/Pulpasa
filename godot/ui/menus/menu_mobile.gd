class_name MenuMobile
extends RefCounted
## Ajustes de los menús en el perfil MOBILE (ADR-005 E3): texto mínimo, botones de alto mínimo y
## separación mínima, en unidades de lienzo según el alto actual (UiScale.px_to_units). Se puede
## repetir al cambiar el alto del lienzo: parte siempre de las medidas originales de la escena.

const META_HEIGHT: StringName = &"menu_mobile_base_height"
const META_SEPARATION: StringName = &"menu_mobile_base_separation"


## Aplica el perfil a todo `root`. Con un perfil sin mínimos (escritorio) no cambia nada.
static func apply(root: Control, profile: UiProfile) -> void:
	var canvas_height: float = root.get_viewport().get_visible_rect().size.y
	TextFloor.apply(root, UiScale.px_to_units(profile.text_min_px, canvas_height))
	if profile.menu_button_min_px <= 0.0:
		return
	var button_height: float = ceilf(UiScale.px_to_units(profile.menu_button_min_px, canvas_height))
	var gap: int = ceili(UiScale.px_to_units(profile.menu_button_gap_px, canvas_height))
	var containers: Dictionary[BoxContainer, bool] = {}
	for node: Node in root.find_children("*", "Button", true, false):
		var button: Button = node as Button
		if not button.has_meta(META_HEIGHT):
			button.set_meta(META_HEIGHT, button.custom_minimum_size.y)
		var base_height: float = button.get_meta(META_HEIGHT)
		button.custom_minimum_size.y = maxf(base_height, button_height)
		var parent: BoxContainer = button.get_parent() as BoxContainer
		if parent != null:
			containers[parent] = true
	for container: BoxContainer in containers:
		if not container.has_meta(META_SEPARATION):
			container.set_meta(META_SEPARATION, container.get_theme_constant(&"separation"))
		var base_separation: int = container.get_meta(META_SEPARATION)
		container.add_theme_constant_override(&"separation", maxi(base_separation, gap))
