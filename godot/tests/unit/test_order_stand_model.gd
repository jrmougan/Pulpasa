extends GutTest
## PUL-053: el `Model` del puesto de entrega enseña el toldillo de su `slot_id` (4 colores, del 5
## en adelante se repiten), escribe el número del puesto y no toca la escena de contrato: modelo a
## escala 1, resaltado con el material por defecto sobre `OutlineHull` y `%OrderLabel` intacto.
## PUL-184 (art-bible v3 §6.3): paleta plana de los 4 puestos y números macizos sin contorno, con
## contraste WCAG 2.1 ≥ 11:1 sobre la placa (`OrderPlatePaper`) y sobre el faldón frontal.

const EventBusScript: GDScript = preload("res://autoload/event_bus.gd")
const OrderServiceScript: GDScript = preload("res://autoload/order_service.gd")
const STAND_SCENE: PackedScene = preload("res://entities/stations/order_stand.tscn")
const CATALOG: OrderCatalog = preload("res://data/orders/order_catalog.tres")
const MODEL_GLB: String = "res://assets/models/stations/order_stand/order_stand.glb"
const PALETTE: StandPalette = preload("res://data/config/stand_palette.tres")
const NAVY: String = "1d3557"
const CREAM: String = "f7f4ec"
const SURFACE_TOP: String = "ede8df"
const MIN_CONTRAST: float = 11.0
## Superficies de `counter` en `order_stand.glb`: tablero (`mat_steel_brushed_top`) y faldón frontal
## (cuerpo `mat_steel_dark` y chapa `order_stand_atlas` donde va `StandNumber`).
const COUNTER_TOP_SURFACE: int = 2
const COUNTER_FRONT_SURFACES: Array[int] = [0, 5]

var _bus: Node
var _service: Node


func before_each() -> void:
	_bus = add_child_autofree(EventBusScript.new())
	_service = OrderServiceScript.new()
	_service.set_bus(_bus)
	add_child_autofree(_service)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5
	_service.setup(CATALOG, rng)


func _stand(slot_id: int) -> OrderStand:
	var stand: OrderStand = STAND_SCENE.instantiate()
	stand.slot_id = slot_id
	stand.set_bus(_bus)
	stand.set_service(_service)
	add_child_autofree(stand)
	return stand


## Luminancia relativa WCAG 2.1.
static func _luminance(color: Color) -> float:
	var channels: Array[float] = []
	for c: float in [color.r, color.g, color.b]:
		channels.append(c / 12.92 if c <= 0.04045 else pow((c + 0.055) / 1.055, 2.4))
	return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]


static func _contrast(a: Color, b: Color) -> float:
	var la: float = _luminance(a)
	var lb: float = _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _albedo(stand: OrderStand, mesh_name: String, surface: int) -> Color:
	var mesh: MeshInstance3D = stand.get_node("Model").find_child(mesh_name, true, false)
	assert_not_null(mesh, "%s en el .glb" % mesh_name)
	var material: StandardMaterial3D = mesh.get_active_material(surface) as StandardMaterial3D
	assert_not_null(material, "%s/%d con StandardMaterial3D" % [mesh_name, surface])
	return material.albedo_color if material != null else Color.TRANSPARENT


func _visible_awnings(stand: OrderStand) -> Array[int]:
	var shown: Array[int] = []
	for i: int in range(1, OrderStandModel.AWNING_COUNT + 1):
		var awning: Node3D = stand.get_node("Model").find_child("awning_%d" % i, true, false)
		assert_not_null(awning, "awning_%d en el .glb" % i)
		if awning != null and awning.visible:
			shown.append(i)
	return shown


func test_awning_index_cycles_every_four_stands() -> void:
	assert_eq(OrderStandModel.awning_index(1), 1)
	assert_eq(OrderStandModel.awning_index(4), 4)
	assert_eq(OrderStandModel.awning_index(5), 1)
	assert_eq(OrderStandModel.awning_index(0), 4)


func test_each_stand_shows_its_awning_and_number() -> void:
	for slot_id: int in [1, 2, 3, 4]:
		var stand: OrderStand = _stand(slot_id)
		assert_eq(_visible_awnings(stand), [slot_id] as Array[int], "puesto %d" % slot_id)
		assert_eq((stand.get_node("StandNumber") as Label3D).text, str(slot_id))


func test_refresh_follows_slot_id_change() -> void:
	var stand: OrderStand = _stand(1)
	stand.slot_id = 3
	(stand.get_node("Model") as OrderStandModel).refresh()
	assert_eq(_visible_awnings(stand), [3] as Array[int])
	assert_eq((stand.get_node("StandNumber") as Label3D).text, "3")


func test_model_is_the_glb_at_unit_scale() -> void:
	var model: Node3D = _stand(1).get_node("Model")
	assert_eq(model.scene_file_path, MODEL_GLB)
	assert_eq(model.transform, Transform3D.IDENTITY)


func test_stand_measures_counter_1_4_by_1_0_without_node_scale() -> void:
	var stand: OrderStand = _stand(1)
	var counter: MeshInstance3D = stand.get_node("Model").find_child("counter", true, false)
	var size: Vector3 = counter.get_aabb().size
	assert_almost_eq(size.x, 1.4, 0.1, "ancho del mostrador")
	var body: BoxShape3D = (stand.get_node("CollisionShape3D") as CollisionShape3D).shape
	assert_almost_eq(body.size.y, 1.0, 0.05, "alto del mostrador (colisión)")
	assert_eq(stand.scale, Vector3.ONE)


func test_highlight_uses_default_outline_on_hull() -> void:
	var stand: OrderStand = _stand(1)
	var highlight: Highlightable = stand.get_node("%Highlightable")
	assert_eq(highlight.material, Highlightable.DEFAULT_MATERIAL)
	assert_eq(highlight.root, stand.get_node("OutlineHull"))
	highlight.show()
	var model_mesh: MeshInstance3D = stand.get_node("Model").find_child("counter", true, false)
	assert_null(model_mesh.material_overlay, "el contorno va en el casco, no en el modelo")
	var hull: MeshInstance3D = stand.get_node("OutlineHull/Counter")
	assert_eq(hull.material_overlay, Highlightable.DEFAULT_MATERIAL)


func test_order_label_contract_kept() -> void:
	var label: Label3D = _stand(2).get_node("%OrderLabel")
	assert_eq(label.text, OrderStand.EMPTY_LABEL)
	assert_eq(label.billboard, BaseMaterial3D.BILLBOARD_ENABLED)


func test_pul184_palette_is_v3_flat() -> void:
	var expected: Array[String] = ["c8402f", "2f6fb5", "f2c230", "4fa05a"]
	for i: int in expected.size():
		assert_eq(PALETTE.color_for(i + 1).to_html(false), expected[i], "puesto %d" % (i + 1))


func test_pul184_order_label_is_solid_dark_on_cream_plate() -> void:
	var stand: OrderStand = _stand(1)
	assert_not_null(_service.request_order(1), "comanda para el puesto 1")
	var label: Label3D = stand.get_node("%OrderLabel")
	assert_ne(label.text, OrderStand.EMPTY_LABEL, "comanda activa")
	assert_eq(label.outline_size, 0)
	assert_eq(label.modulate.to_html(false), NAVY)
	assert_eq(label.font_size, 76)
	assert_almost_eq(label.pixel_size, 0.005, 0.00001)
	assert_false(label.shaded)
	var paper: Color = _albedo(stand, "OrderPlatePaper", 0)
	assert_eq(paper.to_html(false), CREAM)
	assert_eq(_albedo(stand, "OrderPlateFrame", 0).to_html(false), NAVY)
	assert_gte(_contrast(label.modulate, paper), MIN_CONTRAST)


func test_pul184_stand_number_is_solid_cream_on_navy_front() -> void:
	var stand: OrderStand = _stand(1)
	var number: Label3D = stand.get_node("StandNumber")
	assert_eq(number.outline_size, 0)
	assert_eq(number.modulate.to_html(false), CREAM)
	assert_eq(number.font_size, 96)
	assert_almost_eq(number.pixel_size, 0.005, 0.00001)
	assert_false(number.shaded)
	for surface: int in COUNTER_FRONT_SURFACES:
		var front: Color = _albedo(stand, "counter", surface)
		assert_eq(front.to_html(false), NAVY, "faldón, superficie %d" % surface)
		assert_gte(_contrast(number.modulate, front), MIN_CONTRAST)
	assert_eq(_albedo(stand, "counter", COUNTER_TOP_SURFACE).to_html(false), SURFACE_TOP)
