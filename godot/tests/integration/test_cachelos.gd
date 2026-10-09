extends GutTest

const KITCHEN_SCENE: PackedScene = preload("res://entities/stations/kitchen.tscn")
const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const CACHELOS_SCENE: PackedScene = preload("res://entities/items/cachelos.tscn")
const STATION_SCENE: PackedScene = preload("res://entities/stations/seasoning_station.tscn")
const SMALL_BOX: Resource = preload("res://data/boxes/small.tres")

const STEP: float = 0.1
const INTERACTABLE_LAYER: int = 1 << 2

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
	_kitchen = KITCHEN_SCENE.instantiate()
	_level.add_child(_kitchen)


func after_each() -> void:
	get_tree().paused = false


func _cook_for(seconds: float) -> void:
	simulate(_kitchen, roundi(seconds / STEP), STEP)


func test_ac2_cachelo_raw_to_pot_to_cooked() -> void:
	var cachelo: Ingredient = CACHELOS_SCENE.instantiate()
	_level.add_child(cachelo)
	_hold.pick_up(cachelo)

	_kitchen.interact(_actor)
	assert_true(_kitchen.is_cooking())
	assert_null(_hold.get_held_item())

	_cook_for(5.0)
	assert_true(cachelo.is_cooked())


## PUL-061 (AC12 de la estación): los cachelos cocidos ya no se echan sobre la caja; van al cuenco
## de la estación. La caja llena consume la pulsación sin cambiar y los cachelos siguen en la mano.
func test_ac2_cachelo_cooked_no_longer_seasons_a_full_box() -> void:
	var cachelo: Ingredient = CACHELOS_SCENE.instantiate()
	_level.add_child(cachelo)
	cachelo.set_cooked()
	_hold.pick_up(cachelo)

	var box: Box = BOX_SCENE.instantiate()
	_level.add_child(box)
	box.data = SMALL_BOX
	box.fill = 1.0  # full

	assert_true(box.interact(_actor))

	assert_eq(box.get_contents().seasonings.size(), 0)
	assert_eq(_hold.get_held_item(), cachelo)
	assert_true(is_instance_valid(cachelo) and not cachelo.is_queued_for_deletion())


func test_ac2_cachelo_raw_rejected_by_box() -> void:
	var cachelo: Ingredient = CACHELOS_SCENE.instantiate()
	_level.add_child(cachelo)
	_hold.pick_up(cachelo)

	var box: Box = BOX_SCENE.instantiate()
	_level.add_child(box)
	box.data = SMALL_BOX
	box.fill = 1.0  # full

	box.interact(_actor)

	var contents := box.get_contents()
	assert_eq(contents.seasonings.size(), 0)
	assert_eq(_hold.get_held_item(), cachelo)


## Los cuatro condimentos caben a la vez (pimentón, sal, aceite y cachelos) con la API de la
## estación (`toggle_seasoning`, ADR-003 §8.3).
func test_ac3_four_seasonings() -> void:
	var box: Box = BOX_SCENE.instantiate()
	_level.add_child(box)
	box.data = SMALL_BOX
	box.fill = 1.0  # full
	for path: String in ["salt", "paprika", "oil", "cachelos"]:
		var seasoning: SeasoningData = load("res://data/seasonings/%s.tres" % path)
		assert_eq(box.toggle_seasoning(seasoning, true), SeasoningRules.Rejection.NONE, path)

	var contents := box.get_contents()
	assert_eq(contents.seasonings.size(), 4)


## PUL-046: una malla por estado (cachelos_raw / cachelos_cooked) con los colores de la paleta
## (art-bible §3.3); sustituye a la prueba de cambio de material del placeholder (PUL-033).
func test_pul046_state_meshes_and_palette() -> void:
	var cachelo: Ingredient = CACHELOS_SCENE.instantiate()
	_level.add_child(cachelo)
	var raw: MeshInstance3D = cachelo.get_node("Model").find_child("cachelos_raw") as MeshInstance3D
	var cooked: MeshInstance3D = (
		cachelo.get_node("Model").find_child("cachelos_cooked") as MeshInstance3D
	)
	assert_not_null(raw)
	assert_not_null(cooked)
	assert_true(raw.visible, "en crudo se ve la patata entera")
	assert_false(cooked.visible)
	cachelo.set_cooked()
	assert_false(raw.visible)
	assert_true(cooked.visible, "al cocerse se ven los trozos")
	assert_has(_material_names(raw), "mat_food_potato_raw")
	assert_has(_material_names(cooked), "mat_food_potato_cooked")
	assert_does_not_have(_material_names(cooked), "mat_food_potato_raw")
	var raw_color: Color = _albedo(raw, "mat_food_potato_raw")
	var cooked_color: Color = _albedo(cooked, "mat_food_potato_cooked")
	assert_gt(cooked_color.get_luminance() - raw_color.get_luminance(), 0.3, "luminosidad")


func _material_names(mesh: MeshInstance3D) -> Array[String]:
	var names: Array[String] = []
	for i: int in mesh.get_surface_override_material_count():
		names.append(mesh.get_active_material(i).resource_name)
	return names


func _albedo(mesh: MeshInstance3D, material_name: String) -> Color:
	for i: int in mesh.get_surface_override_material_count():
		var material: BaseMaterial3D = mesh.get_active_material(i) as BaseMaterial3D
		if material != null and material.resource_name == material_name:
			return material.albedo_color
	return Color.BLACK


## PUL-097 (R6): los cachelos cocidos en la olla van al cuenco de la estación: 2 raciones cada uno.
func test_pul097_cooked_cachelo_from_the_pot_gives_two_portions_to_the_bowl() -> void:
	var station: SeasoningStation = STATION_SCENE.instantiate()
	station.position = Vector3(0.0, 0.0, 10.0)
	_level.add_child(station)
	var bowl: CachelosBowl = station.get_node("CachelosBowl")
	var cachelo: Ingredient = CACHELOS_SCENE.instantiate()
	_level.add_child(cachelo)
	_hold.pick_up(cachelo)
	_kitchen.interact(_actor)
	_cook_for(5.0)
	assert_true(cachelo.is_cooked())
	_kitchen.interact(_actor)
	assert_eq(_hold.get_held_item(), cachelo, "cachelo cocido en la mano")

	assert_true(bowl.interact(_actor))
	assert_eq(bowl.stock, 2)
	assert_null(_hold.get_held_item())
