extends Node
## PUL-185: nodo de captura que monta `capture_pul185.gd` cuando los autoloads ya existen.

const HUD_SCENE: PackedScene = preload("res://ui/hud/hud.tscn")
const TICKET_SCENE: PackedScene = preload("res://ui/tickets/order_ticket.tscn")
const ENTRY_SCENE: PackedScene = preload("res://ui/tickets/ticket_entry.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const BOX: BoxData = preload("res://data/boxes/box.tres")
const CATALOG: OrderCatalog = preload("res://data/orders/order_catalog.tres")
const SEASONINGS: Array[SeasoningData] = [
	preload("res://data/seasonings/sweet_dressing.tres"),
	preload("res://data/seasonings/hot_dressing.tres"),
	preload("res://data/seasonings/cachelos.tres"),
]
const FLOOR: Color = Color("#C4A882")

var _out: String = ProjectSettings.globalize_path("res://../docs/evidence/PUL-185")


func _ready() -> void:
	var root: Window = get_tree().root
	var world: Node3D = Node3D.new()
	root.add_child(world)
	var camera: Camera3D = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 4.0
	camera.rotation_degrees = Vector3(-45, 0, 0)
	camera.position = Vector3(0, 6, 6)
	world.add_child(camera)
	camera.current = true
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-60, 30, 0)
	world.add_child(sun)
	var ground: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(40, 40)
	var floor_material: StandardMaterial3D = StandardMaterial3D.new()
	floor_material.albedo_color = FLOOR
	floor_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	plane.material = floor_material
	ground.mesh = plane
	ground.position.y = -1.0
	world.add_child(ground)
	## Dos cajas: una con dulce + cachelos, otra con picante + cachelos (dulce y picante se
	## excluyen).
	for i: int in 2:
		var box: Box = BOX_SCENE.instantiate()
		box.data = BOX
		box.freeze = true
		world.add_child(box)
		box.position = Vector3(-0.9 + 1.8 * i, 0, 0)
		box.fill = 1.0
		box.apply_seasoning(SEASONINGS[i])
		box.apply_seasoning(SEASONINGS[2])

	var ui: CanvasLayer = CanvasLayer.new()
	root.add_child(ui)
	var hud: Control = HUD_SCENE.instantiate()
	ui.add_child(hud)
	var tickets: VBoxContainer = VBoxContainer.new()
	tickets.position = Vector2(1040, 8)
	ui.add_child(tickets)
	for i: int in 2:
		var ticket: OrderTicket = TICKET_SCENE.instantiate()
		tickets.add_child(ticket)
		var data: OrderData = CATALOG.orders[0].duplicate()
		data.seasonings = [SEASONINGS[i], SEASONINGS[2]] as Array[SeasoningData]
		(ticket.get_node("%Entry") as TicketEntry).setup(data)
	var zoom: TicketEntry = ENTRY_SCENE.instantiate()
	ui.add_child(zoom)
	zoom.position = Vector2(420, 40)
	zoom.set_icon_px(96.0)
	var all: OrderData = CATALOG.orders[0].duplicate()
	all.seasonings = SEASONINGS.duplicate()
	zoom.setup(all)

	for _i: int in 30:
		await get_tree().process_frame
	var image: Image = root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(_out)
	image.save_png(_out.path_join("v3_hud_tickets_pegatinas.png"))
	var zoom_rect: Rect2i = Rect2i(zoom.get_global_rect()).grow(12)
	image.get_region(zoom_rect).save_png(_out.path_join("pegatinas_zoom_picante_p4.png"))
	var hud_rect: Rect2i = Rect2i((hud.get_node("%Background") as Control).get_global_rect())
	image.get_region(hud_rect.grow(8)).save_png(_out.path_join("hud_v3.png"))
	print("PUL-185 capturas en ", _out)
	get_tree().quit(0)
