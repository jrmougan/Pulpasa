extends GutTest
## PUL-126 AC4 (diseño AC17, ADR-003 §11.8): `%StockMeter` del cuenco repite `stock` con 4 muescas
## legibles: `stock` llenas y el resto huecas con contorno, >= 24 px a 1080 de alto y contraste
## >= 3:1 entre relleno y hueco. Se lee la textura del `Sprite3D` (lo que se ve), no el estado.

const BOWL_SCENE: PackedScene = preload("res://entities/stations/cachelos_bowl.tscn")
const STATION_SCENE: PackedScene = preload("res://entities/stations/seasoning_station.tscn")
const CAMERA_SIZE: float = 12.74
const HEIGHT_PX: float = 1080.0
const NOTCHES: int = 4

var _level: Node3D
var _station: SeasoningStation
var _bowl: CachelosBowl
var _data: SeasoningStationData


func before_each() -> void:
	_level = add_child_autofree(Node3D.new())
	_station = STATION_SCENE.instantiate()
	_level.add_child(_station)
	_bowl = _station.get_node("CachelosBowl")
	_data = _station.data
	var camera: Camera3D = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = CAMERA_SIZE
	_level.add_child(camera)
	camera.current = true


func _meter() -> Sprite3D:
	return _bowl.get_node("%StockMeter") as Sprite3D


func _image() -> Image:
	return _meter().texture.get_image()


## Centro (en texels) de la muesca `index`.
func _center(index: int) -> Vector2i:
	var gap: int = _data.stock_notch_gap_px
	var notch: int = _data.stock_notch_px
	return Vector2i(gap + index * (notch + gap) + notch / 2, (notch + 2 * gap) / 2)


func _is_filled(image: Image, index: int) -> bool:
	return _same_rgb(image.get_pixelv(_center(index)), _data.stock_fill_color)


## Mismo color RGB dentro de la cuantización de 8 bits de la textura.
func _same_rgb(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.01 and absf(a.g - b.g) < 0.01 and absf(a.b - b.b) < 0.01


func _filled_count() -> int:
	var image: Image = _image()
	var count: int = 0
	for index: int in NOTCHES:
		if _is_filled(image, index):
			count += 1
	return count


func _luminance(color: Color) -> float:
	var linear: Color = color.srgb_to_linear()
	return 0.2126 * linear.r + 0.7152 * linear.g + 0.0722 * linear.b


func _contrast(a: Color, b: Color) -> float:
	var light: float = maxf(_luminance(a), _luminance(b))
	var dark: float = minf(_luminance(a), _luminance(b))
	return (light + 0.05) / (dark + 0.05)


func test_meter_is_a_billboard_sprite_without_depth_test_in_the_bowl_scene() -> void:
	var meter: Sprite3D = _meter()
	assert_not_null(meter)
	assert_eq(meter.billboard, BaseMaterial3D.BILLBOARD_ENABLED)
	assert_true(meter.no_depth_test, "nunca queda tapado por el cuenco ni el personaje")
	assert_false(meter.shaded)
	var bare: CachelosBowl = BOWL_SCENE.instantiate()
	assert_not_null(bare.get_node_or_null("%StockMeter"), "también en la escena sola")
	bare.free()


## AC4: con 0, 1, 2, 3 y 4 raciones se ven siempre 4 muescas y `stock` llenas.
func test_ac4_stock_notches_filled_equal_the_stock() -> void:
	for stock: int in [0, 1, 2, 3, 4]:
		_bowl.stock = stock
		var image: Image = _image()
		assert_eq(
			image.get_width(),
			NOTCHES * _data.stock_notch_px + (NOTCHES + 1) * _data.stock_notch_gap_px,
			"4 muescas de ancho (stock %d)" % stock
		)
		assert_eq(_filled_count(), stock, "stock %d: llenas" % stock)
		for index: int in NOTCHES:
			if index >= stock:
				assert_true(
					_same_rgb(image.get_pixelv(_center(index)), _data.stock_empty_color),
					"stock %d: la muesca %d está hueca" % [stock, index]
				)


func test_ac4_two_portions_show_four_notches_two_filled() -> void:
	_bowl.stock = 2
	assert_eq(_filled_count(), 2)
	var image: Image = _image()
	assert_true(_is_filled(image, 0))
	assert_true(_is_filled(image, 1))
	assert_false(_is_filled(image, 2))
	assert_false(_is_filled(image, 3))


## Las muescas huecas llevan contorno: el borde de una hueca no es el color de la placa.
func test_ac4_hollow_notches_have_an_outline() -> void:
	_bowl.stock = 0
	var image: Image = _image()
	var radius: int = _data.stock_notch_px / 2
	for index: int in NOTCHES:
		var edge: Vector2i = _center(index) + Vector2i(-radius + 1, 0)
		assert_true(
			_same_rgb(image.get_pixelv(edge), _data.stock_outline_color),
			"la muesca %d tiene contorno" % index
		)


func test_ac4_fill_and_hollow_contrast_at_least_3_to_1() -> void:
	_bowl.stock = 2
	var image: Image = _image()
	var filled: Color = image.get_pixelv(_center(0))
	var hollow: Color = image.get_pixelv(_center(3))
	assert_gte(_contrast(filled, hollow), 3.0, "relleno contra hueco")
	var edge: Color = image.get_pixelv(_center(3) + Vector2i(-_data.stock_notch_px / 2 + 1, 0))
	assert_gte(_contrast(edge, hollow), 3.0, "contorno contra interior hueco")


## Cada muesca ocupa >= 24 px en pantalla con la cámara ortográfica a 1080 de alto.
func test_ac4_each_notch_is_at_least_24_px_at_1080() -> void:
	_bowl.stock = 2
	var camera: Camera3D = get_viewport().get_camera_3d()
	assert_not_null(camera)
	var metres_per_px: float = camera.size / HEIGHT_PX
	var notch_metres: float = _data.stock_notch_px * _meter().pixel_size
	assert_gte(notch_metres / metres_per_px, 24.0 - 0.01, "px por muesca a 1080")


## Con otro tamaño de cámara las muescas conservan su tamaño en pantalla (px, no metros).
func test_ac4_notch_screen_size_does_not_depend_on_the_camera_size() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	camera.size = CAMERA_SIZE / 2.0
	await wait_process_frames(2)
	var metres_per_px: float = camera.size / HEIGHT_PX
	var notch_metres: float = _data.stock_notch_px * _meter().pixel_size
	assert_almost_eq(notch_metres / metres_per_px, float(_data.stock_notch_px), 0.01)


## Se rehace con cada cambio de `stock` (reponer y poner), no solo al arrancar.
func test_ac4_meter_follows_restock_and_put() -> void:
	assert_eq(_filled_count(), 0, "al arrancar, vacío")
	var player: Player = (preload("res://entities/player/player.tscn") as PackedScene).instantiate()
	_level.add_child(player)
	var hold: HoldComponent = player.get_node("%HoldComponent")
	hold.items_root = _level
	var actor: InteractionComponent = player.get_node("%InteractionComponent")
	var cachelo: Ingredient = (
		(preload("res://entities/items/cachelos.tscn") as PackedScene).instantiate()
	)
	_level.add_child(cachelo)
	cachelo.set_cooked()
	assert_true(hold.pick_up(cachelo))
	assert_true(_bowl.interact(actor))
	assert_eq(_bowl.stock, 2)
	assert_eq(_filled_count(), 2, "reponer: dos muescas")
	var box: Box = (preload("res://entities/items/box.tscn") as PackedScene).instantiate()
	box.data = preload("res://data/boxes/box.tres")
	_level.add_child(box)
	box.fill = 1.0
	assert_true(hold.pick_up(box))
	assert_true(_bowl.interact(actor))
	assert_eq(_bowl.stock, 1)
	assert_eq(_filled_count(), 1, "poner: una muesca menos")
