# gdlint: disable=max-public-methods
extends GutTest
## PUL-101 R16 (L4): Individual con cambio, dos pedidos S con un solo pulpo en `level_01.tscn` real
## y exactamente 2 pulsaciones de `p1_switch`. Todo con el teclado y el detector reales
## (`level_walker.gd`): el test nunca llama a `interact()` ni publica `target_changed`.

const LEVEL: PackedScene = preload("res://scenes/levels/level_01.tscn")
const SMALL_BOX: BoxData = preload("res://data/boxes/small.tres")
const Walker: GDScript = preload("res://tests/integration/level_walker.gd")
## R16: comandas S del catálogo real sin cachelos (dulce+sal y aceite+dulce).
const R16_ORDERS: Array[OrderData] = [
	preload("res://data/orders/order_2.tres"),
	preload("res://data/orders/order_4.tres"),
]
const R16_PATIENCE: float = 900.0
const R16_STAND_FRONT: float = 2.5
const R16_SWITCH_WAIT: float = 0.3

var _level: Node
var _switch_presses: int = 0


func before_each() -> void:
	PhaselessConfig.disable()
	GameState.set_paused(false)
	watch_signals(EventBus)
	_switch_presses = 0


func after_each() -> void:
	for keycode: Key in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_Q]:
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = keycode
		Input.parse_input_event(event)
	Input.flush_buffered_events()
	GameState.set_paused(false)
	GameState.reset_input()
	if is_instance_valid(_level):
		_level.free()
	_level = null
	PhaselessConfig.restore()


## Nivel real en Individual con dos comandas S activas (dulce+sal y aceite+dulce), sin caducidad
## práctica, para jugarlas con el teclado y el detector reales (`level_walker.gd`).
func _load_two_order_level() -> void:
	var catalog: OrderCatalog = OrderCatalog.new()
	var orders: Array[OrderData] = []
	for template: OrderData in R16_ORDERS:
		var copy: OrderData = template.duplicate() as OrderData
		copy.max_time = R16_PATIENCE
		orders.append(copy)
	catalog.orders = orders
	catalog.max_active_orders = 2
	_level = LEVEL.instantiate()
	_level.set("order_catalog", catalog)
	(_level.get_node("CharacterSwitcher") as CharacterSwitcher).set_mode(GameMode.Mode.SINGLE)
	add_child(_level)
	await wait_physics_frames(2)
	var config: RoundConfig = _level.get("round_config")
	RoundManager.round_state.advance(config.first_order_delay)


func _xz(node: Node3D) -> Vector2:
	return Vector2(node.global_position.x, node.global_position.z)


## Cambio de personaje con la tecla del jugador 1 (`p1_switch`); cuenta las pulsaciones.
func _press_switch(walker: RefCounted) -> void:
	_switch_presses += 1
	await walker.call(&"tap", KEY_Q)
	await wait_seconds(R16_SWITCH_WAIT)


## Cualquier pieza usada de frente desde `stand`; devuelve el objetivo que tenía el detector.
func _use_at(walker: RefCounted, part: Node3D, stand: Vector2) -> Node:
	return await walker.call(&"use", _xz(part), stand)


func test_r16_single_with_switch_two_s_orders_one_octopus_two_switches() -> void:
	await _load_two_order_level()
	var switched_before: int = get_signal_emit_count(EventBus, "character_switched")
	var active: Array[ActiveOrder] = OrderService.get_active_orders()
	assert_eq(active.size(), 2, "dos pedidos")
	var server_player: Player = _level.get_node("Characters/Player1") as Player
	var cook_player: Player = _level.get_node("Characters/Player2") as Player
	var server: RefCounted = Walker.new(get_tree(), server_player)
	var cook: RefCounted = Walker.new(get_tree(), cook_player)
	var stations: Node = _level.get_node("Stations")

	# 1. Servicio: dos cajas S del rack, cada una a su pasaplatos por el lado de condimentar.
	var boxes: Array[Box] = []
	var slots: Array[Slot] = [stations.get_node("PassSlot01"), stations.get_node("PassSlot02")]
	var spawner: Node3D = stations.get_node("BoxShelf/SmallSpawner")
	for i: int in 2:
		var at: Vector2 = _xz(spawner)
		assert_eq(await server.use(at, at + Vector2(0.9, 0.0)), spawner, "rack")
		var box: Box = server_player.get_node("%HoldComponent").get_held_item() as Box
		assert_not_null(box, "caja S en la mano")
		assert_eq(box.data, SMALL_BOX)
		var slot_xz: Vector2 = _xz(slots[i])
		assert_eq(await server.use(slot_xz, Vector2(slot_xz.x, 1.0)), slots[i], "pasaplatos")
		assert_eq(slots[i].get_item(), box)
		boxes.append(box)

	# 2. Cambio 1: cocinero. Un pulpo cocido corta las dos cajas por el lado de pase.
	await _press_switch(server)
	var cook_hold: Holder = cook_player.get_node("%HoldComponent")
	var storage: Node3D = stations.get_node("OctopusStorage")
	var pot: Node3D = stations.get_node("Kitchen")
	var back: Vector2 = Vector2(0.0, 0.9)
	assert_eq(await cook.use(_xz(storage), _xz(storage) + back), storage, "nevera")
	var octopus: Ingredient = cook_hold.get_held_item() as Ingredient
	assert_not_null(octopus, "pulpo en la mano")
	assert_eq(await cook.use(_xz(pot), _xz(pot) + back), pot, "olla")
	assert_true(
		await wait_until(func() -> bool: return octopus.is_cooked(), octopus.data.cook_time + 3.0),
		"pulpo cocido"
	)
	assert_eq(await cook.use(_xz(pot), _xz(pot) + back), pot, "saca el pulpo")
	assert_eq(cook_hold.get_held_item(), octopus)
	for i: int in 2:
		var slot_xz: Vector2 = _xz(slots[i])
		var guard: int = 0
		while not boxes[i].is_full() and guard < 30:
			guard += 1
			assert_eq(await cook.use(slot_xz, Vector2(slot_xz.x, -1.0)), boxes[i], "corta")
		assert_true(boxes[i].is_full(), "caja %d llena" % (i + 1))
		if i == 0:
			assert_true(is_instance_valid(octopus), "el mismo pulpo sirve para la segunda caja")

	# 3. Cambio 2: servicio. Cada caja se condimenta en la mano y se entrega en su puesto.
	await _press_switch(cook)
	var station: SeasoningStation = stations.get_node("SeasoningStation")
	for i: int in 2:
		var order: ActiveOrder = active[i]
		var slot_xz: Vector2 = _xz(slots[i])
		assert_eq(await server.use(slot_xz, Vector2(slot_xz.x, 1.0)), boxes[i], "coge la caja")
		for seasoning: SeasoningData in order.data.seasonings:
			var dispenser: SeasoningDispenser = _dispenser_of(station, seasoning)
			assert_not_null(dispenser, seasoning.display_name)
			var at: Vector2 = _xz(dispenser)
			var stand: Vector2 = Vector2(at.x, station.global_position.z + 1.0)
			assert_eq(await server.use(at, stand), dispenser, dispenser.name)
		var kiosk: OrderStand = stations.get_node("OrderStand%d" % order.slot_id) as OrderStand
		var kiosk_xz: Vector2 = _xz(kiosk)
		await server.walk_to(kiosk_xz + Vector2(0.0, -R16_STAND_FRONT))
		for _n: int in 20:
			if server.detector().get_target() == kiosk:
				break
			await server.push_towards(kiosk_xz, 1)
		await server.tap_interact()
		assert_signal_emit_count(EventBus, "order_completed", i + 1, "entrega %d" % (i + 1))

	assert_signal_emit_count(EventBus, "order_completed", 2)
	assert_signal_not_emitted(EventBus, "delivery_rejected")
	assert_eq(_switch_presses, 2, "exactamente 2 pulsaciones de p1_switch")
	var switched: int = get_signal_emit_count(EventBus, "character_switched") - switched_before
	assert_eq(switched, 2, "el nivel cambia de personaje dos veces")


func _dispenser_of(station: SeasoningStation, seasoning: SeasoningData) -> SeasoningDispenser:
	for child: Node in station.get_node("Dispensers").get_children():
		if (child as SeasoningDispenser).seasoning.same_as(seasoning):
			return child as SeasoningDispenser
	return null
