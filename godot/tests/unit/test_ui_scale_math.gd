extends GutTest
## PUL-122 AC3: conversiones de UiScale (ADR-005 E3).


func test_px_to_units_keeps_proportion_of_screen_height() -> void:
	assert_almost_eq(UiScale.px_to_units(120.0, 1080.0), 120.0, 0.001)
	# 1280x720 sin estirar: 1080 px de referencia caben en 720 unidades.
	assert_almost_eq(UiScale.px_to_units(36.0, 720.0), 24.0, 0.001)
	assert_almost_eq(UiScale.px_to_units(0.0, 720.0), 0.0, 0.001)


func test_72_dp_are_180_screen_px_at_1080_with_any_canvas() -> void:
	# Pantalla de 1080 de alto con distintos estiramientos: unidades * escala = px de pantalla.
	for canvas_height: float in [720.0, 1080.0, 960.0, 540.0]:
		var scale: float = 1080.0 / canvas_height
		var units: float = UiScale.dp_to_units(72.0, 2.5, canvas_height)
		assert_almost_eq(units * scale, 180.0, 0.001, "lienzo %d" % int(canvas_height))


func test_dp_to_units_is_px_to_units_of_dp_times_density() -> void:
	assert_almost_eq(
		UiScale.dp_to_units(48.0, 2.5, 720.0), UiScale.px_to_units(120.0, 720.0), 0.001
	)


func test_safe_margins_for_2340x1080_notch() -> void:
	var window: Vector2 = Vector2(2340, 1080)
	var safe: Rect2 = Rect2(132, 0, 2340 - 132 - 132, 1080 - 63)
	# Lienzo 1560 x 720 (escala 1,5): 132 px -> 88 unidades, 63 px -> 42.
	var margins: Vector4 = UiScale.safe_margins(window, safe, Vector2(1560, 720))
	assert_almost_eq(margins.x, 88.0, 0.001)
	assert_almost_eq(margins.y, 0.0, 0.001)
	assert_almost_eq(margins.z, 88.0, 0.001)
	assert_almost_eq(margins.w, 42.0, 0.001)


func test_safe_margins_in_screen_px_when_canvas_equals_window() -> void:
	var margins: Vector4 = UiScale.safe_margins(
		Vector2(2340, 1080), Rect2(132, 0, 2076, 1017), Vector2(2340, 1080)
	)
	assert_eq(margins, Vector4(132, 0, 132, 63))


func test_safe_margins_zero_when_safe_area_is_null() -> void:
	var window: Vector2 = Vector2(2340, 1080)
	assert_eq(UiScale.safe_margins(window, Rect2(), Vector2(1560, 720)), Vector4.ZERO)


func test_safe_margins_zero_when_safe_area_covers_window() -> void:
	var window: Vector2 = Vector2(1920, 1080)
	assert_eq(UiScale.safe_margins(window, Rect2(Vector2.ZERO, window), window), Vector4.ZERO)
	var wider: Rect2 = Rect2(-10, -10, 2000, 1200)
	assert_eq(UiScale.safe_margins(window, wider, window), Vector4.ZERO)
