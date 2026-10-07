extends GutTest
## PUL-047: el `Model` de la caja (BoxModel) muestra el plato del tamaño de `data`, el relleno
## progresivo con las rodajas y los cachelos si los lleva; las pegatinas 3D del `.glb` van ocultas
## y los nodos de contrato de `box.tscn` siguen en su sitio. PUL-077: el resaltado sale del volumen
## cerrado `hull_<tamaño>` de la talla visible, no de la bandeja abierta.

const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const SMALL: BoxData = preload("res://data/boxes/small.tres")
const MEDIUM: BoxData = preload("res://data/boxes/medium.tres")
const LARGE: BoxData = preload("res://data/boxes/large.tres")
const SALT: SeasoningData = preload("res://data/seasonings/salt.tres")
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


func test_size_key_comes_from_the_data_file() -> void:
	assert_eq(BoxModel.size_key(SMALL), &"small")
	assert_eq(BoxModel.size_key(MEDIUM), &"medium")
	assert_eq(BoxModel.size_key(LARGE), &"large")
	assert_eq(BoxModel.size_key(null), BoxModel.DEFAULT_SIZE)
	assert_eq(BoxModel.size_key(BoxData.new()), BoxModel.DEFAULT_SIZE)


func test_each_size_shows_only_its_plate_with_the_bible_diameter() -> void:
	for data: BoxData in [SMALL, MEDIUM, LARGE]:
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
	for data: BoxData in [SMALL, MEDIUM, LARGE]:
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
	var box: Box = _box(SMALL)
	box.data = LARGE
	_model(box).refresh()
	assert_eq(_model(box).get_size(), &"large")
	assert_true(_visible(box, "box_large"))
	assert_false(_visible(box, "box_small"))


func test_fill_levels_show_progressive_slices() -> void:
	assert_eq(BoxModel.fill_level(0.0), 0)
	assert_eq(BoxModel.fill_level(0.2), 1)
	assert_eq(BoxModel.fill_level(0.5), 2)
	assert_eq(BoxModel.fill_level(0.95), 2)
	assert_eq(BoxModel.fill_level(1.0), 3)
	var box: Box = _box(MEDIUM)
	assert_eq(_octopus_layers(box), [false, false, false] as Array[bool], "vacía")
	_set_fill(box, 0.1)
	assert_eq(_octopus_layers(box), [true, false, false] as Array[bool], "empezada")
	_set_fill(box, 0.6)
	assert_eq(_octopus_layers(box), [true, true, false] as Array[bool], "a medias")
	_set_fill(box, 1.0)
	assert_eq(_octopus_layers(box), [true, true, true] as Array[bool], "llena")


func test_slices_sit_on_the_plate_floor() -> void:
	var box: Box = _box(LARGE)
	var octopus: Node3D = box.get_node("Model/Octopus") as Node3D
	var anchor: Node3D = box.get_node("Model").find_child("Anchor_Fill_large") as Node3D
	assert_almost_eq(octopus.position.y, anchor.position.y, 0.001)
	assert_gt(anchor.position.y, 0.0)


func test_cachelos_follow_the_seasoning() -> void:
	var box: Box = _box(SMALL)
	_set_fill(box, 1.0)
	assert_false(_visible(box, "cachelos_pieces_a"))
	assert_eq(box.toggle_seasoning(SALT, true), SeasoningRules.Rejection.NONE)
	assert_false(_visible(box, "cachelos_pieces_a"), "otro condimento no añade cachelos")
	assert_eq(box.toggle_seasoning(CACHELOS, true), SeasoningRules.Rejection.NONE)
	assert_true(_visible(box, "cachelos_pieces_a"))
	assert_true(_visible(box, "cachelos_pieces_b"))
	assert_true(box.remove_seasoning(CACHELOS))
	assert_false(_visible(box, "cachelos_pieces_a"))


func test_3d_sticker_is_hidden_and_anchors_exist() -> void:
	var box: Box = _box(MEDIUM)
	assert_false(_visible(box, "sticker"), "la fila en juego es %BadgeRow")
	for size: StringName in BoxModel.SIZES:
		for i: int in 4:
			var anchor_name: String = "Anchor_Sticker_%s_%d" % [size, i]
			assert_not_null(box.get_node("Model").find_child(anchor_name), anchor_name)


func test_contract_nodes_survive_the_new_model() -> void:
	var box: Box = _box(MEDIUM)
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


func test_collision_matches_the_model_of_each_size() -> void:
	var expected: Dictionary[BoxData, Vector3] = {
		SMALL: Vector3(0.338, 0.284, 0.320),
		MEDIUM: Vector3(0.396, 0.333, 0.375),
		LARGE: Vector3(0.491, 0.414, 0.466),
	}
	var shapes: Array[Shape3D] = []
	for data: BoxData in expected:
		var box: Box = _box(data)
		var body: CollisionShape3D = box.get_node("CollisionShape3D") as CollisionShape3D
		assert_eq((body.shape as BoxShape3D).size, expected[data], str(data.display_name))
		shapes.append(body.shape)
	assert_ne(shapes[0], shapes[1], "las cajas no comparten la forma")
	assert_ne(shapes[1], shapes[2], "las cajas no comparten la forma")
