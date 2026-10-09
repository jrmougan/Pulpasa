extends SceneTree
## PUL-105: comprueba que cada Slot de los sandboxes tiene superficie con colision debajo
## (rayo vertical contra la capa 1, a la altura de la marca) y captura cada sandbox.
## Uso: godot --audio-driver Dummy --resolution 1920x1080 -s docs/evidence/PUL-105/check_and_shoot.gd (desde godot/ con --path)

const SCENES: Dictionary = {
	"kitchen_sandbox": "res://scenes/sandbox/kitchen_sandbox.tscn",
	"player_sandbox": "res://scenes/sandbox/player_sandbox.tscn",
	"items_sandbox": "res://entities/items/sandbox/items_sandbox.tscn",
}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var failed: bool = false
	for key: String in SCENES:
		var packed: PackedScene = load(SCENES[key])
		var inst: Node = packed.instantiate()
		root.add_child(inst)
		for i: int in 8:
			await process_frame
			await physics_frame
		var slots: Array[Node] = []
		_collect(inst, slots)
		for s: Node in slots:
			var slot: StaticBody3D = s as StaticBody3D
			var from: Vector3 = slot.global_position + Vector3(0, 1.3, 0)
			var q: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
				from, slot.global_position + Vector3(0, 0.3, 0), 1
			)
			var hit: Dictionary = slot.get_world_3d().direct_space_state.intersect_ray(q)
			var ok: bool = not hit.is_empty() and hit["position"].y > 0.9
			print("%s/%s surface=%s" % [key, slot.name, hit.get("position", "NONE")], " OK" if ok else " FAIL")
			failed = failed or not ok
		await process_frame
		get_root().get_viewport().get_texture().get_image().save_png(
			ProjectSettings.globalize_path("res://../docs/evidence/PUL-105/%s.png" % key)
		)
		inst.queue_free()
		await process_frame
	quit(1 if failed else 0)


func _collect(n: Node, out: Array[Node]) -> void:
	if n.scene_file_path == "res://entities/stations/slot.tscn":
		out.append(n)
	for c: Node in n.get_children():
		_collect(c, out)
