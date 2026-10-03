class_name MenuPanel
extends Control
## Presentación compartida. Los textos fuente actúan como claves gettext para tr().

@onready var title: Label = %Title
@onready var description: Label = %Description
@onready var ratio: Label = %Ratio
@onready var primary_button: Button = %PrimaryButton
@onready var exit_button: Button = %ExitButton


func configure(heading: String, primary: String) -> void:
	title.text = tr(heading)
	primary_button.text = tr(primary)
	exit_button.text = tr("Salir")


func focus_primary() -> void:
	primary_button.grab_focus()
