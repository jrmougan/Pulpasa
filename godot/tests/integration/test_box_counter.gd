extends GutTest
## PUL-125 AC3 (diseño AC14, ADR-003 §11.8): `%CutCounter` de la caja. Con k = 1…5 cortes se ve
## `k/6` con k segmentos llenos, numeral de al menos 36 px y barra de al menos 8 px de grosor a
## 1080 de alto con la cámara de juego; con k = 0 no se ve; en el corte que llena muestra `6/6`
## 0,5 s, suena `box_full` una vez (en lugar de `cut`) y se oculta.

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const CAMERA_SCENE: PackedScene = preload("res://entities/camera/camera_rig.tscn")
const SCREEN_HEIGHT: float = 1080.0
const STEP: float = 0.1

var _level: Node3D
var _actor: InteractionComponent
var _box: Box
var _cues: Array[StringName] = []
var _camera_size: float


func before_each() -> void:
	_cues.clear()
	_level = add_child_autofree(Node3D.new())
	var player: Player = PLAYER_SCENE.instantiate()
	_level.add_child(player)
	var hold: HoldComponent = player.get_node("%HoldComponent")
	hold.items_root = _level
	_actor = player.get_node("%InteractionComponent")
	_box = BOX_SCENE.instantiate()
	_level.add_child(_box)
	var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
	_level.add_child(octopus)
	octopus.set_cooked()
	assert_true(hold.pick_up(octopus))
	(_box.get_node("%Feedback") as FeedbackPlayer).played.connect(_cues.append)
	var camera: Camera3D = CAMERA_SCENE.instantiate()
	_camera_size = camera.size
	camera.free()


func _counter() -> Node3D:
	return _box.get_node("%CutCounter")


func _bar() -> WorldProgressBar:
	return _box.get_node("%CutBar")


func _numeral() -> Label3D:
	return _box.get_node("%CutNumeral")


func _cut(times: int) -> void:
	for _i: int in times:
		assert_true(_box.interact(_actor))


func test_ac3_counter_is_hidden_with_zero_cuts() -> void:
	assert_eq(_box.get_presses(), 0)
	assert_false(_counter().visible)


func test_ac3_shows_k_of_6_with_k_segments_for_1_to_5_cuts() -> void:
	for k: int in range(1, 6):
		_cut(1)
		assert_eq(_box.get_presses(), k)
		assert_true(_counter().visible, "%d/6 visible" % k)
		assert_eq(_numeral().text, "%d/6" % k)
		assert_almost_eq(_bar().get_progress() * 6.0, float(k), 0.0001, "%d segmentos llenos" % k)
	assert_eq(_bar().segments, 6)


func test_ac3_numeral_is_at_least_36_px_and_bar_at_least_8_px_at_1080() -> void:
	var numeral_px: float = (
		float(_numeral().font_size) * _numeral().pixel_size * SCREEN_HEIGHT / _camera_size
	)
	assert_gte(numeral_px, 36.0, "numeral a 1080")
	assert_gte(_bar().get_thickness_px(_camera_size, SCREEN_HEIGHT), 8.0, "grosor de la barra")
	assert_gte(_bar().get_segment_width_px(_camera_size, SCREEN_HEIGHT), 14.0, "ancho de segmento")


func test_ac3_numeral_and_bar_are_billboards_without_depth_test() -> void:
	assert_eq(_numeral().billboard, BaseMaterial3D.BILLBOARD_ENABLED)
	assert_true(_numeral().no_depth_test)
	assert_eq(_bar().billboard, BaseMaterial3D.BILLBOARD_ENABLED)
	assert_true(_bar().no_depth_test)


func test_ac3_full_shows_6_of_6_for_half_a_second_then_hides_with_one_box_full() -> void:
	_cut(5)
	assert_eq(_cues, [&"cut", &"cut", &"cut", &"cut", &"cut"] as Array[StringName])
	_cut(1)
	assert_true(_box.is_full())
	assert_true(_counter().visible)
	assert_eq(_numeral().text, "6/6")
	assert_eq(_cues.count(&"box_full"), 1, "suena box_full una vez")
	assert_eq(_cues.count(&"cut"), 5, "box_full sustituye a cut en el corte que llena")
	simulate(_box, 4, STEP)
	assert_true(_counter().visible, "a 0,4 s sigue a la vista")
	simulate(_box, 2, STEP)
	assert_false(_counter().visible, "a 0,6 s se oculta")
	assert_eq(_cues.count(&"box_full"), 1)


func test_ac3_get_presses_follows_the_fill() -> void:
	assert_eq(_box.get_presses(), 0)
	_cut(2)
	assert_eq(_box.get_presses(), 2)
	_box.fill = 1.0
	assert_eq(_box.get_presses(), 6)


func test_ac3_full_counter_does_not_run_down_while_paused() -> void:
	_cut(6)
	get_tree().paused = true
	for _i: int in 60:
		await get_tree().physics_frame
	assert_true(_counter().visible, "congelado en pausa")
	get_tree().paused = false
	await wait_seconds(0.7)
	assert_false(_counter().visible, "se oculta al reanudar")
