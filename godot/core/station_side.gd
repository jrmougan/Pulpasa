class_name StationSide
extends RefCounted
## Lado de un mostrador de pase en el plano del suelo (ADR-003 §8.1). Común a 3D (`(x, z)`) y 2D.

enum Side { PASS, OPERATOR }


## `OPERATOR` si `point` está en la mitad de `operator_point` respecto a la mediatriz entre los dos
## marcadores (el propio límite cuenta como `OPERATOR`); si no, `PASS`.
static func classify(
	point: Vector2, pass_point: Vector2, operator_point: Vector2
) -> StationSide.Side:
	var middle: Vector2 = (pass_point + operator_point) / 2.0
	if (point - middle).dot(operator_point - pass_point) >= 0.0:
		return Side.OPERATOR
	return Side.PASS
