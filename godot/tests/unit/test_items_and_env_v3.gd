extends GutTest
## PUL-187: materiales planos v3 en entorno, comida, cajas y cocineros (art-bible §3, §5.2, §6.1).
## Los mapeos viven en los `.glb.import` (`_subresources["materials"]`); aquí se comprueba lo que
## llega a las mallas importadas por nombre de superficie (= slot real del `.glb`).

const MAT_DIR := "res://assets/materials/v3/"
const ENV_DIR := "res://assets/models/environment/romeria_v2/"
const TENT_PLATE_TEXTURE := ENV_DIR + "tent_plate_albedo.png"
const OCTOPUS_SCENE := "res://entities/items/octopus.tscn"
const CACHELOS_SCENE := "res://entities/items/cachelos.tscn"
const BOX_SCENE := "res://entities/items/box.tscn"
const PLAYER_SCENE := "res://entities/player/player.tscn"
const COLOR_TOLERANCE := 0.005

## Estado → [malla visible esperada, slot de cuerpo, hex].
const OCTOPUS_STATES: Array[Array] = [
	["octopus_raw", "mat_food_octopus_raw", "#E0AFB2"],
	["octopus_cooked", "mat_food_octopus_cooked", "#B8283D"],
	["octopus_burnt", "mat_food_octopus_burnt", "#2A2320"],
]
const CACHELOS_STATES: Array[Array] = [
	["cachelos_raw", "mat_food_potato_raw", "#8E6B47"],
	["cachelos_cooked", "mat_food_potato_cooked", "#F2D56B"],
	["cachelos_burnt", "mat_food_potato_burnt", "#2A2320"],
]
## `.glb` del entorno → slots que deben acabar en un `.tres` de la biblioteca v3.
const ENV_MODELS: Array[String] = [
	"back_e.glb",
	"back_w.glb",
	"ground_e.glb",
	"ground_w.glb",
	"props_e.glb",
	"props_w.glb",
	"tent.glb"
]
## Slots de `ground_*_decals`, malla ya oculta en `environment.tscn` (biblia v3 §5.1).
const PRUNED_SLOTS: Array[String] = ["env_track", "env_puddle"]


static func _luminance(color: Color) -> float:
	var channels: Array[float] = []
	for value: float in [color.r, color.g, color.b]:
		channels.append(value / 12.92 if value <= 0.04045 else pow((value + 0.055) / 1.055, 2.4))
	return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]


static func _contrast(a: Color, b: Color) -> float:
	var la: float = _luminance(a)
	var lb: float = _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


## Material de la superficie `slot` de `mesh` (null si no la tiene).
static func _slot(mesh: MeshInstance3D, slot: String) -> StandardMaterial3D:
	for index: int in mesh.mesh.get_surface_count():
		if mesh.mesh.surface_get_name(index) == slot:
			var override: Material = mesh.get_surface_override_material(index)
			if override != null:
				return override as StandardMaterial3D
			return mesh.mesh.surface_get_material(index) as StandardMaterial3D
	return null


func _mesh(root: Node, mesh_name: String) -> MeshInstance3D:
	return root.find_child(mesh_name, true, false) as MeshInstance3D


func _instance(path: String) -> Node:
	var root: Node = (load(path) as PackedScene).instantiate()
	add_child_autofree(root)
	return root


func _assert_hex(material: StandardMaterial3D, hex: String, label: String) -> void:
	assert_not_null(material, label)
	if material == null:
		return
	var expected: Color = Color(hex)
	for channel: int in 4:
		assert_almost_eq(material.albedo_color[channel], expected[channel], COLOR_TOLERANCE, label)


## Albedo del slot de cuerpo de la malla visible en cada estado (crudo, cocido, quemado).
func _state_colors(path: String, states: Array[Array]) -> Array[Color]:
	var ingredient: Ingredient = _instance(path) as Ingredient
	var colors: Array[Color] = []
	for index: int in states.size():
		if index == 1:
			ingredient.set_cooked()
		elif index == 2:
			ingredient.set_burnt()
		var expected: Array = states[index]
		var mesh: MeshInstance3D = _mesh(ingredient, expected[0])
		assert_true(mesh.visible, "%s visible" % expected[0])
		for other: Array in states:
			if other != expected:
				assert_false(_mesh(ingredient, other[0]).visible, "%s oculto" % other[0])
		var material: StandardMaterial3D = _slot(mesh, expected[1])
		_assert_hex(material, expected[2], "%s.%s" % expected.slice(0, 2))
		colors.append(material.albedo_color)
	return colors


# --- AC1 ---------------------------------------------------------------------------------------


func test_tent_hides_empty_signs_and_keeps_brand_plate() -> void:
	var tent: Node = _instance(ENV_DIR + "tent.glb")
	var structure: MeshInstance3D = _mesh(tent, "tent_structure")
	for slot: String in ["env_sign", "env_board"]:
		var hidden: StandardMaterial3D = _slot(structure, slot)
		assert_eq(hidden.resource_path, MAT_DIR + "mat_hidden_alpha.tres", slot)
		assert_eq(hidden.albedo_color.a, 0.0, "%s alfa" % slot)
		assert_ne(hidden.transparency, BaseMaterial3D.TRANSPARENCY_DISABLED, "%s alfa" % slot)
	var plate: StandardMaterial3D = _slot(_mesh(tent, "tent_plate"), "env_plate")
	assert_eq(plate.resource_path, MAT_DIR + "mat_tent_plate.tres")
	assert_eq(plate.albedo_texture.resource_path, TENT_PLATE_TEXTURE)


func test_environment_uses_only_v3_materials() -> void:
	for file_name: String in ENV_MODELS:
		var root: Node = _instance(ENV_DIR + file_name)
		for node: Node in root.find_children("*", "MeshInstance3D", true, false):
			var mesh: MeshInstance3D = node as MeshInstance3D
			for index: int in mesh.mesh.get_surface_count():
				var material: Material = mesh.mesh.surface_get_material(index)
				var slot: String = mesh.mesh.surface_get_name(index)
				if slot in PRUNED_SLOTS:
					continue
				var label: String = "%s/%s" % [file_name, slot]
				assert_true(material.resource_path.begins_with(MAT_DIR), label)


# --- AC2 ---------------------------------------------------------------------------------------


func test_octopus_states_are_flat_and_contrasted() -> void:
	var colors: Array[Color] = _state_colors(OCTOPUS_SCENE, OCTOPUS_STATES)
	assert_gte(_contrast(colors[0], colors[1]), 3.20, "crudo/cocido")
	assert_gte(_contrast(colors[0], colors[2]), 3.0, "crudo/quemado")


func test_cachelos_states_are_flat_and_contrasted() -> void:
	var colors: Array[Color] = _state_colors(CACHELOS_SCENE, CACHELOS_STATES)
	assert_gte(_contrast(colors[0], colors[1]), 3.20, "crudo/cocido")
	assert_gte(_contrast(colors[1], colors[2]), 3.0, "cocido/quemado")


# --- AC3 ---------------------------------------------------------------------------------------


func test_box_layers_contrast_with_the_layer_below() -> void:
	var box: Node = _instance(BOX_SCENE)
	var plate: MeshInstance3D = _mesh(box.get_node(^"Model/Plate"), "box_medium")
	var outside: StandardMaterial3D = _slot(plate, "mat_plastic_red")
	var inside: StandardMaterial3D = _slot(plate, "atlas_box")
	var octopus: StandardMaterial3D = _slot(
		_mesh(box.get_node(^"Model/Octopus"), "octopus_pieces_a"), "mat_food_octopus_pieces"
	)
	var cachelos: StandardMaterial3D = _slot(
		_mesh(box.get_node(^"Model/Cachelos"), "cachelos_pieces_a"), "mat_food_potato_cooked"
	)
	_assert_hex(outside, "#C8402F", "exterior")
	_assert_hex(inside, "#EDE8DF", "interior")
	_assert_hex(octopus, "#B8283D", "rodajas de pulpo")
	_assert_hex(cachelos, "#F2D56B", "cachelos")
	assert_gte(_contrast(outside.albedo_color, inside.albedo_color), 4.0, "exterior/interior")
	assert_gte(_contrast(octopus.albedo_color, inside.albedo_color), 4.0, "pulpo/interior")
	assert_gte(_contrast(cachelos.albedo_color, octopus.albedo_color), 4.0, "cachelos/pulpo")


func test_box_keeps_functional_slots() -> void:
	var plate: Node = _instance(BOX_SCENE).get_node(^"Model/Plate")
	var hull: StandardMaterial3D = _slot(_mesh(plate, "hull_medium"), "mat_outline_hull")
	var sticker: StandardMaterial3D = _slot(_mesh(plate, "sticker"), "mat_sticker_atlas")
	for material: StandardMaterial3D in [hull, sticker]:
		assert_not_null(material)
		assert_false(material.resource_path.begins_with(MAT_DIR), "slot funcional sin plano v3")


# --- AC4 ---------------------------------------------------------------------------------------


func test_cooks_wear_player_colours_without_pbr_maps() -> void:
	var model: Node = _instance(PLAYER_SCENE).get_node(^"Model")
	var expected: Dictionary[String, Dictionary] = {
		"cook_body_j1":
		{
			"mat_cloth_player_1": "#2F6FB5",
			"mat_cloth_shirt": "#F7F4EC",
			"mat_cloth_pants": "#1D3557",
			"mat_skin_light": "#E0AFB2",
		},
		"cook_hat_j1": {"mat_cloth_player_1": "#2F6FB5"},
		"cook_body_j2":
		{
			"mat_cloth_player_2": "#F2C230",
			"mat_cloth_shirt": "#F7F4EC",
			"mat_cloth_pants": "#1D3557",
		},
		"cook_hat_j2": {"mat_cloth_player_2": "#F2C230"},
	}
	for mesh_name: String in expected:
		var mesh: MeshInstance3D = _mesh(model, mesh_name)
		for slot: String in expected[mesh_name]:
			var material: StandardMaterial3D = _slot(mesh, slot)
			_assert_hex(material, expected[mesh_name][slot], "%s.%s" % [mesh_name, slot])
			assert_null(material.albedo_texture, "%s sin textura" % slot)
			assert_false(material.normal_enabled, "%s sin normal" % slot)
