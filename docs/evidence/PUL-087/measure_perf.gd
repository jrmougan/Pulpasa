extends SceneTree
## Medición de rendimiento de la estética v2 (PUL-087, biblia v2 §4.3). No forma parte del juego.
## Arranca una partida real con GameState.start_level, mueve a los jugadores con acciones del
## InputMap (andar, coger/soltar) y mide cada frame sin vsync ni límite de fps.
## Uso (desde la raíz del repo):
##   xvfb-run -a godot --audio-driver Dummy --path godot --resolution 1920x1080 \
##     -s "$PWD/docs/evidence/PUL-087/measure_perf.gd" \
##     -- <salida.json> <tilt 0|1> <segundos> <modo 0|1> [apagar]
## [apagar]: lista separada por comas para aislar costes: ssao, glow, adjust, dir_shadow,
## omni, omni_shadow, msaa (no cambia nada del proyecto; solo esta ejecución).

const RENDER_CONFIG := "res://data/config/render_config.tres"
const WARMUP_FRAMES := 240
const MOVES: Array[String] = ["move_up", "move_down", "move_left", "move_right"]

var _out: String
var _tilt: bool
var _seconds: float
var _mode: int
var _off: PackedStringArray = []
var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0]
	_tilt = args[1] == "1"
	_seconds = float(args[2])
	_mode = int(args[3])
	if args.size() > 4:
		_off = args[4].split(",", false)
	_rng.seed = 87
	_run.call_deferred()


func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var game_state: Node = root.get_node("GameState")
	game_state.call("start_level", _mode)
	for i in 10:
		await process_frame
	var level: Node = current_scene
	var env: Node = level.get_node("Environment")
	var cfg: Resource = (load(RENDER_CONFIG) as Resource).duplicate()
	cfg.set("tilt_shift_enabled", _tilt)
	cfg.set("environment", (cfg.get("environment") as Environment).duplicate())
	_strip(cfg.get("environment") as Environment, level)
	env.call("apply", cfg)
	var vp: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	for i in WARMUP_FRAMES:
		await process_frame
	var frame_ms: Array[float] = []
	var gpu_ms: Array[float] = []
	var cpu_render_ms: Array[float] = []
	var draw_calls: Array[float] = []
	var primitives: Array[float] = []
	var objects: Array[float] = []
	var start: int = Time.get_ticks_usec()
	var last: int = start
	var next_input: int = 0
	var shots := 0
	while Time.get_ticks_usec() - start < int(_seconds * 1_000_000.0):
		var now: int = Time.get_ticks_usec()
		if now >= next_input:
			_drive()
			next_input = now + 400_000
		await process_frame
		now = Time.get_ticks_usec()
		frame_ms.append((now - last) / 1000.0)
		last = now
		gpu_ms.append(RenderingServer.viewport_get_measured_render_time_gpu(vp))
		cpu_render_ms.append(RenderingServer.viewport_get_measured_render_time_cpu(vp))
		draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		primitives.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
		objects.append(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
		if shots == 0 and now - start > int(_seconds * 500_000.0):
			shots = 1
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(_out.get_basename() + ".png")
	for action: String in _all_actions():
		Input.action_release(action)
	var report := {
		"tilt_shift": _tilt,
		"mode": _mode,
		"off": _off,
		"resolution": root.get_visible_rect().size,
		"adapter": RenderingServer.get_video_adapter_name(),
		"frames": frame_ms.size(),
		"fps_avg": frame_ms.size() / (_sum(frame_ms) / 1000.0),
		"frame_ms": _stats(frame_ms),
		"gpu_ms": _stats(gpu_ms),
		"cpu_render_ms": _stats(cpu_render_ms),
		"draw_calls": _stats(draw_calls),
		"primitives": _stats(primitives),
		"objects": _stats(objects),
		"video_mem_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		"texture_mem_mb": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
		"buffer_mem_mb": Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / 1048576.0,
		"scene": _scene_counts(current_scene),
	}
	var f := FileAccess.open(_out, FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	print(JSON.stringify(report))
	quit()


func _strip(e: Environment, level: Node) -> void:
	e.ssao_enabled = e.ssao_enabled and not _off.has("ssao")
	e.glow_enabled = e.glow_enabled and not _off.has("glow")
	e.adjustment_enabled = e.adjustment_enabled and not _off.has("adjust")
	for node: Node in level.find_children("*", "Light3D", true, false):
		var light := node as Light3D
		if light is DirectionalLight3D and _off.has("dir_shadow"):
			light.shadow_enabled = false
		elif light is OmniLight3D and _off.has("omni"):
			light.visible = false
		elif light is OmniLight3D and _off.has("omni_shadow"):
			light.shadow_enabled = false


## Cada 0,4 s cambia la dirección de cada jugador y a veces pulsa interactuar.
func _drive() -> void:
	var players: Array[String] = ["p1_"]
	if _mode == 1:
		players.append("p2_")
	for prefix: String in players:
		for move: String in MOVES:
			Input.action_release(prefix + move)
		Input.action_press(prefix + MOVES[_rng.randi_range(0, MOVES.size() - 1)])
		if _rng.randf() < 0.3:
			Input.action_press(prefix + "interact")
		else:
			Input.action_release(prefix + "interact")
	if _mode == 0 and _rng.randf() < 0.1:
		Input.action_press("p1_switch")
	else:
		Input.action_release("p1_switch")


func _all_actions() -> Array[String]:
	var out: Array[String] = ["p1_switch"]
	for prefix: String in ["p1_", "p2_"]:
		out.append(prefix + "interact")
		for move: String in MOVES:
			out.append(prefix + move)
	return out


## Materiales distintos, superficies, mallas y luces de la escena (visibles en el árbol) y la
## parte de ellas dentro del frustum de la cámara activa (aprox. por AABB).
func _scene_counts(scene: Node) -> Dictionary:
	var cam: Camera3D = root.get_camera_3d()
	var mats := {}
	var mats_on_screen := {}
	var surfaces := 0
	var meshes := 0
	var omni := 0
	var omni_shadow := 0
	var spot := 0
	var dir := 0
	var tris := 0
	for node: Node in scene.find_children("*", "VisualInstance3D", true, false):
		var vi := node as VisualInstance3D
		if not vi.is_visible_in_tree():
			continue
		if vi is OmniLight3D:
			omni += 1
			if (vi as Light3D).shadow_enabled:
				omni_shadow += 1
		elif vi is SpotLight3D:
			spot += 1
		elif vi is DirectionalLight3D:
			dir += 1
		var mi := vi as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		meshes += 1
		tris += mi.mesh.get_faces().size() / 3
		var aabb: AABB = mi.global_transform * mi.get_aabb()
		var on_screen: bool = cam != null and _aabb_in_frustum(cam, aabb)
		for s in mi.mesh.get_surface_count():
			surfaces += 1
			var mat: Material = mi.material_override
			if mat == null:
				mat = mi.get_surface_override_material(s)
			if mat == null:
				mat = mi.mesh.surface_get_material(s)
			if mat == null:
				continue
			mats[mat.get_rid()] = true
			if on_screen:
				mats_on_screen[mat.get_rid()] = true
	return {
		"mesh_instances": meshes,
		"surfaces": surfaces,
		"triangles_scene": tris,
		"materials_distinct": mats.size(),
		"materials_on_screen": mats_on_screen.size(),
		"omni_lights": omni,
		"omni_lights_shadow": omni_shadow,
		"spot_lights": spot,
		"directional_lights": dir,
	}


func _aabb_in_frustum(cam: Camera3D, aabb: AABB) -> bool:
	for i in 8:
		if cam.is_position_in_frustum(aabb.get_endpoint(i)):
			return true
	return cam.is_position_in_frustum(aabb.get_center())


func _sum(values: Array[float]) -> float:
	var total := 0.0
	for v: float in values:
		total += v
	return total


func _stats(values: Array[float]) -> Dictionary:
	var sorted: Array[float] = values.duplicate()
	sorted.sort()
	var n: int = sorted.size()
	if n == 0:
		return {}
	return {
		"avg": _sum(sorted) / n,
		"p50": sorted[n / 2],
		"p99": sorted[mini(n - 1, int(n * 0.99))],
		"max": sorted[n - 1],
	}
