extends GutTest
## PUL-020: HUD dirigido exclusivamente por eventos del reloj de ronda.

const HUD_SCENE: PackedScene = preload("res://ui/hud/hud.tscn")
const BusScript: GDScript = preload("res://autoload/event_bus.gd")
const ServiceScript: GDScript = preload("res://autoload/order_service.gd")
const ManagerScript: GDScript = preload("res://autoload/round_manager.gd")
const CATALOG: OrderCatalog = preload("res://data/orders/order_catalog.tres")

var _bus: Node
var _service: Node
var _manager: Node
var _hud: RoundHUD


func before_each() -> void:
	_bus = add_child_autofree(BusScript.new())
	_service = ServiceScript.new()
	_service.set_bus(_bus)
	add_child_autofree(_service)
	_service.setup(CATALOG)
	_manager = ManagerScript.new()
	_manager.set_bus(_bus)
	_manager.set_order_service(_service)
	_manager.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child_autofree(_manager)
	_manager.set_physics_process(false)
	_hud = HUD_SCENE.instantiate()
	_hud.set_bus(_bus)
	add_child_autofree(_hud)


func after_each() -> void:
	get_tree().paused = false


func _start() -> void:
	var config: RoundConfig = RoundConfig.new()
	config.duration = 180.0
	_manager.start_round(config, [1] as Array[int])


func _text(node_name: String) -> String:
	return (_hud.get_node("%" + node_name) as Label).text


func test_ac1_mount_does_not_start_round_or_own_clock() -> void:
	assert_null(_manager.round_state)
	assert_eq(_text("TimeLeft"), "0.0 s")
	_bus.round_started.emit(180.0)
	await wait_physics_frames(4)
	assert_eq(_text("TimeLeft"), "180.0 s", "sin eventos no avanza")


func test_ac1_round_signals_update_time_and_finish_at_zero() -> void:
	_start()
	assert_eq(_text("TimeLeft"), "180.0 s")
	_manager.round_state.advance(60.0)
	assert_eq(_text("TimeLeft"), "120.0 s")
	_manager.round_state.advance(120.0)
	assert_eq(_text("TimeLeft"), "0.0 s")
	assert_true(_manager.round_state.is_finished())


func test_ac1_pause_freezes_actual_round_and_hud() -> void:
	_start()
	_manager.set_physics_process(true)
	get_tree().paused = true
	var before: float = _manager.round_state.get_time_left()
	await wait_process_frames(4)
	assert_eq(_manager.round_state.get_time_left(), before)
	assert_eq(_text("TimeLeft"), "180.0 s")
	get_tree().paused = false
	await wait_physics_frames(4)
	assert_lt(_manager.round_state.get_time_left(), before)


func test_ac1_productivity_uses_reported_boxes_and_elapsed_time() -> void:
	_start()
	_bus.score_changed.emit(2, 0)
	assert_eq(_text("BoxesPerMinute"), "0.00", "no divide por cero")
	_manager.round_state.advance(60.0)
	assert_eq(_text("BoxesPerMinute"), "2.00")
	_bus.score_changed.emit(3, 0)
	assert_eq(_text("BoxesPerMinute"), "3.00")
	_manager.round_state.advance(60.0)
	assert_eq(_text("BoxesPerMinute"), "1.50")
	_start()
	assert_eq(_text("BoxesPerMinute"), "0.00", "reinicio sin score_changed inicial")
