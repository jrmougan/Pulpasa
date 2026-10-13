extends Node
## PUL-152 AC4: caso 09 en juego real, copia de `docs/evidence/PUL-138/capture_pul138.gd` ampliada
## a las dos ollas y a las dos safe areas. Uso, desde la raíz:
##   godot --path godot --resolution 2340x1080 --position 0,0 \
##     -s ../docs/evidence/PUL-152/capture_caso09_boot.gd -- --touch --out=<dir> --tag=2340x1080
## `level_01` real en perfil táctil: una caja con contador visible en cada pasaplatos (01-06) y
## el activo en reposo (física real) en cada olla (oeste `Kitchen`, este `Kitchen2`), en su plaza
## (z −3,1) y en el extremo norte (z −3,4), con safe area nula y con la de diseño (132 / 0 / 132 /
## 63 a 2340×1080, escalada al alto). La safe area se inyecta en los `SafeAreaMargin` de la UI, en
## `TouchControls` y en `CameraRig` (lo que leerían de `DisplayServer`). En rojo, la zona de
## botones de `CameraRig._button_zone` (ADR-005 E4, D27.2). Solape = alto de la intersección del
## rectángulo del contador (unión de sus visuales proyectados) con la zona, en px reales.
## `--host-safe`: ver la variable. Escribe `<tag>-caso09-<nula|diseno>-<oeste|este>-<z3_1|z3_4>.jpg`
## (salvo con `--no-jpg`) y `<tag>-caso09-medidas.json`.

const LEVEL: PackedScene = preload("res://scenes/levels/level_01.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const BOX_DATA: BoxData = preload("res://data/boxes/box.tres")
const SLOTS: Array[String] = [
	"PassSlot01", "PassSlot02", "PassSlot03", "PassSlot04", "PassSlot05", "PassSlot06"
]
const POTS: Array[Array] = [["oeste", "Kitchen"], ["este", "Kitchen2"]]
const STAND_ZS: Array[float] = [-3.1, -3.4]
## Safe area de diseño (izq, arriba, der, abajo) en px a 1080 de alto.
const SAFE_DESIGN_1080: Vector4 = Vector4(132.0, 0.0, 132.0, 63.0)

var _out: String = "."
var _tag: String = "captura"
var _jpg: bool = true
## `--host-safe`: la pasada «nula» no inyecta nada y deja la safe area del sistema (como las
## capturas de PUL-136 y PUL-138); sirve para comparar con ellas (hallazgo H-05).
var _host_safe: bool = false
var _level: Node3D
var _rig: CameraRig
var _p1: CharacterBody3D
var _touch: TouchControls
var _outline: ReferenceRect
var _boxes: Dictionary = {}


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=")
		elif arg == "--no-jpg":
			_jpg = false
		elif arg == "--host-safe":
			_host_safe = true
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


## Safe area en px de pantalla (rectángulo) a partir de márgenes a 1080 de alto.
func _safe_rect(margins_1080: Vector4) -> Rect2:
	var window: Vector2 = Vector2(get_tree().root.size)
	var k: float = window.y / 1080.0
	var m: Vector4 = margins_1080 * k
	return Rect2(m.x, m.y, window.x - m.x - m.z, window.y - m.y - m.w)


func _apply_safe(margins_1080: Vector4) -> Vector4:
	var window: Vector2 = Vector2(get_tree().root.size)
	var rect: Rect2 = _safe_rect(margins_1080)
	for node: Node in _level.get_node("UI").find_children("*", "SafeAreaMargin", true, false):
		(node as SafeAreaMargin).set_safe_rect(rect, window)
	_touch.apply_safe_rect(rect, window)
	var units: Vector4 = UiScale.safe_margins(window, rect, _canvas())
	_rig.set_safe_margins(units)
	return units


## Alto (px reales) de la intersección de `rect` con `other` (0 si no se cortan).
func _overlap_y(rect: Rect2, other: Rect2) -> float:
	return rect.intersection(other).size.y * _s() if rect.intersects(other) else 0.0


func _disc_rect(button: TouchButton, radius: float) -> Rect2:
	return Rect2(button.get_center() - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)


func _shot(scene: String) -> void:
	await _wait(0.6)
	await RenderingServer.frame_post_draw
	if not _jpg:
		return
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
	_p1 = _level.get_node(^"Characters/Player1") as CharacterBody3D
	_touch = _level.get_node(^"UI/TouchControls") as TouchControls
	_touch.set_last_source(TouchInput.Source.TOUCH)
	(_level.get_node(^"Characters/Player2") as Node3D).global_position = Vector3(-5.4, 0.005, 3.0)
	var cuts: int = 1
	for slot: String in SLOTS:
		_boxes[slot] = _box_on(slot, cuts)
		cuts = cuts % 5 + 1
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_outline = ReferenceRect.new()
	_outline.border_color = Color.RED
	_outline.border_width = 3.0
	_outline.editor_only = false
	layer.add_child(_outline)
	var m: Dictionary = {
		"tag": _tag,
		"window_px": [get_tree().root.size.x, get_tree().root.size.y],
		"stretch_scale": snappedf(_s(), 0.0001),
		"host_display_safe_area": str(DisplayServer.get_display_safe_area()),
		"views": {},
	}
	for safe: Array in [["nula", Vector4.ZERO], ["diseno", SAFE_DESIGN_1080]]:
		var units: Vector4 = Vector4.ZERO
		if _host_safe and safe[0] == "nula":
			units = _rig.call(&"_safe_margins", _canvas()) as Vector4
		else:
			units = _apply_safe(safe[1] as Vector4)
		await _wait(0.2)
		var zone: Rect2 = _rig.call(&"_button_zone", _canvas()) as Rect2
		_outline.position = zone.position
		_outline.size = zone.size
		var action: TouchButton = _touch.get_node(^"%ActionButton") as TouchButton
		var switch: TouchButton = _touch.get_node(^"%SwitchButton") as TouchButton
		var layout: Dictionary = {
			"safe_margins_px": [units.x * _s(), units.y * _s(), units.z * _s(), units.w * _s()],
			"safe_area_margin_px":
			[
				_touch.get_safe_rect().position.x * _s(),
				(_canvas().x - _touch.get_safe_rect().end.x) * _s(),
				(_canvas().y - _touch.get_safe_rect().end.y) * _s(),
			],
			"zone_px": _px(zone),
		}
		for pair: Array in [["action", action], ["switch", switch]]:
			var button: TouchButton = pair[1] as TouchButton
			layout[pair[0]] = {
				"center_px":
				[
					snappedf(button.get_center().x * _s(), 0.1),
					snappedf(button.get_center().y * _s(), 0.1)
				],
				"diameter_px": snappedf(button.size.x * _s(), 0.1),
				"hit_radius_px": snappedf(button.get_hit_radius() * _s(), 0.1),
			}
		var action_px: Rect2 = Rect2(action.get_global_rect().position, action.size)
		var switch_px: Rect2 = Rect2(switch.get_global_rect().position, switch.size)
		layout["gap_x_px"] = snappedf((action_px.position.x - switch_px.end.x) * _s(), 0.1)
		layout["bottom_delta_px"] = snappedf((action_px.end.y - switch_px.end.y) * _s(), 0.1)
		m["layout_" + str(safe[0])] = layout
		for pot: Array in POTS:
			var pot_node: Node3D = _level.get_node("Stations/" + str(pot[1])) as Node3D
			for z: float in STAND_ZS:
				_p1.global_position = Vector3(pot_node.global_position.x, 0.005, z)
				_p1.velocity = Vector3.ZERO
				await _wait(1.2)
				var rows: Dictionary = {}
				var worst: float = 0.0
				var worst_hit: float = 0.0
				var worst_disc: float = 0.0
				for slot: String in SLOTS:
					var rect: Rect2 = _widget(_boxes[slot].get_node(^"%CutCounter") as Node3D)
					var over: float = _overlap_y(rect, zone)
					var hit: float = maxf(
						_overlap_y(rect, _disc_rect(action, action.get_hit_radius())),
						_overlap_y(rect, _disc_rect(switch, switch.get_hit_radius()))
					)
					var disc: float = maxf(
						_overlap_y(rect, _disc_rect(action, action.size.x * 0.5)),
						_overlap_y(rect, _disc_rect(switch, switch.size.x * 0.5))
					)
					worst = maxf(worst, over)
					worst_hit = maxf(worst_hit, hit)
					worst_disc = maxf(worst_disc, disc)
					rows[slot] = {
						"rect_px": _px(rect),
						"overlap_px": snappedf(over, 0.1),
						"overlap_hit_box_px": snappedf(hit, 0.1),
						"overlap_disc_box_px": snappedf(disc, 0.1),
					}
				var z_name: String = "z%s" % ("%.1f" % -z).replace(".", "_")
				var key: String = "%s-%s-%s" % [safe[0], pot[0], z_name]
				m["views"][key] = {
					"player_xz":
					[
						snappedf(_p1.global_position.x, 0.001),
						snappedf(_p1.global_position.z, 0.001)
					],
					"requested_xz": [pot_node.global_position.x, z],
					"camera_focus":
					[snappedf(_rig.get_focus().x, 0.001), snappedf(_rig.get_focus().y, 0.001)],
					"counters": rows,
					"max_overlap_px": snappedf(worst, 0.1),
					"max_overlap_hit_box_px": snappedf(worst_hit, 0.1),
					"max_overlap_disc_box_px": snappedf(worst_disc, 0.1),
				}
				print("VISTA ", _tag, " ", key, " ", snappedf(worst, 0.1))
				await _shot("caso09-" + key)
	var path: String = "%s/%s-caso09-medidas.json" % [_out, _tag]
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(m, "\t"))
	file.close()
	# Libera el nivel antes de salir: si no, el audio ambiente de `level_audio.tscn` sigue sonando y
	# Godot avisa al salir de recursos en uso (ERROR que `run_all.sh` trata como fallo).
	_level.queue_free()
	await _wait(0.2)
	print("MEDIDAS ", _tag, " caso09 ok")
	get_tree().quit()
