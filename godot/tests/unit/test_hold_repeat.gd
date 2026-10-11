extends GutTest
## PUL-121 AC6 (núcleo): HoldRepeat da `true` cada `interval` desde `arm()`, conserva el sobrante
## y no cuenta desarmado (ADR-003 §11.4).


func _count(repeat: HoldRepeat, total: float, step: float) -> int:
	var pulses: int = 0
	var steps: int = roundi(total / step)
	for _i: int in steps:
		if repeat.advance(step):
			pulses += 1
	return pulses


func test_ac6_disarmed_never_fires() -> void:
	var repeat: HoldRepeat = HoldRepeat.new(0.2)
	assert_false(repeat.is_armed())
	assert_false(repeat.advance(10.0))


func test_ac6_fires_each_interval_after_arm() -> void:
	var repeat: HoldRepeat = HoldRepeat.new(0.2)
	repeat.arm()
	assert_true(repeat.is_armed())
	assert_false(repeat.advance(0.19))
	assert_true(repeat.advance(0.01))
	assert_false(repeat.advance(0.1))
	assert_true(repeat.advance(0.1))


func test_ac6_one_point_o_five_seconds_gives_five_repeats_with_any_step() -> void:
	# El primer corte lo da la pulsación; 1,05 s mantenido añade 5 repeticiones (6 en total).
	for step: float in [0.05, 1.0 / 60.0, 0.01]:
		var repeat: HoldRepeat = HoldRepeat.new(0.2)
		repeat.arm()
		assert_eq(_count(repeat, 1.05, step), 5, "paso %f" % step)


func test_ac6_fires_at_most_once_per_call_and_keeps_the_remainder() -> void:
	var repeat: HoldRepeat = HoldRepeat.new(0.2)
	repeat.arm()
	assert_true(repeat.advance(0.5))
	# Sobran 0,3: la siguiente llamada cumple otro intervalo y aún quedan 0,1.
	assert_true(repeat.advance(0.0))
	assert_false(repeat.advance(0.0))
	assert_true(repeat.advance(0.1))


func test_ac6_disarm_stops_and_arm_restarts_from_zero() -> void:
	var repeat: HoldRepeat = HoldRepeat.new(0.2)
	repeat.arm()
	repeat.advance(0.15)
	repeat.disarm()
	assert_false(repeat.is_armed())
	assert_false(repeat.advance(1.0))
	repeat.arm()
	assert_false(repeat.advance(0.15))
	assert_true(repeat.advance(0.05))


func test_ac6_interval_comes_from_the_constructor() -> void:
	var repeat: HoldRepeat = HoldRepeat.new(0.5)
	repeat.arm()
	assert_false(repeat.advance(0.4))
	assert_true(repeat.advance(0.1))
