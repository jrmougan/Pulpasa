extends Node
## PUL-180: Script de captura del estado de partida (v2) y prototipo en el motor de las
## 3 direcciones minimalistas (A · Feira Clara, B · Bloques de Romería, C · Maqueta de Papel).
## Sustituye materiales, luz, entorno y visibilidad de atrezo en tiempo de ejecución sin
## tocar escenas ni recursos versionados.
##
## Uso (desde la raíz del repositorio):
##   xvfb-run -a godot --audio-driver Dummy --path godot --resolution 1920x1080 \
##     -s "$PWD/docs/evidence/PUL-180/capture_boot.gd" -- --out="$PWD/docs/evidence/PUL-180"

const LEVEL_SCENE: PackedScene = preload("res://scenes/levels/level_01.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const BOX_DATA: BoxData = preload("res://data/boxes/box.tres")
const SWEET: SeasoningData = preload("res://data/seasonings/sweet_dressing.tres")
const HOT: SeasoningData = preload("res://data/seasonings/hot_dressing.tres")
const CACHELOS: SeasoningData = preload("res://data/seasonings/cachelos.tres")
const OCTOPUS_DATA: IngredientData = preload("res://data/ingredients/octopus.tres")

const DESKTOP_SIZE: Vector2i = Vector2i(1920, 1080)
const MOBILE_SIZE: Vector2i = Vector2i(800, 370)

var root: Window
var _out: String = ""
var _art_dir: String = ""
var _config: RoundConfig
var _positions: Dictionary = {}


func _ready() -> void:
	root = get_tree().root
	var base_dir: String = (get_script() as Script).resource_path.get_base_dir()
	_out = ProjectSettings.globalize_path(base_dir)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	_art_dir = _out.get_base_dir().get_base_dir() + "/art/minimal"
	_config = load("res://data/config/round_config.tres") as RoundConfig
	_run.call_deferred()


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().process_frame
		await get_tree().physics_frame


func _set_window_size(size: Vector2i) -> void:
	DisplayServer.window_set_size(size)
	root.size = size
	await _frames(8)


func _ensure_dir(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path)


func _save_shot(path: String) -> void:
	await _frames(4)
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	image.save_png(path)
	print("CAPTURA ", path, " ", image.get_size())


func _run() -> void:
	_ensure_dir(_out + "/partida")
	_ensure_dir(_out + "/direccion_a")
	_ensure_dir(_out + "/direccion_b")
	_ensure_dir(_out + "/direccion_c")
	_ensure_dir(_art_dir)

	var styles: Array[Dictionary] = [
		{"id": "partida", "folder": _out + "/partida", "art_png": ""},
		{
			"id": "dir_a",
			"folder": _out + "/direccion_a",
			"art_png": _art_dir + "/direccion-a-color-plano.png"
		},
		{
			"id": "dir_b",
			"folder": _out + "/direccion_b",
			"art_png": _art_dir + "/direccion-b-geometrica.png"
		},
		{
			"id": "dir_c",
			"folder": _out + "/direccion_c",
			"art_png": _art_dir + "/direccion-c-maqueta-papel.png"
		},
	]

	for entry: Dictionary in styles:
		var style_id: String = str(entry["id"])
		var folder: String = str(entry["folder"])
		var art_png: String = str(entry["art_png"])
		await _capture_style_desktop(style_id, folder, art_png)
		await _capture_style_mobile(style_id, folder)

	var json_path: String = _out + "/posiciones_verificadas.json"
	var file: FileAccess = FileAccess.open(json_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(_positions, "\t"))
	file.close()
	print("POSICIONES ", json_path, " ok")
	await _frames(6)
	get_tree().quit()


func _capture_style_desktop(style_id: String, folder: String, art_png: String) -> void:
	await _set_window_size(DESKTOP_SIZE)
	var gs: Node = root.get_node("GameState")
	gs.call("set_platform", PlatformProfile.Kind.DESKTOP)
	var level: Node3D = await _build_staged_level(false)
	if style_id != "partida":
		_apply_minimal_style(level, style_id)
	await _frames(6)
	_record_positions(level, style_id + "_1080p")
	await _save_shot(folder + "/1920x1080_con_hud.png")
	var ui: CanvasLayer = level.get_node("UI") as CanvasLayer
	ui.visible = false
	await _save_shot(folder + "/1920x1080_sin_hud.png")
	if art_png != "":
		var img: Image = root.get_texture().get_image()
		img.save_png(art_png)
		print("ART_PNG ", art_png, " ", img.get_size())
	await _cleanup_level(level)


func _capture_style_mobile(style_id: String, folder: String) -> void:
	await _set_window_size(MOBILE_SIZE)
	var gs: Node = root.get_node("GameState")
	gs.call("set_platform", PlatformProfile.Kind.MOBILE)
	var level: Node3D = await _build_staged_level(true)
	if style_id != "partida":
		_apply_minimal_style(level, style_id)
	await _frames(8)
	_record_positions(level, style_id + "_800x370")
	await _save_shot(folder + "/800x370_movil.png")
	await _cleanup_level(level)


func _cleanup_level(level: Node3D) -> void:
	var rm: Node = root.get_node("RoundManager")
	rm.set_process(false)
	level.queue_free()
	await _frames(8)


func _build_staged_level(mobile: bool) -> Node3D:
	_config.phases = [] as Array[PhaseData]
	_config.rng_seed = 42
	var rm: Node = root.get_node("RoundManager")
	rm.set_process(true)
	var level: Node3D = LEVEL_SCENE.instantiate() as Node3D
	root.add_child(level)
	await _frames(4)

	# Safe area nula (ventana completa) para evitar que el escritorio anfitrión desplace la UI.
	var window: Vector2 = Vector2(root.size)
	var rect: Rect2 = Rect2(Vector2.ZERO, window)
	for margin: Node in level.get_node("UI").find_children("*", "SafeAreaMargin", true, false):
		(margin as SafeAreaMargin).set_safe_rect(rect, window)
	var controls: TouchControls = level.get_node_or_null("UI/TouchControls") as TouchControls
	if controls != null:
		controls.visible = mobile
		if mobile:
			controls.apply_safe_rect(rect, window)
	var rig: CameraRig = level.get_node("CameraRig") as CameraRig
	rig.set_safe_margins(UiScale.safe_margins(window, rect, root.get_visible_rect().size))
	rig.set_profile(rig.mobile_profile if mobile else rig.desktop_profile)

	# 4 comandas deterministas y congeladas con paciencia alta.
	var catalog: OrderCatalog = level.get("order_catalog") as OrderCatalog
	for order: OrderData in catalog.orders:
		order.max_time = 900.0
	rm.get("round_state").call("advance", _config.first_order_delay)
	await _frames(4)
	rm.set_process(false)

	var p1: Player = level.get_node("Characters/Player1") as Player
	var p2: Player = level.get_node("Characters/Player2") as Player
	var hold1: HoldComponent = p1.get_node("%HoldComponent") as HoldComponent
	var hold2: HoldComponent = p2.get_node("%HoldComponent") as HoldComponent
	var actor1: InteractionComponent = p1.get_node("%InteractionComponent") as InteractionComponent
	var items: Node = level.get_node("Items")

	# 1. Olla 1 (Kitchen): pulpo cociendo al ~60 % con anillo y vapor.
	var kitchen1: CookingStation = level.get_node("Stations/Kitchen") as CookingStation
	var raw_in_pot1: Ingredient = _spawn_octopus(items, "raw")
	hold1.pick_up(raw_in_pot1)
	kitchen1.interact(actor1)
	kitchen1._physics_process(3.0)
	kitchen1.set_physics_process(false)

	# 2. Olla 2 (Kitchen2): pulpo cocido listo (anillo READY).
	var kitchen2: CookingStation = level.get_node("Stations/Kitchen2") as CookingStation
	var raw_in_pot2: Ingredient = _spawn_octopus(items, "raw")
	hold1.pick_up(raw_in_pot2)
	kitchen2.interact(actor1)
	kitchen2._physics_process(5.5)
	kitchen2.set_physics_process(false)

	# 3. Pulpo crudo y pulpo quemado sobre las encimeras traseras para lectura de estados.
	var raw_counter: Ingredient = _spawn_octopus(items, "raw")
	_freeze_item_at(raw_counter, Vector3(-2.3, 1.26, -4.0))
	var burnt_counter: Ingredient = _spawn_octopus(items, "burnt")
	_freeze_item_at(burnt_counter, Vector3(-0.3, 1.26, -4.0))

	# 4. Cuenco de cachelos con 3 raciones visibles.
	var station: SeasoningStation = level.get_node("Stations/SeasoningStation") as SeasoningStation
	var bowl: CachelosBowl = station.get_node("CachelosBowl") as CachelosBowl
	bowl.stock = 3

	# 5. Cajas en los pasaplatos:
	# - PassSlot02: caja llena con aliño picante (#8F1A14).
	var slot2: Slot = level.get_node("Stations/PassSlot02") as Slot
	var box_hot: Box = _spawn_box(items, 1.0, [HOT])
	slot2.call("_store", box_hot)

	# - PassSlot03: caja a medias (3/6 cortes, fill = 0.5) con contador visible.
	var slot3: Slot = level.get_node("Stations/PassSlot03") as Slot
	var box_half: Box = _spawn_box(items, 0.0, [])
	slot3.call("_store", box_half)
	var cutter: Ingredient = _spawn_octopus(items, "cooked")
	hold1.pick_up(cutter)
	for _c: int in 3:
		box_half.interact(actor1)
	var drop_cutter: Node = hold1.drop()
	if drop_cutter != null:
		drop_cutter.queue_free()

	# - PassSlot04: caja llena con aliño dulce + cachelos (#D6361F + #F2D56B).
	var slot4: Slot = level.get_node("Stations/PassSlot04") as Slot
	var box_sweet_cach: Box = _spawn_box(items, 1.0, [SWEET, CACHELOS])
	slot4.call("_store", box_sweet_cach)

	# 6. Posicionar los 2 cocineros con objetos representativos en la mano:
	# - J2 en cocina con un pulpo cocido (#B8283D) mirando hacia la barra/pasaplatos.
	var cooked_held: Ingredient = _spawn_octopus(items, "cooked")
	hold2.pick_up(cooked_held)
	_place_player(p2, Vector2(-2.5, -1.6), Vector2(-3.3, 0.0))

	# - J1 (activo) frente a la estación de condimentos con caja llena (dulce + cachelos).
	var box_held: Box = _spawn_box(items, 1.0, [SWEET, CACHELOS])
	hold1.pick_up(box_held)
	_place_player(p1, Vector2(-0.4, 1.5), Vector2(0.2, 0.0))

	await _frames(6)
	rig.step(1.0)
	await _frames(4)
	return level


func _spawn_octopus(parent: Node, mode: String) -> Ingredient:
	var octo: Ingredient = OCTOPUS_SCENE.instantiate() as Ingredient
	parent.add_child(octo)
	if mode == "cooked":
		octo.set_cooked()
	elif mode == "burnt":
		octo.set_burnt()
	return octo


func _spawn_box(parent: Node, fill_val: float, seasonings: Array[SeasoningData]) -> Box:
	var box: Box = BOX_SCENE.instantiate() as Box
	box.data = BOX_DATA
	parent.add_child(box)
	if fill_val > 0.0:
		box.set("_ingredient", OCTOPUS_DATA)
		box.fill = fill_val
		box.fill_changed.emit(fill_val)
	for s: SeasoningData in seasonings:
		box.apply_seasoning(s)
	return box


func _freeze_item_at(item: RigidBody3D, pos: Vector3) -> void:
	item.collision_layer = 0
	item.linear_velocity = Vector3.ZERO
	item.angular_velocity = Vector3.ZERO
	item.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	item.freeze = true
	item.global_position = pos


func _place_player(player: Player, stand: Vector2, aim: Vector2) -> void:
	var d: Vector2 = aim - stand
	player.global_position = Vector3(stand.x, 0.005, stand.y)
	player.velocity = Vector3.ZERO
	player.rotation = Vector3(0.0, atan2(-d.x, -d.y), 0.0)


func _record_positions(level: Node3D, key: String) -> void:
	var cam: Camera3D = root.get_camera_3d()
	var scale_y: float = root.get_final_transform().get_scale().y
	var nodes: Dictionary = {
		"OrderStand1": level.get_node("Stations/OrderStand1") as Node3D,
		"OrderStand2": level.get_node("Stations/OrderStand2") as Node3D,
		"OrderStand3": level.get_node("Stations/OrderStand3") as Node3D,
		"OrderStand4": level.get_node("Stations/OrderStand4") as Node3D,
		"Kitchen": level.get_node("Stations/Kitchen") as Node3D,
		"Kitchen2": level.get_node("Stations/Kitchen2") as Node3D,
		"Bar_SeasoningStation": level.get_node("Stations/SeasoningStation") as Node3D,
		"Player1": level.get_node("Characters/Player1") as Node3D,
		"Player2": level.get_node("Characters/Player2") as Node3D,
	}
	var entry: Dictionary = {
		"camera_pos": _vec3_arr(cam.global_position),
		"camera_rot_deg": _vec3_arr(cam.global_rotation_degrees),
		"camera_ortho_size": snappedf(cam.size, 0.01),
		"elements": {}
	}
	for label: String in nodes.keys():
		var n: Node3D = nodes[label] as Node3D
		var screen_pt: Vector2 = cam.unproject_position(n.global_position) * scale_y
		entry["elements"][label] = {
			"world_xyz": _vec3_arr(n.global_position),
			"screen_xy_px": [snappedf(screen_pt.x, 0.1), snappedf(screen_pt.y, 0.1)],
		}
	_positions[key] = entry


func _vec3_arr(v: Vector3) -> Array[float]:
	return [snappedf(v.x, 0.01), snappedf(v.y, 0.01), snappedf(v.z, 0.01)]


# --- Prototipo en el motor de las 3 direcciones minimalistas -----------------------------------


func _flat(
	hex: String,
	rough: float = 0.88,
	metal: float = 0.0,
	alpha: float = 1.0,
	emission_hex: String = "",
	emission_energy: float = 0.0
) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	var col: Color = Color(hex)
	col.a = alpha
	mat.albedo_color = col
	mat.roughness = rough
	mat.metallic = metal
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	if alpha < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission_hex != "":
		mat.emission_enabled = true
		mat.emission = Color(emission_hex)
		mat.emission_energy_multiplier = emission_energy
	return mat


func _apply_minimal_style(level: Node3D, style_id: String) -> void:
	_configure_environment_and_lights(level, style_id)
	_hide_props_for_style(level, style_id)
	var table: Dictionary = _build_material_table(style_id)
	_override_all_meshes(level, style_id, table)
	_enhance_dispensers_and_stands(level, style_id)
	_style_ui(level, style_id)


func _configure_environment_and_lights(level: Node3D, style_id: String) -> void:
	var env_node: Node3D = level.get_node("Environment") as Node3D
	var world_env: WorldEnvironment = env_node.get_node("WorldEnvironment") as WorldEnvironment
	var env: Environment = world_env.environment.duplicate(true) as Environment
	world_env.environment = env
	world_env.camera_attributes = null

	var sun: DirectionalLight3D = env_node.get_node("Sun") as DirectionalLight3D
	var bulbs: Node3D = env_node.get_node("Bulbs") as Node3D
	var vignette: CanvasLayer = env_node.get_node("Vignette") as CanvasLayer
	bulbs.visible = false
	vignette.visible = false
	env.adjustment_color_correction = null

	if style_id == "dir_a":
		# Dirección A · Feira Clara: luz cálida diurna con sombras suaves, sin bombillas ni viñeta.
		sun.light_color = Color("#FFF4E0")
		sun.light_energy = 1.18
		sun.shadow_blur = 3.2
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color("#4FA05A")
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color("#EDE8DF")
		env.ambient_light_energy = 0.72
		env.ssao_enabled = true
		env.ssao_radius = 0.45
		env.ssao_intensity = 1.1
		env.glow_enabled = false
		env.adjustment_enabled = true
		env.adjustment_contrast = 1.05
		env.adjustment_saturation = 1.05
	elif style_id == "dir_b":
		# Dirección B · Bloques de Romería: geometría pura sobre vacío pizarra, sombras duras, sin SSAO.
		sun.light_color = Color("#FFFFFF")
		sun.light_energy = 1.15
		sun.shadow_blur = 0.15
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color("#18222C")
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color("#D4DAE0")
		env.ambient_light_energy = 0.78
		env.ssao_enabled = false
		env.glow_enabled = false
		env.adjustment_enabled = true
		env.adjustment_contrast = 1.12
		env.adjustment_saturation = 1.08
	elif style_id == "dir_c":
		# Dirección C · Maqueta de Papel: estudio blanco difuso con SSAO marcado en pliegues.
		sun.light_color = Color("#FFFFFF")
		sun.light_energy = 1.05
		sun.shadow_blur = 2.6
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color("#E4DFD5")
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color("#F7F4EC")
		env.ambient_light_energy = 0.85
		env.ssao_enabled = true
		env.ssao_radius = 0.65
		env.ssao_intensity = 2.8
		env.ssao_light_affect = 0.35
		env.glow_enabled = false
		env.adjustment_enabled = true
		env.adjustment_contrast = 1.06
		env.adjustment_saturation = 1.04


func _hide_props_for_style(level: Node3D, style_id: String) -> void:
	# En las 3 direcciones desaparecen decals de suelo (charcos/rodadas), guirnaldas,
	# atrezo de encimeras (tablas/jarras), desorden industrial trasero y etiquetas obsoletas D25.
	var common_hide: Array[String] = [
		"Environment/Model/GroundWest/ground_w/ground_w_decals",
		"Environment/Model/GroundEast/ground_e/ground_e_decals",
		"Environment/Model/BackWest/back_w/back_w_props",
		"Environment/Model/BackEast/back_e/back_e_props",
		"Environment/Model/BackWest/back_w/back_w_fence",
		"Environment/Model/BackEast/back_e/back_e_fence",
		"Environment/Model/Tent/tent/tent_bulbs",
		"Environment/Model/PropsWest/props_w/props_w_garlands",
		"Environment/Model/PropsEast/props_e/props_e_garlands",
		"Environment/Model/PropsWest/props_w/props_w_props",
		"Environment/Model/PropsEast/props_e/props_e_props",
		"KitchenLayout/BackCounter/BackBetweenStoragePot/Model/props_crock",
		"KitchenLayout/BackCounter/BackRight/Model/props_board",
		"KitchenLayout/BackCounter/BackRight/Model/props_crock",
		"KitchenLayout/Walls/WallLeftKitchen/Model/props_crock",
		"KitchenLayout/Walls/WallRight/Model/props_board",
		"Stations/Kitchen/Model/Pot/pot/gas_bottle",
		"Stations/Kitchen2/Model/Pot/pot/gas_bottle",
		"Stations/OctopusStorage/Model/octopus_storage/pump",
		"Stations/BoxShelf/Model/box_shelf/cartons",
		"Stations/BoxShelf/Model/box_shelf/SizePanel_large",
		"Stations/BoxShelf/Model/box_shelf/SizePanel_medium",
		"Stations/BoxShelf/Model/box_shelf/SizePanel_small",
		"Stations/BoxShelf/Model/box_shelf/labels",
		"Stations/SeasoningStation/Model/seasoning_station/CounterArrow_oil",
		"Stations/SeasoningStation/Model/seasoning_station/CounterArrow_salt",
		"Stations/SeasoningStation/Model/seasoning_station/Label_oil",
		"Stations/SeasoningStation/Model/seasoning_station/Label_salt",
		"Stations/SeasoningStation/Model/seasoning_station/ServiceArrow_oil",
		"Stations/SeasoningStation/Model/seasoning_station/ServiceArrow_salt",
	]
	for p: String in common_hide:
		var n: Node3D = level.get_node_or_null(p) as Node3D
		if n != null:
			n.visible = false

	if style_id == "dir_b":
		# Dirección B (Geometría pura): elimina todo el entorno exterior Z3, rejillas y tapas de ollas.
		var dir_b_hide: Array[String] = [
			"Environment/Model/GroundWest",
			"Environment/Model/GroundEast",
			"Environment/Model/BackWest",
			"Environment/Model/BackEast",
			"Environment/Model/Tent",
			"Environment/Model/PropsWest",
			"Environment/Model/PropsEast",
			"KitchenLayout/Floor/Grates",
			"Stations/Kitchen/Model/Pot/pot/lid",
			"Stations/Kitchen2/Model/Pot/pot/lid",
		]
		for p: String in dir_b_hide:
			var n: Node3D = level.get_node_or_null(p) as Node3D
			if n != null:
				n.visible = false
		# Recorta el suelo jugable exactamente al perímetro de la isla de cocina/servicio.
		var floor_mesh: MeshInstance3D = (
			level.get_node("KitchenLayout/Floor/Mesh") as MeshInstance3D
		)
		var plane: PlaneMesh = PlaneMesh.new()
		plane.size = Vector2(15.6, 10.6)
		floor_mesh.mesh = plane
		floor_mesh.position = Vector3(0.78, 0.0, 2.52)


func _build_material_table(style_id: String) -> Dictionary:
	# Colores de comida y condimentos (§3.4) compartidos en las 3 direcciones.
	var common: Dictionary = {
		"mat_food_octopus_raw": _flat("#E0AFB2", 0.65),
		"mat_food_octopus_cooked": _flat("#B8283D", 0.55),
		"mat_food_octopus_pieces": _flat("#B8283D", 0.55),
		"mat_food_octopus_burnt": _flat("#2A2320", 0.95),
		"mat_food_potato_raw": _flat("#8E6B47", 0.85),
		"mat_food_potato_cooked": _flat("#F2D56B", 0.65),
		"mat_food_potato_burnt": _flat("#2A2320", 0.95),
		"atlas_octopus": _flat("#B8283D", 0.60),
		"atlas_cachelos": _flat("#F2D56B", 0.65),
		"mat_cloth_player_1": _flat("#2F6FB5", 0.85),
		"mat_cloth_player_2": _flat("#F2C230", 0.85),
		"mat_cloth_shirt": _flat("#F7F4EC", 0.90),
		"mat_cloth_pants": _flat("#1D3557", 0.90),
		"mat_skin_light": _flat("#E0AFB2", 0.80),
		"mat_skin_dark": _flat("#8E6B47", 0.80),
		"mat_cook_atlas": _flat("#1D3557", 0.85),
	}

	if style_id == "dir_a":
		# Dirección A · Feira Clara (16 colores hex)
		var a: Dictionary = {
			"kitchen_floor_dirt": _flat("#C4A882", 0.92),
			"mat_ground_dirt": _flat("#C4A882", 0.92),
			"mat_grass": _flat("#4FA05A", 0.92),
			"env_fern": _flat("#4FA05A", 0.90),
			"env_foliage": _flat("#4FA05A", 0.90),
			"mat_granite": _flat("#8C96A0", 0.88),
			"mat_steel_brushed_top": _flat("#EDE8DF", 0.82),
			"mat_steel_brushed": _flat("#8C96A0", 0.82),
			"mat_steel_brushed_mid": _flat("#8C96A0", 0.85),
			"mat_steel_dark": _flat("#1D3557", 0.88),
			"counters_atlas": _flat("#8C96A0", 0.85),
			"order_stand_atlas": _flat("#1D3557", 0.88),
			"seasoning_station_atlas": _flat("#EDE8DF", 0.82),
			"mat_plastic_red": _flat("#C8402F", 0.65),
			"mat_plastic_blue": _flat("#2F6FB5", 0.65),
			"mat_canvas_red": _flat("#C8402F", 0.88),
			"mat_canvas_paper": _flat("#F7F4EC", 0.90),
			"mat_canvas_stand_1": _flat("#C8402F", 0.85),
			"mat_canvas_stand_2": _flat("#2F6FB5", 0.85),
			"mat_canvas_stand_3": _flat("#F2C230", 0.85),
			"mat_canvas_stand_4": _flat("#4FA05A", 0.85),
			"mat_food_tray_liner": _flat("#EDE8DF", 0.90),
			"atlas_box": _flat("#EDE8DF", 0.90),
			"mat_burlap": _flat("#8E6B47", 0.90),
			"atlas_cachelos_storage": _flat("#8E6B47", 0.90),
			"mat_clay": _flat("#8E6B47", 0.82),
			"mat_wood_used": _flat("#8E6B47", 0.85),
			"mat_wood_dark": _flat("#8E6B47", 0.88),
			"mat_cardboard": _flat("#C4A882", 0.90),
			"mat_rubber": _flat("#2A2320", 0.90),
			"mat_rubber_hose_red": _flat("#C8402F", 0.85),
			"mat_rubber_hose_green": _flat("#4FA05A", 0.85),
			"mat_glass_water": _flat("#2F6FB5", 0.30, 0.0, 0.45),
			"pot_water": _flat("#2F6FB5", 0.35),
			"mat_emissive_bulb": _flat("#F2C230", 0.50, 0.0, 1.0, "#F2C230", 0.8),
			"mat_emissive_screen": _flat("#EDE8DF", 0.50),
			"env_board": _flat("#1D3557", 0.88),
			"env_sign": _flat("#1D3557", 0.88),
			"env_atlas": _flat("#8C96A0", 0.88),
			"counter_pass_signs": _flat("#F2C230", 0.80),
		}
		a.merge(common)
		return a

	if style_id == "dir_b":
		# Dirección B · Bloques de Romería (14 colores hex)
		var b: Dictionary = {
			"kitchen_floor_dirt": _flat("#D4DAE0", 0.95),
			"mat_ground_dirt": _flat("#18222C", 0.98),
			"mat_grass": _flat("#18222C", 0.98),
			"mat_granite": _flat("#18222C", 0.98),
			"mat_steel_brushed_top": _flat("#EFECE6", 0.92),
			"mat_steel_brushed": _flat("#1D3557", 0.92),
			"mat_steel_brushed_mid": _flat("#1D3557", 0.92),
			"mat_steel_dark": _flat("#18222C", 0.95),
			"counters_atlas": _flat("#1D3557", 0.92),
			"order_stand_atlas": _flat("#1D3557", 0.92),
			"seasoning_station_atlas": _flat("#EFECE6", 0.92),
			"mat_plastic_red": _flat("#D6361F", 0.85),
			"mat_plastic_blue": _flat("#2F6FB5", 0.85),
			"mat_canvas_red": _flat("#D6361F", 0.92),
			"mat_canvas_paper": _flat("#EFECE6", 0.92),
			"mat_canvas_stand_1": _flat("#D6361F", 0.90),
			"mat_canvas_stand_2": _flat("#2F6FB5", 0.90),
			"mat_canvas_stand_3": _flat("#F2C230", 0.90),
			"mat_canvas_stand_4": _flat("#4FA05A", 0.90),
			"mat_food_tray_liner": _flat("#EFECE6", 0.92),
			"atlas_box": _flat("#EFECE6", 0.92),
			"mat_burlap": _flat("#8E6B47", 0.92),
			"atlas_cachelos_storage": _flat("#8E6B47", 0.92),
			"mat_clay": _flat("#1D3557", 0.92),
			"mat_wood_used": _flat("#1D3557", 0.92),
			"mat_wood_dark": _flat("#18222C", 0.95),
			"mat_cardboard": _flat("#1D3557", 0.92),
			"mat_rubber": _flat("#18222C", 0.95),
			"mat_glass_water": _flat("#2F6FB5", 0.40, 0.0, 0.55),
			"pot_water": _flat("#2F6FB5", 0.50),
			"mat_emissive_bulb": _flat("#F2C230", 0.80),
			"mat_emissive_screen": _flat("#EFECE6", 0.80),
			"counter_pass_signs": _flat("#F2C230", 0.90),
			"mat_food_octopus_burnt": _flat("#18222C", 0.98),
			"mat_food_potato_burnt": _flat("#18222C", 0.98),
		}
		for k: String in common.keys():
			if not b.has(k):
				b[k] = common[k]
		return b

	# Dirección C · Maqueta de Papel (15 colores hex)
	var c: Dictionary = {
		"kitchen_floor_dirt": _flat("#E4DFD5", 0.95),
		"mat_ground_dirt": _flat("#E4DFD5", 0.95),
		"mat_grass": _flat("#E4DFD5", 0.95),
		"env_fern": _flat("#CBC5B9", 0.95),
		"env_foliage": _flat("#CBC5B9", 0.95),
		"mat_granite": _flat("#CBC5B9", 0.95),
		"mat_steel_brushed_top": _flat("#F7F4EC", 0.92),
		"mat_steel_brushed": _flat("#CBC5B9", 0.92),
		"mat_steel_brushed_mid": _flat("#CBC5B9", 0.92),
		"mat_steel_dark": _flat("#2A2320", 0.92),
		"counters_atlas": _flat("#CBC5B9", 0.92),
		"order_stand_atlas": _flat("#F7F4EC", 0.92),
		"seasoning_station_atlas": _flat("#F7F4EC", 0.92),
		"mat_plastic_red": _flat("#C8402F", 0.75),
		"mat_plastic_blue": _flat("#CBC5B9", 0.90),
		"mat_canvas_red": _flat("#CBC5B9", 0.92),
		"mat_canvas_paper": _flat("#F7F4EC", 0.95),
		"mat_canvas_stand_1": _flat("#C8402F", 0.85),
		"mat_canvas_stand_2": _flat("#2F6FB5", 0.85),
		"mat_canvas_stand_3": _flat("#F2C230", 0.85),
		"mat_canvas_stand_4": _flat("#4FA05A", 0.85),
		"mat_food_tray_liner": _flat("#F7F4EC", 0.95),
		"atlas_box": _flat("#F7F4EC", 0.95),
		"mat_burlap": _flat("#CBC5B9", 0.92),
		"atlas_cachelos_storage": _flat("#CBC5B9", 0.92),
		"mat_clay": _flat("#2A2320", 0.90),
		"mat_wood_used": _flat("#F7F4EC", 0.92),
		"mat_wood_dark": _flat("#CBC5B9", 0.92),
		"mat_cardboard": _flat("#E4DFD5", 0.92),
		"mat_rubber": _flat("#2A2320", 0.92),
		"mat_glass_water": _flat("#2F6FB5", 0.35, 0.0, 0.45),
		"pot_water": _flat("#2F6FB5", 0.40),
		"mat_emissive_bulb": _flat("#F2C230", 0.80),
		"mat_emissive_screen": _flat("#F7F4EC", 0.90),
		"env_board": _flat("#2A2320", 0.92),
		"env_sign": _flat("#CBC5B9", 0.92),
		"env_atlas": _flat("#CBC5B9", 0.92),
		"counter_pass_signs": _flat("#2A2320", 0.90),
	}
	c.merge(common)
	return c


func _override_all_meshes(level: Node3D, style_id: String, table: Dictionary) -> void:
	for node: Node in level.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.mesh == null:
			continue
		var rel_path: String = str(level.get_path_to(mi))
		if rel_path.contains("OutlineHull"):
			continue
		if rel_path == "KitchenLayout/Floor/Mesh":
			mi.material_override = table["kitchen_floor_dirt"]
			continue
		# Mesas de comensales del fondo (Z3) en Dirección C: maqueta monocroma sin comida roja.
		if style_id == "dir_c" and rel_path.contains("props_") and rel_path.contains("_tables"):
			for s: int in mi.mesh.get_surface_count():
				mi.set_surface_override_material(s, _flat("#F7F4EC", 0.95))
			continue

		for s: int in mi.mesh.get_surface_count():
			var active: Material = mi.get_active_material(s)
			if active == null or active is ShaderMaterial:
				continue
			if active is StandardMaterial3D:
				var sm: StandardMaterial3D = active as StandardMaterial3D
				if (
					sm.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA
					and sm.albedo_color.a < 0.05
				):
					continue
			var mname: String = active.resource_name
			if mname == "":
				mname = active.resource_path.get_file().get_basename()
			# Conserva el cartel de marca PulpaSA en el toldo.
			if mname == "env_plate":
				continue
			if table.has(mname):
				mi.set_surface_override_material(s, table[mname])


func _enhance_dispensers_and_stands(level: Node3D, style_id: String) -> void:
	# Placas y colores de §3.4 en la estación de condimentos con contraste >= 3:1 garantizado.
	var station: Node3D = level.get_node("Stations/SeasoningStation") as Node3D
	var light_top: String = "#EDE8DF"
	if style_id == "dir_b":
		light_top = "#EFECE6"
	elif style_id == "dir_c":
		light_top = "#F7F4EC"
	var dark_support: String = "#1D3557"
	if style_id == "dir_c":
		dark_support = "#2A2320"

	# Alfombrilla de estación como placa clara bajo los dos aliños oscuros (#D6361F y #8F1A14).
	var service_mat: MeshInstance3D = (
		station.get_node_or_null("Model/seasoning_station/ServiceMat") as MeshInstance3D
	)
	if service_mat != null:
		service_mat.set_surface_override_material(0, _flat(light_top, 0.90))

	# Flechas/etiquetas activas (sweet, hot, potato) con su color exacto de §3.4.
	var sweet_mat: StandardMaterial3D = _flat("#D6361F", 0.75)
	var hot_mat: StandardMaterial3D = _flat("#8F1A14", 0.75)
	var potato_mat: StandardMaterial3D = _flat("#F2D56B", 0.75)
	for suffix: String in ["CounterArrow_", "Label_", "ServiceArrow_"]:
		var ms: MeshInstance3D = (
			station.get_node_or_null("Model/seasoning_station/" + suffix + "sweet")
			as MeshInstance3D
		)
		if ms != null:
			ms.set_surface_override_material(0, sweet_mat)
		var mh: MeshInstance3D = (
			station.get_node_or_null("Model/seasoning_station/" + suffix + "hot") as MeshInstance3D
		)
		if mh != null:
			mh.set_surface_override_material(0, hot_mat)
		var mp: MeshInstance3D = (
			station.get_node_or_null("Model/seasoning_station/" + suffix + "potato")
			as MeshInstance3D
		)
		if mp != null:
			mp.set_surface_override_material(0, potato_mat)

	var fascia: MeshInstance3D = (
		station.get_node_or_null("Model/seasoning_station/ServiceFascia") as MeshInstance3D
	)
	if fascia != null:
		fascia.set_surface_override_material(0, _flat(dark_support, 0.90))

	# Cuerpos cilíndricos limpios en los dispensadores dulce (#D6361F) y picante (#8F1A14).
	var sweet_disp: Node3D = station.get_node("Dispensers/SweetDressing") as Node3D
	var hot_disp: Node3D = station.get_node("Dispensers/HotDressing") as Node3D
	_add_clean_dispenser_body(sweet_disp, "#D6361F", light_top)
	_add_clean_dispenser_body(hot_disp, "#8F1A14", light_top)

	# Placa del número y comanda en los 4 puestos de entrega (corrige D1 de PUL-087 en minimalismo).
	for i: int in range(1, 5):
		var stand: Node3D = level.get_node("Stations/OrderStand%d" % i) as Node3D
		var frame: MeshInstance3D = (
			stand.get_node_or_null("Model/order_stand/OrderPlateFrame") as MeshInstance3D
		)
		var paper: MeshInstance3D = (
			stand.get_node_or_null("Model/order_stand/OrderPlatePaper") as MeshInstance3D
		)
		if frame != null:
			frame.set_surface_override_material(0, _flat(dark_support, 0.90))
		if paper != null:
			paper.set_surface_override_material(0, _flat("#F7F4EC", 0.92))
		var num_lbl: Label3D = stand.get_node_or_null("StandNumber") as Label3D
		if num_lbl != null:
			num_lbl.modulate = Color("#1D3557" if style_id != "dir_c" else "#2A2320")
		var ord_lbl: Label3D = stand.get_node_or_null("OrderLabel") as Label3D
		if ord_lbl != null:
			ord_lbl.modulate = Color("#F7F4EC")
			ord_lbl.outline_modulate = Color(dark_support)
			ord_lbl.outline_size = 14


func _add_clean_dispenser_body(disp: Node3D, hex_body: String, hex_collar: String) -> void:
	var collar: MeshInstance3D = MeshInstance3D.new()
	var collar_mesh: CylinderMesh = CylinderMesh.new()
	collar_mesh.top_radius = 0.22
	collar_mesh.bottom_radius = 0.24
	collar_mesh.height = 0.03
	collar.mesh = collar_mesh
	collar.material_override = _flat(hex_collar, 0.90)
	collar.position = Vector3(0.0, 0.015, 0.45)
	disp.add_child(collar)

	var body: MeshInstance3D = MeshInstance3D.new()
	var body_mesh: CylinderMesh = CylinderMesh.new()
	body_mesh.top_radius = 0.14
	body_mesh.bottom_radius = 0.15
	body_mesh.height = 0.24
	body.mesh = body_mesh
	body.material_override = _flat(hex_body, 0.70)
	body.position = Vector3(0.0, 0.13, 0.45)
	disp.add_child(body)


func _style_ui(level: Node3D, style_id: String) -> void:
	var ui: Node = level.get_node("UI")
	var panel_bg: Color = Color("#1D3557")
	var header_bg: Color = Color("#2A2320")
	var border_col: Color = Color("#EDE8DF")
	var well_bg: Color = Color("#2A2320")
	var text_col: Color = Color("#F7F4EC")

	if style_id == "dir_b":
		panel_bg = Color("#18222C")
		header_bg = Color("#1D3557")
		border_col = Color("#EFECE6")
		well_bg = Color("#1D3557")
		text_col = Color("#F7F4EC")
	elif style_id == "dir_c":
		panel_bg = Color("#F7F4EC")
		header_bg = Color("#1D3557")
		border_col = Color("#2A2320")
		well_bg = Color("#2A2320")
		text_col = Color("#2A2320")

	var panel_box: StyleBoxFlat = StyleBoxFlat.new()
	panel_box.bg_color = panel_bg
	panel_box.border_color = border_col
	panel_box.set_border_width_all(2)
	panel_box.set_corner_radius_all(4 if style_id != "dir_b" else 0)
	panel_box.set_content_margin_all(8)

	var header_box: StyleBoxFlat = StyleBoxFlat.new()
	header_box.bg_color = header_bg
	header_box.set_corner_radius_all(2 if style_id != "dir_b" else 0)
	header_box.set_content_margin_all(6)

	var well_box: StyleBoxFlat = StyleBoxFlat.new()
	well_box.bg_color = well_bg
	well_box.set_corner_radius_all(2 if style_id != "dir_b" else 0)
	well_box.set_content_margin_all(4)

	for node: Node in ui.find_children("*", "PanelContainer", true, false):
		var pc: PanelContainer = node as PanelContainer
		if pc.theme_type_variation == &"UiPanel":
			pc.add_theme_stylebox_override(&"panel", panel_box)
		elif pc.theme_type_variation == &"UiHeader":
			pc.add_theme_stylebox_override(&"panel", header_box)
		elif pc.theme_type_variation == &"DisplayWell":
			pc.add_theme_stylebox_override(&"panel", well_box)

	if style_id == "dir_c":
		# En Maqueta de Papel el cuerpo del ticket es papel (#F7F4EC); textos en grafito (#2A2320).
		for node: Node in ui.find_children("*", "Label", true, false):
			var lbl: Label = node as Label
			var p: String = str(ui.get_path_to(lbl))
			if not p.contains("Header") and not p.contains("Well"):
				lbl.add_theme_color_override(&"font_color", text_col)
