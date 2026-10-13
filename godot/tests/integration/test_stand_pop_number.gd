extends GutTest
## PUL-142: el POP del puesto (`deliver_ok`) escala `Model`, y `StandNumber` (hermano de `Model`,
## scene-tree.md §3) debe seguir por delante de la placa (`Anchor_Number`) durante todo el POP:
## a cada fracción de `visual_time` el número sigue el transform de `Model` y queda delante de la
## placa en el eje de la cámara (y en el frente del puesto, −Z local).

const EventBusScript: GDScript = preload("res://autoload/event_bus.gd")
const OrderServiceScript: GDScript = preload("res://autoload/order_service.gd")
const STAND_SCENE: PackedScene = preload("res://entities/stations/order_stand.tscn")
const MAP: AudioFeedbackMap = preload("res://data/audio/feedback_map.tres")
const FRACTIONS: Array[float] = [0.0, 0.15, 0.35, 0.55, 1.0]
## Hacia la cámara de juego en el marco del puesto (la cámara mira con cabeceo ~38° y el puesto
## está girado 180°, de frente a ella: `level_01`).
const TO_CAMERA: Vector3 = Vector3(0.0, 0.615662, -0.788011)

var _stand: OrderStand
var _model: Node3D
var _number: Label3D
var _plate: Node3D
var _feedback: FeedbackPlayer


func before_each() -> void:
	var bus: Node = add_child_autofree(EventBusScript.new())
	var service: Node = OrderServiceScript.new()
	service.set_bus(bus)
	add_child_autofree(service)
	_stand = STAND_SCENE.instantiate()
	_stand.set_bus(bus)
	_stand.set_service(service)
	add_child_autofree(_stand)
	_model = _stand.get_node(^"Model") as Node3D
	_number = _stand.get_node(^"StandNumber") as Label3D
	_plate = _model.find_child("Anchor_Number", true, false) as Node3D
	_feedback = _stand.get_node(^"%Feedback") as FeedbackPlayer


func test_ac2_number_stays_in_front_of_plate_during_pop() -> void:
	assert_not_null(_plate, "Anchor_Number en el modelo")
	var rest: Transform3D = _model.transform.affine_inverse() * _number.transform
	_feedback.play_cue(&"deliver_ok")
	var tween: Tween = _feedback.get_visual_tween(_stand)
	assert_not_null(tween, "deliver_ok anima el puesto")
	tween.pause()
	var time: float = MAP.get_cue(&"deliver_ok").visual_time
	var done: float = 0.0
	var grew: bool = false
	for fraction: float in FRACTIONS:
		var at: float = fraction * time
		if at > done:
			tween.custom_step(at - done)
			done = at
		grew = grew or _model.scale.x > 1.05
		var plate: Vector3 = _stand.to_local(_plate.global_position)
		var number: Vector3 = _number.position
		var tag: String = "%d %% (escala %.3f)" % [roundi(fraction * 100.0), _model.scale.x]
		assert_gt(
			(number - plate).dot(TO_CAMERA), 0.0, "delante de la placa hacia la cámara, %s" % tag
		)
		assert_lt(number.z, plate.z, "delante de la placa en el frente del puesto, %s" % tag)
		assert_true(
			_number.transform.is_equal_approx(_model.transform * rest),
			"el número sigue a Model, %s" % tag
		)
	assert_true(grew, "el POP llegó a escalar Model")
	assert_true(_number.transform.is_equal_approx(rest), "vuelve a reposo")


func test_ac3_order_cues_stay_on_order_label() -> void:
	var label: Node3D = _stand.get_node(^"%OrderLabel") as Node3D
	var rest: Transform3D = _number.transform
	_feedback.play_cue(&"order_expired", label)
	assert_not_null(_feedback.get_visual_tween(label), "order_expired sobre %OrderLabel")
	assert_null(_feedback.get_visual_tween(_stand), "sin POP del puesto")
	assert_true(_number.transform.is_equal_approx(rest), "el número no se mueve")
