extends Node
## Capturas de PUL-127 (prompt de acción, aro activo/inactivo, Local 2P y contorno a través del
## personaje) sobre `level_01` real, a 1920x1080 y a 1280x720 (cada una en un SubViewport de ese
## tamaño, así que las medidas en px son las de esa resolución). Las estaciones aún no
## publican verbo
## (PUL-125/PUL-126): el hint de cada objetivo se inyecta con `ActionPrompt.show_hint` y el contorno
## con `Highlightable.acquire`, como haría el detector. Uso, desde `godot/` (con ventana):
##   godot --path . ../docs/evidence/PUL-127/capture.tscn -- <directorio absoluto de salida>

const LEVEL: PackedScene = preload("res://scenes/levels/level_01.tscn")
const PROMPT: PackedScene = preload("res://entities/player/action_prompt.tscn")
const SIZES: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(1280, 720)]

var _dir: String = ""
var _viewport: SubViewport
var _level: Node
var _camera: Camera3D
var _base_forward: Vector3
var _log: PackedStringArray = []


func _ready() -> void:
	_dir = OS.get_cmdline_user_args()[0]
	for size: Vector2i in SIZES:
		await _session(size)
	var file: FileAccess = FileAccess.open(_dir + "/measures.txt", FileAccess.WRITE)
	file.store_string("\n".join(_log) + "\n")
	file.close()
	get_tree().quit()


func _session(size: Vector2i) -> void:
	var tag: String = "%dx%d" % [size.x, size.y]
	_viewport = SubViewport.new()
	_viewport.size = size
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	_level = LEVEL.instantiate()
	_viewport.add_child(_level)
	await _frames(8)
	(_level.get_node("UI") as CanvasLayer).visible = false
	_camera = _level.get_node("CameraRig") as Camera3D
	_base_forward = -_camera.global_basis.z
	var p1: Player = _level.get_node("Characters/Player1") as Player
	var p2: Player = _level.get_node("Characters/Player2") as Player
	_control(p1).controlled_by = 1
	_control(p2).controlled_by = 0
	# 1. Prompts OK y BLOQUEADO sobre varios objetivos.
	var trash: Node3D = _level.get_node("Stations/TrashBinKitchen") as Node3D
	var kitchen2: Node3D = _level.get_node("Stations/Kitchen2") as Node3D
	var shelf: Node3D = _level.get_node("Stations/OctopusStorage") as Node3D
	_park(p1, Vector3(40.0, 0.0, 40.0))
	_park(p2, Vector3(40.0, 0.0, 44.0))
	_focus((trash.global_position + kitchen2.global_position) * 0.5, 7.0)
	var shown: Array[Node] = []
	shown.append(_prompt_on(trash, ActionHint.ok(ActionVerb.TRASH), 1, false))
	shown.append(
		_prompt_on(kitchen2, ActionHint.blocked(ActionVerb.COOK, ActionReason.BUSY), 1, true)
	)
	await _shot("prompts_kitchen_" + tag)
	_clear(shown)
	_focus(shelf.global_position, 6.0)
	shown.append(_prompt_on(shelf, ActionHint.ok(ActionVerb.PICK_UP), 1, false))
	await _shot("prompt_ok_pick_up_" + tag)
	_clear(shown)
	var station: Node3D = _level.get_node("Stations/SeasoningStation") as Node3D
	var sweet: Node3D = station.get_node("Dispensers/SweetDressing") as Node3D
	var hot: Node3D = station.get_node("Dispensers/HotDressing") as Node3D
	var bowl: Node3D = station.get_node("CachelosBowl") as Node3D
	_focus(station.global_position, 7.0)
	var replace: ActionHint = ActionHint.ok(ActionVerb.SEASON_SWEET)
	replace.replaces = true
	shown.append(_prompt_on(sweet, replace, 1, false))
	shown.append(
		_prompt_on(
			hot, ActionHint.blocked(ActionVerb.SEASON_HOT, ActionReason.ALREADY_APPLIED), 1, true
		)
	)
	shown.append(
		_prompt_on(
			bowl, ActionHint.blocked(ActionVerb.CACHELOS, ActionReason.BOX_NOT_FULL), 1, true
		)
	)
	await _shot("prompts_station_" + tag)
	await _measure_prompt(shown[0] as ActionPrompt, tag)
	_clear(shown)
	# 2. Aro del activo y del inactivo.
	_park(p1, trash.global_position + Vector3(-2.0, 0.0, 3.0))
	_park(p2, trash.global_position + Vector3(0.0, 0.0, 3.0))
	_focus(trash.global_position + Vector3(-1.0, 0.0, 3.0), 2.4)
	await _shot("rings_active_inactive_" + tag)
	# 3. Local 2P: dos prompts sobre el mismo objetivo.
	_control(p2).controlled_by = 2
	_park(p1, trash.global_position + Vector3(-1.2, 0.0, 1.6))
	_park(p2, trash.global_position + Vector3(1.2, 0.0, 1.6))
	_focus(trash.global_position + Vector3(0.0, 0.0, 1.0), 3.4)
	for pair: Array in [
		[p1, ActionHint.ok(ActionVerb.TRASH)],
		[p2, ActionHint.blocked(ActionVerb.TRASH, ActionReason.BUSY)]
	]:
		var player: Player = pair[0] as Player
		var prompt: ActionPrompt = player.get_node("%ActionPrompt") as ActionPrompt
		prompt.set_mode(GameMode.Mode.COOP_2P)
		prompt.show_hint(trash, pair[1] as ActionHint)
		shown.append(prompt)
	await _shot("local_2p_two_prompts_" + tag)
	var left: ActionPrompt = shown[0] as ActionPrompt
	var right: ActionPrompt = shown[1] as ActionPrompt
	var separation: float = left.offset_px_of(left.get_node("%Plate") as Sprite3D).distance_to(
		right.offset_px_of(right.get_node("%Plate") as Sprite3D)
	)
	_log.append(
		(
			"%s local_2p separacion de centros de placa: %.1f px (placa %.1f px, hueco %.1f px)"
			% [tag, separation, left.plate_px(), separation - left.plate_px()]
		)
	)
	for prompt: ActionPrompt in [left, right]:
		prompt.show_hint(null, ActionHint.none())
	_control(p2).controlled_by = 0
	# 4. Cubo desde el sur con una caja en la mano: prompt entero y contorno tras el personaje.
	await _south_of_the_bin(p1, trash, tag)
	_viewport.queue_free()
	await _frames(2)


func _south_of_the_bin(player: Player, trash: Node3D, tag: String) -> void:
	_park(player, trash.global_position + Vector3(0.0, 0.0, 0.85))
	player.rotation.y = 0.0
	# El detector real del personaje también ilumina el cubo: se apaga para medir el contorno.
	var detector: InteractionDetector = player.get_node("%InteractionDetector") as InteractionDetector
	detector.actor = null
	await _frames(3)
	var hold: HoldComponent = player.get_node("%HoldComponent") as HoldComponent
	var box: Node3D = (load("res://entities/items/box.tscn") as PackedScene).instantiate() as Node3D
	_level.get_node("Items").add_child(box)
	hold.pick_up(box)
	_focus(trash.global_position + Vector3(0.0, 0.0, 0.6), 3.4)
	var prompt: ActionPrompt = player.get_node("%ActionPrompt") as ActionPrompt
	prompt.set_mode(GameMode.Mode.SINGLE)
	prompt.show_hint(trash, ActionHint.ok(ActionVerb.TRASH))
	var silhouette: Image = await _silhouette(player, trash)
	var light: Highlightable = _highlightable(trash)
	# Estados de referencia para medir el contorno visible a través del personaje.
	var model: Node3D = player.get_node("Model") as Node3D
	prompt.visible = false
	await _frames(3)
	var base_hidden: Image = await _grab(model, false, false, light)
	var outline_hidden: Image = await _grab(model, false, true, light)
	var base_shown: Image = await _grab(model, true, false, light)
	prompt.visible = true
	var full: Image = await _grab(model, true, true, light)
	full.save_png("%s/cube_from_south_%s.png" % [_dir, tag])
	var mask: int = 0
	var visible_through: int = 0
	var debug: Image = Image.create(full.get_width(), full.get_height(), false, Image.FORMAT_RGB8)
	for y: int in outline_hidden.get_height():
		for x: int in outline_hidden.get_width():
			var inside: bool = silhouette.get_pixel(x, y).is_equal_approx(Color.MAGENTA)
			if not inside and _differs(outline_hidden.get_pixel(x, y), base_hidden.get_pixel(x, y)):
				mask += 1
				debug.set_pixel(x, y, Color.RED)
				if _differs(full.get_pixel(x, y), base_shown.get_pixel(x, y)):
					visible_through += 1
					debug.set_pixel(x, y, Color.GREEN)
	debug.save_png("%s/cube_from_south_outline_mask_%s.png" % [_dir, tag])
	(
		_log
		. append(
			(
				"%s cubo desde el sur: contorno %d px, visibles con el personaje delante %d px (%.1f %%)"
				% [
					tag,
					mask,
					visible_through,
					100.0 * float(visible_through) / maxf(float(mask), 1.0)
				]
			)
		)
	)
	light.release(self)
	(box.get_parent()).remove_child(box)
	box.queue_free()


## Silueta del cubo (magenta plano, sin contorno ni personaje): el contorno es lo de fuera.
func _silhouette(player: Player, trash: Node3D) -> Image:
	var flat: StandardMaterial3D = StandardMaterial3D.new()
	flat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flat.albedo_color = Color.MAGENTA
	var meshes: Array[Node] = trash.find_children("*", "MeshInstance3D", true, false)
	for mesh: Node in meshes:
		(mesh as MeshInstance3D).material_override = flat
	var model: Node3D = player.get_node("Model") as Node3D
	model.visible = false
	(player.get_node("ActiveIndicator") as Node3D).visible = false
	(player.get_node("ActiveMarker") as Node3D).visible = false
	(player.get_node("%ActionPrompt") as Node3D).visible = false
	await _frames(4)
	var image: Image = _viewport.get_texture().get_image()
	for mesh: Node in meshes:
		(mesh as MeshInstance3D).material_override = null
	return image


## Captura con el personaje visible/oculto y el contorno puesto/quitado.
func _grab(model: Node3D, character: bool, outline: bool, light: Highlightable) -> Image:
	model.visible = character
	(model.get_parent().get_node("ActiveIndicator") as Node3D).visible = character
	(model.get_parent().get_node("ActiveMarker") as Node3D).visible = character
	if outline:
		light.acquire(self)
	else:
		light.release(self)
	await _frames(4)
	return _viewport.get_texture().get_image()


func _differs(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.06


func _measure_prompt(prompt: ActionPrompt, tag: String) -> void:
	var verb: Sprite3D = prompt.get_node("%VerbIcon") as Sprite3D
	var plate: Sprite3D = prompt.get_node("%Plate") as Sprite3D
	_log.append(
		(
			"%s prompt OK: icono %.1f px, placa %.1f px"
			% [tag, prompt.size_px_of(verb), prompt.size_px_of(plate)]
		)
	)


## Prompt independiente (control propio) sobre `target`, con su contorno (ambar si bloqueado).
func _prompt_on(target: Node3D, hint: ActionHint, player: int, blocked: bool) -> ActionPrompt:
	var control: ControlComponent = ControlComponent.new()
	control.controlled_by = player
	_level.add_child(control)
	var actor: InteractionComponent = InteractionComponent.new()
	actor.control = control
	_level.add_child(actor)
	var prompt: ActionPrompt = PROMPT.instantiate() as ActionPrompt
	prompt.actor = actor
	_level.add_child(prompt)
	prompt.set_mode(GameMode.Mode.SINGLE)
	prompt.show_hint(target, hint)
	var light: Highlightable = _highlightable(target)
	if light != null:
		light.set_blocked(blocked)
		light.acquire(prompt)
	prompt.set_meta(&"light", light)
	return prompt


func _clear(shown: Array[Node]) -> void:
	for node: Node in shown:
		var prompt: ActionPrompt = node as ActionPrompt
		var light: Highlightable = prompt.get_meta(&"light", null) as Highlightable
		if light != null:
			light.release(prompt)
			light.set_blocked(false)
		prompt.show_hint(null, ActionHint.none())
		prompt.visible = false
	shown.clear()


func _highlightable(target: Node) -> Highlightable:
	for child: Node in target.get_children():
		if child is Highlightable:
			return child as Highlightable
	return null


func _control(player: Player) -> ControlComponent:
	return player.get_node("%Control") as ControlComponent


func _park(player: Player, at: Vector3) -> void:
	player.global_position = Vector3(at.x, 0.005, at.z)


func _focus(point: Vector3, size: float) -> void:
	_camera.size = size
	_camera.global_position = point + Vector3(0.0, 0.3, 0.0) - _base_forward * 20.0


func _shot(name: String) -> void:
	await _frames(6)
	_viewport.get_texture().get_image().save_png("%s/%s.png" % [_dir, name])


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().process_frame
