extends GutTest
## PUL-130: núcleo `CameraFollow` (ADR-005 E5): amortiguación crítica, paneo ease-out, límites del
## nivel y punto de la flecha de borde. Puro, sin escenas.

const DT: float = 1.0 / 60.0
const AREA_MIN: Vector2 = Vector2(-7.0, -5.0)
const AREA_MAX: Vector2 = Vector2(9.4, 6.6)


func _run(follow: CameraFollow, target: Vector2, seconds: float, smooth: float) -> void:
	for i: int in int(seconds / DT):
		follow.follow(target, smooth, DT)


func test_follow_converges_without_overshoot() -> void:
	var f: CameraFollow = CameraFollow.new()
	var target: Vector2 = Vector2(5.0, -3.0)
	var worst_overshoot: float = 0.0
	for i: int in 240:
		f.follow(target, 0.2, DT)
		worst_overshoot = maxf(
			worst_overshoot, (f.position - Vector2.ZERO).dot(target.normalized()) - target.length()
		)
	assert_lt(worst_overshoot, 0.0001, "no rebasa el objetivo")
	assert_lt(f.position.distance_to(target), 0.01, "converge")


func test_follow_time_reaches_most_of_the_distance() -> void:
	var f: CameraFollow = CameraFollow.new()
	_run(f, Vector2(4.0, 0.0), 0.2, 0.2)
	assert_gt(f.position.x, 4.0 * 0.5, "en follow_time recorre más de la mitad")
	assert_lt(f.position.x, 4.0, "sin llegar aún")


func test_rest_has_no_oscillation() -> void:
	var f: CameraFollow = CameraFollow.new()
	f.snap_to(Vector2(1.0, 2.0))
	var target: Vector2 = Vector2(1.0, 2.0)
	var worst: float = 0.0
	for i: int in 300:
		f.follow(target, 0.2, DT)
		worst = maxf(worst, f.position.distance_to(target))
	assert_lt(worst, 0.05, "en reposo no se mueve más de 0,05 m")


func test_target_jitter_stays_within_tolerance() -> void:
	var f: CameraFollow = CameraFollow.new()
	f.snap_to(Vector2.ZERO)
	var worst: float = 0.0
	for i: int in 300:
		var target: Vector2 = Vector2(0.01 * sin(i * 0.9), 0.0)
		f.follow(target, 0.2, DT)
		worst = maxf(worst, f.position.length())
	assert_lt(worst, 0.05)


func test_zero_smooth_time_snaps() -> void:
	var f: CameraFollow = CameraFollow.new()
	f.follow(Vector2(3.0, 3.0), 0.0, DT)
	assert_eq(f.position, Vector2(3.0, 3.0))


func test_pan_takes_duration_and_is_ease_out() -> void:
	var f: CameraFollow = CameraFollow.new()
	var target: Vector2 = Vector2(10.0, 0.0)
	f.pan_to(target, 0.35)
	assert_true(f.is_panning())
	_run(f, target, 0.175, 0.2)
	assert_gt(f.position.x, 5.0, "ease-out: a media duración ya pasó de la mitad")
	assert_true(f.is_panning())
	_run(f, target, 0.2, 0.2)
	assert_false(f.is_panning(), "termina a los 0,35 s")
	assert_almost_eq(f.position.x, 10.0, 0.01)


func test_pan_follows_moving_target() -> void:
	var f: CameraFollow = CameraFollow.new()
	f.pan_to(Vector2(2.0, 0.0), 0.35)
	for i: int in 30:
		f.follow(Vector2(2.0 + i * 0.05, 0.0), 0.2, DT)
	assert_false(f.is_panning())
	assert_almost_eq(f.position.x, 2.0 + 29 * 0.05, 0.5, "al acabar sigue al objetivo vivo")


func test_pan_zero_duration_snaps() -> void:
	var f: CameraFollow = CameraFollow.new()
	f.pan_to(Vector2(1.0, 1.0), 0.0)
	assert_eq(f.position, Vector2(1.0, 1.0))
	assert_false(f.is_panning())


func test_clamp_focus_limits_view_to_margin() -> void:
	var half: Vector2 = Vector2(4.0, 3.0)
	var low: Vector2 = CameraFollow.clamp_focus(
		Vector2(-99.0, -99.0), half, AREA_MIN, AREA_MAX, 1.0
	)
	assert_true(low.is_equal_approx(Vector2(-4.0, -3.0)))
	var high: Vector2 = CameraFollow.clamp_focus(Vector2(99.0, 99.0), half, AREA_MIN, AREA_MAX, 1.0)
	assert_true(high.is_equal_approx(Vector2(6.4, 4.6)))
	var inside: Vector2 = CameraFollow.clamp_focus(Vector2(1.0, 1.0), half, AREA_MIN, AREA_MAX, 1.0)
	assert_eq(inside, Vector2(1.0, 1.0))


func test_clamp_focus_centers_when_view_is_larger() -> void:
	var focus: Vector2 = CameraFollow.clamp_focus(
		Vector2(5.0, 5.0), Vector2(30.0, 30.0), AREA_MIN, AREA_MAX, 1.0
	)
	assert_eq(focus, (AREA_MIN + AREA_MAX) * 0.5)


func test_edge_point_on_boundary_towards_target() -> void:
	var bounds: Rect2 = Rect2(24.0, 24.0, 2292.0, 1032.0)
	var none: Rect2 = Rect2()
	var right: Vector2 = CameraFollow.edge_point(
		Vector2(5000.0, 540.0), bounds, none, Vector2(48.0, 48.0), 16.0
	)
	assert_almost_eq(right.x, bounds.end.x, 0.01)
	assert_almost_eq(right.y, 540.0, 0.01)
	var left: Vector2 = CameraFollow.edge_point(
		Vector2(-900.0, 540.0), bounds, none, Vector2(48.0, 48.0), 16.0
	)
	assert_almost_eq(left.x, bounds.position.x, 0.01)
	var inside: Vector2 = CameraFollow.edge_point(
		Vector2(500.0, 500.0), bounds, none, Vector2(48.0, 48.0), 16.0
	)
	assert_eq(inside, Vector2(500.0, 500.0), "dentro de la zona devuelve el propio punto")


func test_edge_point_avoids_button_zone() -> void:
	var bounds: Rect2 = Rect2(24.0, 24.0, 2292.0, 1032.0)
	var avoid: Rect2 = Rect2(1950.0, 600.0, 390.0, 480.0)
	var size: Vector2 = Vector2(48.0, 48.0)
	for target: Vector2 in [
		Vector2(5000.0, 1000.0), Vector2(3000.0, 2500.0), Vector2(2000.0, 4000.0)
	]:
		var p: Vector2 = CameraFollow.edge_point(target, bounds, avoid, size, 16.0)
		var arrow: Rect2 = Rect2(p - size * 0.5, size)
		assert_false(
			arrow.intersects(avoid.grow(15.0)), "a 16 px de la zona de botones: %s" % target
		)
		assert_true(bounds.grow(0.01).has_point(p), "dentro de los límites: %s" % target)


# --- PUL-133: banda superior tapada (H-01) ---------------------------------------------------


func test_covered_focus_centers_target_in_visible_part() -> void:
	var focus: Vector2 = CameraFollow.covered_focus(Vector2(2.0, 1.0), 3.0)
	assert_eq(focus, Vector2(2.0, -0.5), "medio tramo de banda al norte")
	assert_eq(CameraFollow.covered_focus(Vector2(2.0, 1.0), 0.0), Vector2(2.0, 1.0))


func test_covered_clamp_without_cover_matches_plain_clamp() -> void:
	var half: Vector2 = Vector2(6.0, 5.0)
	for focus: Vector2 in [Vector2(-20, -20), Vector2(0, 0), Vector2(30, 30)]:
		assert_eq(
			CameraFollow.clamp_focus_covered(focus, half, AREA_MIN, AREA_MAX, 1.0, 0.0, 0.0),
			CameraFollow.clamp_focus(focus, half, AREA_MIN, AREA_MAX, 1.0)
		)


func test_covered_clamp_lets_north_edge_clear_the_band() -> void:
	var half: Vector2 = Vector2(6.0, 3.0)
	var cover: float = 1.5
	var reach: float = 2.0
	var focus: Vector2 = CameraFollow.clamp_focus_covered(
		Vector2(0.0, -50.0), half, AREA_MIN, AREA_MAX, 1.0, cover, reach
	)
	var top: float = CameraFollow.visible_top(focus.y, half.y, cover)
	assert_almost_eq(top, AREA_MIN.y - 1.0 - reach, 0.0001, "la parte visible llega al alcance")
	assert_lt(top, AREA_MIN.y - reach, "el borde norte y lo que tiene encima quedan visibles")


func test_covered_clamp_keeps_south_and_side_limits() -> void:
	var half: Vector2 = Vector2(6.0, 3.0)
	var plain: Vector2 = CameraFollow.clamp_focus(
		Vector2(50.0, 50.0), half, AREA_MIN, AREA_MAX, 1.0
	)
	var covered: Vector2 = CameraFollow.clamp_focus_covered(
		Vector2(50.0, 50.0), half, AREA_MIN, AREA_MAX, 1.0, 1.5, 2.0
	)
	assert_eq(covered, plain, "al sur y al este no cambia")


func test_covered_clamp_centers_when_view_is_larger_than_area() -> void:
	var focus: Vector2 = CameraFollow.clamp_focus_covered(
		Vector2(3.0, 3.0), Vector2(40.0, 40.0), AREA_MIN, AREA_MAX, 1.0, 1.0, 1.0
	)
	assert_eq(focus.y, (AREA_MIN.y + AREA_MAX.y) * 0.5)
