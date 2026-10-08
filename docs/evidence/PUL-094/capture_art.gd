extends SceneTree
## Review board at exactly the gameplay camera pitch and 1080p pixels/metre.
## godot --audio-driver Dummy --path godot --resolution 1920x1080 -s <script> -- <repo> <card>

var stage: Node3D
var camera: Camera3D
var repo: String
var card: String


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	repo = args[0]
	card = args[1]
	stage = Node3D.new()
	root.add_child(stage)
	current_scene = stage
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_SKY
	world.environment.background_color = Color("39434e")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("c3cede")
	world.environment.ambient_light_energy = 0.7
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("8f9eb0")
	sky_material.sky_horizon_color = Color("d4d5d3")
	sky_material.ground_bottom_color = Color("727477")
	sky_material.ground_horizon_color = Color("d4d5d3")
	world.environment.sky = Sky.new()
	world.environment.sky.sky_material = sky_material
	stage.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.light_energy = 1.0
	stage.add_child(sun)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.74
	stage.add_child(camera)
	camera.position = Vector3(0, sin(deg_to_rad(38)) * 16, cos(deg_to_rad(38)) * 16)
	camera.look_at(Vector3.ZERO)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(24, 24)
	floor_mesh.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color("707577")
	floor_mat.roughness = 1
	floor_mesh.material_override = floor_mat
	floor_mesh.position.y = -0.032
	stage.add_child(floor_mesh)
	var title := Label.new()
	title.text = card + " | 1920 x 1080 | cámara 38° / 12,74 m | escala nativa"
	title.position = Vector2(40, 30)
	title.add_theme_font_size_override("font_size", 26)
	root.add_child(title)
	match card:
		"PUL-094":
			_station()
		"PUL-095":
			_boxes()
		"PUL-096":
			_stands(false)
	await _shot("native_1080.png")
	if card == "PUL-094":
		camera.position.z = -camera.position.z
		camera.look_at(Vector3.ZERO)
		await _shot("rear_1080.png")
	if card == "PUL-096":
		for frame: Node in stage.find_children("DeliveryFrame", "MeshInstance3D", true, false):
			var mesh := frame as MeshInstance3D
			var material: StandardMaterial3D = load(
				"res://assets/models/stations/order_stand/delivery_zone_on.tres"
			) as StandardMaterial3D
			material = material.duplicate() as StandardMaterial3D
			material.emission = (mesh.get_meta("stand_color") as Color)
			mesh.material_override = material
		await _shot("delivery_on_1080.png")
	quit()


func model(path: String, pos: Vector3) -> Node3D:
	var obj: Node3D = (load("res://assets/models/" + path) as PackedScene).instantiate() as Node3D
	stage.add_child(obj)
	obj.position = pos
	var hull: Node3D = obj.find_child("OutlineHull", true, false) as Node3D
	if hull != null:
		hull.visible = false
	return obj


func label(text: String, pos: Vector3, size: int = 22) -> void:
	var obj := Label3D.new()
	obj.text = text
	obj.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	obj.font_size = size
	obj.pixel_size = 0.01
	obj.no_depth_test = true
	stage.add_child(obj)
	obj.position = pos


func variant(obj: Node3D, names: Array[String], shown: String) -> void:
	for key: String in names:
		var node: Node3D = obj.find_child(key, true, false) as Node3D
		if node != null:
			node.visible = key == shown


func _station() -> void:
	var stand := model("stations/seasoning_station/seasoning_station.glb", Vector3(0, 0, -3))
	var names: Array[String] = ["paprika_sweet", "paprika_hot", "salt", "oil"]
	var anchors: Array[String] = ["SweetPaprika", "HotPaprika", "Salt", "Oil"]
	for i: int in 4:
		var anchor: Node3D = stand.find_child("Anchor_Dispenser_" + anchors[i], true, false) as Node3D
		var obj := model("stations/seasoning_station/seasoning_dispenser.glb", anchor.global_position)
		variant(obj, names, names[i])
		var isolated := model("stations/seasoning_station/seasoning_dispenser.glb", Vector3(i * 1.2 - 1.8, 0, .6))
		variant(isolated, names, names[i])
		label(anchors[i], Vector3(i * 1.2 - 1.8, 0, 1.25), 18)
	var bowl_anchor: Node3D = stand.find_child("Anchor_Bowl", true, false) as Node3D
	var full := model("stations/seasoning_station/cachelos_bowl.glb", bowl_anchor.global_position)
	var states: Array[String] = ["Portions0", "Portions1", "Portions2", "Portions3", "Portions4"]
	variant(full, states, "Portions4")
	for i: int in 5:
		var bowl := model("stations/seasoning_station/cachelos_bowl.glb", Vector3(i * 1.2 - 2.4, 0, 3))
		variant(bowl, states, "Portions%d" % i)
		label("%d raciones" % i, Vector3(i * 1.2 - 2.4, 0, 3.65), 18)
	label("SERVICIO · dulce / picante / sal / aceite / cachelos · centros 1 m", Vector3(0, 0, -1.5), 22)


func _boxes() -> void:
	var rack := model("stations/box_shelf/box_shelf.glb", Vector3(-3.6, 0, -1.5))
	rack.rotation.y = -PI / 2
	label("Rack · giro real -90°", Vector3(-3.6, 0, .4))
	for i: int in 3:
		var obj := model("items/box/box.glb", Vector3(i * 1.2 + .2, 0, -1.5))
		variant(obj, ["box_small", "box_medium", "box_large"], ["box_small", "box_medium", "box_large"][i])
		var sticker: Node3D = obj.find_child("sticker", true, false) as Node3D
		sticker.visible = false
		label(["S · círculo", "M · óvalo", "L · rectángulo"][i], Vector3(i * 1.2 + .2, 0, -.8), 18)
	for i: int in 3:
		var module := model("furniture/counters/counter_1m.glb", Vector3(i * 1.4 - 1.4, 0, 1.7))
		model("furniture/counters/pass_mark.glb", module.position + Vector3(0, 1, 0))
	model("furniture/counters/pass_threshold.glb", Vector3(3.4, 0, 1.7))
	label("Pasaplatos · campo despejado / umbral de suelo", Vector3(1, 0, 2.7))


func _stands(_lit: bool) -> void:
	var colors: Array[Color] = [Color("d2473f"), Color("3f7cc8"), Color("e8c23a"), Color("4fa05a")]
	for i: int in 4:
		var obj := model("stations/order_stand/order_stand.glb", Vector3(i * 2.2 - 3.3, 0, 1))
		obj.rotation.y = PI
		for j: int in 4:
			(obj.find_child("awning_%d" % (j + 1), true, false) as Node3D).visible = i == j
		var anchor: Node3D = obj.find_child("Anchor_OrderLabel", true, false) as Node3D
		var order := Label3D.new()
		order.text = ["#17", "#28", "#39", "–"][i]
		order.font = load("res://assets/fonts/montserrat/Montserrat-Bold.otf") as Font
		order.font_size = 96
		order.pixel_size = .00439
		order.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		order.modulate = Color("1d3557")
		order.outline_size = 0
		stage.add_child(order)
		order.global_position = anchor.global_position
		var number: Node3D = obj.find_child("Anchor_Number", true, false) as Node3D
		var digit := Label3D.new()
		digit.text = str(i + 1)
		digit.font_size = 64
		digit.pixel_size = .0058
		digit.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		digit.modulate = Color("1d3557")
		digit.outline_size = 0
		stage.add_child(digit)
		digit.global_position = number.global_position + Vector3(0, 0, .02)
		var frame: MeshInstance3D = obj.find_child("DeliveryFrame", true, false) as MeshInstance3D
		frame.set_meta("stand_color", colors[i])
		frame.material_override = load("res://assets/models/stations/order_stand/delivery_zone_off.tres") as Material


func _shot(filename: String) -> void:
	for i: int in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	var folder: String = repo + "/docs/evidence/" + card
	img.save_png(folder + "/" + filename)
	if card == "PUL-094" and filename == "native_1080.png":
		var gray: Image = img.duplicate() as Image
		for y: int in gray.get_height():
			for x: int in gray.get_width():
				var color: Color = gray.get_pixel(x, y)
				var luminance: float = color.r * .2126 + color.g * .7152 + color.b * .0722
				gray.set_pixel(x, y, Color(luminance, luminance, luminance))
		gray.save_png(folder + "/grayscale_1080.png")
	print("CAPTURE OK ", folder, "/", filename)
