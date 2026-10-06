extends SceneTree
## Capturas de PUL-074 (no forma parte del juego; escena temporal construida en memoria).
## Desde la raíz del repo:
## xvfb-run -a godot --audio-driver Dummy --path godot --resolution 1920x1080 \
##   -s "$PWD/docs/evidence/PUL-074/capture_pul074.gd" \
##   -- <lamina|level> "$PWD/docs/evidence/PUL-074"
## Luz neutra provisional (PUL-073 va en paralelo): el coordinador la repite con la luz final.

const V2 := "res://assets/materials/v2/"
const TEST_GLB := "res://assets/models/_pipeline/materials_v2_test/materials_v2_test.glb"
const V1_TO_V2 := {
	"mat_wood_light": "mat_wood_used",
	"mat_wood_mid": "mat_wood_used",
	"mat_wood_dark": "mat_wood_dark",
	"mat_steel_grey": "mat_steel_brushed_top",
	"mat_iron_black": "mat_steel_dark",
	"mat_copper": "mat_copper",
	"mat_copper_dark": "mat_copper",
	"mat_copper_light": "mat_copper",
	"mat_burlap": "mat_burlap",
	"mat_ground_dirt": "mat_ground_dirt",
	"mat_ground_grass": "mat_grass",
	"mat_ground_stone": "mat_granite",
	"mat_canvas_stripe": "mat_canvas_red",
	"mat_canvas_cream": "mat_canvas_paper",
	"mat_bunting_blue": "mat_canvas_stand_2",
	"mat_bunting_green": "mat_canvas_stand_4",
	"mat_bunting_yellow": "mat_canvas_stand_3",
	"mat_lantern_warm": "mat_emissive_bulb",
	"mat_ice_blue": "mat_plastic_blue",
	"mat_octopus_raw": "mat_food_octopus_raw",
	"mat_octopus_raw_dark": "mat_food_octopus_raw",
	"mat_octopus_cooked": "mat_food_octopus_cooked",
	"mat_potato_raw": "mat_food_potato_raw",
	"mat_potato_cooked": "mat_food_potato_cooked",
	"mat_potato_cooked_dark": "mat_food_potato_cooked",
	"mat_cook_shirt": "mat_cloth_shirt",
	"mat_cook_trousers": "mat_cloth_pants",
	"mat_cook_j1_accent": "mat_cloth_player_1",
	"mat_cook_j2_accent": "mat_cloth_player_2",
	"mat_cook_j1_skin": "mat_skin_light",
	"mat_cook_j2_skin": "mat_skin_dark",
	"res://assets/materials/terrain.tres": "mat_ground_dirt",
	"res://assets/materials/ph_wood.tres": "mat_wood_used",
}

var _cache: Dictionary = {}
var _unmapped: Dictionary = {}


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args[0] == "lamina":
		await _lamina(args[1])
	else:
		await _level(args[1])
	quit()


func _v2(mat_name: String, tile_m: float) -> StandardMaterial3D:
	var key: String = "%s@%s" % [mat_name, tile_m]
	if _cache.has(key):
		return _cache[key]
	var m: StandardMaterial3D = (load(V2 + mat_name + ".tres") as StandardMaterial3D).duplicate()
	# Primitivas y mallas v1 no tienen UV a la densidad v2: triplanar en mundo, 1 UV = tile_m.
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / tile_m
	_cache[key] = m
	return m


func _shot(path: String) -> void:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)


func _lamina(out_dir: String) -> void:
	var scene := Node3D.new()
	root.add_child(scene)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	# Cielo gris neutro: los metales necesitan algo que reflejar (con fondo de color salen negros).
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.62, 0.64, 0.67)
	sky_mat.sky_horizon_color = Color(0.72, 0.73, 0.74)
	sky_mat.ground_bottom_color = Color(0.3, 0.3, 0.3)
	sky_mat.ground_horizon_color = Color(0.5, 0.5, 0.5)
	env.environment.background_mode = Environment.BG_SKY
	env.environment.sky = Sky.new()
	env.environment.sky.sky_material = sky_mat
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.environment.ambient_light_energy = 0.7
	env.environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.environment.glow_enabled = true
	env.environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	scene.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-55, -30, 0)
	scene.add_child(sun)
	var files: PackedStringArray = []
	for f: String in DirAccess.get_files_at(V2):
		if f.ends_with(".tres"):
			files.append(f.get_basename())
	files.sort()
	var cols: int = 9
	var px: float = 2.2
	var py: float = 2.4
	var rows: int = int(ceil((files.size() + 5) / float(cols)))
	for i in files.size():
		var mat_name: String = files[i]
		var c := Vector3((i % cols - (cols - 1) / 2.0) * px, 0, (i / cols) * py)
		var tile: float = 4.0 if mat_name == "mat_ground_dirt" else 2.0
		var s := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.45
		sm.height = 0.9
		s.mesh = sm
		s.material_override = _v2(mat_name, tile)
		s.position = c + Vector3(-0.5, 0.45, 0)
		scene.add_child(s)
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.8, 0.8, 0.8)
		b.mesh = bm
		b.material_override = _v2(mat_name, tile)
		b.position = c + Vector3(0.5, 0.4, 0)
		b.rotation_degrees = Vector3(0, -20, 0)
		scene.add_child(b)
		_label(scene, mat_name.trim_prefix("mat_"), c + Vector3(0, 0.01, 0.8))
	# Asset de prueba (AC2), a escala x2.
	var n: int = files.size()
	var inst: Node3D = (load(TEST_GLB) as PackedScene).instantiate()
	var c0 := Vector3((n % cols - (cols - 1) / 2.0) * px, 0, (n / cols) * py)
	inst.position = c0
	inst.scale = Vector3.ONE * 2.0
	scene.add_child(inst)
	_label(scene, "glb de prueba (x2)", c0 + Vector3(0, 0.01, 0.8))
	# Resaltado del juego (highlight_outline) sobre los materiales más claros (§6.1-7).
	var hl: Material = load("res://shaders/highlight_outline.tres")
	var lit: PackedStringArray = [
		"mat_steel_brushed", "mat_steel_brushed_top", "mat_canvas_paper", "mat_ground_dirt"
	]
	for k in lit.size():
		var c := Vector3(((n + 1 + k) % cols - (cols - 1) / 2.0) * px, 0, ((n + 1 + k) / cols) * py)
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.8, 0.8, 0.8)
		b.mesh = bm
		b.material_override = _v2(lit[k], 4.0 if lit[k] == "mat_ground_dirt" else 2.0)
		b.material_overlay = hl
		b.position = c + Vector3(0, 0.4, 0)
		b.rotation_degrees = Vector3(0, -20, 0)
		scene.add_child(b)
		_label(scene, lit[k].trim_prefix("mat_") + "\n+ resaltado", c + Vector3(0, 0.01, 0.85))
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 60)
	ground.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.35, 0.35, 0.35)
	fm.roughness = 0.9
	ground.material_override = fm
	scene.add_child(ground)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	cam.size = cols * px + 0.6
	cam.rotation_degrees = Vector3(-52, 0, 0)
	var center := Vector3(0, 0.3, (rows - 1) * py / 2.0 + 0.3)
	cam.position = center + Vector3(0, sin(deg_to_rad(52)), cos(deg_to_rad(52))) * 30.0
	scene.add_child(cam)
	cam.make_current()
	for i in 20:
		await process_frame
	await _shot(out_dir + "/godot_lamina.png")


func _label(parent: Node3D, text: String, pos: Vector3) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = 40
	l.pixel_size = 0.005
	l.rotation_degrees = Vector3(-90, 0, 0)
	l.position = pos
	parent.add_child(l)


func _level(out_dir: String) -> void:
	var level: Node = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	for i in 60:
		await process_frame
	var ui: Node = level.get_node_or_null("UI")
	if ui != null:
		ui.set("visible", false)
	for hl: Node in level.find_children("*", "Highlightable", true, false):
		var p: String = str(level.get_path_to(hl))
		if p.contains("Kitchen/") or p.contains("SeasoningStation/") or p.contains("OrderStand1/"):
			hl.call("show")
	await _shot(out_dir + "/level_before.png")
	_apply_v2(level)
	await _shot(out_dir + "/level_after.png")
	print("PUL074 sin mapear: ", _unmapped.keys())


func _apply_v2(level: Node) -> void:
	for node: Node in level.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var cur: Material = mi.get_active_material(s)
			if cur == null:
				continue
			var key: String = cur.resource_name if cur.resource_name != "" else cur.resource_path
			if V1_TO_V2.has(key):
				var tile: float = 4.0 if V1_TO_V2[key] == "mat_ground_dirt" else 2.0
				mi.set_surface_override_material(s, _v2(V1_TO_V2[key], tile))
			else:
				_unmapped[key] = true
