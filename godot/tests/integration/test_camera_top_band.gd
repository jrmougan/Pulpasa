extends GutTest
## PUL-133 AC1 y AC2 (H-01 de PUL-132): la cámara móvil trata la banda superior (HUD + tickets) y la
## safe area como zona tapada. Con `level_01` real y el perfil móvil, a 2340x1080, 1920x1080 y
## 800x370, con el personaje en cada plaza de olla: el anillo de cocción (entero), la cabeza con su
## marcador y el suelo alcanzable quedan por debajo de la banda y dentro de la safe area. Medidas en
## px reales: un `SubViewport` no se estira, así que las unidades de lienzo son px de pantalla.

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
## Holgura de medio px para la proyección.
const EPS: float = 0.5

var _viewport: SubViewport
var _level: Node3D
var _rig: CameraRig
var _player: Node3D


func _build(size: Vector2i) -> void:
	_viewport = SubViewport.new()
	_viewport.size = size
	add_child_autofree(_viewport)
	_level = LEVEL.instantiate()
	_viewport.add_child(_level)
	_rig = _level.get_node(^"CameraRig") as CameraRig
	_rig.ui_profile = UI_MOBILE
	_rig.set_safe_margins(Vector4(0.0, 0.0, 0.0, 0.0))
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


func _band_bottom() -> float:
	return BAND_PX * _k()


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


func test_ac1_ring_and_character_stay_below_the_band_at_every_pot() -> void:
	for size: Vector2i in SIZES:
		_build(size)
		await wait_process_frames(2)
		var stations: Node3D = _level.get_node(^"Stations") as Node3D
		var pots: Array[CookingStation] = []
		for child: Node in stations.get_children():
			if child is CookingStation:
				pots.append(child as CookingStation)
		assert_gt(pots.size(), 1, "hay varias ollas")
		for pot: CookingStation in pots:
			var base: Vector2 = Vector2(pot.global_position.x, pot.global_position.z)
			# Plaza: de pie al sur de la olla, y en la propia olla (el caso más al norte).
			for stand: Vector2 in [base + Vector2(0.0, 0.9), base]:
				_put(stand)
				var tag: String = "%s olla %s plaza %s" % [size, pot.name, stand]
				for ring: WorldProgressRing in pot.get_rings():
					var c: Vector2 = _px(ring.global_position)
					var half: float = ring.diameter_px * _k() * 0.5
					_assert_inside(Rect2(c - Vector2(half, half), Vector2(half, half) * 2.0), tag)
				var head: Vector2 = _px(_player.global_position + Vector3.UP * MARKER_HEIGHT_M)
				var marker: float = MARKER_PX * _k() * 0.5
				_assert_inside(
					Rect2(head - Vector2(marker, marker), Vector2(marker, marker) * 2.0), tag
				)
				var feet: Vector2 = _px(_player.global_position)
				assert_lte(feet.y, _safe_rect().end.y + EPS, "%s: pies sobre la safe area" % tag)


func test_ac1_prompt_icons_stay_below_the_band_at_every_pot() -> void:
	_build(SIZES[0])
	await wait_process_frames(2)
	var prompt: ActionPrompt = _player.get_node(^"%ActionPrompt") as ActionPrompt
	var pot: CookingStation = _level.get_node(^"Stations/Kitchen") as CookingStation
	var base: Vector2 = Vector2(pot.global_position.x, pot.global_position.z)
	_put(base + Vector2(0.0, 0.9))
	prompt.show_hint(pot, ActionHint.new())
	await wait_process_frames(2)
	for sprite: Sprite3D in [prompt.get_node(^"%VerbIcon"), prompt.get_node(^"%Plate")]:
		var c: Vector2 = _px(sprite.global_position)
		var half: float = prompt.size_px_of(sprite) * 0.5
		assert_gte(c.y - half, _band_bottom() - EPS, "%s bajo la banda" % sprite.name)


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
