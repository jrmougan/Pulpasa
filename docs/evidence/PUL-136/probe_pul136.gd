extends Node
## Sonda de PUL-136 (caso 09: contador N/6 de los pasaplatos bajo los botones). Uso, desde la raíz:
##   godot --path godot --resolution 2340x1080 --position 0,0 -s \
##     ../docs/evidence/PUL-136/probe_boot.gd -- --touch --out=<dir> --tag=2340x1080
## Con el activo en reposo en cada plaza de las ollas, mide el contador de una caja en cada
## pasaplatos (01-06) y su cruce con: la zona de botones actual (rectángulo de E4), los discos
## táctiles reales de los botones y las alternativas de diseño (A: contador desplazado; B: botón
## de cambiar a la izquierda del de acción). Todo se aplica en tiempo de ejecución sobre la escena
## real: no cambia código, escenas ni datos. Escribe `<tag>-medidas.json` y capturas
## `<tag>-<escena>.jpg` en px reales.

const LEVEL: PackedScene = preload("res://scenes/levels/level_01.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const BOX_DATA: BoxData = preload("res://data/boxes/box.tres")
const SLOTS: Array[String] = [
	"PassSlot01", "PassSlot02", "PassSlot03", "PassSlot04", "PassSlot05", "PassSlot06"
]
## Plazas de las ollas (z −3,1, la de `test_camera_button_zone.gd`) y el punto más al norte al
## que llega el activo caminando en las ollas (z −3,4, medido con `reach_pul136.gd`; el centro de
## la olla, z −4,0, no es alcanzable).
const STANDS: Array[Vector2] = [
	Vector2(-1.3, -3.1), Vector2(-1.3, -3.4), Vector2(0.7, -3.1), Vector2(0.7, -3.4)
]
## Variantes del contador (offset local respecto a la posición actual, m).
const COUNTER_VARIANTS: Dictionary = {
	"actual": Vector3.ZERO,
	"A1_oeste": Vector3(-0.85, -0.3, 0.0),
	"A2_arriba_0_6": Vector3(0.0, 0.6, 0.0),
	"A3_arriba_1_2": Vector3(0.0, 1.2, 0.0),
}

var _out: String = "."
var _tag: String = "sonda"
var _level: Node3D
var _rig: CameraRig
var _p1: Node3D
var _touch: TouchControls
var _boxes: Dictionary = {}
var _m: Dictionary = {}


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=")
	_run.call_deferred()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _canvas() -> Vector2:
	return get_tree().root.get_visible_rect().size


## px reales por unidad de lienzo.
func _s() -> float:
	return float(get_tree().root.size.y) / _canvas().y


## px de diseño (a 1080) → unidades de lienzo.
func _u(px: float) -> float:
	return UiScale.px_to_units(px, _canvas().y)


func _ui() -> UiProfile:
	return get_tree().root.get_node(^"GameState").get("ui_profile") as UiProfile


func _shot(scene: String) -> void:
	await _wait(0.6)
	await RenderingServer.frame_post_draw
	var image: Image = get_tree().root.get_texture().get_image()
	var path: String = "%s/%s-%s.jpg" % [_out, _tag, scene]
	image.save_jpg(path, 0.85)
	print("CAPTURA ", path, " ", image.get_size())


## Zona de botones actual (E4) en unidades de lienzo.
func _zone_now() -> Rect2:
	var c: Vector2 = _canvas()
	var left: float = c.x - _u(_ui().button_zone_width_px)
	var top: float = _u(_ui().button_zone_top_px)
	return Rect2(left, top, c.x - left, c.y - top)


## Alternativa B: botones en fila (cambiar a la izquierda de acción, alineados abajo). La zona baja
## hasta el borde superior de la zona táctil del botón de acción (1080 − 48 − 180 − 12 = 840).
func _zone_b() -> Rect2:
	var c: Vector2 = _canvas()
	var left: float = c.x - _u(_ui().button_zone_width_px)
	var top: float = c.y - _u(48.0 + 180.0 + 12.0)
	return Rect2(left, top, c.x - left, c.y - top)


func _rect_list(units: Rect2) -> Array:
	var rect: Rect2 = Rect2(units.position * _s(), units.size * _s())
	return [
		snappedf(rect.position.x, 0.1),
		snappedf(rect.position.y, 0.1),
		snappedf(rect.size.x, 0.1),
		snappedf(rect.size.y, 0.1)
	]


func _widget_px(node: Node3D) -> Rect2:
	var mpp: float = _rig.size / _canvas().y
	var out: Rect2 = Rect2()
	var first: bool = true
	for child: Node in node.find_children("*", "VisualInstance3D", true, false):
		if not (child as Node3D).is_visible_in_tree():
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


## Discos táctiles (centro y radio con margen de toque) de acción y cambiar, en unidades de lienzo.
func _discs() -> Array:
	var out: Array = []
	for name: StringName in [&"ActionButton", &"SwitchButton"]:
		var button: TouchButton = _touch.get_node("%" + name) as TouchButton
		out.append([button.get_center(), button.get_radius() + _u(12.0)])
	return out


func _rect_hits_disc(rect: Rect2, center: Vector2, radius: float) -> bool:
	var closest: Vector2 = center.clamp(rect.position, rect.end)
	return closest.distance_to(center) <= radius


func _rect_hits_discs(rect: Rect2, discs: Array) -> bool:
	for disc: Array in discs:
		if _rect_hits_disc(rect, disc[0], disc[1]):
			return true
	return false


func _box_on(slot_name: String, cuts: int) -> Box:
	var slot: Slot = _level.get_node("Stations/" + slot_name) as Slot
	var box: Box = BOX_SCENE.instantiate()
	box.data = BOX_DATA
	slot.get_node(^"Anchor").add_child(box)
	slot.call("_store", box)
	(box.get_node(^"%CutCounter") as Node3D).visible = true
	(box.get_node(^"%CutNumeral") as Label3D).text = "%d/6" % cuts
	(box.get_node(^"%CutBar") as WorldProgressBar).set_progress(cuts / 6.0)
	return box


func _set_counter_offset(offset: Vector3) -> void:
	for box: Box in _boxes.values():
		(box.get_node(^"%CutCounter") as Node3D).position = Vector3(0.0, 0.62, 0.0) + offset


## Botón de cambiar en fila: a la izquierda del de acción, alineado por abajo.
func _switch_in_row(enabled: bool) -> void:
	_touch.refresh_layout()
	if not enabled:
		return
	var action: TouchButton = _touch.get_node(^"%ActionButton") as TouchButton
	var switch: TouchButton = _touch.get_node(^"%SwitchButton") as TouchButton
	var big: float = action.get_radius()
	var small: float = switch.get_radius()
	var center: Vector2 = action.get_center() + Vector2(-(big + _u(24.0) + small), big - small)
	switch.global_position = center - switch.size / 2.0


func _settle(at: Vector2) -> void:
	_p1.global_position = Vector3(at.x, 0.005, at.y)
	await _wait(0.8)


func _measure() -> Dictionary:
	var out: Dictionary = {}
	var discs_now: Array = _discs()
	for stand: Vector2 in STANDS:
		await _settle(stand)
		var per_stand: Dictionary = {}
		for variant: String in COUNTER_VARIANTS:
			_set_counter_offset(COUNTER_VARIANTS[variant])
			var rows: Dictionary = {}
			for slot: String in SLOTS:
				var rect: Rect2 = _widget_px(_boxes[slot].get_node(^"%CutCounter") as Node3D)
				var c: Vector2 = _canvas()
				var on_screen: bool = rect.intersects(Rect2(Vector2.ZERO, c))
				rows[slot] = {
					"rect_px": _rect_list(rect),
					"on_screen": on_screen,
					"zone_now": rect.intersects(_zone_now()),
					"discs_now": _rect_hits_discs(rect, discs_now),
					"zone_b": rect.intersects(_zone_b()),
					"band": rect.position.y < _u(_ui().top_band_max_px),
				}
			per_stand[variant] = rows
		# Cuerpo de cada caja (sin contador), para la alternativa B.
		_set_counter_offset(Vector3.ZERO)
		var bodies: Dictionary = {}
		for slot: String in SLOTS:
			var counter: Node3D = _boxes[slot].get_node(^"%CutCounter") as Node3D
			counter.visible = false
			var rect: Rect2 = _widget_px(_boxes[slot])
			counter.visible = true
			bodies[slot] = {
				"rect_px": _rect_list(rect),
				"zone_now": rect.intersects(_zone_now()),
				"zone_b": rect.intersects(_zone_b())
			}
		per_stand["box_body"] = bodies
		per_stand["player_at"] = [
			snappedf(_p1.global_position.x, 0.01), snappedf(_p1.global_position.z, 0.01)
		]
		per_stand["focus"] = [
			snappedf(_rig.get_focus().x, 0.01), snappedf(_rig.get_focus().y, 0.01)
		]
		out["%s,%s" % [stand.x, stand.y]] = per_stand
	return out


func _run() -> void:
	await _wait(0.3)
	_level = LEVEL.instantiate()
	get_tree().root.add_child(_level)
	await _wait(0.5)
	_rig = _level.get_node(^"CameraRig") as CameraRig
	_p1 = _level.get_node(^"Characters/Player1") as Node3D
	_touch = _level.get_node(^"UI/TouchControls") as TouchControls
	_touch.set_last_source(TouchInput.Source.TOUCH)
	(_level.get_node(^"Characters/Player2") as Node3D).global_position = Vector3(-5.4, 0.005, 3.0)
	var cuts: int = 1
	for slot: String in SLOTS:
		_boxes[slot] = _box_on(slot, cuts)
		cuts = cuts % 5 + 1
	_m["tag"] = _tag
	_m["window_px"] = [get_tree().root.size.x, get_tree().root.size.y]
	_m["zone_now_px"] = _rect_list(_zone_now())
	_m["zone_b_px"] = _rect_list(_zone_b())
	var discs: Array = []
	for disc: Array in _discs():
		discs.append(
			[
				snappedf(disc[0].x * _s(), 0.1),
				snappedf(disc[0].y * _s(), 0.1),
				snappedf(disc[1] * _s(), 0.1)
			]
		)
	_m["discs_now_px"] = discs
	_m["stands"] = await _measure()
	# Capturas: activo en la olla oeste (caso 09 de PUL-133/PUL-134).
	await _settle(STANDS[0])
	_set_counter_offset(Vector3.ZERO)
	await _shot("01-actual")
	_set_counter_offset(COUNTER_VARIANTS["A1_oeste"])
	await _shot("02-A1-contador-al-oeste")
	_set_counter_offset(COUNTER_VARIANTS["A3_arriba_1_2"])
	await _shot("03-A3-contador-1-2-m-mas-alto")
	_set_counter_offset(Vector3.ZERO)
	_switch_in_row(true)
	await get_tree().process_frame
	var b_discs: Array = []
	for disc: Array in _discs():
		b_discs.append(
			[
				snappedf(disc[0].x * _s(), 0.1),
				snappedf(disc[0].y * _s(), 0.1),
				snappedf(disc[1] * _s(), 0.1)
			]
		)
	_m["discs_b_px"] = b_discs
	await _shot("04-B-botones-en-fila")
	var file: FileAccess = FileAccess.open("%s/%s-medidas.json" % [_out, _tag], FileAccess.WRITE)
	file.store_string(JSON.stringify(_m, "\t"))
	file.close()
	print("MEDIDAS ", _tag, " ok")
	get_tree().quit()
