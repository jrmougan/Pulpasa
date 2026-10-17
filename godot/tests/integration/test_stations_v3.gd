extends GutTest
## PUL-186: encimeras, suelo y estaciones v3 (art-bible §3.1, §5.1, §5.3, §6.2; D28). Import de los
## `.glb` sin texturas embebidas y con materiales planos v3, atrezo de Z1/Z2 podado (oculto, no
## borrado), estación de condimentos limpia con contrastes ≥ 3.90 : 1, placa D26.7 sobre el cuerpo
## pintado de cada dispensador y vapor `Steam` visible al cocer.

const IMPORT_DIRS: Array[String] = [
	"res://assets/models/furniture/counters/",
	"res://assets/models/stations/",
]
const SCENES: Array[String] = [
	"res://entities/environment/kitchen_layout.tscn",
	"res://entities/stations/kitchen.tscn",
	"res://entities/stations/octopus_storage.tscn",
	"res://entities/stations/cachelos_storage.tscn",
	"res://entities/stations/box_shelf.tscn",
	"res://entities/stations/seasoning_station.tscn",
	"res://entities/stations/seasoning_dispenser.tscn",
	"res://entities/stations/cachelos_bowl.tscn",
	"res://entities/stations/trash_bin.tscn",
	"res://entities/stations/slot.tscn",
]
const V2_DIR := "res://assets/materials/v2/"
const FLOOR_DIRT := "kitchen_floor_dirt.tres"
const V3_DIR := "res://assets/materials/v3/"
## Atrezo podado por escena (art-bible §5.1, Z1 y Z2).
const PRUNED: Dictionary[String, Array] = {
	"res://entities/environment/kitchen_layout.tscn":
	[
		"BackCounter/BackBetweenStoragePot/Model/props_crock",
		"BackCounter/BackRight/Model/props_board",
		"BackCounter/BackRight/Model/props_crock",
		"Walls/WallLeftKitchen/Model/props_crock",
		"Walls/WallRight/Model/props_board",
	],
	"res://entities/stations/kitchen.tscn": ["Model/Pot/pot/gas_bottle"],
	"res://entities/stations/octopus_storage.tscn": ["Model/octopus_storage/pump"],
	"res://entities/stations/box_shelf.tscn":
	[
		"Model/box_shelf/cartons",
		"Model/box_shelf/SizePanel_large",
		"Model/box_shelf/SizePanel_medium",
		"Model/box_shelf/SizePanel_small",
		"Model/box_shelf/labels",
	],
}
const SIGN_KINDS: Array[String] = ["CounterArrow", "Label", "ServiceArrow"]
const SIGN_SUFFIXES: Array[String] = ["sweet", "hot", "salt", "oil", "potato"]
const MIN_CONTRAST := 3.90
const SURFACE_TOP := "mat_surface_top.tres"
const BRAND_NAVY := "mat_brand_navy.tres"
const STEAM_MOUTH := Color("#2A2320")
const KITCHEN_SCENE: PackedScene = preload("res://entities/stations/kitchen.tscn")
const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const STATION_SCENE: PackedScene = preload("res://entities/stations/seasoning_station.tscn")


func test_ac1_imports_discard_images_and_keep_materials_embedded() -> void:
	var imports: Array[String] = []
	for dir_path: String in IMPORT_DIRS:
		imports.append_array(_find_glb_imports(dir_path))
	assert_gt(imports.size(), 20, "módulos de encimera y estaciones")
	for path: String in imports:
		var config := ConfigFile.new()
		assert_eq(config.load(path), OK, path)
		assert_eq(config.get_value("params", "gltf/embedded_image_handling", -1), 0, path)
		assert_eq(config.get_value("params", "materials/extract", -1), 0, path)
		var subresources: Dictionary = config.get_value("params", "_subresources", {})
		var materials: Dictionary = subresources.get("materials", {})
		assert_gt(materials.size(), 0, "%s: slots mapeados" % path)
		for slot: String in materials:
			var target: String = (materials[slot] as Dictionary).get("use_external/path", "")
			assert_true(target.begins_with(V3_DIR), "%s: %s → %s" % [path, slot, target])


func test_ac1_visible_meshes_use_flat_materials_without_v2() -> void:
	for scene_path: String in SCENES:
		var root: Node = _instance(scene_path)
		for mesh: MeshInstance3D in _visible_meshes(root):
			for surface: int in mesh.mesh.get_surface_count():
				var material: Material = mesh.get_active_material(surface)
				var label: String = "%s %s s%d" % [scene_path.get_file(), mesh.name, surface]
				if material == null:
					continue
				assert_false(material.resource_path.begins_with(V2_DIR), label)
				assert_false(material.resource_path.ends_with(FLOOR_DIRT), label)
				_assert_flat(material, label)


func test_ac1_floor_is_ground_sand() -> void:
	var layout: Node = _instance("res://entities/environment/kitchen_layout.tscn")
	var floor_mesh: MeshInstance3D = layout.get_node("Floor/Mesh") as MeshInstance3D
	assert_eq(floor_mesh.material_override.resource_path, V3_DIR + "mat_ground_sand.tres")


func test_ac2_props_are_hidden() -> void:
	for scene_path: String in PRUNED:
		var root: Node = _instance(scene_path)
		add_child(root)
		for node_path: String in PRUNED[scene_path]:
			var node: Node3D = root.get_node_or_null(node_path) as Node3D
			assert_not_null(node, "%s: %s" % [scene_path.get_file(), node_path])
			if node != null:
				assert_false(node.is_visible_in_tree(), "%s oculto" % node_path)
		remove_child(root)


func test_ac2_rack_panels_stay_in_tree() -> void:
	var shelf: Node = _instance("res://entities/stations/box_shelf.tscn")
	var panels: Array[Node] = shelf.find_children("SizePanel_*", "MeshInstance3D", true, false)
	assert_eq(panels.size(), 3, "SizePanel_* ocultos pero no borrados")


func test_ac3_pre_d25_signs_are_hidden() -> void:
	var station: Node3D = add_child_autofree(STATION_SCENE.instantiate())
	var model: Node = station.get_node("Model/seasoning_station")
	var count := 0
	for kind: String in SIGN_KINDS:
		for suffix: String in SIGN_SUFFIXES:
			var sign_node: Node3D = model.get_node("%s_%s" % [kind, suffix]) as Node3D
			assert_false(sign_node.is_visible_in_tree(), sign_node.name)
			count += 1
	assert_eq(count, 15)


func test_ac3_seasoning_contrasts() -> void:
	var station: Node3D = add_child_autofree(STATION_SCENE.instantiate())
	await wait_physics_frames(1)
	var model: Node = station.get_node("Model/seasoning_station")
	var mat: Color = _albedo(model.get_node("ServiceMat"), 0, SURFACE_TOP)
	_albedo(model.get_node("ServiceFascia"), 0, BRAND_NAVY)
	var sweet: Color = _albedo(_body(station, "SweetDressing", "paprika_sweet"), 0, "")
	var hot: Color = _albedo(_body(station, "HotDressing", "paprika_hot"), 0, "")
	_albedo(_body(station, "SweetDressing", "paprika_sweet"), 1, SURFACE_TOP)
	var bowl_model: Node = station.get_node("CachelosBowl/Model/cachelos_bowl")
	var bowl: Color = _albedo(bowl_model.get_node("bowl"), 0, BRAND_NAVY)
	var cachelos: Color = _albedo(bowl_model.get_node("Portions4"), 1, "mat_cachelos_cooked.tres")
	assert_almost_eq(_contrast(sweet, mat), 3.91, 0.01, "dulce sobre ServiceMat")
	assert_almost_eq(_contrast(hot, mat), 7.40, 0.01, "picante sobre ServiceMat")
	assert_almost_eq(_contrast(cachelos, bowl), 8.54, 0.01, "cachelos sobre el cuenco")
	for ratio: float in [_contrast(sweet, mat), _contrast(hot, mat), _contrast(cachelos, bowl)]:
		assert_gte(ratio, MIN_CONTRAST)


func test_dispenser_body_is_v3_and_icon_plate_stays() -> void:
	var station: Node3D = add_child_autofree(STATION_SCENE.instantiate())
	await wait_physics_frames(1)
	var expected: Dictionary[String, Array] = {
		"SweetDressing": ["paprika_sweet", "mat_paprika_sweet.tres"],
		"HotDressing": ["paprika_hot", "mat_paprika_hot.tres"],
	}
	for dispenser: String in expected:
		var body: MeshInstance3D = _body(station, dispenser, expected[dispenser][0])
		_albedo(body, 0, expected[dispenser][1])
		var plate: Sprite3D = body.get_node_or_null("FrontPlate") as Sprite3D
		assert_not_null(plate, "%s: placa D26.7" % dispenser)
		if plate == null:
			continue
		assert_true(plate.is_visible_in_tree(), "%s: placa visible" % dispenser)
		var icon: Sprite3D = plate.get_node("FrontIcon") as Sprite3D
		assert_true(icon.is_visible_in_tree(), "%s: icono visible" % dispenser)
		assert_not_null(icon.texture)
		var bounds: AABB = body.get_aabb()
		assert_false(bounds.has_point(plate.position), "%s: la placa sale del cuerpo" % dispenser)


func test_ac4_steam_visible_while_cooking() -> void:
	var level: Node3D = add_child_autofree(Node3D.new())
	var player: Player = PLAYER_SCENE.instantiate()
	level.add_child(player)
	var hold: HoldComponent = player.get_node("%HoldComponent")
	hold.items_root = level
	var kitchen: CookingStation = KITCHEN_SCENE.instantiate()
	level.add_child(kitchen)
	kitchen.position = Vector3(0, 0, -1.2)
	var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
	level.add_child(octopus)
	assert_true(hold.pick_up(octopus))
	assert_true(kitchen.interact(player.get_node("%InteractionComponent")))
	simulate(kitchen, 1, 0.1)
	var steam: GPUParticles3D = kitchen.get_node("Model/Steam") as GPUParticles3D
	assert_true(steam.emitting, "vapor al cocer")
	assert_true(steam.is_visible_in_tree())
	assert_gte(steam.amount, 16, "bastantes partículas")
	var puff: SphereMesh = steam.draw_pass_1 as SphereMesh
	assert_gte(puff.radius, 0.1, "bocanadas grandes para la cámara ortográfica")
	var process: ParticleProcessMaterial = steam.process_material as ParticleProcessMaterial
	var ramp: Gradient = (process.color_ramp as GradientTexture1D).gradient
	var peak := Color(0, 0, 0, 0)
	for index: int in ramp.get_point_count():
		if ramp.get_color(index).a > peak.a:
			peak = ramp.get_color(index)
	assert_gte(peak.a, 0.8, "vapor casi opaco en su pico")
	assert_gte(_contrast(peak, STEAM_MOUTH), MIN_CONTRAST, "vapor sobre la boca #2A2320")


func _find_glb_imports(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	for sub: String in DirAccess.get_directories_at(dir_path):
		found.append_array(_find_glb_imports(dir_path + sub + "/"))
	for file_name: String in DirAccess.get_files_at(dir_path):
		if file_name.ends_with(".glb.import"):
			found.append(dir_path + file_name)
	return found


func _instance(scene_path: String) -> Node:
	var scene: PackedScene = load(scene_path) as PackedScene
	return autofree(scene.instantiate())


## Mallas visibles (propio `visible` de cada antecesor 3D), sin necesidad de árbol.
func _visible_meshes(root: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh.mesh != null and _shown(mesh, root):
			result.append(mesh)
	return result


func _shown(node: Node, root: Node) -> bool:
	var current: Node = node
	while current != null:
		if current is Node3D and not (current as Node3D).visible:
			return false
		if current == root:
			return true
		current = current.get_parent()
	return true


func _assert_flat(material: Material, label: String) -> void:
	var flat: BaseMaterial3D = material as BaseMaterial3D
	if flat == null:
		return
	assert_null(flat.albedo_texture, "%s sin albedo_texture" % label)
	assert_null(flat.normal_texture, "%s sin normal_texture" % label)
	assert_null(flat.roughness_texture, "%s sin roughness_texture" % label)
	assert_null(flat.metallic_texture, "%s sin metallic_texture" % label)
	assert_null(flat.ao_texture, "%s sin ao_texture" % label)


func _body(station: Node, dispenser: String, mesh_name: String) -> MeshInstance3D:
	var path: String = "Dispensers/%s/Model/seasoning_dispenser/%s" % [dispenser, mesh_name]
	return station.get_node(path) as MeshInstance3D


## Albedo del material activo de [param surface]; si [param file] no está vacío, comprueba que es
## ese `.tres` de la v3.
func _albedo(node: Node, surface: int, file: String) -> Color:
	var mesh: MeshInstance3D = node as MeshInstance3D
	var material: BaseMaterial3D = mesh.get_active_material(surface) as BaseMaterial3D
	assert_not_null(material, "%s s%d" % [mesh.name, surface])
	if material == null:
		return Color.BLACK
	if not file.is_empty():
		assert_eq(material.resource_path, V3_DIR + file, "%s s%d" % [mesh.name, surface])
	return material.albedo_color


## Contraste WCAG 2.1 entre dos colores sRGB (sin alfa).
func _contrast(a: Color, b: Color) -> float:
	var la: float = _luminance(a)
	var lb: float = _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _luminance(color: Color) -> float:
	var linear: Color = color.srgb_to_linear()
	return 0.2126 * linear.r + 0.7152 * linear.g + 0.0722 * linear.b
