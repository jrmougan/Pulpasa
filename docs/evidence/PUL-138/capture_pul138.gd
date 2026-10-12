extends Node
## Capturas de PUL-138 (B-AC5, caso 09 con los botones en fila). Uso, desde la raíz:
##   godot --path godot --resolution 2340x1080 --position 0,0 -s \
##     ../docs/evidence/PUL-138/capture_boot.gd -- --touch --out=<dir> --tag=2340x1080
## `level_01` real en perfil táctil con safe area nula: una caja con contador visible en cada
## pasaplatos (01-06) y el activo en reposo en la olla oeste, en su plaza (z −3,1) y en el extremo
## norte (z −3,4). Se dibuja en rojo el contorno de la zona de botones que usa `CameraRig`
## (ADR-005 E4, D27.2). Escribe `<tag>-caso09-z<z>.jpg` y `<tag>-medidas.json` (px reales).

const LEVEL: PackedScene = preload("res://scenes/levels/level_01.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const BOX_DATA: BoxData = preload("res://data/boxes/box.tres")
const SLOTS: Array[String] = [
	"PassSlot01", "PassSlot02", "PassSlot03", "PassSlot04", "PassSlot05", "PassSlot06"
]
const STAND_ZS: Array[float] = [-3.1, -3.4]

var _out: String = "."
var _tag: String = "captura"
var _level: Node3D
var _rig: CameraRig
var _p1: Node3D
var _touch: TouchControls
var _outline: ReferenceRect
var _boxes: Dictionary = {}


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


func _s() -> float:
	return float(get_tree().root.size.y) / _canvas().y


func _px(rect: Rect2) -> Array:
	return [
		snappedf(rect.position.x * _s(), 0.1),
		snappedf(rect.position.y * _s(), 0.1),
		snappedf(rect.size.x * _s(), 0.1),
		snappedf(rect.size.y * _s(), 0.1)
	]


func _widget(node: Node3D) -> Rect2:
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


func _shot(scene: String) -> void:
	await _wait(0.6)
	await RenderingServer.frame_post_draw
	var image: Image = get_tree().root.get_texture().get_image()
	var path: String = "%s/%s-%s.jpg" % [_out, _tag, scene]
	image.save_jpg(path, 0.85)
	print("CAPTURA ", path, " ", image.get_size())


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
	var zone: Rect2 = _rig.call(&"_button_zone", _canvas()) as Rect2
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_outline = ReferenceRect.new()
	_outline.border_color = Color.RED
	_outline.border_width = 3.0
	_outline.editor_only = false
	_outline.position = zone.position
	_outline.size = zone.size
	layer.add_child(_outline)
	var pot_x: float = (_level.get_node(^"Stations/Kitchen") as Node3D).global_position.x
	var m: Dictionary = {
		"tag": _tag,
		"window_px": [get_tree().root.size.x, get_tree().root.size.y],
		"zone_px": _px(zone),
	}
	for name: StringName in [&"ActionButton", &"SwitchButton"]:
		var button: TouchButton = _touch.get_node("%" + name) as TouchButton
		m[name] = {
			"center_px": [button.get_center().x * _s(), button.get_center().y * _s()],
			"hit_radius_px": button.get_hit_radius() * _s()
		}
	for z: float in STAND_ZS:
		_p1.global_position = Vector3(pot_x, 0.005, z)
		await _wait(0.8)
		var rows: Dictionary = {}
		var worst: float = 0.0
		for slot: String in SLOTS:
			var rect: Rect2 = _widget(_boxes[slot].get_node(^"%CutCounter") as Node3D)
			var over: float = rect.intersection(zone).size.y if rect.intersects(zone) else 0.0
			worst = maxf(worst, over * _s())
			rows[slot] = {"rect_px": _px(rect), "overlap_px": snappedf(over * _s(), 0.1)}
		m["z %.1f" % z] = {"counters": rows, "max_overlap_px": snappedf(worst, 0.1)}
		await _shot("caso09-z%s" % ("%.1f" % -z).replace(".", "_"))
	var file: FileAccess = FileAccess.open("%s/%s-medidas.json" % [_out, _tag], FileAccess.WRITE)
	file.store_string(JSON.stringify(m, "\t"))
	file.close()
	print("MEDIDAS ", _tag, " ok")
	get_tree().quit()
