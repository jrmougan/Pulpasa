extends GutTest
## PUL-135 AC1 y PUL-138 B-AC2 (ADR-005 E4 «Enmienda D27», D27.2): con los `TouchControls`
## reales (`touch_config.tres`) y la safe area nula o la de diseño, la zona táctil de cada botón de
## la zona (acción y cambio en fila, con su margen de toque) cae dentro de la zona de botones que
## usa `CameraRig`, anclada a la esquina inferior derecha de la safe area
## (x ≥ ancho − safe der. − `button_zone_width_px`, y ≥ alto − safe inf. − `button_zone_height_px`,
## hasta el borde del lienzo). El test imprime la tabla de holguras izquierda y superior de cada
## botón. Un `SubViewport` del tamaño de la resolución no se estira: unidades de lienzo = px.

const SCENE: PackedScene = preload("res://ui/touch/touch_controls.tscn")
const UI_MOBILE: UiProfile = preload("res://data/config/ui_profile_mobile.tres")
const SIZES: Array[Vector2i] = [Vector2i(2340, 1080), Vector2i(1920, 1080), Vector2i(800, 370)]
## Safe areas (izq, arriba, der, abajo) en px a 1080 de alto: nula y la de diseño
## (132 / 0 / 132 / 63 a 2340x1080).
const SAFES: Dictionary = {
	"nula": Vector4.ZERO,
	"diseño": Vector4(132.0, 0.0, 132.0, 63.0),
}
## Tolerancia al comparar bordes (unidades de lienzo): `SafeAreaMargin` redondea los márgenes a
## constantes enteras (21,6 → 22 a 800x370) y la cámara los usa sin redondear.
const EPS: float = 1.0

var _controls: TouchControls


func before_each() -> void:
	GameState.set_platform(PlatformProfile.Kind.MOBILE)
	GameState.mode = GameMode.Mode.SINGLE


func after_each() -> void:
	GameState.set_platform(PlatformProfile.Kind.DESKTOP)


func _open(size: Vector2i, safe_1080: Vector4) -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = size
	add_child_autofree(viewport)
	_controls = SCENE.instantiate()
	viewport.add_child(_controls)
	await wait_process_frames(2)
	var s: Vector2 = Vector2(size)
	var m: Vector4 = safe_1080 * (s.y / 1080.0)
	var rect: Rect2 = Rect2(m.x, m.y, s.x - m.x - m.z, s.y - m.y - m.w)
	_controls.apply_safe_rect(rect, s)
	await wait_process_frames(1)


## Zona de botones como la calcula `CameraRig._button_zone` (D27.2, unidades de lienzo).
func _zone(size: Vector2i, safe_1080: Vector4) -> Rect2:
	var canvas: Vector2 = Vector2(size)
	var m: Vector4 = safe_1080 * (canvas.y / 1080.0)
	var left: float = canvas.x - m.z - UiScale.px_to_units(UI_MOBILE.button_zone_width_px, canvas.y)
	var top: float = canvas.y - m.w - UiScale.px_to_units(UI_MOBILE.button_zone_height_px, canvas.y)
	return Rect2(left, top, canvas.x - left, canvas.y - top)


## Cuadrado que envuelve la zona táctil (radio visible + margen de toque).
func _touch_rect(button: TouchButton) -> Rect2:
	var reach: float = button.get_hit_radius()
	return Rect2(button.get_center() - Vector2.ONE * reach, Vector2.ONE * reach * 2.0)


func test_bac2_zone_buttons_with_touch_margin_fit_the_camera_button_zone() -> void:
	for size: Vector2i in SIZES:
		for safe_name: String in SAFES:
			await _open(size, SAFES[safe_name])
			var zone: Rect2 = _zone(size, SAFES[safe_name])
			var k: float = float(size.y) / 1080.0
			var bottom: float = (SAFES[safe_name] as Vector4).w * k
			assert_almost_eq(zone.position.y, size.y - bottom - 240.0 * k, 0.5, "y de la zona")
			for path: NodePath in [^"%ActionButton", ^"%SwitchButton"]:
				var button: TouchButton = _controls.get_node(path) as TouchButton
				var rect: Rect2 = _touch_rect(button)
				(
					gut
					. p(
						(
							"%s %s %s: toque %s, zona %s, holgura izq %.1f arriba %.1f"
							% [
								size,
								safe_name,
								button.name,
								rect,
								zone,
								rect.position.x - zone.position.x,
								rect.position.y - zone.position.y,
							]
						)
					)
				)
				assert_gt(rect.size.x, 0.0, "%s %s: el botón se mide" % [size, button.name])
				assert_true(
					zone.grow(EPS).encloses(rect),
					"%s safe %s: %s %s dentro de %s" % [size, safe_name, button.name, rect, zone]
				)


func test_ac1_pause_button_sits_in_the_top_band_above_the_button_zone() -> void:
	for size: Vector2i in SIZES:
		for safe_name: String in SAFES:
			await _open(size, SAFES[safe_name])
			var pause: TouchButton = _controls.get_node(^"%PauseButton") as TouchButton
			var rect: Rect2 = _touch_rect(pause)
			assert_lt(
				rect.end.y,
				_zone(size, SAFES[safe_name]).position.y,
				"%s safe %s: pausa %s sobre la zona" % [size, safe_name, rect]
			)
