extends GutTest
## PUL-143: colocación de las plazas de la olla (`cooking_station.gd`). Las anclas se reparten a lo
## ancho a `CookingStation.SLOT_SPACING` entre sí, centradas en el `%AnchorPoint` de la escena, con
## la capacidad de `data/config/kitchen.tres` y con una forzada de 3; cada pulpo metido queda sobre
## el ancla de su plaza. La separación de los anillos la cubre `test_level_01.gd` (PUL-131).

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const KITCHEN_SCENE: PackedScene = preload("res://entities/stations/kitchen.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const KITCHEN_DATA: KitchenData = preload("res://data/config/kitchen.tres")
const FORCED_CAPACITY: int = 3
const TOLERANCE: float = 0.001

var _level: Node3D
var _hold: HoldComponent
var _actor: InteractionComponent
var _kitchen: CookingStation


func before_each() -> void:
	_level = add_child_autofree(Node3D.new())
	var player: Player = PLAYER_SCENE.instantiate()
	_level.add_child(player)
	_hold = player.get_node("%HoldComponent")
	_hold.items_root = _level
	_actor = player.get_node("%InteractionComponent")


## Instancia la cocina; con `capacity` > 0 la fuerza sobre una copia de los datos antes de `_ready`.
func _spawn_kitchen(capacity: int = 0) -> void:
	_kitchen = KITCHEN_SCENE.instantiate()
	if capacity > 0:
		var data: KitchenData = _kitchen.data.duplicate() as KitchenData
		data.capacity = capacity
		_kitchen.data = data
	_level.add_child(_kitchen)
	_kitchen.position = Vector3(0, 0, -1.2)


## Posición local del `%AnchorPoint` tal como está en la escena (antes de que `_ready` la reparta).
func _scene_anchor_position() -> Vector3:
	var fresh: Node3D = KITCHEN_SCENE.instantiate()
	var position: Vector3 = (fresh.get_node("AnchorPoint") as Node3D).position
	fresh.free()
	return position


func _anchors() -> Array[Node3D]:
	var anchors: Array[Node3D] = []
	for slot: CookingStation.SlotData in _kitchen._slots:
		anchors.append(slot.anchor)
	return anchors


func _octopus_in_hand() -> Ingredient:
	var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
	_level.add_child(octopus)
	assert_true(_hold.pick_up(octopus))
	return octopus


func _assert_layout(capacity: int) -> void:
	var anchors: Array[Node3D] = _anchors()
	assert_eq(anchors.size(), capacity, "una ancla por plaza")
	var base: Vector3 = _scene_anchor_position()
	var sum_x: float = 0.0
	for i: int in anchors.size():
		var anchor: Node3D = anchors[i]
		assert_eq(anchor.get_parent(), _kitchen, "ancla %d hija de la olla" % i)
		sum_x += anchor.position.x
		assert_almost_eq(anchor.position.y, base.y, TOLERANCE, "misma Y en la plaza %d" % i)
		assert_almost_eq(anchor.position.z, base.z, TOLERANCE, "misma Z en la plaza %d" % i)
		if i > 0:
			assert_almost_eq(
				anchor.position.x - anchors[i - 1].position.x,
				CookingStation.SLOT_SPACING,
				TOLERANCE,
				"plazas %d y %d a SLOT_SPACING" % [i - 1, i]
			)
	assert_almost_eq(sum_x / float(capacity), base.x, TOLERANCE, "centradas en el ancla base")


## Mete dos pulpos en orden y comprueba que cada uno queda sobre el ancla de su plaza.
func _assert_two_octopuses_on_their_anchors() -> void:
	var octopuses: Array[Ingredient] = []
	for i: int in 2:
		var octopus: Ingredient = _octopus_in_hand()
		assert_true(_kitchen.interact(_actor), "acepta el pulpo %d" % i)
		octopuses.append(octopus)
	var anchors: Array[Node3D] = _anchors()
	for i: int in octopuses.size():
		var point: Node3D = octopuses[i].get_node("%AnchorPoint")
		assert_true(
			point.global_transform.is_equal_approx(anchors[i].global_transform),
			"pulpo %d sobre el ancla de la plaza %d" % [i, i]
		)
	assert_almost_eq(
		anchors[1].position.x - anchors[0].position.x,
		CookingStation.SLOT_SPACING,
		TOLERANCE,
		"los dos pulpos a SLOT_SPACING"
	)


func test_ac1_kitchen_data_capacity_is_spread_and_centered() -> void:
	assert_gt(KITCHEN_DATA.capacity, 1, "kitchen.tres tiene más de una plaza")
	_spawn_kitchen()
	_assert_layout(KITCHEN_DATA.capacity)


func test_ac1_forced_capacity_three_is_spread_and_centered() -> void:
	_spawn_kitchen(FORCED_CAPACITY)
	_assert_layout(FORCED_CAPACITY)


func test_ac2_two_octopuses_sit_on_their_slot_anchors() -> void:
	_spawn_kitchen()
	_assert_two_octopuses_on_their_anchors()


func test_ac2_two_octopuses_sit_on_their_slot_anchors_with_capacity_three() -> void:
	_spawn_kitchen(FORCED_CAPACITY)
	_assert_two_octopuses_on_their_anchors()
