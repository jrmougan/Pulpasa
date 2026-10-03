class_name OrderTicket
extends PanelContainer
## Un ticket por id; solo el bus modifica su paciencia.

var order_id: int = -1
var _bus: Node


func _ready() -> void:
	if _bus == null:
		_bus = EventBus
	_bus.order_patience_changed.connect(_on_patience_changed)
	%PatienceBar.hide()


func set_bus(bus: Node) -> void:
	_bus = bus


func setup(order: ActiveOrder) -> void:
	order_id = order.id
	var id_format: String = tr("TICKET_ID_FORMAT")
	if id_format == "TICKET_ID_FORMAT":
		id_format = "#%d"
	%OrderId.text = id_format % order_id
	%Entry.setup(order.data)
	%PatienceBar.hide()


func _on_patience_changed(id: int, time_left: float, max_time: float) -> void:
	if id != order_id:
		return
	var bar: TextureProgressBar = %PatienceBar
	bar.visible = max_time > 0.0
	if max_time > 0.0:
		bar.max_value = max_time
		bar.value = clampf(time_left, 0.0, max_time)
