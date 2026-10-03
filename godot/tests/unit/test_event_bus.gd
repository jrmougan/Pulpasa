extends GutTest
## PUL-004 AC1: EventBus declara exactamente las señales de bus de docs/arch/signals.md §2.

const EventBusScript: GDScript = preload("res://autoload/event_bus.gd")

## Firma esperada por señal: lista de [nombre_arg, Variant.Type, clases admitidas].
## Clases vacías: tipo primitivo. Las de objeto son tipos de valor de core/ (PUL-006).
const ORDER_CLASSES: Array[String] = ["ActiveOrder"]
const RESULT_CLASSES: Array[String] = ["RoundResult"]
const CATALOG: Dictionary = {
	"round_started": [["duration", TYPE_FLOAT, []]],
	"round_time_changed": [["time_left", TYPE_FLOAT, []]],
	"round_finished": [["result", TYPE_OBJECT, RESULT_CLASSES]],
	"score_changed": [["boxes_delivered", TYPE_INT, []], ["revenue", TYPE_INT, []]],
	"orders_reset": [],
	"order_generated": [["order", TYPE_OBJECT, ORDER_CLASSES]],
	"order_completed": [["order", TYPE_OBJECT, ORDER_CLASSES], ["points", TYPE_INT, []]],
	"delivery_rejected":
	[["slot_id", TYPE_INT, []], ["order_id", TYPE_INT, []], ["penalty", TYPE_INT, []]],
	"order_patience_changed":
	[["order_id", TYPE_INT, []], ["time_left", TYPE_FLOAT, []], ["max_time", TYPE_FLOAT, []]],
	"order_expired": [["order", TYPE_OBJECT, ORDER_CLASSES], ["penalty", TYPE_INT, []]],
	"pause_changed": [["is_paused", TYPE_BOOL, []]],
	"character_switched": [["player_index", TYPE_INT, []], ["character_index", TYPE_INT, []]],
	"device_assigned": [["player_index", TYPE_INT, []], ["device", TYPE_INT, []]],
	"device_disconnected": [["player_index", TYPE_INT, []]],
}


func _declared_signals() -> Dictionary:
	var result: Dictionary = {}
	for sig: Dictionary in EventBusScript.get_script_signal_list():
		result[sig["name"]] = sig["args"]
	return result


func test_ac1_bus_declares_exactly_catalog_signal_names() -> void:
	var declared: Array = _declared_signals().keys()
	declared.sort()
	var expected: Array = CATALOG.keys()
	expected.sort()
	assert_eq(declared, expected)


func test_ac1_bus_signal_signatures_match_catalog() -> void:
	var declared: Dictionary = _declared_signals()
	for sig_name: String in CATALOG:
		if not declared.has(sig_name):
			fail_test("Falta la señal %s" % sig_name)
			continue
		var expected_args: Array = CATALOG[sig_name]
		var args: Array = declared[sig_name]
		assert_eq(args.size(), expected_args.size(), "nº de argumentos de %s" % sig_name)
		for i: int in mini(args.size(), expected_args.size()):
			var arg: Dictionary = args[i]
			var exp: Array = expected_args[i]
			assert_eq(arg["name"], exp[0], "%s arg %d: nombre" % [sig_name, i])
			assert_eq(arg["type"], exp[1], "%s.%s: tipo" % [sig_name, exp[0]])
			var classes: Array = exp[2]
			if not classes.is_empty():
				assert_has(classes, String(arg["class_name"]), "%s.%s: clase" % [sig_name, exp[0]])


func test_ac1_bus_has_no_state() -> void:
	var props: Array[String] = []
	for prop: Dictionary in EventBusScript.get_script_property_list():
		if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			props.append(prop["name"])
	assert_eq(props, [] as Array[String])
	assert_eq(EventBusScript.get_script_method_list().size(), 0)


func test_ac1_bus_is_not_3d() -> void:
	var bus: Node = EventBusScript.new()
	assert_false(bus is Node3D)
	bus.free()
