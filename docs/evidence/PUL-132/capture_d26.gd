extends Node
## PUL-132: capturas y medidas de D26 sobre `level_01` real, a una resolución.
##
## Uso (desde la raíz del repositorio; una ejecución por resolución, con ventana):
##   godot --path godot --resolution 2340x1080 --position 0,0 -s \
##     ../docs/evidence/PUL-132/capture_d26.gd -- --touch --safe \
##     --out=docs/evidence/PUL-132 --tag=2340x1080-touch
## Argumentos de usuario:
## - `--touch`: perfil táctil real (`core/platform_profile.gd`).
## - `--safe`: simula la safe area del diseño (132/0/132/63) escalada al alto de la ventana.
## - `--out=<dir>` y `--tag=<id>`: carpeta y prefijo de los ficheros.
## Escribe `<tag>-<escena>.png` y `<tag>-medidas.json` en `--out`. Las medidas van en px REALES de
## pantalla (unidades de lienzo por la escala de estiramiento) y, con `_at_1080`, su equivalente
## a 1080 de alto (`px * 1080 / alto`).
## Nada de esto se ejecuta en `verify.sh`: es una herramienta de evidencia, reproducible a mano.

const LEVEL: PackedScene = preload("res://scenes/levels/level_01.tscn")
const MAIN_MENU: PackedScene = preload("res://ui/menus/main_menu.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const CACHELOS_SCENE: PackedScene = preload("res://entities/items/cachelos.tscn")
const BOX_DATA: BoxData = preload("res://data/boxes/box.tres")
const SWEET: SeasoningData = preload("res://data/seasonings/sweet_dressing.tres")
const HOT: SeasoningData = preload("res://data/seasonings/hot_dressing.tres")
const CACHELOS: SeasoningData = preload("res://data/seasonings/cachelos.tres")
const SAFE_DESIGN: Rect2 = Rect2(132.0, 0.0, 2076.0, 1017.0)
const DESIGN_SIZE: Vector2 = Vector2(2340.0, 1080.0)
const CHARACTER_HEIGHT: float = 1.6

var root: Window
var _out: String = "."
var _tag: String = "run"
var _touch: bool = false
var _safe: bool = false
var _level: Node3D
var _p1: Player
var _p2: Player
var _hold: HoldComponent
var _actor: InteractionComponent
var _m: Dictionary = {}
var _band_bottom: float = 0.0
var _config: RoundConfig


func _ready() -> void:
	root = get_tree().root
	_config = load("res://data/config/round_config.tres") as RoundConfig
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=")
		elif arg == "--touch":
			_touch = true
		elif arg == "--safe":
			_safe = true
	_run.call_deferred()


# --- Utilidades ---------------------------------------------------------------------------------


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().process_frame


func _scale() -> float:
	return root.get_final_transform().get_scale().y


func _real_height() -> float:
	return float(root.size.y)


func _to_1080(px: float) -> float:
	return px * 1080.0 / _real_height()


func _shot(scene: String) -> void:
	await _wait(0.5)
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path: String = "%s/%s-%s.jpg" % [_out, _tag, scene]
	image.save_jpg(path, 0.85)
	print("CAPTURA ", path, " ", image.get_size())


func _node(path: String) -> Node:
	return root.get_node(path)


func _camera() -> Camera3D:
	return root.get_camera_3d()


func _xz(node: Node3D) -> Vector2:
	return Vector2(node.global_position.x, node.global_position.z)


func _stations(path: String) -> Node3D:
	return _level.get_node("Stations/" + path) as Node3D


func _station() -> SeasoningStation:
	return _stations("SeasoningStation") as SeasoningStation


func _yaw(from: Vector2, to: Vector2) -> float:
	var direction: Vector2 = to - from
	return atan2(-direction.x, -direction.y)


func _place(player: Player, stand: Vector2, aim: Vector2) -> void:
	player.global_position = Vector3(stand.x, 0.005, stand.y)
	player.velocity = Vector3.ZERO
	player.rotation = Vector3(0.0, _yaw(stand, aim), 0.0)


func _clear_hand() -> void:
	var held: Node = _hold.get_held_item()
	if held != null:
		_hold.drop()
		held.queue_free()


func _items() -> Node:
	return _level.get_node("Items")


func _new_octopus(cooked: bool) -> Ingredient:
	var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
	_items().add_child(octopus)
	if cooked:
		octopus.set_cooked()
	return octopus


func _new_box(fill: float) -> Box:
	var box: Box = BOX_SCENE.instantiate()
	box.data = BOX_DATA
	_items().add_child(box)
	box.fill = fill
	return box


func _equip(item: Node) -> void:
	_clear_hand()
	_hold.pick_up(item)


## Escala de la safe area del diseño al alto de esta ventana (solo con `--safe`).
func _apply_safe_area() -> void:
	if not _safe:
		return
	var window: Vector2 = Vector2(root.size)
	var k: float = window.y / DESIGN_SIZE.y
	var rect: Rect2 = Rect2(SAFE_DESIGN.position * k, SAFE_DESIGN.size * k)
	if window.x != DESIGN_SIZE.x * k:
		rect = Rect2(132.0 * k, 0.0, window.x - 264.0 * k, window.y - 63.0 * k)
	for node: Node in _level.get_node("UI").find_children("*", "SafeAreaMargin", true, false):
		(node as SafeAreaMargin).set_safe_rect(rect, window)
	var controls: TouchControls = _level.get_node_or_null("UI/TouchControls") as TouchControls
	if controls != null:
		controls.apply_safe_rect(rect, window)
	_m["safe_rect_px"] = [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


func _control_px(control: Control) -> Rect2:
	var rect: Rect2 = control.get_global_rect()
	var s: float = _scale()
	return Rect2(rect.position * s, rect.size * s)


func _rect_list(rect: Rect2) -> Array:
	return [
		snappedf(rect.position.x, 0.1),
		snappedf(rect.position.y, 0.1),
		snappedf(rect.size.x, 0.1),
		snappedf(rect.size.y, 0.1)
	]


## Lado en px reales de pantalla de un sprite del mundo, proyectando dos puntos de su borde.
func _sprite_px(sprite: Sprite3D) -> float:
	if sprite.texture == null:
		return 0.0
	var camera: Camera3D = _camera()
	var right: Vector3 = camera.global_transform.basis.x
	var half: float = (
		sprite.pixel_size * float(sprite.texture.get_width()) * 0.5 * absf(sprite.scale.x)
	)
	var a: Vector2 = camera.unproject_position(sprite.global_position - right * half)
	var b: Vector2 = camera.unproject_position(sprite.global_position + right * half)
	return a.distance_to(b) * _scale()


func _meters_per_px() -> float:
	return _camera().size / _real_height()


func _texts_under(node: Node) -> Array:
	var found: Array = []
	for child: Node in node.find_children("*", "Control", true, false):
		var control: Control = child as Control
		if control.is_visible_in_tree() and TextFloor.font_size_of(control) > 0:
			var size_px: float = TextFloor.font_size_of(control) * _scale()
			found.append(
				{"path": str(control.get_path()), "px": size_px, "text": _text_of(control)}
			)
	return found


func _text_of(control: Control) -> String:
	if control is Label:
		return (control as Label).text
	if control is Button:
		return (control as Button).text
	if control is RichTextLabel:
		return (control as RichTextLabel).get_parsed_text()
	return ""


func _min_text(node: Node, label: String) -> void:
	var texts: Array = _texts_under(node)
	var lowest: Dictionary = {}
	for entry: Dictionary in texts:
		if lowest.is_empty() or float(entry["px"]) < float(lowest["px"]):
			lowest = entry
	_m["min_text_" + label] = {
		"count": texts.size(),
		"min_px": snappedf(float(lowest.get("px", 0.0)), 0.01),
		"min_px_at_1080": snappedf(_to_1080(float(lowest.get("px", 0.0))), 0.01),
		"node": lowest.get("path", ""),
		"text": lowest.get("text", ""),
	}


# --- Medidas ------------------------------------------------------------------------------------


func _measure_scale() -> void:
	var camera: Camera3D = _camera()
	var feet: Vector3 = _p1.global_position
	var a: Vector2 = camera.unproject_position(feet)
	var b: Vector2 = camera.unproject_position(feet + Vector3.UP * CHARACTER_HEIGHT)
	var ppm: float = absf(a.y - b.y) * _scale() / CHARACTER_HEIGHT
	_m["camera_size_m"] = camera.size
	_m["px_per_meter"] = snappedf(ppm, 0.1)
	_m["px_per_meter_at_1080"] = snappedf(_to_1080(ppm), 0.1)
	_m["character_px"] = snappedf(ppm * CHARACTER_HEIGHT, 0.1)
	_m["character_px_at_1080"] = snappedf(_to_1080(ppm * CHARACTER_HEIGHT), 0.1)


func _measure_prompt(label: String) -> void:
	var prompts: Array[Node] = _p1.find_children("*", "ActionPrompt", true, false)
	if prompts.is_empty():
		return
	var prompt: ActionPrompt = prompts[0] as ActionPrompt
	var entry: Dictionary = {
		"shown": prompt.is_shown(),
		"verb": str(prompt.get_hint().verb),
		"state": int(prompt.get_hint().state),
		"reason": str(prompt.get_hint().reason),
		"icon_px": snappedf(_sprite_px(prompt.get_node("%VerbIcon") as Sprite3D), 0.1),
		"plate_px": snappedf(_sprite_px(prompt.get_node("%Plate") as Sprite3D), 0.1),
		"icon_px_formula":
		snappedf(prompt.size_px_of(prompt.get_node("%VerbIcon") as Sprite3D), 0.1),
	}
	var reason: Sprite3D = prompt.get_node("%ReasonIcon") as Sprite3D
	var cross: Sprite3D = prompt.get_node("%Cross") as Sprite3D
	if reason.visible:
		entry["reason_icon_px"] = snappedf(_sprite_px(reason), 0.1)
	if cross.visible:
		entry["cross_px"] = snappedf(_sprite_px(cross), 0.1)
	entry["icon_px_at_1080"] = snappedf(_to_1080(float(entry["icon_px"])), 0.1)
	_m["prompt_" + label] = entry


func _measure_touch_controls() -> void:
	var controls: TouchControls = _level.get_node_or_null("UI/TouchControls") as TouchControls
	if controls == null:
		_m["touch_controls"] = "no instanciados (perfil escritorio)"
		return
	var action: ActionButton = controls.get_node("%ActionButton") as ActionButton
	var switch: Control = controls.get_node("%SwitchButton") as Control
	var pause: Control = controls.get_node("%PauseButton") as Control
	var s: float = _scale()
	var entry: Dictionary = {"visible": controls.visible}
	for pair: Array in [["action", action], ["switch", switch], ["pause", pause]]:
		var control: Control = pair[1] as Control
		var rect: Rect2 = _control_px(control)
		entry[pair[0]] = {
			"rect_px": _rect_list(rect),
			"diameter_px": snappedf(rect.size.x, 0.1),
			"center_px": [snappedf(rect.get_center().x, 0.1), snappedf(rect.get_center().y, 0.1)],
		}
	var slop_px: float = action.hit_slop * s
	entry["action"]["hit_px"] = snappedf(_control_px(action).size.x + 2.0 * slop_px, 0.1)
	var safe: Rect2 = controls.get_safe_rect()
	var safe_px: Rect2 = Rect2(safe.position * s, safe.size * s)
	entry["safe_rect_px"] = _rect_list(safe_px)
	var action_rect: Rect2 = _control_px(action)
	entry["action_margin_px"] = {
		"right": snappedf(safe_px.end.x - action_rect.end.x, 0.1),
		"bottom": snappedf(safe_px.end.y - action_rect.end.y, 0.1),
	}
	var switch_rect: Rect2 = _control_px(switch)
	entry["switch_to_action_gap_px"] = snappedf(action_rect.position.y - switch_rect.end.y, 0.1)
	var stick: VirtualStick = controls.get_node("%MoveStick") as VirtualStick
	entry["stick_base_px"] = snappedf(stick.get_base_diameter() * s, 0.1)
	entry["stick_radius_px"] = snappedf(stick.get_travel_radius() * s, 0.1)
	entry["stick_zone_px"] = _rect_list(
		Rect2(controls.get_stick_zone().position * s, controls.get_stick_zone().size * s)
	)
	_m["touch_controls"] = entry


func _measure_top_band() -> void:
	var hud_blocks: Array[Rect2] = []
	var hud: Node = _level.get_node("UI/HUD")
	var background: Control = hud.get_node_or_null("%Background") as Control
	if background != null:
		hud_blocks.append(_control_px(background))
	var tickets: Array[Rect2] = []
	var panel: Node = _level.get_node("UI/OrderTicketsPanel")
	for ticket: Node in panel.get_node("%Tickets").get_children():
		if (ticket as Control).is_visible_in_tree():
			tickets.append(_control_px(ticket as Control))
	var w: float = float(root.size.x)
	var h: float = _real_height()
	var k: float = h / 1080.0
	var stick_zone: Rect2 = Rect2(0.0, 200.0 * k, w * 0.5, h - 200.0 * k)
	var button_zone: Rect2 = Rect2(w - 390.0 * k, 600.0 * k, 390.0 * k, h - 600.0 * k)
	var blocks: Array[Rect2] = []
	blocks.append_array(hud_blocks)
	blocks.append_array(tickets)
	var pause_rect: Rect2 = Rect2()
	var controls: TouchControls = _level.get_node_or_null("UI/TouchControls") as TouchControls
	if controls != null and controls.visible:
		pause_rect = _control_px(controls.get_node("%PauseButton") as Control)
	var overlaps: Array = []
	for i: int in blocks.size():
		if blocks[i].intersects(stick_zone):
			overlaps.append("bloque %d con zona del stick" % i)
		if blocks[i].intersects(button_zone):
			overlaps.append("bloque %d con zona de botones" % i)
		for j: int in range(i + 1, blocks.size()):
			if blocks[i].intersects(blocks[j]):
				overlaps.append("bloque %d con bloque %d" % [i, j])
		if pause_rect.size != Vector2.ZERO and blocks[i].intersects(pause_rect):
			overlaps.append("bloque %d con botón de pausa" % i)
	var band_bottom: float = 0.0
	for block: Rect2 in blocks:
		band_bottom = maxf(band_bottom, block.end.y)
	_band_bottom = band_bottom
	var entry: Dictionary = {
		"hud_rect_px": _rect_list(hud_blocks[0]) if not hud_blocks.is_empty() else [],
		"tickets_px": [],
		"stick_zone_px": _rect_list(stick_zone),
		"button_zone_px": _rect_list(button_zone),
		"overlaps": overlaps,
		"band_height_px": snappedf(band_bottom, 0.1),
		"band_fraction": snappedf(band_bottom / h, 0.001),
	}
	for rect: Rect2 in tickets:
		entry["tickets_px"].append(_rect_list(rect))
	if tickets.size() > 1:
		entry["ticket_gap_px"] = snappedf(tickets[1].position.x - tickets[0].end.x, 0.1)
	if not tickets.is_empty():
		entry["ticket_width_px"] = snappedf(tickets[0].size.x, 0.1)
	_m["top_band"] = entry


func _measure_rings() -> void:
	var camera: Camera3D = _camera()
	var kitchen: CookingStation = _stations("Kitchen") as CookingStation
	var entries: Array = []
	for ring: WorldProgressRing in kitchen.get_rings():
		var at: Vector2 = camera.unproject_position(ring.global_position) * _scale()
		var top_edge: float = at.y - 32.0 * _real_height() / 1080.0
		(
			entries
			. append(
				{
					"screen_px": [snappedf(at.x, 0.1), snappedf(at.y, 0.1)],
					"under_top_band": top_edge < _band_bottom,
					"state": int(ring.get_state()),
					"diameter_px": snappedf(ring.get_diameter_px(camera.size, _real_height()), 0.1),
					"thickness_px":
					snappedf(ring.get_thickness_px(camera.size, _real_height()), 0.1),
					"thickness_px_at_1080":
					snappedf(ring.get_thickness_px(camera.size, 1080.0), 0.1),
					"diameter_px_at_1080": snappedf(ring.get_diameter_px(camera.size, 1080.0), 0.1),
				}
			)
		)
	_m["cook_rings"] = entries


func _measure_player_rings() -> void:
	var mpp: float = _meters_per_px()
	for pair: Array in [["active", "%ActiveIndicator"], ["inactive", "%InactiveIndicator"]]:
		var p: Player = _p1 if pair[0] == "active" else _p2
		var mesh: MeshInstance3D = p.get_node(pair[1]) as MeshInstance3D
		var torus: TorusMesh = mesh.mesh as TorusMesh
		var thickness: float = (torus.outer_radius - torus.inner_radius) / mpp
		_m["player_ring_" + pair[0]] = {
			"visible": mesh.is_visible_in_tree(),
			"thickness_px": snappedf(thickness, 0.1),
			"thickness_px_at_1080": snappedf(_to_1080(thickness), 0.1),
		}
	var marker: Sprite3D = _p1.get_node("%ActiveMarker") as Sprite3D
	_m["active_marker_px"] = snappedf(_sprite_px(marker), 0.1)
	_m["active_marker_px_at_1080"] = snappedf(_to_1080(_sprite_px(marker)), 0.1)
	var other: Sprite3D = _p2.get_node("%ActiveMarker") as Sprite3D
	_m["inactive_marker_visible"] = other.is_visible_in_tree()


func _measure_counter(box: Box) -> void:
	var bar: WorldProgressBar = box.get_node("%CutBar") as WorldProgressBar
	var numeral: Label3D = box.get_node("%CutNumeral") as Label3D
	var camera: Camera3D = _camera()
	var mpp: float = _meters_per_px()
	_m["box_counter"] = {
		"visible": (box.get_node("%CutCounter") as Node3D).visible,
		"text": numeral.text,
		"bar_thickness_px": snappedf(bar.get_thickness_px(camera.size, _real_height()), 0.1),
		"bar_thickness_px_at_1080": snappedf(bar.get_thickness_px(camera.size, 1080.0), 0.1),
		"segment_width_px": snappedf(bar.get_segment_width_px(camera.size, _real_height()), 0.1),
		"segment_width_px_at_1080": snappedf(bar.get_segment_width_px(camera.size, 1080.0), 0.1),
		"numeral_px": snappedf(float(numeral.font_size) * numeral.pixel_size / mpp, 0.1),
		"numeral_px_at_1080":
		snappedf(_to_1080(float(numeral.font_size) * numeral.pixel_size / mpp), 0.1),
	}


func _measure_bowl() -> void:
	var bowl: CachelosBowl = _station().get_node("CachelosBowl") as CachelosBowl
	var meter: Sprite3D = bowl.get_node("%StockMeter") as Sprite3D
	var data: SeasoningStationData = (
		_station().data if _station().data != null else SeasoningStation.DEFAULT_DATA
	)
	var notch: float = float(data.stock_notch_px) * meter.pixel_size / _meters_per_px()
	_m["bowl"] = {
		"stock": bowl.stock,
		"notch_px": snappedf(notch, 0.1),
		"notch_px_at_1080": snappedf(_to_1080(notch), 0.1),
		"meter_visible": meter.is_visible_in_tree(),
	}


# --- Escenas ------------------------------------------------------------------------------------


func _run() -> void:
	await _frames(3)
	_m["tag"] = _tag
	_m["window_px"] = [root.size.x, root.size.y]
	_m["stretch_scale"] = snappedf(_scale(), 0.0001)
	_m["platform"] = "MOBILE" if _node("GameState").platform == 1 else "DESKTOP"
	_m["user_args"] = Array(OS.get_cmdline_user_args())
	# Sin fases: los 4 puestos desde el principio (tickets y zonas de los cuatro).
	_config.phases = [] as Array[PhaseData]
	_level = LEVEL.instantiate()
	root.add_child(_level)
	await _frames(4)
	_p1 = _level.get_node("Characters/Player1") as Player
	_p2 = _level.get_node("Characters/Player2") as Player
	_hold = _p1.get_node("%HoldComponent")
	_actor = _p1.get_node("%InteractionComponent")
	_apply_safe_area()
	var catalog_patience: float = 900.0
	for order: OrderData in _level.get("order_catalog").orders:
		order.max_time = catalog_patience
	_node("RoundManager").round_state.advance(_config.first_order_delay)
	await _wait(1.0)
	# 1. Vista general: HUD, 4 tickets y controles (con el stick activo en el perfil táctil).
	_place(_p1, Vector2(4.7, 3.0), Vector2(4.7, 4.0))
	_place(_p2, Vector2(-4.3, -2.0), Vector2(-4.3, -3.0))
	await _wait(1.2)
	_measure_scale()
	_measure_touch_controls()
	_measure_top_band()
	_min_text(_level.get_node("UI"), "partida")
	await _shot("01-vista-general")
	if _touch:
		var stick_at: Vector2 = Vector2(300.0, 700.0) * (_real_height() / 1080.0)
		var down: InputEventScreenTouch = InputEventScreenTouch.new()
		down.index = 0
		down.position = stick_at / _scale()
		down.pressed = true
		root.push_input(down, true)
		Input.flush_buffered_events()
		var drag: InputEventScreenDrag = InputEventScreenDrag.new()
		drag.index = 0
		drag.position = (stick_at + Vector2(60.0, -40.0) * (_real_height() / 1080.0)) / _scale()
		root.push_input(drag, true)
		Input.flush_buffered_events()
		await _wait(0.3)
		_measure_touch_controls()
		await _shot("02-stick-activo-y-botones")
		var up: InputEventScreenTouch = InputEventScreenTouch.new()
		up.index = 0
		up.position = stick_at / _scale()
		up.pressed = false
		root.push_input(up, true)
		Input.flush_buffered_events()
		await _wait(0.4)
	# 2. Prompt OK: COGER en la nevera con la mano vacía.
	var fridge: Vector2 = _xz(_stations("OctopusStorage"))
	_clear_hand()
	_place(_p1, fridge + Vector2(0.0, 0.9), fridge)
	await _wait(1.3)
	_measure_prompt("ok_coger")
	_measure_touch_controls()
	await _shot("03-prompt-ok-coger")
	# 3. Prompt BLOQUEADO: aliñar con una caja a medias en el dispensador dulce (`caja a medias`).
	var sweet: Node3D = _station().get_node("Dispensers/SweetDressing") as Node3D
	var sweet_at: Vector2 = _xz(sweet)
	_equip(_new_box(0.5))
	_place(_p1, Vector2(sweet_at.x, _station().global_position.z + 1.0), sweet_at)
	await _wait(1.3)
	_measure_prompt("bloqueado_caja_a_medias")
	_measure_touch_controls()
	await _shot("04-prompt-bloqueado-caja-a-medias")
	# 4. Cuenco con 2 raciones y cachelos cocidos en la mano (reponer, OK).
	var bowl: CachelosBowl = _station().get_node("CachelosBowl") as CachelosBowl
	bowl.stock = 2
	var cachelos: Ingredient = CACHELOS_SCENE.instantiate()
	_items().add_child(cachelos)
	cachelos.set_cooked()
	_equip(cachelos)
	var bowl_at: Vector2 = _xz(bowl)
	_place(_p1, Vector2(bowl_at.x, _station().global_position.z + 1.0), bowl_at)
	await _wait(1.3)
	_measure_bowl()
	_measure_prompt("ok_cachelos_cuenco")
	await _shot("05-cuenco-2-raciones")
	# 5. Contador N/6: caja en el pasaplatos con 3 cortes, de cara desde el lado de pase.
	_clear_hand()
	var slot: Slot = _stations("PassSlot05") as Slot
	var box: Box = _new_box(0.0)
	_equip(box)
	var slot_at: Vector2 = _xz(slot)
	_place(_p1, Vector2(slot_at.x, _station().global_position.z + 1.0), slot_at)
	await _wait(0.8)
	_actor.interact_pressed()
	await _wait(0.4)
	_place(_p1, Vector2(slot_at.x, _station().global_position.z - 1.0), slot_at)
	_equip(_new_octopus(true))
	await _wait(1.0)
	for _i: int in 3:
		_actor.interact_pressed()
		await _wait(0.25)
	await _wait(0.6)
	_measure_counter(box)
	_measure_prompt("ok_cortar")
	await _shot("06-contador-3-de-6")
	# 6. Anillo de cocción: pulpo crudo en la olla; listo, aviso de quemado y quemado.
	_clear_hand()
	var kitchen: CookingStation = _stations("Kitchen") as CookingStation
	var kitchen_at: Vector2 = _xz(kitchen)
	_equip(_new_octopus(false))
	_place(_p1, kitchen_at + Vector2(0.0, 0.9), kitchen_at)
	await _wait(1.0)
	_actor.interact_pressed()
	await _wait(2.5)
	_measure_rings()
	await _shot("07-anillo-cociendo")
	var ring: WorldProgressRing = kitchen.get_rings()[0]
	var guard: int = 0
	while ring.get_state() != WorldProgressRing.State.READY and guard < 120:
		await _wait(0.1)
		guard += 1
	await _wait(0.4)
	_measure_rings()
	await _shot("08-anillo-listo")
	guard = 0
	while ring.get_state() != WorldProgressRing.State.WARNING and guard < 150:
		await _wait(0.1)
		guard += 1
	await _wait(0.15)
	_measure_rings()
	await _shot("09-aviso-de-quemado")
	# 7. Aros activo e inactivo con los dos personajes juntos.
	_clear_hand()
	_place(_p1, Vector2(4.7, 3.0), Vector2(4.7, 4.0))
	_place(_p2, Vector2(3.4, 3.2), Vector2(3.4, 4.0))
	await _wait(1.2)
	_measure_player_rings()
	await _shot("10-aros-activo-e-inactivo")
	# 8. Zona de entrega encendida: caja que coincide con la comanda del puesto 2.
	var active: Array = _node("OrderService").get_active_orders()
	var wanted: ActiveOrder = active[0] as ActiveOrder
	for candidate: ActiveOrder in active:
		if candidate.slot_id == 2:
			wanted = candidate
	var stand: OrderStand = _stations("OrderStand%d" % wanted.slot_id) as OrderStand
	var matching: Box = _new_box(0.0)
	var cutter: Ingredient = _new_octopus(true)
	_equip(cutter)
	while not matching.is_full():
		matching.interact(_actor)
		if not is_instance_valid(cutter) or cutter.is_queued_for_deletion():
			cutter = _new_octopus(true)
			_equip(cutter)
	for seasoning: SeasoningData in wanted.data.seasonings:
		matching.apply_seasoning(seasoning)
	_equip(matching)
	var zone_at: Vector2 = _xz(stand.get_node("%DeliveryZone") as Node3D)
	_place(_p1, zone_at + Vector2(0.0, -1.6), zone_at)
	await _wait(1.5)
	_m["zone_lit"] = stand.is_zone_lit()
	_measure_prompt("zona")
	await _shot("11-zona-de-entrega-encendida")
	# 9. Pausa y fin de partida (sin controles táctiles).
	_node("GameState").set_paused(true)
	await _wait(0.5)
	_min_text(_level.get_node("UI/PauseMenu"), "pausa")
	_m["pause_buttons"] = _buttons_of(_level.get_node("UI/PauseMenu"))
	await _shot("12-pausa")
	_node("GameState").set_paused(false)
	await _wait(0.3)
	_node("RoundManager").round_state.advance(_config.duration + 1.0)
	await _wait(1.0)
	var controls: TouchControls = _level.get_node_or_null("UI/TouchControls") as TouchControls
	_m["game_over_touch_controls_visible"] = controls != null and controls.visible
	_min_text(_level.get_node("UI/GameOver"), "game_over")
	_m["game_over_buttons"] = _buttons_of(_level.get_node("UI/GameOver"))
	await _shot("13-game-over")
	# 10. Menú principal.
	_level.queue_free()
	await _frames(3)
	var menu: Control = MAIN_MENU.instantiate()
	root.add_child(menu)
	await _frames(4)
	_min_text(menu, "menu_principal")
	_m["menu_buttons"] = _buttons_of(menu)
	await _shot("14-menu-principal")
	var file: FileAccess = FileAccess.open("%s/%s-medidas.json" % [_out, _tag], FileAccess.WRITE)
	file.store_string(JSON.stringify(_m, "\t"))
	file.close()
	print("MEDIDAS ", _tag, " ok")
	get_tree().quit()


func _buttons_of(node: Node) -> Array:
	var found: Array = []
	for child: Node in node.find_children("*", "Button", true, false):
		var button: Button = child as Button
		if button.is_visible_in_tree():
			var rect: Rect2 = _control_px(button)
			(
				found
				. append(
					{
						"text": button.text,
						"height_px": snappedf(rect.size.y, 0.1),
						"height_px_at_1080": snappedf(_to_1080(rect.size.y), 0.1),
						"y_px": snappedf(rect.position.y, 0.1),
					}
				)
			)
	return found
