extends GutTest
## PUL-053: el `Model` del puesto de entrega enseña el toldillo de su `slot_id` (4 colores, del 5
## en adelante se repiten), escribe el número del puesto y no toca la escena de contrato: modelo a
## escala 1, resaltado con el material por defecto sobre `OutlineHull` y `%OrderLabel` intacto.

const EventBusScript: GDScript = preload("res://autoload/event_bus.gd")
const OrderServiceScript: GDScript = preload("res://autoload/order_service.gd")
const STAND_SCENE: PackedScene = preload("res://entities/stations/order_stand.tscn")
const CATALOG: OrderCatalog = preload("res://data/orders/order_catalog.tres")
const MODEL_GLB: String = "res://assets/models/stations/order_stand/order_stand.glb"

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
