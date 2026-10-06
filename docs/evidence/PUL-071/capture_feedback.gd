extends SceneTree
## Capturas de PUL-071 desde la cámara de level_01 (registro reproducible; no es parte del juego).
## Uso, desde la raíz del repo:
##   xvfb-run -a godot --path godot --audio-driver Dummy --resolution 1920x1080 \
##     -s "$PWD/docs/evidence/PUL-071/capture_feedback.gd" -- <out_dir>
## Dispara cada acción de audio-y-fx AC5 por su camino real (mano, olla, bandeja, señales del bus)
## y fotografía la respuesta visual de `%Feedback` a lo largo de `visual_time`, parando su `Tween`
## y avanzándolo a mano. Salen `<accion>_<n>.png` (recorte ×2 alrededor del objetivo).

## Fracciones de `visual_time` fotografiadas.
const FRACTIONS: Array[float] = [0.0, 0.15, 0.35, 0.55, 0.75, 1.0]
const MAP: AudioFeedbackMap = preload("res://data/audio/feedback_map.tres")

var _level: Node
var _out: String
var _hold: HoldComponent
var _actor: InteractionComponent
var _player: Node3D


func _initialize() -> void:
	_out = OS.get_cmdline_user_args()[0]
	_level = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
	root.add_child(_level)
	current_scene = _level
	for i in 10:
		await process_frame
	_player = _level.get_node("Characters/Player1") as Node3D
	_hold = _player.get_node("%HoldComponent") as HoldComponent
	_actor = _player.get_node("%InteractionComponent") as InteractionComponent
	var kitchen := _level.get_node("Stations/Kitchen") as CookingStation
	kitchen.set_physics_process(false)

	# Coger: POP del pulpo en la mano.
	_player.global_position = kitchen.global_position + Vector3(1.2, 0.0, 1.4)
	_player.rotation.y = PI  # de cara a la cámara: se ve lo que lleva en la mano
	var octopus := _spawn("res://entities/items/octopus.tscn") as Ingredient
	_hold.pick_up(octopus)
	await _film("pick_up", _player.get_node("%Feedback"), octopus, octopus)

	# Cocer: POP de la olla al meterlo y del pulpo al terminar.
	kitchen.interact(_actor)
	await _film("cook_start", kitchen.get_node("%Feedback"), kitchen, kitchen)
	for i in roundi(octopus.data.cook_time / 0.05) + 1:
		kitchen._physics_process(0.05)
	await _film("cook_done", kitchen.get_node("%Feedback"), octopus, kitchen)

	# Condimentar: caja llena en la bandeja, sal desde el dispensador.
	var station := _level.get_node("Stations/SeasoningStation") as SeasoningStation
	var box := _spawn("res://entities/items/box.tscn") as Box
	box.fill = 1.0
	_hold.pick_up(box)
	station.get_tray().interact(_actor)
	_player.global_position = station.global_position + Vector3(2.5, 0.0, 1.6)
	box.toggle_seasoning(load("res://data/seasonings/salt.tres") as SeasoningData, true)
	await _film("season", box.get_node("%Feedback"), box, box)

	# Entregas: correcta (POP) y errónea (SHAKE) en el puesto 1, por el bus.
	# Sin tipar: `OrderStand` usa el autoload `EventBus`, que en `-s` aún no existe al compilar.
	var stand := _level.get_node("Stations/OrderStand1") as Node3D
	var slot_id: int = stand.get(&"slot_id")
	var bus: Node = root.get_node("EventBus")
	bus.order_completed.emit(ActiveOrder.new(999, null, slot_id), 0)
	await _film("deliver_ok", stand.get_node("%Feedback"), stand, stand)
	bus.delivery_rejected.emit(slot_id, -1, 0)
	await _film("deliver_error", stand.get_node("%Feedback"), stand, stand)
	quit()


func _spawn(path: String) -> Node3D:
	var item := (load(path) as PackedScene).instantiate() as Node3D
	_level.get_node("Items").add_child(item)
	return item


## Fotografía la respuesta de `cue` sobre `target` en cada fracción de `visual_time`.
func _film(cue: StringName, feedback: FeedbackPlayer, target: Node3D, anchor: Node3D) -> void:
	var tween: Tween = feedback.get_visual_tween(target)
	if tween == null:
		push_error("sin respuesta visual: %s" % cue)
		return
	tween.pause()
	var time: float = MAP.get_cue(cue).visual_time
	var done: float = 0.0
	for i: int in FRACTIONS.size():
		var at: float = FRACTIONS[i] * time
		if at > done:
			tween.custom_step(at - done)
			done = at
		await _shot("%s_%d" % [cue, i], anchor)
	if tween.is_valid():
		tween.custom_step(time)


func _shot(name: String, anchor: Node3D) -> void:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var a := root.get_camera_3d().unproject_position(anchor.global_position + Vector3(0, 0.8, 0))
	var rect := Rect2i(int(a.x) - 180, int(a.y) - 150, 360, 300)
	var crop := img.get_region(rect.intersection(Rect2i(Vector2i.ZERO, img.get_size())))
	crop.resize(crop.get_width() * 2, crop.get_height() * 2, Image.INTERPOLATE_NEAREST)
	crop.save_png(_out + "/%s.png" % name)
