extends GutTest
## PUL-047: el `Model` de la caja (BoxModel) muestra el plato único (variante mediana del `.glb`),
## el relleno progresivo con las rodajas y los cachelos si los lleva; las pegatinas 3D del `.glb`
## van ocultas y los nodos de contrato de `box.tscn` siguen en su sitio. PUL-077: el resaltado sale
## del volumen cerrado `hull_medium`, no de la bandeja abierta.

const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const BOX: BoxData = preload("res://data/boxes/box.tres")
const SWEET: SeasoningData = preload("res://data/seasonings/sweet_dressing.tres")
const CACHELOS: SeasoningData = preload("res://data/seasonings/cachelos.tres")
## Diámetro exterior por tamaño (art-bible §2.1, ±10 %).
const DIAMETERS: Dictionary[StringName, float] = {&"small": 0.34, &"medium": 0.42, &"large": 0.49}


func _box(data: BoxData) -> Box:
	var box: Box = BOX_SCENE.instantiate()
	box.data = data
	add_child_autofree(box)
	return box


func _model(box: Box) -> BoxModel:
	return box.get_node("Model") as BoxModel


func _visible(box: Box, node_name: String) -> bool:
	var node: Node3D = box.get_node("Model").find_child(node_name, true, false) as Node3D
	assert_not_null(node, node_name)
	return node != null and node.is_visible_in_tree()


func _set_fill(box: Box, fill: float) -> void:
	box.fill = fill
	box.fill_changed.emit(fill)


func _octopus_layers(box: Box) -> Array[bool]:
	var shown: Array[bool] = []
	for layer: StringName in BoxModel.OCTOPUS_LAYERS:
		shown.append(_visible(box, layer))
	return shown


func test_single_variant_is_medium_for_any_data() -> void:
	## D25: la caja única usa la variante mediana del `.glb`.
	assert_eq(_model(_box(BOX)).get_size(), BoxModel.VARIANT)
	assert_eq(BoxModel.VARIANT, &"medium")


func test_each_size_shows_only_its_plate_with_the_bible_diameter() -> void:
	for data: BoxData in [BOX]:
		var box: Box = _box(data)
		var size: StringName = _model(box).get_size()
		for key: StringName in BoxModel.SIZES:
			assert_eq(_visible(box, "box_" + key), key == size, "%s: box_%s" % [size, key])
		var plate: MeshInstance3D = (
			box.get_node("Model").find_child("box_" + size) as MeshInstance3D
		)
		var aabb: AABB = plate.mesh.get_aabb()
		assert_almost_eq(aabb.size.x, DIAMETERS[size], DIAMETERS[size] * 0.1, size)
		assert_almost_eq(aabb.size.y, 0.10, 0.01, size)
		assert_almost_eq(aabb.position.y, 0.0, 0.001, "%s: base en el origen" % size)


func test_outline_hull_follows_the_size() -> void:
	for data: BoxData in [BOX]:
		var box: Box = _box(data)
		var size: StringName = _model(box).get_size()
		var highlightable: Highlightable = box.get_node("%Highlightable") as Highlightable
		assert_not_null(highlightable.root, "%s: raíz del contorno" % size)
		assert_eq(highlightable.root.name, &"OutlineHull")
		for key: StringName in BoxModel.SIZES:
			assert_eq(_visible(box, "hull_" + key), key == size, "%s: hull_%s" % [size, key])
		highlightable.show()
		var hull: MeshInstance3D = (
			box.get_node("Model").find_child("hull_" + size) as MeshInstance3D
		)
		assert_eq(hull.material_overlay, highlightable.material, "%s: contorno en el hull" % size)
		var tray: MeshInstance3D = box.get_node("Model").find_child("box_" + size) as MeshInstance3D
		assert_null(tray.material_overlay, "%s: la bandeja abierta no lleva contorno" % size)
		highlightable.hide()


func test_refresh_follows_data_assigned_after_ready() -> void:
	var box: Box = _box(BOX)
	box.data = BoxData.new()
	_model(box).refresh()
	assert_eq(_model(box).get_size(), &"medium")
	assert_true(_visible(box, "box_medium"))
	assert_false(_visible(box, "box_small"))
	assert_false(_visible(box, "box_large"))


func test_fill_levels_show_progressive_slices() -> void:
	assert_eq(BoxModel.fill_level(0.0), 0)
	assert_eq(BoxModel.fill_level(0.2), 1)
	assert_eq(BoxModel.fill_level(0.5), 2)
	assert_eq(BoxModel.fill_level(0.95), 2)
	assert_eq(BoxModel.fill_level(1.0), 3)
	var box: Box = _box(BOX)
	assert_eq(_octopus_layers(box), [false, false, false] as Array[bool], "vacía")
	_set_fill(box, 0.1)
	assert_eq(_octopus_layers(box), [true, false, false] as Array[bool], "empezada")
	_set_fill(box, 0.6)
	assert_eq(_octopus_layers(box), [true, true, false] as Array[bool], "a medias")
	_set_fill(box, 1.0)
	assert_eq(_octopus_layers(box), [true, true, true] as Array[bool], "llena")


func test_slices_sit_on_the_plate_floor() -> void:
	var box: Box = _box(BOX)
	var octopus: Node3D = box.get_node("Model/Octopus") as Node3D
	var anchor: Node3D = box.get_node("Model").find_child("Anchor_Fill_medium") as Node3D
	assert_almost_eq(octopus.position.y, anchor.position.y, 0.001)
	assert_gt(anchor.position.y, 0.0)


func test_cachelos_follow_the_seasoning() -> void:
	var box: Box = _box(BOX)
	_set_fill(box, 1.0)
	assert_false(_visible(box, "cachelos_pieces_a"))
	assert_eq(box.apply_seasoning(SWEET), SeasoningRules.Rejection.NONE)
	assert_false(_visible(box, "cachelos_pieces_a"), "otro condimento no añade cachelos")
	assert_eq(box.toggle_seasoning(CACHELOS), SeasoningRules.Rejection.NONE)
	assert_true(_visible(box, "cachelos_pieces_a"))
	assert_true(_visible(box, "cachelos_pieces_b"))
	assert_true(box.remove_seasoning(CACHELOS))
	assert_false(_visible(box, "cachelos_pieces_a"))


func test_3d_sticker_is_hidden_and_anchors_exist() -> void:
	var box: Box = _box(BOX)
	assert_false(_visible(box, "sticker"), "la fila en juego es %BadgeRow")
	for size: StringName in BoxModel.SIZES:
		for i: int in 4:
			var anchor_name: String = "Anchor_Sticker_%s_%d" % [size, i]
			assert_not_null(box.get_node("Model").find_child(anchor_name), anchor_name)


func test_contract_nodes_survive_the_new_model() -> void:
	var box: Box = _box(BOX)
	assert_true(box.is_in_group(&"box"))
	for path: String in ["%BadgeRow", "%AnimationPlayer", "%AnchorPoint", "%FillBar", "%Lid"]:
		assert_not_null(box.get_node_or_null(path), path)
	var player: AnimationPlayer = box.get_node("%AnimationPlayer") as AnimationPlayer
	assert_true(player.has_animation(&"box_open"))
	assert_true(player.has_animation(&"box_close"))
	var shape: BoxShape3D = (
		(box.get_node("CollisionShape3D") as CollisionShape3D).shape as BoxShape3D
	)
	assert_eq(shape.size, Vector3(0.396, 0.333, 0.375))


func test_collision_matches_the_medium_plate_and_is_not_shared() -> void:
	var shapes: Array[Shape3D] = []
	for i: int in 2:
		var box: Box = _box(BOX)
		var body: CollisionShape3D = box.get_node("CollisionShape3D") as CollisionShape3D
		assert_eq((body.shape as BoxShape3D).size, Vector3(0.396, 0.333, 0.375))
		shapes.append(body.shape)
	assert_ne(shapes[0], shapes[1], "las cajas no comparten la forma")
