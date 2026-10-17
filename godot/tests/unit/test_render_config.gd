extends GutTest
## PUL-073/PUL-183: luz y post-proceso en `render_config.tres` (biblia de arte v3 §4, D28). El
## tilt-shift viene apagado (D22) y `LevelEnvironment` aplica el entorno a su `WorldEnvironment`.

const CONFIG: RenderConfig = preload("res://data/config/render_config.tres")
const ENVIRONMENT_SCENE: PackedScene = preload("res://entities/environment/environment.tscn")
const MAX_OMNI_LIGHTS: int = 6
## Sub-mallas ruidosas de Z1/Z3 que se ocultan (biblia v3 §5.1).
const PRUNED_MESHES: Array[String] = [
	"Model/GroundWest/ground_w/ground_w_decals",
	"Model/GroundEast/ground_e/ground_e_decals",
	"Model/BackWest/back_w/back_w_props",
	"Model/BackEast/back_e/back_e_props",
	"Model/BackWest/back_w/back_w_fence",
	"Model/BackEast/back_e/back_e_fence",
	"Model/Tent/tent/tent_bulbs",
	"Model/PropsWest/props_w/props_w_garlands",
	"Model/PropsEast/props_e/props_e_garlands",
	"Model/PropsWest/props_w/props_w_props",
	"Model/PropsEast/props_e/props_e_props",
]
## Lo que se queda visible en Z3.
const KEPT_MESHES: Array[String] = [
	"Model/Tent/tent/tent_awning",
	"Model/Tent/tent/tent_plate",
	"Model/BackWest/back_w/back_w_wall",
	"Model/BackEast/back_e/back_e_wall",
	"Model/PropsWest/props_w/props_w_tables",
	"Model/PropsEast/props_e/props_e_tables",
]


func test_tilt_shift_off_by_default() -> void:
	assert_false(CONFIG.tilt_shift_enabled)
	var attrs: CameraAttributesPractical = CONFIG.make_camera_attributes()
	assert_not_null(attrs)
	assert_false(attrs.dof_blur_far_enabled)
	assert_false(attrs.dof_blur_near_enabled)


func test_tilt_shift_toggle_only_blurs_far() -> void:
	var config: RenderConfig = CONFIG.duplicate() as RenderConfig
	config.tilt_shift_enabled = true
	var attrs: CameraAttributesPractical = config.make_camera_attributes()
	assert_true(attrs.dof_blur_far_enabled)
	assert_false(attrs.dof_blur_near_enabled, "el cercano emborrona los kioscos")
	assert_false(CONFIG.camera_attributes.dof_blur_far_enabled, "no modifica el recurso compartido")


func test_environment_matches_art_bible() -> void:
	var env: Environment = CONFIG.environment
	assert_not_null(env)
	assert_eq(env.background_mode, Environment.BG_COLOR)
	assert_eq(env.background_color.to_html(false), "4fa05a", "meadow_green")
	assert_eq(env.ambient_light_source, Environment.AMBIENT_SOURCE_COLOR)
	assert_eq(env.ambient_light_color.to_html(false), "ede8df")
	assert_almost_eq(env.ambient_light_energy, 0.72, 0.01)
	assert_almost_eq(env.ambient_light_sky_contribution, 0.0, 0.001)
	assert_eq(env.reflected_light_source, Environment.REFLECTION_SOURCE_DISABLED)
	assert_eq(env.tonemap_mode, Environment.TONE_MAPPER_FILMIC)
	assert_almost_eq(env.tonemap_exposure, 1.0, 0.001)
	assert_almost_eq(env.tonemap_white, 6.0, 0.001)


func test_contact_ssao_on() -> void:
	var env: Environment = CONFIG.environment
	assert_true(env.ssao_enabled, "SSAO de contacto")
	assert_almost_eq(env.ssao_radius, 0.45, 0.01)
	assert_almost_eq(env.ssao_intensity, 1.1, 0.05)
	assert_almost_eq(env.ssao_power, 1.3, 0.05)
	assert_almost_eq(env.ssao_detail, 0.0, 0.001)
	assert_almost_eq(env.ssao_light_affect, 0.1, 0.01)


func test_forbidden_post_process_off() -> void:
	var env: Environment = CONFIG.environment
	assert_false(env.glow_enabled, "sin glow")
	assert_true(env.adjustment_enabled)
	assert_null(env.adjustment_color_correction, "sin LUT")
	assert_almost_eq(env.adjustment_brightness, 1.0, 0.001)
	assert_almost_eq(env.adjustment_contrast, 1.05, 0.001)
	assert_almost_eq(env.adjustment_saturation, 1.05, 0.001)
	assert_false(CONFIG.tilt_shift_enabled)


func test_scene_applies_config() -> void:
	var level_env: LevelEnvironment = ENVIRONMENT_SCENE.instantiate() as LevelEnvironment
	add_child_autofree(level_env)
	var world: WorldEnvironment = level_env.get_node("WorldEnvironment") as WorldEnvironment
	assert_eq(world.environment, CONFIG.environment)
	assert_not_null(world.camera_attributes)
	assert_false((world.camera_attributes as CameraAttributesPractical).dof_blur_far_enabled)


func test_light_budget() -> void:
	var level_env: Node = ENVIRONMENT_SCENE.instantiate()
	add_child_autofree(level_env)
	var omnis: Array[Node] = level_env.find_children("*", "OmniLight3D", true, false)
	assert_lte(omnis.size(), MAX_OMNI_LIGHTS, "≤ 6 bombillas como luz real")
	for node: Node in omnis:
		assert_false((node as OmniLight3D).shadow_enabled, "%s sin sombra" % node.name)
	var sun: DirectionalLight3D = level_env.get_node("Sun") as DirectionalLight3D
	assert_true(sun.shadow_enabled)
	var elevation: float = rad_to_deg(asin(sun.global_basis.z.y))
	assert_between(elevation, 50.0, 60.0, "elevación del sol")


func test_bulbs_and_vignette_off() -> void:
	var level_env: Node = ENVIRONMENT_SCENE.instantiate()
	add_child_autofree(level_env)
	assert_false((level_env.get_node("Bulbs") as Node3D).visible)
	for node: Node in level_env.get_node("Bulbs").get_children():
		assert_false((node as OmniLight3D).visible, "%s apagada" % node.name)
	assert_false((level_env.get_node("Vignette") as CanvasLayer).visible)


func test_noisy_props_pruned() -> void:
	var level_env: Node = ENVIRONMENT_SCENE.instantiate()
	add_child_autofree(level_env)
	for path: String in PRUNED_MESHES:
		var mesh: MeshInstance3D = level_env.get_node(path) as MeshInstance3D
		assert_not_null(mesh, path)
		assert_false(mesh.is_visible_in_tree(), "%s oculto" % path)
	for path: String in KEPT_MESHES:
		var mesh: MeshInstance3D = level_env.get_node(path) as MeshInstance3D
		assert_not_null(mesh, path)
		assert_true(mesh.is_visible_in_tree(), "%s visible" % path)
