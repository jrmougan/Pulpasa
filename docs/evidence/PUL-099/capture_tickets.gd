extends SceneTree
## HUD con 4 tickets (S/M/L, un color por puesto) a 1080p.
## Uso (desde godot/): godot --audio-driver Dummy --resolution 1920x1080 -s ../docs/evidence/PUL-099/capture_tickets.gd -- <dir absoluto>


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var bg: ColorRect = ColorRect.new()
	bg.color = Color("3b4a3a")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	await process_frame
	var panel: Control = (load("res://ui/tickets/order_tickets_panel.tscn") as PackedScene).instantiate()
	root.add_child(panel)
	var catalog: Resource = load("res://data/orders/order_catalog.tres")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20
	var service: Node = root.get_node("OrderService")
	service.setup(catalog, rng)
	service.board.fill_slots([1, 2, 3, 4] as Array[int])
	for i: int in 10:
		await process_frame
	var tickets: Array[Node] = panel.get_node("%Tickets").get_children()
	for i: int in tickets.size():
		root.get_node("EventBus").order_patience_changed.emit(tickets[i].get("order_id"), 40.0 - 8.0 * i, 40.0)
	for i: int in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var shot: Image = root.get_texture().get_image()
	shot.save_png(out + "/tickets_1080.png")
	var crop: Image = shot.get_region(Rect2i(0, 0, 1000, 330))
	crop.resize(crop.get_width() * 2, crop.get_height() * 2, Image.INTERPOLATE_BILINEAR)
	crop.save_png(out + "/tickets_zoom.png")
	var sizes: Array[String] = []
	for ticket: Node in tickets:
		sizes.append((ticket.get_node("Content/Entry/Details/RecipeRow/SizeBadge/SizeLabel") as Label).text)
	print("CAPTURE TICKETS OK tickets=", tickets.size(), " sizes=", sizes)
	quit()
