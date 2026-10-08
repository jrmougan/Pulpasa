extends SceneTree
## PUL-096: capturas de evidencia. Uso (desde la raiz del repo):
## godot --path godot --audio-driver Dummy --resolution 1920x1080 --script
## res://../docs/evidence/PUL-096/capture_zone.gd

const MODEL: PackedScene = preload("res://assets/models/stations/order_stand/order_stand.glb")
const MAT_OFF: StandardMaterial3D = preload(
	"res://assets/models/stations/order_stand/delivery_zone_off.tres"
)
const MAT_ON: StandardMaterial3D = preload(
	"res://assets/models/stations/order_stand/delivery_zone_on.tres"
)
const COLORS: Array[Color] = [Color("D2473F"), Color("3F7CC8"), Color("E8C23A"), Color("4FA05A")]
const IDS: Array[String] = ["#17", "#28", "#39", "–"]
const FONT: FontFile = preload("res://assets/fonts/LiberationSans.ttf")


func _initialize() -> void:
	var out: String = ProjectSettings.globalize_path("res://../docs/evidence/PUL-096")
	var root3d: Node3D = Node3D.new()
	root.add_child(root3d)
	var env: WorldEnvironment = WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.5, 0.52, 0.55)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.8, 0.8, 0.8)
	root3d.add_child(env)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	root3d.add_child(sun)
	var cam: Camera3D = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	root3d.add_child(cam)
	var frames: Array[MeshInstance3D] = []
	for i: int in 4:
		var stand: Node3D = MODEL.instantiate()
		stand.rotation.y = PI
		stand.position = Vector3(-4.5 + 3.0 * i, 0.0, 0.0)
		root3d.add_child(stand)
		var awning_mats: Array[Node] = stand.find_children(
			"awning_*", "MeshInstance3D", true, false
		)
		for a: Node in awning_mats:
			(a as MeshInstance3D).visible = a.name == "awning_%d" % (i + 1)
		frames.append(stand.find_child("DeliveryFrame", true, false) as MeshInstance3D)
		var lab: Label3D = Label3D.new()
		lab.text = IDS[i]
		lab.font = FONT
		lab.font_size = 96
		lab.pixel_size = 0.00439
		lab.modulate = Color(0.1, 0.18, 0.35)
		lab.no_depth_test = true
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		stand.add_child(lab)
		lab.position = stand.find_child("Anchor_OrderLabel", true, false).position
	# Vista de juego (38 grados) y vista cenital cercana de la zona.
	cam.size = 12.74 * 0.5
	cam.look_at_from_position(Vector3(0, 8.0, 10.0), Vector3(0.0, 0.5, 0.0))
	await _shot(out + "/zone_off_1080.png")
	for i: int in 4:
		var m: StandardMaterial3D = MAT_ON.duplicate()
		m.emission = COLORS[i]
		m.albedo_color = COLORS[i]
		frames[i].material_override = m
	await _shot(out + "/zone_on_1080.png")
	quit(0)


func _shot(path: String) -> void:
	for n: int in 4:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURE OK ", path)
