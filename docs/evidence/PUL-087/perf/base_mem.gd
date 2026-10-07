extends SceneTree
## Memoria de vídeo base (sin nivel): mismo Environment, sol con sombra y cámara a 1080p.


func _initialize() -> void:
	var cfg: Resource = load("res://data/config/render_config.tres")
	var we := WorldEnvironment.new()
	we.environment = cfg.get("environment")
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	root.add_child(sun)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	root.add_child(cam)
	var box := MeshInstance3D.new()
	box.mesh = BoxMesh.new()
	box.position = Vector3(0, 0, -3)
	root.add_child(box)
	for i in 120:
		await process_frame
	print("BASE tex MB ", Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0)
	print("BASE video MB ", Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0)
	quit()
