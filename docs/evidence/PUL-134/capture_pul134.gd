extends Node
## Capturas y medidas de PUL-134 (flecha bajo la banda y zona de botones). Uso, desde la raíz:
##   godot --path godot --resolution 2340x1080 --position 0,0 -s \
##     ../docs/evidence/PUL-134/capture_boot.gd -- --touch --out=<dir> --tag=2340x1080-despues
## Escribe `<tag>-<escena>.jpg` y `<tag>-medidas.json`. Mide en unidades de lienzo (el lienzo se
## estira) y guarda px reales de la ventana (× `_s()`). Solo usa API
## pública que ya existía antes de PUL-134, así sirve para las capturas «antes» y «después».

const LEVEL: PackedScene = preload("res://scenes/levels/level_01.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const BOX_DATA: BoxData = preload("res://data/boxes/box.tres")
const DESIGN_SIZE: Vector2 = Vector2(2340.0, 1080.0)
const CHARACTER_HEIGHT: float = 1.6

var _out: String = "."
var _tag: String = "captura"
var _level: Node3D
var _rig: CameraRig
var _p1: Node3D
var _p2: Node3D
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


func _shot(scene: String) -> void:
	await _wait(0.5)
	await RenderingServer.frame_post_draw
	var image: Image = get_tree().root.get_texture().get_image()
	var path: String = "%s/%s-%s.jpg" % [_out, _tag, scene]
	image.save_jpg(path, 0.85)
	print("CAPTURA ", path, " ", image.get_size())


func _place(player: Node3D, at: Vector2) -> void:
	player.global_position = Vector3(at.x, 0.005, at.y)


func _ui() -> UiProfile:
	return get_tree().root.get_node(^"GameState").get("ui_profile") as UiProfile


## Zona de botones en unidades de lienzo (como `CameraRig._button_zone`).
func _zone() -> Rect2:
	var c: Vector2 = _canvas()
	var ui: UiProfile = _ui()
	var left: float = c.x - UiScale.px_to_units(ui.button_zone_width_px, c.y)
	var top: float = UiScale.px_to_units(ui.button_zone_top_px, c.y)
	return Rect2(left, top, c.x - left, c.y - top)


## Rectángulo en unidades de lienzo → lista en px reales.
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
		var visual: VisualInstance3D = child as VisualInstance3D
		var aabb: AABB = visual.get_aabb()
		var scale: Vector3 = visual.global_basis.get_scale()
		var center: Vector2 = _rig.unproject_position(visual.global_transform * aabb.get_center())
		var half: Vector2 = Vector2(aabb.size.x * scale.x, aabb.size.y * scale.y) * 0.5 / mpp
		var rect: Rect2 = Rect2(center - half, half * 2.0)
		out = rect if first else out.merge(rect)
		first = false
	return out


func _body_px(player: Node3D) -> Rect2:
	var right: Vector3 = Vector3.RIGHT * 0.35
	var feet: Vector3 = player.global_position
	var a: Vector2 = _rig.unproject_position(feet - right)
	var b: Vector2 = _rig.unproject_position(feet + right + Vector3.UP * CHARACTER_HEIGHT)
	return Rect2(a, Vector2.ZERO).expand(b)


func _box_on(slot_name: String) -> Box:
	var slot: Slot = _level.get_node("Stations/" + slot_name) as Slot
	var box: Box = BOX_SCENE.instantiate()
	box.data = BOX_DATA
	slot.get_node(^"Anchor").add_child(box)
	slot.call("_store", box)
	var counter: Node3D = box.get_node(^"%CutCounter") as Node3D
	counter.visible = true
	(box.get_node(^"%CutNumeral") as Label3D).text = "3/6"
	(box.get_node(^"%CutBar") as WorldProgressBar).set_progress(0.5)
	return box


func _counter_entry(box: Box) -> Dictionary:
	var rect: Rect2 = _widget_px(box.get_node(^"%CutCounter") as Node3D)
	return {"rect_px": _rect_list(rect), "under_buttons": rect.intersects(_zone())}


func _run() -> void:
	await _wait(0.3)
	_level = LEVEL.instantiate()
	get_tree().root.add_child(_level)
	await _wait(0.5)
	_rig = _level.get_node(^"CameraRig") as CameraRig
	_p1 = _level.get_node(^"Characters/Player1") as Node3D
	_p2 = _level.get_node(^"Characters/Player2") as Node3D
	var cover: float = UiScale.px_to_units(_ui().top_band_max_px, _canvas().y)
	_m["tag"] = _tag
	_m["window_px"] = [get_tree().root.size.x, get_tree().root.size.y]
	_m["button_zone_px"] = _rect_list(_zone())
	_m["px_per_canvas_unit"] = snappedf(_s(), 0.0001)
	_m["top_cover_px"] = snappedf(cover * _s(), 0.1)
	# 1. M-2: inactivo en la plaza de la olla 2, tapado por la banda; activo al sur.
	var row: Vector3 = Vector3(0.7, 0.005, -3.1)
	_p2.global_position = row
	var active_z: float = 6.0
	var seen: Vector2 = Vector2(0.0, -1.0)
	while active_z > row.z:
		_place(_p1, Vector2(0.0, active_z))
		await _wait(0.6)
		seen = _rig.unproject_position(row + Vector3.UP * CameraRig.CHARACTER_CENTER_HEIGHT)
		if seen.y >= 0.0:
			break
		active_z -= 0.25
	var arrow_layer: CanvasLayer = _rig.get_node(^"%OffscreenArrow") as CanvasLayer
	var arrow: TextureRect = _rig.get_node(^"%Arrow") as TextureRect
	_m["m2"] = {
		"active_z": active_z,
		"inactive_center_px": [snappedf(seen.x * _s(), 0.1), snappedf(seen.y * _s(), 0.1)],
		"inactive_under_band": seen.y >= 0.0 and seen.y < cover,
		"arrow_visible": arrow_layer.visible,
		"arrow_rect_px": _rect_list(Rect2(arrow.position, arrow.size)),
		"arrow_below_band": arrow_layer.visible and arrow.position.y >= cover - 0.5,
	}
	await _shot("01-flecha-inactivo-bajo-la-banda")
	# 2. Activo en el borde este, a media altura (franja de botones).
	_p2.global_position = Vector3(-4.3, 0.005, -2.0)
	_place(_p1, Vector2(9.4, 3.0))
	await _wait(0.8)
	var body: Rect2 = _body_px(_p1)
	_m["east_edge"] = {"body_px": _rect_list(body), "under_buttons": body.intersects(_zone())}
	await _shot("02-activo-en-el-borde-este")
	# 3. Caja 3/6 en el pasaplatos 06 con el activo en su plaza (lado de pase).
	var box6: Box = _box_on("PassSlot06")
	_place(_p1, Vector2(6.7, 1.0))
	await _wait(0.8)
	_m["pass_slot_06_from_its_stand"] = _counter_entry(box6)
	await _shot("03-contador-desde-su-plaza")
	# 4. Caso 09 (limitación, opción B): activo en las ollas y caja en el pasaplatos 05.
	box6.queue_free()
	var box5: Box = _box_on("PassSlot05")
	_place(_p1, Vector2(-1.3, -3.1))
	await _wait(0.8)
	_m["case_09_pass_slot_05_from_pots"] = _counter_entry(box5)
	await _shot("04-caso-09-caja-lejos-del-activo")
	var file: FileAccess = FileAccess.open("%s/%s-medidas.json" % [_out, _tag], FileAccess.WRITE)
	file.store_string(JSON.stringify(_m, "\t"))
	file.close()
	print("MEDIDAS ", _tag, " ok")
	get_tree().quit()
