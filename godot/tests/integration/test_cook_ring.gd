extends GutTest
## PUL-125 AC4 (diseño AC15, ADR-003 §11.8): `%CookRing` por plaza de la olla. Anillo de al menos
## 64 px de diámetro y trazo de al menos 8 px a 1080 de alto con la cámara de juego; cociendo, arco
## blanco que crece; listo, verde con ✓ y el cue `cook_ready` una vez (no `cook_done`).

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const KITCHEN_SCENE: PackedScene = preload("res://entities/stations/kitchen.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const CAMERA_SCENE: PackedScene = preload("res://entities/camera/camera_rig.tscn")
const OCTOPUS: IngredientData = preload("res://data/ingredients/octopus.tres")
const KITCHEN_DATA: KitchenData = preload("res://data/config/kitchen.tres")
const MARK_READY: Texture2D = preload("res://assets/textures/ui/actions/icon_mark_ready.svg")
const SCREEN_HEIGHT: float = 1080.0
const STEP: float = 0.1
## Tolerancia de coma flotante al medir (no es holgura de diseño).
const EPSILON: float = 0.001

var _level: Node3D
var _hold: HoldComponent
var _actor: InteractionComponent
var _kitchen: CookingStation
var _cues: Array[StringName] = []
var _camera_size: float


func before_each() -> void:
	_cues.clear()
	_level = add_child_autofree(Node3D.new())
	var player: Player = PLAYER_SCENE.instantiate()
	_level.add_child(player)
	_hold = player.get_node("%HoldComponent")
	_hold.items_root = _level
	_actor = player.get_node("%InteractionComponent")
	_kitchen = KITCHEN_SCENE.instantiate()
	_level.add_child(_kitchen)
	(_kitchen.get_node("%Feedback") as FeedbackPlayer).played.connect(_cues.append)
	var camera: Camera3D = CAMERA_SCENE.instantiate()
	_camera_size = camera.size
	camera.free()


func _ring(index: int = 0) -> WorldProgressRing:
	return _kitchen.get_rings()[index]


func _cook_one() -> Ingredient:
	var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
	_level.add_child(octopus)
	assert_true(_hold.pick_up(octopus))
	assert_true(_kitchen.interact(_actor))
	return octopus


func _advance(seconds: float) -> void:
	simulate(_kitchen, roundi(seconds / STEP), STEP)


## PUL-131 (revisión de PUL-125): el anillo mide 64 px a 1080 con la cámara activa, sea la de
## escritorio (12,74 m) o la móvil (7,0 m), y las plazas se separan en consecuencia.
func test_pul131_ring_follows_the_active_camera_size() -> void:
	var camera: Camera3D = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.74
	_level.add_child(camera)
	camera.current = true
	await wait_process_frames(2)
	assert_almost_eq(_ring(0).get_diameter_px(12.74, SCREEN_HEIGHT), 64.0, 0.1, "escritorio")
	camera.size = 7.0
	await wait_process_frames(2)
	assert_almost_eq(_ring(0).get_diameter_px(7.0, SCREEN_HEIGHT), 64.0, 0.1, "móvil")
	assert_gte(_ring(0).get_thickness_px(7.0, SCREEN_HEIGHT) + EPSILON, 8.0, "trazo móvil")
	var spacing: float = _ring(1).position.x - _ring(0).position.x
	assert_almost_eq(spacing, 64.0 * CookingStation.RING_SPACING_RATIO * 7.0 / 1080.0, 0.001)


func test_ac4_there_is_one_ring_per_slot_and_none_is_visible_at_rest() -> void:
	var rings: Array[WorldProgressRing] = _kitchen.get_rings()
	assert_eq(rings.size(), KITCHEN_DATA.capacity)
	for ring: WorldProgressRing in rings:
		assert_false(ring.visible)
		assert_eq(ring.get_state(), WorldProgressRing.State.HIDDEN)
	assert_null(_kitchen.get_node_or_null("%CookBar"), "%CookBar ya no existe")


func test_ac4_ring_is_at_least_64_px_with_a_stroke_of_at_least_8_px_at_1080() -> void:
	for ring: WorldProgressRing in _kitchen.get_rings():
		assert_gte(ring.get_diameter_px(_camera_size, SCREEN_HEIGHT) + EPSILON, 64.0, "diámetro")
		assert_gte(ring.get_thickness_px(_camera_size, SCREEN_HEIGHT) + EPSILON, 8.0, "trazo")
	assert_eq(KITCHEN_DATA.ring_diameter_px, 64.0)
	assert_eq(KITCHEN_DATA.ring_thickness_px, 8.0)


## Mide el anillo dibujado en la textura: píxeles opacos de la fila central, en px de pantalla.
func test_ac4_drawn_stroke_measures_at_least_8_px_on_screen() -> void:
	var ring: WorldProgressRing = _ring()
	var image: Image = (ring.get_node("%Ring") as TextureProgressBar).texture_progress.get_image()
	var row: int = image.get_height() / 2
	var opaque: int = 0
	var first: int = -1
	var last: int = -1
	for x: int in image.get_width():
		if image.get_pixel(x, row).a > 0.5:
			opaque += 1
			last = x
			if first < 0:
				first = x
	var screen_per_texture: float = ring.pixel_size * SCREEN_HEIGHT / _camera_size
	# Dos cruces del anillo en la fila central: trazo izquierdo y derecho.
	assert_gte(float(opaque) / 2.0 * screen_per_texture + 0.5, 8.0, "trazo medido en píxeles")
	assert_gte(float(last - first + 1) * screen_per_texture + 0.5, 64.0, "diámetro medido")


func test_ac4_cooking_ring_is_a_white_arc_that_grows() -> void:
	_cook_one()
	var ring: WorldProgressRing = _ring()
	assert_true(ring.visible)
	assert_eq(ring.get_state(), WorldProgressRing.State.COOKING)
	assert_eq(ring.get_ring_color(), WorldProgressRing.COLOR_COOKING)
	assert_null(ring.get_mark(), "sin marca mientras cuece")
	_advance(OCTOPUS.cook_time / 2.0)
	assert_almost_eq(ring.get_progress(), 0.5, 0.03)
	var half: float = ring.get_progress()
	_advance(1.0)
	assert_gt(ring.get_progress(), half, "el arco crece")


func test_ac4_ready_ring_is_green_with_a_check_and_cook_ready_sounds_once() -> void:
	var octopus: Ingredient = _cook_one()
	_advance(OCTOPUS.cook_time)
	assert_true(octopus.is_cooked())
	var ring: WorldProgressRing = _ring()
	assert_true(ring.visible)
	assert_eq(ring.get_state(), WorldProgressRing.State.READY)
	assert_eq(ring.get_ring_color(), WorldProgressRing.COLOR_READY)
	assert_gt(ring.get_ring_color().g, ring.get_ring_color().r, "verde")
	assert_eq(ring.get_mark(), MARK_READY, "con ✓")
	assert_eq(ring.get_progress(), 1.0)
	assert_eq(_cues.count(&"cook_ready"), 1, "cook_ready una vez")
	assert_eq(_cues.count(&"cook_done"), 0, "cook_done ya no suena")
	_advance(2.0)
	assert_eq(_cues.count(&"cook_ready"), 1, "no se repite")


func test_ac4_picking_the_ready_one_hides_its_ring() -> void:
	_cook_one()
	_advance(OCTOPUS.cook_time)
	assert_true(_kitchen.interact(_actor))
	assert_false(_ring().visible)


func test_ac4_second_slot_has_its_own_ring_and_they_do_not_overlap() -> void:
	_cook_one()
	_cook_one()
	_advance(1.0)
	var first: WorldProgressRing = _ring(0)
	var second: WorldProgressRing = _ring(1)
	assert_true(first.visible and second.visible)
	assert_ne(first, second)
	var diameter_m: float = 64.0 * _camera_size / SCREEN_HEIGHT
	assert_gte(first.position.distance_to(second.position) + EPSILON, diameter_m, "no se tapan")
	_advance(OCTOPUS.cook_time)
	assert_eq(_ring(1).get_state(), WorldProgressRing.State.READY)


func test_ac4_ring_data_comes_from_kitchen_tres() -> void:
	var ring: WorldProgressRing = _ring()
	assert_eq(ring.diameter_px, KITCHEN_DATA.ring_diameter_px)
	assert_eq(ring.thickness_px, KITCHEN_DATA.ring_thickness_px)
	assert_eq(ring.blink_hz, KITCHEN_DATA.warn_blink_hz)
