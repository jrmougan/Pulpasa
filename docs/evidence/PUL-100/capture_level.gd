extends SceneTree
## PUL-100: level_01 con la camara real; el portador con la caja del puesto 1 enciende SU zona y no las otras.
## Tambien comprueba que la zona nueva no choca con nada del nivel y es alcanzable.
## Uso (desde godot/): timeout 300 godot --audio-driver Dummy --resolution 1920x1080 -s ../docs/evidence/PUL-100/capture_level.gd -- <dir absoluto>

const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var level: Node3D = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(level)
	current_scene = level
	for i: int in 30:
		await process_frame
	var service: Node = root.get_node("OrderService")
	service.board.set_active_slots([1, 2, 3, 4] as Array[int])
	service.board.fill_slots([1, 2, 3, 4] as Array[int])
	var stands: Array[Node] = []
	for n: String in ["OrderStand1", "OrderStand2", "OrderStand3", "OrderStand4"]:
		stands.append(level.get_node("Stations/" + n) as Node)
	# level_01 coloca los kioscos en y=-0,04 y la marca (0,02 local) queda bajo el suelo (y=0): para ver la
	# zona en la captura se suben a y=0. Es un hallazgo para PUL-101 (dueño de level_01.tscn).
	for st: Node in stands:
		(st as Node3D).position.y = 0.0
	_probe(level, stands)
	var player: Node3D = level.get_node("Characters/Player1") as Node3D
	var hold: Node = player.get_node("%HoldComponent")
	var actor: Node = player.get_node("%InteractionComponent")
	var order: Variant = null
	for o: Variant in service.get_active_orders():
		if o.slot_id == 1:
			order = o
	var box: Variant = BOX_SCENE.instantiate()
	level.add_child(box)
	box.data = order.data.recipe.box
	var guard: int = 0
	while not box.is_full() and guard < 200:
		var octopus: Variant = OCTOPUS_SCENE.instantiate()
		level.add_child(octopus)
		octopus.set_cooked()
		hold.pick_up(octopus)
		while octopus.is_inside_tree() and not box.is_full() and guard < 200:
			box.interact(actor)
			guard += 1
		if is_instance_valid(octopus):
			hold.drop()
			octopus.free()
	for seasoning: Variant in order.data.seasonings:
		box.toggle_seasoning(seasoning, true)
	hold.pick_up(box)
	var zone1: Vector3 = (stands[0].get_node("%DeliveryZone") as Node3D).global_position
	player.global_position = zone1 + Vector3(-1.5, 0, 0)
	for i: int in 20:
		await physics_frame
	var fr: MeshInstance3D = stands[0].find_child("DeliveryFrame", true, false) as MeshInstance3D
	print("frame ", fr.global_position, " aabb ", fr.global_transform * fr.get_aabb(), " vis ", fr.is_visible_in_tree(), " mat ", fr.material_override)
	for s: Node in stands:
		print("stand ", s.get("slot_id"), " lit=", s.call("is_zone_lit"))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out + "/level_zone_lit_1080.png")
	quit()


func _probe(level: Node3D, stands: Array[Node]) -> void:
	var space: PhysicsDirectSpaceState3D = level.get_world_3d().direct_space_state
	for s: Node in stands:
		var zone: Area3D = s.get_node("%DeliveryZone") as Area3D
		var shape: CollisionShape3D = zone.get_child(0) as CollisionShape3D
		var q: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
		q.shape = shape.shape
		q.transform = shape.global_transform
		q.collision_mask = 0xFFFFF
		q.collide_with_areas = true
		var hits: Array[String] = []
		for r: Dictionary in space.intersect_shape(q, 32):
			var c: Node = r["collider"] as Node
			if not s.is_ancestor_of(c):
				hits.append(str(level.get_path_to(c)))
		print("zone ", s.get("slot_id"), " centre=", shape.global_position, " overlaps=", hits)
