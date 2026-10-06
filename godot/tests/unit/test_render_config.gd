extends GutTest
## PUL-073: luz y post-proceso en `render_config.tres` (biblia de arte v2 §1.3). El tilt-shift
## viene apagado por defecto (D22) y `LevelEnvironment` aplica el entorno a su `WorldEnvironment`.

const CONFIG: RenderConfig = preload("res://data/config/render_config.tres")
const ENVIRONMENT_SCENE: PackedScene = preload("res://entities/environment/environment.tscn")
const MAX_OMNI_LIGHTS: int = 6


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
	assert_true(env.ssao_enabled, "SSAO")
	assert_true(env.glow_enabled, "glow para emisivos")
	assert_gt(env.glow_hdr_threshold, 1.0, "glow solo en emisivos")
	assert_true(
		env.tonemap_mode in [Environment.TONE_MAPPER_FILMIC, Environment.TONE_MAPPER_AGX],
		"Filmic o AgX"
	)


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
