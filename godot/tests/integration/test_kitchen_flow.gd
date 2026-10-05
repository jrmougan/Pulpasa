extends GutTest
## PUL-019: flujo completo de cocina sobre `kitchen_sandbox.tscn` con los autoloads reales
## (`OrderService`, `RoundManager`, `EventBus`). Nevera → olla → esperar cocción → caja a la bandeja
## de la estación → llenar → condimentos de la comanda en los dispensadores (PUL-061) → entrega.
## Sin física de movimiento: el jugador se aparta para que su detector no vea nada y cada
## pulsación pasa por `InteractionComponent.interact_pressed()` con el objetivo que publicaría el
## detector (`target_changed`).

const SANDBOX_SCENE: PackedScene = preload("res://scenes/sandbox/kitchen_sandbox.tscn")
const SLOT_ID: int = 1
const OTHER_SLOT_ID: int = 2
## Lejos de todo: el detector del jugador no cambia de objetivo por su cuenta.
const FAR: Vector3 = Vector3(-9, 0, -9)
## Margen sobre `cook_time` para la espera de la cocción.
const COOK_MARGIN: float = 3.0

var _sandbox: Node3D
var _player: Player
var _actor: InteractionComponent
var _detector: Node
var _hold: Holder
var _storage: Node
var _kitchen: CookingStation
var _station: SeasoningStation
## Reloj de los dispensadores: cada pulsación avanza 1 s (antirrebote sin esperas reales).
var _now: float = 100.0
var _stand: OrderStand


func before_each() -> void:
	watch_signals(EventBus)
	_sandbox = SANDBOX_SCENE.instantiate()
	add_child_autofree(_sandbox)
	_player = _sandbox.get_node("Player")
	_player.global_position = FAR
	_actor = _player.get_node("%InteractionComponent")
	_detector = _player.get_node("%InteractionDetector")
	_hold = _player.get_node("%HoldComponent")
	_storage = _sandbox.get_node("Stations/OctopusStorage")
	_kitchen = _sandbox.get_node("Stations/Kitchen")
	_station = _sandbox.get_node("Stations/SeasoningStation")
	for dispenser: Node in _station.get_node("Dispensers").get_children():
		(dispenser as SeasoningDispenser).clock = func() -> float: return _now
	_stand = _sandbox.get_node("Stations/OrderStand1")
	await wait_physics_frames(2)
	# M1: las comandas iniciales se generan tras first_order_delay (5 s, dato).
	RoundManager.round_state.advance(5.0)


## Una pulsación de interactuar con `target` como objetivo del detector (`null` = nada delante).
func _press(target: Node) -> bool:
	_detector.emit_signal(&"target_changed", null, target)
	return _actor.interact_pressed()


func _order_for(slot_id: int) -> ActiveOrder:
	for order: ActiveOrder in OrderService.get_active_orders():
		if order.slot_id == slot_id:
			return order
	return null


func _label(stand: OrderStand) -> String:
	return (stand.get_node("%OrderLabel") as Label3D).text


func _box_spawner(box_data: BoxData) -> ItemSpawner:
	for child: Node in _sandbox.get_node("Stations/BoxShelf").get_children():
		if child is ItemSpawner and (child as ItemSpawner).data == box_data:
			return child
	return null


func _dispenser(seasoning: SeasoningData) -> SeasoningDispenser:
	for child: Node in _station.get_node("Dispensers").get_children():
		if (child as SeasoningDispenser).seasoning == seasoning:
			return child as SeasoningDispenser
	return null


func _is_released(node: Variant) -> bool:
	return not is_instance_valid(node) or (node as Node).is_queued_for_deletion()


## Comanda del puesto 1 con condimentos (precondición de la semilla del sandbox).
func _seasoned_order() -> ActiveOrder:
	var order: ActiveOrder = _order_for(SLOT_ID)
	assert_not_null(order, "el puesto 1 tiene comanda al arrancar")
	assert_gt(order.data.seasonings.size(), 0, "rng_seed del sandbox: comanda con condimentos")
	return order


## Nevera → olla; mientras cuece, caja de la comanda a la bandeja de la estación; tras la cocción,
## pulpo cocido a la mano y cortes sobre la bandeja hasta llenar la caja; el resto del pulpo se
## suelta. Devuelve la caja llena.
func _cook_and_fill(order: ActiveOrder) -> Box:
	assert_true(_press(_storage), "nevera: da un pulpo")
	var octopus: Ingredient = _hold.get_held_item() as Ingredient
	assert_not_null(octopus)
	assert_false(octopus.is_cooked())
	assert_true(_press(_kitchen), "olla: acepta el pulpo crudo")
	assert_true(_kitchen.is_cooking())
	assert_null(_hold.get_held_item())

	var spawner: ItemSpawner = _box_spawner(order.data.recipe.box)
	assert_not_null(spawner, "hay estantería para la caja de la comanda")
	assert_true(_press(spawner), "estantería: da la caja")
	var box: Box = _hold.get_held_item() as Box
	assert_not_null(box)
	assert_eq(box.data, order.data.recipe.box)
	assert_true(_press(_station.get_tray()), "bandeja: guarda la caja")
	assert_eq(_station.get_box(), box)

	await wait_for_signal(_kitchen.cooking_finished, octopus.data.cook_time + COOK_MARGIN)
	assert_true(octopus.is_cooked(), "cocido tras cook_time")
	assert_true(_press(_kitchen), "olla: devuelve el pulpo cocido")
	assert_eq(_hold.get_held_item(), octopus)

	var presses: int = 0
	while not box.is_full() and presses < 100:
		assert_true(_press(box))
		presses += 1
	assert_true(box.is_full(), "caja llena tras %d cortes" % presses)
	if not _is_released(octopus):
		_press(null)
	assert_null(_hold.get_held_item())
	return box


## Pulsa con la mano vacía el dispensador de cada condimento sobre la caja de la bandeja.
func _season(box: Box, seasonings: Array[SeasoningData]) -> void:
	assert_eq(_station.get_box(), box, "la caja está en la bandeja")
	for seasoning: SeasoningData in seasonings:
		var dispenser: SeasoningDispenser = _dispenser(seasoning)
		assert_not_null(dispenser, "dispensador de %s" % seasoning.resource_path)
		assert_true(_press(dispenser), "pulsa el dispensador")
		_now += 1.0
		assert_true(box.has_seasoning(seasoning))
	assert_null(_hold.get_held_item())


func test_ac1_full_flow_completes_exactly_one_order_and_stand_gets_new_one() -> void:
	var order: ActiveOrder = _seasoned_order()
	var other: ActiveOrder = _order_for(OTHER_SLOT_ID)
	assert_eq(_label(_stand), "#%d" % order.id)
	var box: Box = await _cook_and_fill(order)
	_season(box, order.data.seasonings)
	assert_true(_press(box), "coge la caja del slot")
	assert_eq(_hold.get_held_item(), box)

	assert_true(_press(_stand), "puesto: entrega")
	assert_signal_emit_count(EventBus, "order_completed", 1)
	assert_signal_not_emitted(EventBus, "delivery_rejected")
	var completed: ActiveOrder = get_signal_parameters(EventBus, "order_completed", 0)[0]
	assert_eq(completed.id, order.id)
	assert_eq(completed.slot_id, SLOT_ID)
	assert_true(_is_released(box), "la caja entregada se libera")
	assert_null(_hold.get_held_item())

	var replacement: ActiveOrder = _order_for(SLOT_ID)
	assert_not_null(replacement, "el puesto recibe comanda nueva")
	assert_ne(replacement.id, order.id)
	assert_eq(_label(_stand), "#%d" % replacement.id)
	assert_eq(_order_for(OTHER_SLOT_ID).id, other.id, "el otro puesto no cambia")
	await wait_physics_frames(5)
	assert_signal_emit_count(EventBus, "order_completed", 1, "una sola vez, también después")


func test_ac2_missing_seasoning_rejected_extra_seasoning_rejected() -> void:
	var order: ActiveOrder = _seasoned_order()
	var box: Box = await _cook_and_fill(order)
	var wanted: Array[SeasoningData] = order.data.seasonings
	var missing: SeasoningData = wanted[wanted.size() - 1]
	var partial: Array[SeasoningData] = wanted.slice(0, wanted.size() - 1)
	_season(box, partial)
	assert_true(_press(box))

	assert_true(_press(_stand), "consume la pulsación aunque rechace")
	assert_signal_emit_count(EventBus, "delivery_rejected", 1)
	assert_eq(get_signal_parameters(EventBus, "delivery_rejected", 0), [SLOT_ID, order.id, 0])
	assert_signal_not_emitted(EventBus, "order_completed")
	assert_eq(_hold.get_held_item(), box, "la caja rechazada se queda en la mano")
	assert_eq(_order_for(SLOT_ID).id, order.id, "la comanda sigue viva")

	assert_true(_press(_station.get_tray()), "devuelve la caja a la bandeja")
	_season(box, [missing])
	var extra: Array[SeasoningData] = []
	for child: Node in _station.get_node("Dispensers").get_children():
		var data: SeasoningData = (child as SeasoningDispenser).seasoning
		var group: StringName = data.exclusivity_group
		if wanted.has(data) or (not group.is_empty() and box.has_seasoning_in_group(group)):
			continue
		extra.append(data)
		break
	assert_gt(extra.size(), 0, "hay al menos un condimento que la comanda no pide")
	_season(box, extra)
	assert_true(_press(box))
	# El puesto ignora un segundo intento de la misma caja en el mismo tick de física.
	await wait_physics_frames(1)

	assert_true(_press(_stand))
	assert_signal_not_emitted(EventBus, "order_completed")
	assert_signal_emit_count(EventBus, "delivery_rejected", 2)
	assert_eq(get_signal_parameters(EventBus, "delivery_rejected", 1), [SLOT_ID, order.id, 0])
	assert_eq(_hold.get_held_item(), box, "la caja rechazada se queda en la mano")
	assert_eq(_order_for(SLOT_ID).id, order.id, "la comanda sigue viva")
