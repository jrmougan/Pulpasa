extends GutTest
## PUL-057: lado de un mostrador de pase en el plano del suelo (ADR-003 §8.1).

const PASS_POINT: Vector2 = Vector2(0.0, -1.0)
const OPERATOR_POINT: Vector2 = Vector2(0.0, 1.0)


func test_points_on_each_side() -> void:
	assert_eq(
		StationSide.classify(Vector2(0, -1), PASS_POINT, OPERATOR_POINT), StationSide.Side.PASS
	)
	assert_eq(
		StationSide.classify(Vector2(3, 0.5), PASS_POINT, OPERATOR_POINT), StationSide.Side.OPERATOR
	)
	assert_eq(
		StationSide.classify(Vector2(-4, -0.1), PASS_POINT, OPERATOR_POINT), StationSide.Side.PASS
	)


func test_midline_counts_as_operator() -> void:
	assert_eq(
		StationSide.classify(Vector2(2, 0), PASS_POINT, OPERATOR_POINT), StationSide.Side.OPERATOR
	)


func test_rotated_and_moved_station_classifies_the_same() -> void:
	# Estación girada 90° y desplazada: los marcadores mandan, no los ejes.
	var pass_point: Vector2 = Vector2(9.0, 5.0)
	var operator_point: Vector2 = Vector2(11.0, 5.0)
	assert_eq(
		StationSide.classify(Vector2(12, 0), pass_point, operator_point), StationSide.Side.OPERATOR
	)
	assert_eq(
		StationSide.classify(Vector2(8, 9), pass_point, operator_point), StationSide.Side.PASS
	)
