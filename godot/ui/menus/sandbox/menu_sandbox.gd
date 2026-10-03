extends Control
## Sandbox aislado: un turno corto real, sin temporizador de UI ni señales fingidas.

const CONFIG: RoundConfig = preload("res://data/config/round_config.tres")
const CATALOG: OrderCatalog = preload("res://data/orders/order_catalog.tres")

@onready var start_button: Button = %StartButton


func _ready() -> void:
	start_button.text = tr("Iniciar turno de demostración")
	start_button.pressed.connect(_start_round)
	start_button.grab_focus()


func _start_round() -> void:
	start_button.hide()
	OrderService.setup(CATALOG)
	var config: RoundConfig = CONFIG.duplicate() as RoundConfig
	config.duration = 2.0
	RoundManager.start_round(config, [])
