extends GutTest
## PUL-061/097: la estación de condimentos al paso en `level_01.tscn` real (planta B), feature
## `estacion-condimentos.md` AC16–AC18 (D23: sin bandeja, la caja se condimenta en la mano).
## AC16 y AC17 se juegan con el teclado y el detector real
## (`level_walker.gd`): el test nunca llama a `interact()` ni publica `target_changed`.
## AC18 recorre todos los `interactable` del nivel y comprueba que solo los dispensadores y el
## cuenco cambian el condimento de una caja.

const LEVEL: PackedScene = preload("res://scenes/levels/level_01.tscn")
const Walker: GDScript = preload("res://tests/integration/level_walker.gd")
const RECIPE: RecipeData = preload("res://data/recipes/individual.tres")
const SALT: SeasoningData = preload("res://data/seasonings/salt.tres")
const OIL: SeasoningData = preload("res://data/seasonings/oil.tres")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const CACHELOS_SCENE: PackedScene = preload("res://entities/items/cachelos.tscn")
## Del centro de una pieza de la estación al punto desde el que se usa (m).
const ACCESS: float = 1.0
## Distancia al puesto desde la que se le pulsa E, fuera de su `%DeliveryZone` (m).
const STAND_FRONT: float = 2.5
## Espera tras cambiar de personaje (> `switch_cooldown` de `input_config.tres`).
const SWITCH_WAIT: float = 0.3

var _level: Node
var _station: SeasoningStation
## Lados de la barra (−1 cocina, +1 servicio) por los que ha pasado cada personaje.
var _sides: Dictionary[String, Dictionary] = {}


func before_each() -> void:
	GameState.set_paused(false)
	watch_signals(EventBus)
	_sides.clear()


func after_each() -> void:
	if get_tree().physics_frame.is_connected(_track_sides):
		get_tree().physics_frame.disconnect(_track_sides)
	for keycode: Key in [KEY_W, KEY_A, KEY_S, KEY_D]:
		Input.parse_input_event(_release(keycode))
	Input.flush_buffered_events()
	GameState.set_paused(false)
	GameState.reset_input()


func _release(keycode: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = false
	return event


## Nivel real en Individual con una sola comanda (pulpo + sal + aceite) en el puesto 1.
func _load_level() -> void:
	var order: OrderData = OrderData.new()
	order.recipe = RECIPE
	order.seasonings = [SALT, OIL] as Array[SeasoningData]
	order.max_time = 300.0
	var catalog: OrderCatalog = OrderCatalog.new()
	catalog.orders = [order] as Array[OrderData]
	catalog.max_active_orders = 1
	_level = LEVEL.instantiate()
	_level.set("order_catalog", catalog)
	(_level.get_node("CharacterSwitcher") as CharacterSwitcher).set_mode(GameMode.Mode.SINGLE)
	add_child_autofree(_level)
	_station = _level.get_node("Stations/SeasoningStation")
	await wait_physics_frames(2)
	var config: RoundConfig = _level.get("round_config")
	RoundManager.round_state.advance(config.first_order_delay)
	assert_eq(OrderService.get_active_orders().size(), 1)


func _character(index: int) -> Player:
	return _level.get_node("Characters/Player%d" % index) as Player


## Caja de la receta llena con cortes reales de pulpo cocido, en la mano de `character`.
func _full_box_in_hand(character: Player) -> Box:
	var actor: InteractionComponent = character.get_node("%InteractionComponent")
	var hold: Holder = character.get_node("%HoldComponent")
	var box: Box = BOX_SCENE.instantiate()
	box.data = RECIPE.box
	_level.get_node("Items").add_child(box)
	box.global_position = character.global_position + Vector3(0.0, 0.5, 0.0)
	while not box.is_full():
		var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
		_level.get_node("Items").add_child(octopus)
		octopus.set_cooked()
		assert_true(hold.pick_up(octopus))
		while (
			octopus.is_inside_tree() and not octopus.is_queued_for_deletion() and not box.is_full()
		):
			box.interact(actor)
		if hold.get_held_item() != null:
			hold.drop().free()
	assert_true(hold.pick_up(box))
	return box


func _track_sides() -> void:
	for index: int in [1, 2]:
		var key: String = "Player%d" % index
		if not _sides.has(key):
			_sides[key] = {}
		_sides[key][Walker.side_of(Walker.xz(_character(index).global_position))] = true


## Pasaplatos de la barra en que la cocina deja la caja llena.
func _pass_slot() -> Slot:
	return _level.get_node("Stations/PassSlot05") as Slot


func _slot_xz() -> Vector2:
	return Walker.xz(_pass_slot().global_position)


func _dispenser(seasoning: SeasoningData) -> SeasoningDispenser:
	for child: Node in _station.get_node("Dispensers").get_children():
		if (child as SeasoningDispenser).seasoning == seasoning:
			return child as SeasoningDispenser
	return null


## Coge la caja del pasaplatos, la condimenta con sal y aceite en la mano y la entrega en el puesto
## 1, todo desde el lado de condimentar con `walker`.
func _season_and_deliver(walker: Walker, box: Box) -> void:
	var slot: Vector2 = _slot_xz()
	assert_eq(await walker.use(slot, Vector2(slot.x, ACCESS)), box, "coge la caja del pasaplatos")
	assert_eq(walker.holder().get_held_item(), box)
	for seasoning: SeasoningData in [SALT, OIL]:
		var dispenser: SeasoningDispenser = _dispenser(seasoning)
		var at: Vector2 = Walker.xz(dispenser.global_position)
		var stand: Vector2 = Walker.station_stand(at, _station.global_position.z, 1.0)
		assert_eq(await walker.use(at, stand), dispenser, dispenser.name)
		assert_true(box.has_seasoning(seasoning), "caja con %s" % seasoning.display_name)
	assert_eq(walker.holder().get_held_item(), box, "la caja condimentada sigue en la mano")
	var stand: OrderStand = _level.get_node("Stations/OrderStand1")
	var stand_xz: Vector2 = Walker.xz(stand.global_position)
	await walker.walk_to(stand_xz + Vector2(0.0, -STAND_FRONT))
	for _i: int in 20:
		if walker.detector().get_target() == stand:
			break
		await walker.push_towards(stand_xz, 1)
	assert_eq(walker.detector().get_target(), stand, "de cara al puesto 1")
	await walker.tap_interact()


# --- AC16 ----------------------------------------------------------------------------------------


func test_ac16_single_pass_with_switch_completes_order_without_going_around() -> void:
	await _load_level()
	var cook: Player = _character(2)
	var server: Player = _character(1)
	assert_eq(Walker.side_of(Walker.xz(cook.global_position)), -1.0, "A en el lado de pase")
	assert_eq(Walker.side_of(Walker.xz(server.global_position)), 1.0, "B en el de condimentar")
	assert_eq((cook.get_node("%Control") as ControlComponent).controlled_by, 0)
	get_tree().physics_frame.connect(_track_sides)

	# A (cocina) deja la caja llena en el pasaplatos por el lado de pase.
	await _switch(Walker.new(get_tree(), server))
	assert_eq((cook.get_node("%Control") as ControlComponent).controlled_by, 1, "J1 lleva a A")
	var a: Walker = Walker.new(get_tree(), cook)
	var box: Box = _full_box_in_hand(cook)
	var slot: Vector2 = _slot_xz()
	assert_eq(await a.use(slot, Vector2(slot.x, -ACCESS)), _pass_slot(), "pasaplatos")
	assert_eq(_pass_slot().get_item(), box, "caja en el pasaplatos")

	# Cambio a B, que condimenta y entrega.
	await _switch(a)
	assert_eq((server.get_node("%Control") as ControlComponent).controlled_by, 1, "J1 lleva a B")
	await _season_and_deliver(Walker.new(get_tree(), server), box)

	assert_signal_emit_count(EventBus, "order_completed", 1)
	assert_signal_not_emitted(EventBus, "delivery_rejected")
	assert_eq(_sides["Player2"].keys(), [-1.0], "A no sale de la cocina")
	assert_eq(_sides["Player1"].keys(), [1.0], "B no sale del servicio")


# --- AC17 ----------------------------------------------------------------------------------------


func test_ac17_single_character_going_around_the_counter_also_completes() -> void:
	await _load_level()
	var only: Player = _character(1)
	var idle: Player = _character(2)
	var idle_start: Vector3 = idle.global_position
	get_tree().physics_frame.connect(_track_sides)
	var walker: Walker = Walker.new(get_tree(), only)
	var box: Box = _full_box_in_hand(only)

	# Rodea la barra por el hueco y deja la caja por el lado de pase.
	var slot: Vector2 = _slot_xz()
	assert_eq(await walker.use(slot, Vector2(slot.x, -ACCESS)), _pass_slot(), "pasaplatos")
	assert_eq(_pass_slot().get_item(), box)
	# Vuelve al servicio rodeando otra vez, condimenta y entrega.
	await _season_and_deliver(walker, box)

	assert_signal_emit_count(EventBus, "order_completed", 1)
	assert_eq((idle.get_node("%Control") as ControlComponent).controlled_by, 0, "sin cambio")
	assert_true(_sides["Player1"].has(-1.0) and _sides["Player1"].has(1.0), "rodeó la barra")
	assert_almost_eq(idle.global_position.distance_to(idle_start), 0.0, 0.05, "el otro, quieto")


func _switch(walker: Walker) -> void:
	await walker.tap(KEY_Q)
	await wait_seconds(SWITCH_WAIT)


# --- AC18 ----------------------------------------------------------------------------------------


func test_ac18_no_spice_shelf_nor_jars_in_the_level() -> void:
	_level = LEVEL.instantiate()
	add_child_autofree(_level)
	assert_null(_level.get_node_or_null("Stations/SpiceShelf"), "sin SpiceShelf")
	for node: Node in _level.find_children("*", "", true, false):
		var script: Script = node.get_script() as Script
		var path: String = script.resource_path if script != null else ""
		assert_false(path.ends_with("seasoning_item.gd"), "sin botes: %s" % node.get_path())
		assert_false(node.scene_file_path.ends_with("spice_shelf.tscn"), str(node.get_path()))
		assert_false(node.scene_file_path.ends_with("seasoning.tscn"), str(node.get_path()))
	var stations: Array[Node] = _level.find_children("*", "SeasoningStation", true, false)
	assert_eq(stations.size(), 1, "una estación de condimentos")


## Con una caja llena en cada uno de dos pasaplatos, pulsar cualquier `interactable` del nivel con
## la mano vacía o con cachelos cocidos no cambia sus condimentos, salvo los 4 dispensadores y el
## cuenco (que además no son objetivo sin caja en la mano). Control positivo: con la caja en la mano
## sí cambian.
func test_ac18_only_dispensers_and_bowl_change_a_box_seasoning() -> void:
	await _load_level()
	var player: Player = _character(1)
	var actor: InteractionComponent = player.get_node("%InteractionComponent")
	var hold: Holder = player.get_node("%HoldComponent")
	var slot_a: Slot = _level.get_node("Stations/PassSlot02")
	var slot_b: Slot = _level.get_node("Stations/PassSlot01")
	var on_a: Box = _full_box_in_hand(player)
	assert_true(slot_a.interact(actor))
	var on_b: Box = _full_box_in_hand(player)
	assert_true(slot_b.interact(actor))
	assert_null(hold.get_held_item())
	var changes: Array[Node] = []
	for box: Box in [on_a, on_b]:
		box.seasoned.connect(func(_s: SeasoningData) -> void: changes.append(box))
		box.seasoning_removed.connect(func(_s: SeasoningData) -> void: changes.append(box))

	var allowed: Array[Node] = _station.get_node("Dispensers").get_children()
	allowed.append(_station.get_node("CachelosBowl"))
	var others: Array[Node] = []
	for node: Node in get_tree().get_nodes_in_group(&"interactable"):
		if _level.is_ancestor_of(node) and not allowed.has(node):
			others.append(node)
	assert_gt(others.size(), 10, "hay objetivos que barrer")

	for with_cachelos: bool in [false, true]:
		for target: Node in others:
			if not is_instance_valid(target) or target.is_queued_for_deletion():
				continue
			_reset_hand(hold, [on_a, on_b], [slot_a, slot_b], actor)
			if with_cachelos:
				var cachelos: Ingredient = CACHELOS_SCENE.instantiate()
				_level.get_node("Items").add_child(cachelos)
				cachelos.state = IngredientData.CookingState.COOKED
				assert_true(hold.pick_up(cachelos))
			if target.call(&"can_interact", actor):
				target.call(&"interact", actor)
			assert_eq(changes, [] as Array[Node], "%s no condimenta" % target.name)
	_reset_hand(hold, [on_a, on_b], [slot_a, slot_b], actor)
	assert_eq(slot_a.get_item(), on_a)
	assert_true(on_a.get_contents().seasonings.is_empty())
	assert_true(on_b.get_contents().seasonings.is_empty())

	# Control positivo: con la caja en la mano, cada dispensador y el cuenco la cambian.
	var bowl: CachelosBowl = _station.get_node("CachelosBowl")
	var cooked: Ingredient = CACHELOS_SCENE.instantiate()
	_level.get_node("Items").add_child(cooked)
	cooked.state = IngredientData.CookingState.COOKED
	assert_true(hold.pick_up(cooked))
	assert_true(bowl.interact(actor), "cachelos al cuenco")
	assert_true(slot_a.interact(actor), "coge la caja")
	assert_eq(hold.get_held_item(), on_a)
	for dispenser: Node in _station.get_node("Dispensers").get_children():
		changes.clear()
		assert_true(dispenser.call(&"interact", actor))
		assert_gt(changes.size(), 0, "%s condimenta" % dispenser.name)
	changes.clear()
	assert_true(bowl.interact(actor), "alterna cachelos en la caja")
	assert_eq(changes, [on_a] as Array[Node])


## Deja la mano vacía: las cajas vigiladas vuelven a su pasaplatos y lo demás se libera.
func _reset_hand(
	hold: Holder, boxes: Array[Box], slots: Array[Slot], actor: InteractionComponent
) -> void:
	var held: Node = hold.get_held_item()
	if held == null:
		return
	var index: int = boxes.find(held as Box)
	if index >= 0:
		assert_true(slots[index].interact(actor))
	else:
		hold.drop().free()
	assert_null(hold.get_held_item())
