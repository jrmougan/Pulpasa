extends SceneTree
## PUL-142: el número del puesto se ve durante el POP (`deliver_ok`). Mismo método que PUL-139.
## Uso, desde la raíz del repo:
##   xvfb-run -a godot --path godot --audio-driver Dummy --resolution 1920x1080 \
##     -s "$PWD/docs/evidence/PUL-142/capture_stand_pop.gd" -- "$PWD/docs/evidence/PUL-142/pop"
## Dispara `order_new` (POP de %OrderLabel) y `deliver_ok` (POP del puesto) en OrderStand1 por el
## bus y fotografía cada fracción de `visual_time` parando el `Tween` (como PUL-071).

const FRACTIONS: Array[float] = [0.0, 0.15, 0.35, 0.55, 1.0]
const MAP: AudioFeedbackMap = preload("res://data/audio/feedback_map.tres")

var _level: Node
var _out: String


func _initialize() -> void:
	_out = OS.get_cmdline_user_args()[0]
	_level = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
	root.add_child(_level)
	current_scene = _level
	for i in 10:
		await process_frame
	var stand := _level.find_child("OrderStand1", true, false) as Node3D
	var slot_id: int = stand.get(&"slot_id")
	var bus: Node = root.get_node("EventBus")
	var feedback := stand.get_node("%Feedback") as FeedbackPlayer
	var order := ActiveOrder.new(998, load("res://data/orders/a_feira.tres"), slot_id)
	bus.order_generated.emit(order)
	await _film(&"order_new", feedback, stand.get_node("%OrderLabel") as Node3D, stand)
	bus.order_completed.emit(order, 0)
	await _film(&"deliver_ok", feedback, stand, stand)
	quit()



func _film(cue: StringName, feedback: FeedbackPlayer, target: Node3D, anchor: Node3D) -> void:
	var tween: Tween = null
	for i in 60:
		tween = feedback.get_visual_tween(target)
		if tween != null:
			break
		await process_frame
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
	var a := root.get_camera_3d().unproject_position(anchor.global_position)
	# Zona fija del puesto 1 en la captura completa de 1920×1080 (la proyección no coincide con el
	# tamaño de la textura bajo Xvfb).
	var rect := Rect2i(470, 800, 300, 280)
	var crop := img.get_region(rect.intersection(Rect2i(Vector2i.ZERO, img.get_size())))
	crop.resize(crop.get_width() * 2, crop.get_height() * 2, Image.INTERPOLATE_NEAREST)
	crop.save_png(_out + "/%s.png" % name)
	if name.ends_with("_0"):
		img.save_png(_out + "/full_%s.png" % name)
	print("%s stand_px=%s visible=%s" % [name, a, root.get_camera_3d().is_position_in_frustum(anchor.global_position)])
