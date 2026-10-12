extends GutTest
## PUL-134 AC2 (opción A, decisión del responsable: opción C): la zona de botones táctiles cuenta
## como zona tapada en el recorte este cuando el activo está en su franja. Con `level_01` real y el
## perfil móvil, a 2340x1080, 1920x1080 y 800x370, con el activo en reposo en la plaza de cada
## estación con widget (contador N/6 de la caja en cada pasaplatos, anillos de cada olla, medidor
## del cuenco): ningún widget de esa estación ni el propio activo quedan bajo la zona de botones.
## Medidas en px reales (un `SubViewport` no se estira). PUL-135 AC2: lo mismo con la safe area
## derecha de diseño (132 px a 1080), que la zona de botones no descuenta.

const LEVEL: PackedScene = preload("res://scenes/levels/level_01.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const MOBILE: CameraProfile = preload("res://data/config/camera_mobile.tres")
const UI_MOBILE: UiProfile = preload("res://data/config/ui_profile_mobile.tres")
const DT: float = 1.0 / 60.0
const SIZES: Array[Vector2i] = [Vector2i(2340, 1080), Vector2i(1920, 1080), Vector2i(800, 370)]
## Cuerpo del personaje para la comprobación del activo (m).
const BODY_HALF_WIDTH_M: float = 0.35
const BODY_HEIGHT_M: float = 1.6
## Safe areas (izq, arriba, der, abajo) en px a 1080 de alto: nula y derecha de diseño.
const SAFES: Array[Vector4] = [Vector4.ZERO, Vector4(0.0, 0.0, 132.0, 0.0)]

var _viewport: SubViewport
var _level: Node3D
var _rig: CameraRig
var _player: Node3D


func _build(size: Vector2i, safe_1080: Vector4 = Vector4.ZERO) -> void:
	_viewport = SubViewport.new()
	_viewport.size = size
	add_child_autofree(_viewport)
	_level = LEVEL.instantiate()
	_viewport.add_child(_level)
	_rig = _level.get_node(^"CameraRig") as CameraRig
	_rig.ui_profile = UI_MOBILE
	_rig.set_safe_margins(safe_1080 * (float(size.y) / 1080.0))
	_rig.set_profile(MOBILE)
	_rig.current = true
	_player = _level.get_node(^"Characters/Player1") as Node3D


func _put(at: Vector2) -> void:
	_player.global_position = Vector3(at.x, 0.005, at.y)
	_rig.set_profile(MOBILE)
	for i: int in 30:
		_rig.step(DT)


func _zone() -> Rect2:
	var s: Vector2 = Vector2(_viewport.size)
	var k: float = s.y / 1080.0
	var left: float = s.x - UI_MOBILE.button_zone_width_px * k
	var top: float = UI_MOBILE.button_zone_top_px * k
	return Rect2(left, top, s.x - left, s.y - top)


## Rectángulo en pantalla de los widgets bajo `node`: cada `VisualInstance3D` (sprites y textos en
## billboard) proyecta su centro y suma su AABB local a px.
func _widget_px(node: Node3D) -> Rect2:
	var mpp: float = _rig.size / float(_viewport.size.y)
	var out: Rect2 = Rect2()
	var first: bool = true
	var nodes: Array[Node] = [node]
	nodes.append_array(node.find_children("*", "VisualInstance3D", true, false))
	for child: Node in nodes:
		if not child is VisualInstance3D:
			continue
		var visual: VisualInstance3D = child as VisualInstance3D
		var aabb: AABB = visual.get_aabb()
		var scale: Vector3 = visual.global_basis.get_scale()
		var center: Vector2 = _rig.unproject_position(visual.global_transform * aabb.get_center())
		var half: Vector2 = Vector2(aabb.size.x * scale.x, aabb.size.y * scale.y) * 0.5 / mpp
		var rect: Rect2 = Rect2(center - half, half * 2.0)
		out = rect if first else out.merge(rect)
		first = false
	return out


func _body_px() -> Rect2:
	var right: Vector3 = Vector3.RIGHT * BODY_HALF_WIDTH_M
	var feet: Vector3 = _player.global_position
	var a: Vector2 = _rig.unproject_position(feet - right)
	var b: Vector2 = _rig.unproject_position(feet + right + Vector3.UP * BODY_HEIGHT_M)
	return Rect2(a, Vector2.ZERO).expand(b)


func _xz(node: Node3D) -> Vector2:
	return Vector2(node.global_position.x, node.global_position.z)


## Estación, widget y plazas desde las que se usa.
func _cases() -> Array[Dictionary]:
	var cases: Array[Dictionary] = []
	for child: Node in _level.get_node(^"Stations").get_children():
		if child is Slot and String(child.name).begins_with("PassSlot"):
			var slot: Slot = child as Slot
			var box: Box = BOX_SCENE.instantiate()
			slot.get_node(^"Anchor").add_child(box)
			slot.call("_store", box)
			var counter: Node3D = box.get_node(^"%CutCounter") as Node3D
			counter.visible = true
			var at: Vector2 = _xz(slot)
			cases.append(
				{
					"name": slot.name,
					"widgets": [counter],
					"stands": [at + Vector2(0.0, -1.0), at + Vector2(0.0, 1.0)]
				}
			)
		elif child is CookingStation:
			var pot: CookingStation = child as CookingStation
			var rings: Array[Node3D] = []
			for ring: WorldProgressRing in pot.get_rings():
				rings.append(ring)
			var base: Vector2 = _xz(pot)
			cases.append(
				{"name": pot.name, "widgets": rings, "stands": [base + Vector2(0.0, 0.9), base]}
			)
		elif child is SeasoningStation:
			var bowl: CachelosBowl = child.get_node(^"CachelosBowl") as CachelosBowl
			var at: Vector2 = Vector2(bowl.global_position.x, (child as Node3D).global_position.z)
			cases.append(
				{
					"name": "CachelosBowl",
					"widgets": [bowl.get_node(^"%StockMeter")],
					"stands": [at + Vector2(0.0, 1.0), at + Vector2(0.0, -1.0)]
				}
			)
	return cases


func test_ac2_station_widgets_clear_the_button_zone_from_their_stands() -> void:
	for safe: Vector4 in SAFES:
		for size: Vector2i in SIZES:
			await _check_stands(size, safe)


func _check_stands(size: Vector2i, safe: Vector4) -> void:
	_build(size, safe)
	await wait_process_frames(2)
	var cases: Array[Dictionary] = _cases()
	assert_eq(cases.size(), 9, "6 pasaplatos, 2 ollas y el cuenco")
	await wait_process_frames(1)
	var zone: Rect2 = _zone()
	for entry: Dictionary in cases:
		for stand: Vector2 in entry["stands"]:
			_put(stand)
			var body: Rect2 = _body_px()
			assert_false(
				body.intersects(zone),
				(
					"%s safe %s %s plaza %s: activo %s fuera de los botones %s"
					% [size, safe, entry["name"], stand, body, zone]
				)
			)
			for widget: Node3D in entry["widgets"]:
				var rect: Rect2 = _widget_px(widget)
				assert_gt(rect.size.x, 0.0, "%s: el widget se mide" % entry["name"])
				assert_false(
					rect.intersects(zone),
					(
						"%s safe %s %s plaza %s: %s %s fuera de los botones %s"
						% [size, safe, entry["name"], stand, widget.name, rect, zone]
					)
				)


func test_ac2_active_character_clears_the_button_zone_at_the_east_edge() -> void:
	for safe: Vector4 in SAFES:
		for size: Vector2i in SIZES:
			await _check_east_edge(size, safe)


func _check_east_edge(size: Vector2i, safe: Vector4) -> void:
	_build(size, safe)
	await wait_process_frames(2)
	var zone: Rect2 = _zone()
	var hi: Vector2 = MOBILE.play_area_max
	var checked: int = 0
	for at: Vector2 in [Vector2(hi.x, hi.y), Vector2(hi.x, 3.0), Vector2(hi.x, 0.0)]:
		_put(at)
		var body: Rect2 = _body_px()
		if body.end.y <= zone.position.y:
			continue
		checked += 1
		assert_false(
			body.intersects(zone),
			"%s safe %s activo en %s: %s fuera de %s" % [size, safe, at, body, zone]
		)
		assert_lte(body.end.x, float(size.x), "%s safe %s activo en %s" % [size, safe, at])
	assert_gt(checked, 0, "%s safe %s: algún caso en la franja de botones" % [size, safe])


func test_ac2_frame_above_the_button_strip_is_unchanged() -> void:
	_build(SIZES[0])
	await wait_process_frames(2)
	# Activo arriba (fila de ollas): la franja de botones no cuenta y el foco es el de PUL-133.
	var pot: Vector2 = _xz(_level.get_node(^"Stations/Kitchen2") as Node3D)
	var at: Vector2 = pot + Vector2(0.0, 0.9)
	_put(at)
	var cover: float = _rig.top_cover_m()
	var expected: Vector2 = CameraFollow.clamp_focus_covered(
		CameraFollow.covered_focus(at, cover),
		_rig.view_half_extents(),
		MOBILE.play_area_min,
		MOBILE.play_area_max,
		MOBILE.camera_margin_m,
		cover,
		_rig.top_reach_m()
	)
	assert_lt(_rig.get_focus().distance_to(expected), 0.01)
