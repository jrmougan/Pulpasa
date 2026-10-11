class_name UiScale
extends RefCounted
## Conversiones de UI (ADR-005 E3). El estiramiento `canvas_items` + `expand` del proyecto escala
## el lienzo; aquí se pasan medidas en px de pantalla a 1080 de alto a unidades de lienzo.

## Alto de referencia de las medidas del diseño.
const REFERENCE_HEIGHT_PX: float = 1080.0


## Unidades de lienzo que miden `px_at_1080` px a 1080 de alto, con cualquier resolución,
## estiramiento y content_scale. `canvas_height` = get_viewport().get_visible_rect().size.y.
static func px_to_units(px_at_1080: float, canvas_height: float) -> float:
	return px_at_1080 * canvas_height / REFERENCE_HEIGHT_PX


## dp -> unidades de lienzo (ADR-004 §6.2): `px_per_dp_at_1080` px a 1080 de alto por dp.
static func dp_to_units(dp: float, px_per_dp_at_1080: float, canvas_height: float) -> float:
	return px_to_units(dp * px_per_dp_at_1080, canvas_height)


## Márgenes de la safe area (izquierda, arriba, derecha, abajo) en unidades de lienzo. Vector4.ZERO
## si `safe_rect` cubre la ventana o está vacío.
static func safe_margins(window_size: Vector2, safe_rect: Rect2, canvas_size: Vector2) -> Vector4:
	if safe_rect.size.x <= 0.0 or safe_rect.size.y <= 0.0:
		return Vector4.ZERO
	if window_size.x <= 0.0 or window_size.y <= 0.0:
		return Vector4.ZERO
	var left: float = maxf(safe_rect.position.x, 0.0)
	var top: float = maxf(safe_rect.position.y, 0.0)
	var right: float = maxf(window_size.x - safe_rect.end.x, 0.0)
	var bottom: float = maxf(window_size.y - safe_rect.end.y, 0.0)
	if left + top + right + bottom <= 0.0:
		return Vector4.ZERO
	var to_canvas: Vector2 = canvas_size / window_size
	return Vector4(left * to_canvas.x, top * to_canvas.y, right * to_canvas.x, bottom * to_canvas.y)
