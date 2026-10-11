class_name MenuPanel
extends Control
## Presentación compartida. Los textos fuente actúan como claves gettext para tr().
## En el perfil MOBILE aplica los mínimos de texto y de botón del UiProfile (ADR-005 E3).

@onready var title: Label = %Title
@onready var description: Label = %Description
@onready var ratio: Label = %Ratio
@onready var primary_button: Button = %PrimaryButton
@onready var restart_button: Button = %RestartButton
@onready var exit_button: Button = %ExitButton


func _ready() -> void:
	get_viewport().size_changed.connect(apply_profile)
	apply_profile()


func configure(heading: String, primary: String) -> void:
	title.text = tr(heading)
	primary_button.text = tr(primary)
	exit_button.text = tr("Menú") if _is_mobile() else tr("Salir")
	apply_profile()


## Muestra «Reiniciar» entre el botón principal y el de salida (pausa en el perfil MOBILE).
func show_restart(label: String) -> void:
	restart_button.text = tr(label)
	restart_button.show()
	apply_profile()


func focus_primary() -> void:
	primary_button.grab_focus()


## Enlaza el foco y, en MOBILE, aplica los mínimos del perfil. Se repite si cambia el contenido.
func apply_profile() -> void:
	FocusRing.link([primary_button, restart_button, exit_button] as Array[Control])
	if _is_mobile():
		# El lienzo mide 720 de alto: la insignia decorativa cede su sitio a los botones de 120 px.
		%Badge.hide()
		(%Card as Control).custom_minimum_size.x = GameState.ui_profile.menu_card_width
		MenuMobile.apply(self, GameState.ui_profile)


func _is_mobile() -> bool:
	return GameState.platform == PlatformProfile.Kind.MOBILE
