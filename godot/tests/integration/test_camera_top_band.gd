extends GutTest
## PUL-133 AC1 y AC2 (H-01 de PUL-132): la cámara móvil trata la banda superior (HUD + tickets) y la
## safe area como zona tapada. Con `level_01` real y el perfil móvil, a 2340x1080, 1920x1080 y
## 800x370, con el personaje en cada plaza de olla: el anillo de cocción (entero), la cabeza con su
## marcador y el suelo alcanzable quedan por debajo de la banda y dentro de la safe area. Medidas en
## px reales: un `SubViewport` no se estira, así que las unidades de lienzo son px de pantalla.
## PUL-134: flecha de borde con la banda tapada (M-2), prompt en todas las ollas y tamaños (B-1) y
## safe area superior no nula (B-2).

const LEVEL: PackedScene = preload("res://scenes/levels/level_01.tscn")
const MOBILE: CameraProfile = preload("res://data/config/camera_mobile.tres")
const UI_MOBILE: UiProfile = preload("res://data/config/ui_profile_mobile.tres")
const DT: float = 1.0 / 60.0
const SIZES: Array[Vector2i] = [Vector2i(2340, 1080), Vector2i(1920, 1080), Vector2i(800, 370)]
## Safe area del diseño (px a 1080): 132 a los lados y 63 abajo (`controles-tactiles.md`).
const SAFE_SIDE_PX: float = 132.0
const SAFE_BOTTOM_PX: float = 63.0
## Banda real de HUD + tickets a 1080: 24 de margen + 150 del ticket (`TouchHudLayout`).
const BAND_PX: float = 174.0
const HEAD_HEIGHT_M: float = 1.6
const MARKER_HEIGHT_M: float = 2.05
const MARKER_PX: float = 28.0
## Safe area superior no nula para B-2 (px a 1080: muesca de un móvil en vertical girado).
const SAFE_TOP_PX: float = 80.0
## Banda tapada que usa la cámara (`UiProfile.top_band_max_px`, px a 1080).
const COVER_PX: float = 200.0
## Plaza del activo al sur (pasillo de los puestos de pedido) para M-2.
const ACTIVE_SOUTH: Vector2 = Vector2(0.0, 6.0)
## Holgura de medio px para la proyección.
const EPS: float = 0.5

var _viewport: SubViewport
var _level: Node3D
var _rig: CameraRig
var _player: Node3D
var _safe_top: float = 0.0


func _build(size: Vector2i, safe_top_px: float = 0.0) -> void:
	_viewport = SubViewport.new()
	_viewport.size = size
	add_child_autofree(_viewport)
	_level = LEVEL.instantiate()
	_viewport.add_child(_level)
	_rig = _level.get_node(^"CameraRig") as CameraRig
	_rig.ui_profile = UI_MOBILE
	_safe_top = safe_top_px * float(size.y) / 1080.0
	_rig.set_safe_margins(Vector4(0.0, _safe_top, 0.0, 0.0))
	_rig.set_profile(MOBILE)
	_rig.current = true
	_player = _level.get_node(^"Characters/Player1") as Node3D


func _k() -> float:
	return float(_viewport.size.y) / 1080.0


func _put(at: Vector2) -> void:
	_player.global_position = Vector3(at.x, 0.005, at.y)
	_rig.set_profile(MOBILE)
	for i: int in 30:
		_rig.step(DT)


func _px(point: Vector3) -> Vector2:
	return _rig.unproject_position(point)


## Fondo de la banda real: la safe area superior la empuja hacia abajo (`SafeAreaMargin`).
func _band_bottom() -> float:
	return _safe_top + BAND_PX * _k()


func _safe_rect() -> Rect2:
	var s: Vector2 = Vector2(_viewport.size)
	return Rect2(
		SAFE_SIDE_PX * _k(), 0.0, s.x - 2.0 * SAFE_SIDE_PX * _k(), s.y - SAFE_BOTTOM_PX * _k()
	)


func _assert_inside(rect: Rect2, label: String) -> void:
	var safe: Rect2 = _safe_rect()
	assert_gte(rect.position.y, _band_bottom() - EPS, "%s: bajo la banda" % label)
	assert_gte(rect.position.x, safe.position.x - EPS, "%s: safe izq" % label)
	assert_lte(rect.end.x, safe.end.x + EPS, "%s: safe der" % label)
	assert_lte(rect.end.y, safe.end.y + EPS, "%s: safe abajo" % label)


func _pots() -> Array[CookingStation]:
	var pots: Array[CookingStation] = []
	for child: Node in (_level.get_node(^"Stations") as Node3D).get_children():
		if child is CookingStation:
			pots.append(child as CookingStation)
	return pots


## Plazas de una olla: de pie al sur de la olla y en la propia olla (el caso más al norte).
func _stands(pot: CookingStation) -> Array[Vector2]:
	var base: Vector2 = Vector2(pot.global_position.x, pot.global_position.z)
	return [base + Vector2(0.0, 0.9), base]


func _assert_ring_and_head(pot: CookingStation, tag: String) -> void:
	for ring: WorldProgressRing in pot.get_rings():
		var c: Vector2 = _px(ring.global_position)
		var half: float = ring.diameter_px * _k() * 0.5
		_assert_inside(Rect2(c - Vector2(half, half), Vector2(half, half) * 2.0), tag)
	var head: Vector2 = _px(_player.global_position + Vector3.UP * MARKER_HEIGHT_M)
	var marker: float = MARKER_PX * _k() * 0.5
	_assert_inside(Rect2(head - Vector2(marker, marker), Vector2(marker, marker) * 2.0), tag)
	var feet: Vector2 = _px(_player.global_position)
	assert_lte(feet.y, _safe_rect().end.y + EPS, "%s: pies sobre la safe area" % tag)


func test_ac1_ring_and_character_stay_below_the_band_at_every_pot() -> void:
	for size: Vector2i in SIZES:
		_build(size)
		await wait_process_frames(2)
		var pots: Array[CookingStation] = _pots()
		assert_gt(pots.size(), 1, "hay varias ollas")
		for pot: CookingStation in pots:
			for stand: Vector2 in _stands(pot):
				_put(stand)
				_assert_ring_and_head(pot, "%s olla %s plaza %s" % [size, pot.name, stand])


## PUL-134 B-2: con safe area superior no nula, la banda baja y lo alcanzable sigue debajo.
func test_b2_ring_and_character_clear_the_band_with_top_safe_area() -> void:
	for size: Vector2i in SIZES:
		_build(size, SAFE_TOP_PX)
		await wait_process_frames(2)
		assert_gt(_band_bottom(), BAND_PX * _k() + 1.0, "la safe area superior cuenta")
		for pot: CookingStation in _pots():
			for stand: Vector2 in _stands(pot):
				_put(stand)
				_assert_ring_and_head(
					pot, "%s safe %s olla %s plaza %s" % [size, SAFE_TOP_PX, pot.name, stand]
				)


## PUL-134 B-1: el prompt (icono de verbo y plato) bajo la banda en cada tamaño × olla × plaza.
func test_ac1_prompt_icons_stay_below_the_band_at_every_pot() -> void:
	for size: Vector2i in SIZES:
		_build(size)
		await wait_process_frames(2)
		var prompt: ActionPrompt = _player.get_node(^"%ActionPrompt") as ActionPrompt
		for pot: CookingStation in _pots():
			for stand: Vector2 in _stands(pot):
				_put(stand)
				prompt.show_hint(pot, ActionHint.new())
				await wait_process_frames(2)
				var tag: String = "%s olla %s plaza %s" % [size, pot.name, stand]
				for sprite: Sprite3D in [prompt.get_node(^"%VerbIcon"), prompt.get_node(^"%Plate")]:
					var c: Vector2 = _px(sprite.global_position)
					var half: float = prompt.size_px_of(sprite) * 0.5
					assert_gte(
						c.y - half,
						_band_bottom() - EPS,
						"%s: %s bajo la banda" % [tag, sprite.name]
					)


## PUL-134 AC1 (M-2): inactivo en la fila de ollas y activo al sur: el activo se acerca desde el
## límite sur hasta que el inactivo entra en el lienzo, pero bajo la banda tapada (safe area +
## `top_band_max_px`). Ahí no se ve: hay flecha y queda entera bajo la banda.
func test_m2_arrow_for_inactive_hidden_under_the_band() -> void:
	for size: Vector2i in SIZES:
		for safe_top: float in [0.0, SAFE_TOP_PX]:
			_build(size, safe_top)
			await wait_process_frames(2)
			var other: Node3D = _level.get_node(^"Characters/Player2") as Node3D
			var layer: CanvasLayer = _rig.get_node(^"%OffscreenArrow") as CanvasLayer
			var arrow: TextureRect = _rig.get_node(^"%Arrow") as TextureRect
			var cover: float = _safe_top + COVER_PX * _k()
			for pot: CookingStation in _pots():
				var row: Vector3 = Vector3(
					pot.global_position.x, 0.005, pot.global_position.z + 0.9
				)
				other.global_position = row
				var tag: String = "%s safe %s inactivo en %s" % [size, safe_top, pot.name]
				var seen: Vector2 = Vector2(0.0, -1.0)
				var active_z: float = ACTIVE_SOUTH.y
				while seen.y < 0.0 and active_z > row.z:
					_put(Vector2(ACTIVE_SOUTH.x, active_z))
					seen = _px(row + Vector3.UP * CameraRig.CHARACTER_CENTER_HEIGHT)
					active_z -= 0.1
				assert_between(seen.y, 0.0, cover, "%s: en el lienzo pero tapado" % tag)
				assert_true(layer.visible, "%s: hay flecha" % tag)
				assert_gte(arrow.position.y, cover - EPS, "%s: la flecha bajo la banda" % tag)
				assert_lte(arrow.position.y + arrow.size.y, float(size.y) + EPS, "%s: abajo" % tag)


func test_ac2_reachable_floor_is_never_under_the_band_at_rest() -> void:
	for size: Vector2i in SIZES:
		_build(size)
		await wait_process_frames(2)
		var lo: Vector2 = MOBILE.play_area_min
		var hi: Vector2 = MOBILE.play_area_max
		var steps: int = 8
		for i: int in steps + 1:
			var t: float = float(i) / float(steps)
			for edge: Vector2 in [
				Vector2(lerpf(lo.x, hi.x, t), lo.y),
				Vector2(lerpf(lo.x, hi.x, t), hi.y),
				Vector2(lo.x, lerpf(lo.y, hi.y, t)),
				Vector2(hi.x, lerpf(lo.y, hi.y, t)),
			]:
				_put(edge)
				var p: Vector2 = _px(Vector3(edge.x, 0.0, edge.y))
				assert_gte(p.y, _band_bottom() - EPS, "%s: suelo %s bajo la banda" % [size, edge])
