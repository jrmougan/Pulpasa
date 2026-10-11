extends SceneTree
## Capturas de PUL-126: estación de condimentos en la cámara real de `level_01` (cuenco con
## `%StockMeter`, dispensadores con el icono propio de cada aliño), pegatinas dulce/picante en
## cajas y ticket de comanda. El prompt de acción del mundo es PUL-127: aquí se coloca el icono del
## aliño sobre cada dispensador solo para enseñarlo (no es código del juego).
## Uso (con ventana), desde `godot/`:
##   godot --audio-driver Dummy --resolution 1920x1080 -s ../docs/evidence/PUL-126/capture.gd -- <dir>

## Se cargan en `_init` (no con `preload`): los autoloads aún no existen al compilar este script.
var SWEET: Resource
var HOT: Resource
var CACHELOS: Resource
var BOX_SCENE: PackedScene
var BOX_DATA: Resource


func _init() -> void:
	var dir: String = OS.get_cmdline_user_args()[0]
	await process_frame
	SWEET = load("res://data/seasonings/sweet_dressing.tres")
	HOT = load("res://data/seasonings/hot_dressing.tres")
	CACHELOS = load("res://data/seasonings/cachelos.tres")
	BOX_SCENE = load("res://entities/items/box.tscn")
	BOX_DATA = load("res://data/boxes/box.tres")
	var level: Node = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
	root.add_child(level)
	for i: int in 10:
		await process_frame
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var station: Node3D = level.get_node("Stations/SeasoningStation")
	var bowl: Node3D = station.get_node("CachelosBowl")
	var base_size: float = cam.size
	var forward: Vector3 = -cam.global_transform.basis.z
	var floating_nodes: Array[Node] = []

	# 1. Estación: cuenco con 2 raciones y el icono propio de cada aliño sobre su dispensador.
	bowl.set(&"stock", 2)
	for node_name: String in ["SweetDressing", "HotDressing"]:
		var dispenser: Node3D = station.get_node("Dispensers/" + node_name)
		_floating_icon(level, dispenser.get(&"seasoning"), dispenser.global_position + Vector3(0, 1.05, 0.4))
		floating_nodes.append(level.get_child(level.get_child_count() - 1))
	cam.size = base_size * 0.28
	cam.global_position = station.global_position + Vector3(0, 1.2, 0) - forward * 20.0
	await _shot(dir + "/station_dispensers_and_meter.png")

	# 2. Medidor del cuenco con 0, 1... 4 raciones (collage de 5 capturas recortadas).
	cam.size = base_size * 0.1
	cam.global_position = bowl.global_position + Vector3(0, 0.5, 0) - forward * 20.0
	for stock: int in [0, 1, 2, 3, 4]:
		bowl.set(&"stock", stock)
		await _shot(dir + "/bowl_stock_%d.png" % stock)

	for node: Node in floating_nodes:
		node.queue_free()

	# 3. Pegatinas de la caja: dulce y picante (el picante lleva además la marca de guindilla).
	var spot: Vector3 = station.global_position + Vector3(-1.4, 0.3, -2.6)
	var sweet_box: Node3D = _box(level, spot, SWEET)
	var hot_box: Node3D = _box(level, spot + Vector3(1.4, 0.0, 0.0), HOT)
	var cachelos_box: Node3D = _box(level, spot + Vector3(2.8, 0.0, 0.0), SWEET)
	cachelos_box.call(&"apply_seasoning", CACHELOS)
	for i: int in 30:
		await physics_frame
	cam.size = base_size * 0.2
	cam.global_position = hot_box.global_position + Vector3(0, 0.4, 0) - forward * 20.0
	await _shot(dir + "/box_badges_sweet_hot.png")
	_save_zoom(
		cam, [sweet_box, hot_box, cachelos_box], dir + "/box_badges_sweet_hot_zoom.png"
	)

	# 4. Ticket de comanda con la pegatina propia de cada aliño.
	var layer: CanvasLayer = CanvasLayer.new()
	root.add_child(layer)
	var background: ColorRect = ColorRect.new()
	background.color = Color(0.16, 0.14, 0.12)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(background)
	var column: VBoxContainer = VBoxContainer.new()
	column.scale = Vector2(3.0, 3.0)
	column.position = Vector2(80.0, 60.0)
	layer.add_child(column)
	for order_name: String in ["a_feira", "picante", "con_cachelos", "bravo_cachelos"]:
		var entry: Control = (
			(load("res://ui/tickets/ticket_entry.tscn") as PackedScene).instantiate()
		)
		entry.custom_minimum_size.x = 400.0
		column.add_child(entry)
		entry.call(&"setup", load("res://data/orders/%s.tres" % order_name))
	await _shot(dir + "/tickets_stickers.png")
	quit()


func _box(level: Node, at: Vector3, seasoning: Resource) -> Node3D:
	var box: Node3D = BOX_SCENE.instantiate()
	box.set(&"data", BOX_DATA)
	level.add_child(box)
	box.global_position = at
	box.set(&"fill", 1.0)
	box.call(&"apply_seasoning", seasoning)
	return box


func _floating_icon(level: Node, seasoning: Resource, at: Vector3) -> void:
	var plate: Sprite3D = Sprite3D.new()
	var image: Image = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y: int in 80:
		for x: int in 80:
			if Vector2(x + 0.5, y + 0.5).distance_to(Vector2(40, 40)) <= 40.0:
				image.set_pixel(x, y, Color(0.106, 0.106, 0.122, 0.85))
	plate.texture = ImageTexture.create_from_image(image)
	var icon: Sprite3D = Sprite3D.new()
	icon.texture = seasoning.get(&"icon")
	icon.render_priority = 31
	icon.no_depth_test = true
	icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	icon.shaded = false
	icon.pixel_size = 64.0 / maxf(icon.texture.get_width(), 1.0) * (12.74 / 1080.0) * 0.28
	plate.pixel_size = (12.74 / 1080.0) * 0.28
	plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	plate.no_depth_test = true
	plate.shaded = false
	plate.render_priority = 30
	level.add_child(plate)
	plate.global_position = at
	plate.add_child(icon)


func _shot(path: String) -> void:
	for i: int in 6:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(path)


## Recorte x4 (vecino más próximo) de la fila de pegatinas de cada caja, una junto a otra.
func _save_zoom(cam: Camera3D, boxes: Array[Node3D], path: String) -> void:
	var source: Image = root.get_viewport().get_texture().get_image()
	source.convert(Image.FORMAT_RGBA8)
	var half: Vector2i = Vector2i(40, 24)
	var zoom: int = 4
	var sheet: Image = Image.create(
		boxes.size() * half.x * 2 * zoom, half.y * 2 * zoom, false, Image.FORMAT_RGBA8
	)
	for index: int in boxes.size():
		var row: Node3D = boxes[index].get_node("%BadgeRow")
		var center: Vector2i = Vector2i(cam.unproject_position(row.global_position))
		var crop: Image = source.get_region(Rect2i(center - half, half * 2))
		crop.resize(crop.get_width() * zoom, crop.get_height() * zoom, Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), Vector2i(index * crop.get_width(), 0))
	sheet.save_png(path)
