extends Node
## PUL-102: medición del flujo NUEVO (D23, M3c) en `level_01.tscn`. Adaptación de
## `docs/evidence/PUL-090/measure_flow.gd`: mismo bot (teclado simulado y detector real de
## `level_walker.gd`; nunca llama a `interact()`), mismos escenarios y mismas columnas, pero con el
## circuito nuevo:
##   - sin bandeja: la caja vacía del rack va a un pasaplatos (PassSlot), se corta ahí por el lado
##     de la cocina con el pulpo cocido y se lleva EN LA MANO a los dispensadores y al kiosco;
##   - cortes 4 / 6 / 10 (S / M / L), 6 pasaplatos 3 + 3, hueco de la barra a x 3,5;
##   - entrega entrando en la zona iluminada (Z local 3,40 del puesto) con la caja correcta;
##   - cuenco: 2 raciones por cachelo cocido (el pedido 2 con cachelos ya no vuelve a cocer).
##
## Uso (desde la raíz del repo):
##   timeout 300 godot --audio-driver Dummy --resolution 1920x1080 --fixed-fps 60 --path godot \
##     -s "$PWD/docs/evidence/PUL-102/run_measure.gd" -- solo|switch|coop|chain|all [caja sobrante]
## Escribe `docs/evidence/PUL-102/metrics.json` (o `metrics_<parte>.json`) y un resumen por stdout.
##
## Escenarios (cada uno: 2 pedidos seguidos del mismo tipo; el 2.º usa lo sobrante, como PUL-090):
##   solo   Individual, un solo personaje.
##   switch Individual, cocinero y emplatador con `p1_switch`.
##   coop   Coop 2P, J1 emplata (WASD) y J2 cocina (flechas) a la vez.
##   chain  Coop 2P, 4 pedidos S sal+aceite seguidos (R17): `chain_seq` (protocolo de PUL-090,
##          pedidos pares con el sobrante) y `chain_pipe` (cocinero y emplatador se adelantan: dos
##          cajas por pulpo, dos pulpos al fuego, caja N+1 cortándose mientras se condimenta N).
## Un bot anda en línea recta entre puntos y no duda: los tiempos son una cota inferior.

const LEVEL: PackedScene = preload("res://scenes/levels/level_01.tscn")
const Walker: GDScript = preload("res://tests/integration/level_walker.gd")
const SALT: SeasoningData = preload("res://data/seasonings/salt.tres")
const OIL: SeasoningData = preload("res://data/seasonings/oil.tres")
const CACHELOS: SeasoningData = preload("res://data/seasonings/cachelos.tres")
const SMALL: RecipeData = preload("res://data/recipes/individual.tres")
const MEDIUM: RecipeData = preload("res://data/recipes/combo_duo.tres")
const LARGE: RecipeData = preload("res://data/recipes/familiar.tres")

const TICKS: float = 60.0
## Distancia de uso desde el frente de una pieza (m).
const ACCESS: float = 1.0
const SWITCH_FRAMES: int = 18
const RETARGET_FRAMES: int = 30
const ORDERS_PER_RUN: int = 2

var _level: Node
var _frame: int = 0
var _stats: Dictionary = {}
var _last_pos: Dictionary = {}
var _cooked: int = 0
var _completed: int = 0
var _completed_at: Array[int] = []
var _rejections: int = 0
var _delivery_rejections: int = 0
var _results: Array = []
var _part: String = "all"
## Tramos andados por pieza usada (`pieza:metros`), para explicar dónde se van los metros.
var _legs: Array[String] = []
## Pasaplatos de la caja y del pulpo sobrante (protocolo secuencial).
var _box_slot: String = "PassSlot01"
var _left_slot: String = "PassSlot02"
## Pasaplatos rotativos de la cadena de 4 pedidos (3 de un lado de la barra).
var _chain_slots: Array[String] = ["PassSlot01", "PassSlot02", "PassSlot03"]


func _ready() -> void:
	_main.call_deferred()


func _main() -> void:
	for bus: int in AudioServer.bus_count:
		AudioServer.set_bus_mute(bus, true)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_part = args[0]
	if args.size() > 2:
		_box_slot = args[1]
		_left_slot = args[2]
		if _box_slot == "PassSlot04":
			_chain_slots = ["PassSlot04", "PassSlot05", "PassSlot06"]
	var kinds: Array = [
		["S", SMALL, [SALT, OIL]],
		["M", MEDIUM, [SALT, OIL]],
		["L", LARGE, [SALT, OIL]],
		["S+cachelos", SMALL, [OIL, CACHELOS]],
	]
	for mode: String in ["solo", "switch", "coop"]:
		if _part != "all" and _part != mode:
			continue
		for kind: Array in kinds:
			var result: Dictionary = await _run(mode, kind[0], kind[1], kind[2])
			_results.append(result)
			print(JSON.stringify(result))
	if _part == "all" or _part == "chain":
		for mode: String in ["chain_seq", "chain_pipe"]:
			var result: Dictionary = await _run(mode, "S", SMALL, [SALT, OIL])
			_results.append(result)
			print(JSON.stringify(result))
	var file_name: String = "metrics.json" if _part == "all" else "metrics_%s.json" % _part
	if args.size() > 2:
		file_name = "metrics_%s_%s_%s.json" % [_part, _box_slot, _left_slot]
	var path: String = ProjectSettings.globalize_path("res://").path_join(
		"../docs/evidence/PUL-102/" + file_name
	)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(_results, "  "))
	file.close()
	print("OK ", path)
	get_tree().quit(0)


# --- Montaje ------------------------------------------------------------------------------------


func _run(mode: String, kind: String, recipe: RecipeData, seasonings: Array) -> Dictionary:
	var order: OrderData = OrderData.new()
	order.recipe = recipe
	order.seasonings.assign(seasonings)
	order.max_time = 600.0
	var catalog: OrderCatalog = OrderCatalog.new()
	catalog.orders = [order] as Array[OrderData]
	catalog.max_active_orders = 1
	GameState.set_paused(false)
	_level = LEVEL.instantiate()
	_level.set("order_catalog", catalog)
	var switcher: CharacterSwitcher = _level.get_node("CharacterSwitcher")
	var coop: bool = mode == "coop" or mode.begins_with("chain")
	switcher.set_mode(GameMode.Mode.COOP_2P if coop else GameMode.Mode.SINGLE)
	get_tree().root.add_child(_level)
	await _frames(2)
	var config: RoundConfig = _level.get("round_config")
	RoundManager.round_state.advance(config.first_order_delay)
	_cooked = 0
	_completed = 0
	_completed_at.clear()
	_rejections = 0
	_delivery_rejections = 0
	_stats = {
		"presses": 0,
		"switches": 0,
		"retargets": 0,
		"dist1": 0.0,
		"dist2": 0.0,
		"still1": 0,
		"still2": 0
	}
	_frame = 0
	_last_pos = {1: _xz(_char(1)), 2: _xz(_char(2))}
	for pot: String in ["Kitchen", "Kitchen2"]:
		_level.get_node("Stations/" + pot).cooking_finished.connect(_on_cooked.unbind(1))
	var station: SeasoningStation = _station()
	for child: Node in station.get_node("Dispensers").get_children():
		child.rejected.connect(_on_rejected.unbind(1))
	station.get_node("CachelosBowl").rejected.connect(_on_rejected.unbind(1))
	EventBus.order_completed.connect(_on_completed)
	EventBus.delivery_rejected.connect(_on_delivery_rejected)
	get_tree().physics_frame.connect(_track)

	var per_order: Array = []
	if mode == "chain_pipe":
		await _chain_pipe(recipe, seasonings, 4)
		var last: int = 0
		for i: int in _completed_at.size():
			(
				per_order
				. append(
					{
						"order": i + 1,
						"completed": true,
						"seconds": snappedf((_completed_at[i] - last) / TICKS, 0.01),
						"at": snappedf(_completed_at[i] / TICKS, 0.01),
					}
				)
			)
			last = _completed_at[i]
	else:
		var orders_n: int = 4 if mode == "chain_seq" else ORDERS_PER_RUN
		var leftover: bool = false
		for i: int in orders_n:
			var before: Dictionary = _stats.duplicate()
			var start: int = _frame
			var target: int = _completed + 1
			_legs.clear()
			match mode:
				"solo":
					await _solo(recipe, seasonings, leftover)
				"switch":
					await _switch_flow(recipe, seasonings, leftover)
				"coop", "chain_seq":
					await _coop(recipe, seasonings, leftover)
			var ok: bool = _completed >= target
			leftover = not leftover if mode == "chain_seq" else true
			(
				per_order
				. append(
					{
						"order": i + 1,
						"completed": ok,
						"seconds": snappedf((_frame - start) / TICKS, 0.01),
						"presses": _stats.presses - before.presses,
						"switches": _stats.switches - before.switches,
						"legs": _legs.duplicate(),
						"retargets": _stats.retargets - before.retargets,
						"meters_p1": snappedf(_stats.dist1 - before.dist1, 0.1),
						"meters_p2": snappedf(_stats.dist2 - before.dist2, 0.1),
						"still_s_p1": snappedf((_stats.still1 - before.still1) / TICKS, 0.01),
						"still_s_p2": snappedf((_stats.still2 - before.still2) / TICKS, 0.01),
					}
				)
			)

	get_tree().physics_frame.disconnect(_track)
	EventBus.order_completed.disconnect(_on_completed)
	EventBus.delivery_rejected.disconnect(_on_delivery_rejected)
	_level.queue_free()
	await _frames(3)
	GameState.reset_input()
	var result: Dictionary = {
		"mode": mode,
		"kind": kind,
		"cuts": int(round(1.0 / recipe.box.fill_per_press)),
		"orders": per_order,
		"station_rejections": _rejections,
		"delivery_rejections": _delivery_rejections,
	}
	if mode.begins_with("chain"):
		var rest: Array = per_order.slice(1)
		var sum: float = 0.0
		for entry: Dictionary in rest:
			sum += float(entry.seconds)
		result["mean_orders_2_4"] = snappedf(sum / maxf(rest.size(), 1), 0.01)
		result["presses_total"] = _stats.presses
		result["meters_p1_total"] = snappedf(_stats.dist1, 0.1)
		result["meters_p2_total"] = snappedf(_stats.dist2, 0.1)
	return result


func _char(index: int) -> Player:
	return _level.get_node("Characters/Player%d" % index) as Player


func _node(path: String) -> Node3D:
	return _level.get_node("Stations/" + path) as Node3D


static func _xz(node: Node3D) -> Vector2:
	return Vector2(node.global_position.x, node.global_position.z)


func _track() -> void:
	_frame += 1
	for index: int in [1, 2]:
		var here: Vector2 = _xz(_char(index))
		var step: float = here.distance_to(_last_pos[index])
		_stats["dist%d" % index] += step
		if step < 0.001:
			_stats["still%d" % index] += 1
		_last_pos[index] = here


func _on_cooked() -> void:
	_cooked += 1


func _on_completed(_order: ActiveOrder, _points: int) -> void:
	_completed += 1
	_completed_at.append(_frame)


func _on_rejected() -> void:
	_rejections += 1


func _on_delivery_rejected(_slot: int, _order: int, _penalty: int) -> void:
	_delivery_rejections += 1


# --- Acciones medidas ---------------------------------------------------------------------------


## Anda a `stand`, se gira hacia `expected` y pulsa. Si el detector no apunta a `expected`, lo
## corrige empujando hacia él (cuenta como `retarget`: un jugador tendría que recolocarse).
func _use(w: Walker, expected: Node, stand: Vector2, presses: int = 1) -> void:
	var aim: Vector2 = _xz(expected as Node3D)
	var before_m: float = float(_stats["dist%d" % w.player_index])
	await w.walk_to(stand)
	_legs.append("%s:%.1f" % [expected.name, float(_stats["dist%d" % w.player_index]) - before_m])
	await w.push_towards(aim, Walker.FACE_FRAMES)
	if not _targets(w, expected):
		_stats.retargets += 1
		for _i: int in RETARGET_FRAMES:
			if _targets(w, expected):
				break
			await w.push_towards(aim, 1)
	if not _targets(w, expected):
		push_warning("objetivo %s no alcanzado desde %s" % [expected.name, stand])
	for _i: int in presses:
		await w.tap_interact()
		_stats.presses += 1


func _targets(w: Walker, expected: Node) -> bool:
	var target: Node = w.detector().get_target()
	if target == expected:
		return true
	# Un slot ocupado se sustituye por su objeto guardado.
	return expected is Slot and target != null and target == (expected as Slot).get_item()


func _switch(w: Walker) -> void:
	await w.tap(KEY_Q)
	_stats.switches += 1
	await _frames(SWITCH_FRAMES)


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().physics_frame


func _wait_until(condition: Callable) -> void:
	var guard: int = 0
	while not condition.call():
		await get_tree().physics_frame
		guard += 1
		if guard > 60 * 120:
			push_error("espera agotada (120 s de juego)")
			return


func _station() -> SeasoningStation:
	return _node("SeasoningStation") as SeasoningStation


func _bowl() -> CachelosBowl:
	return _station().get_node("CachelosBowl") as CachelosBowl


## Punto de uso de una pieza de la cocina (nevera, olla): al frente, hacia el servicio.
func _kitchen_front(node: String) -> Vector2:
	return _xz(_node(node)) + Vector2(0.0, 0.9)


## Punto de uso de un pasaplatos o pieza de la estación: lado de condimentar (+1) o pase (−1).
func _side(part: Node3D, side: float) -> Vector2:
	return Vector2(_xz(part).x, _station().global_position.z + side * ACCESS)


func _slot(name: String) -> Slot:
	return _node(name) as Slot


func _shelf_spawner(recipe: RecipeData) -> Node3D:
	for name: String in ["SmallSpawner", "MediumSpawner", "LargeSpawner"]:
		var spawner: Node3D = _node("BoxShelf/" + name)
		if spawner.get("data") == recipe.box:
			return spawner
	return null


func _dispenser(seasoning: SeasoningData) -> Node3D:
	for child: Node in _station().get_node("Dispensers").get_children():
		if (child as SeasoningDispenser).seasoning == seasoning:
			return child as Node3D
	return null


func _piece(seasoning: SeasoningData) -> Node3D:
	return _bowl() if seasoning == CACHELOS else _dispenser(seasoning)


func _box_in(slot: Slot) -> Box:
	return slot.get_item() as Box


# --- Bloques del flujo ---------------------------------------------------------------------------


## Servicio: caja del tamaño de la receta del rack a un pasaplatos, por el lado de condimentar.
func _box_to_slot(w: Walker, recipe: RecipeData, slot: Slot) -> void:
	var spawner: Node3D = _shelf_spawner(recipe)
	await _use(w, spawner, _xz(spawner) + Vector2(0.9, 0.0))
	await _use(w, slot, _side(slot, 1.0))


## Cocina: pulpo a la olla 1 (y cachelos a la olla 2 si el cuenco está vacío).
func _start_cooking(w: Walker, cachelos: bool) -> void:
	await _use(w, _node("OctopusStorage"), _kitchen_front("OctopusStorage"))
	await _use(w, _node("Kitchen"), _kitchen_front("Kitchen"))
	if cachelos:
		await _use(w, _node("CachelosStorage"), _kitchen_front("CachelosStorage"))
		await _use(w, _node("Kitchen2"), _kitchen_front("Kitchen2"))


## Recoge lo cocido; los cachelos al cuenco desde el lado de pase; deja el pulpo en la mano.
func _collect_cooked(w: Walker, cachelos: bool, needed: int) -> void:
	await _wait_until(func() -> bool: return _cooked >= needed)
	if cachelos:
		await _use(w, _node("Kitchen2"), _kitchen_front("Kitchen2"))
		await _use(w, _bowl(), _side(_bowl(), -1.0))
	await _use(w, _node("Kitchen"), _kitchen_front("Kitchen"))


## Pulpo cocido en la mano: corta la caja del pasaplatos desde el lado de pase; si queda pulpo, lo
## deja en el pasaplatos de sobrante (salvo `keep`: el cocinero se queda con él en la mano).
func _cut_in_slot(
	w: Walker, recipe: RecipeData, slot: Slot, left: Slot, keep: bool = false
) -> void:
	var presses: int = int(round(1.0 / recipe.box.fill_per_press))
	await _wait_until(func() -> bool: return _box_in(slot) != null)
	await _use(w, slot, _side(slot, -1.0), presses)
	if not keep and w.holder().get_held_item() != null:
		await _use(w, left, _side(left, -1.0))


## Recoge el sobrante del pasaplatos (lado de pase).
func _take_leftover(w: Walker, left: Slot) -> void:
	await _use(w, left.get_item(), _side(left, -1.0))


## Emplatado: coge la caja llena del pasaplatos, pulsa cada condimento (en orden de x) con la caja
## en la mano y entra en la zona de entrega del puesto de la comanda.
func _season_and_deliver(w: Walker, slot: Slot, seasonings: Array) -> void:
	await _wait_until(func() -> bool: return _box_in(slot) != null and _box_in(slot).is_full())
	await _use(w, slot.get_item(), _side(slot, 1.0))
	var pieces: Array = []
	for seasoning: SeasoningData in seasonings:
		pieces.append(_piece(seasoning))
	pieces.sort_custom(
		func(a: Node3D, b: Node3D) -> bool: return a.global_position.x < b.global_position.x
	)
	for piece: Node3D in pieces:
		await _use(w, piece, _side(piece, 1.0))
	await _deliver(w)


func _deliver(w: Walker) -> void:
	var stand: Node3D = _stand_for_order()
	var zone: Node3D = stand.get_node("%DeliveryZone") as Node3D
	var zone_xz: Vector2 = _xz(zone)
	var done: int = _completed
	await w.walk_to(zone_xz + Vector2(0.0, -1.6))
	# Entra en la `%DeliveryZone`: con la caja correcta entrega sin pulsar.
	for _i: int in 20:
		if _completed > done:
			return
		await w.push_towards(zone_xz, 6)
	if _completed > done:
		return
	push_warning("la zona no entregó; pulsa en el puesto")
	await w.push_towards(_xz(stand), 4)
	await w.tap_interact()
	_stats.presses += 1


func _stand_for_order() -> Node3D:
	var orders: Array = OrderService.get_active_orders()
	var slot_id: int = (orders[0] as ActiveOrder).slot_id if not orders.is_empty() else 1
	return _node("OrderStand%d" % slot_id)


# --- Escenarios ----------------------------------------------------------------------------------


## Cocina de un pedido: pulpo (nuevo o sobrante), cachelos si el cuenco no tiene raciones.
func _cook_part(
	w: Walker, recipe: RecipeData, slot: Slot, left: Slot, seasonings: Array, leftover: bool
) -> void:
	var need_cachelos: bool = seasonings.has(CACHELOS) and _bowl().stock < 1
	var needed: int = _cooked
	if leftover:
		if need_cachelos:
			await _use(w, _node("CachelosStorage"), _kitchen_front("CachelosStorage"))
			await _use(w, _node("Kitchen2"), _kitchen_front("Kitchen2"))
			needed += 1
			await _wait_until(func() -> bool: return _cooked >= needed)
			await _use(w, _node("Kitchen2"), _kitchen_front("Kitchen2"))
			await _use(w, _bowl(), _side(_bowl(), -1.0))
		await _take_leftover(w, left)
	else:
		await _start_cooking(w, need_cachelos)
		needed += 2 if need_cachelos else 1
		await _collect_cooked(w, need_cachelos, needed)
	await _cut_in_slot(w, recipe, slot, left)


## Individual con un solo personaje (Player1, empieza en el servicio).
func _solo(recipe: RecipeData, seasonings: Array, leftover: bool) -> void:
	var w: Walker = Walker.new(get_tree(), _char(1), 1)
	var slot: Slot = _slot(_box_slot)
	var left: Slot = _slot(_left_slot)
	await _box_to_slot(w, recipe, slot)
	await _cook_part(w, recipe, slot, left, seasonings, leftover)
	await _season_and_deliver(w, slot, seasonings)


## Individual con cambio: Player1 emplata (servicio) y Player2 cocina (cocina). J1 empieza en P1.
func _switch_flow(recipe: RecipeData, seasonings: Array, leftover: bool) -> void:
	var server: Walker = Walker.new(get_tree(), _char(1), 1)
	var cook: Walker = Walker.new(get_tree(), _char(2), 1)
	var slot: Slot = _slot(_box_slot)
	var left: Slot = _slot(_left_slot)
	await _box_to_slot(server, recipe, slot)
	await _switch(server)
	await _cook_part(cook, recipe, slot, left, seasonings, leftover)
	await _switch(cook)
	await _season_and_deliver(server, slot, seasonings)


## Coop 2P: J1 (WASD) emplata con Player1 y J2 (flechas) cocina con Player2, a la vez.
func _coop(recipe: RecipeData, seasonings: Array, leftover: bool) -> void:
	var server: Walker = Walker.new(get_tree(), _char(1), 1)
	var cook: Walker = Walker.new(get_tree(), _char(2), 2)
	var slot: Slot = _slot(_box_slot)
	var left: Slot = _slot(_left_slot)
	var done: Array[bool] = [false, false]
	var cook_job: Callable = func() -> void:
		await _cook_part(cook, recipe, slot, left, seasonings, leftover)
		done[0] = true
	var server_job: Callable = func() -> void:
		await _box_to_slot(server, recipe, slot)
		await _season_and_deliver(server, slot, seasonings)
		done[1] = true
	cook_job.call()
	server_job.call()
	await _wait_until(func() -> bool: return done[0] and done[1])


## R17: `n` pedidos S seguidos en coop con el flujo adelantado. Emplatador: dos cajas por delante.
## Cocinero: dos pulpos al fuego a la vez; cada pulpo da dos cajas.
func _chain_pipe(recipe: RecipeData, seasonings: Array, n: int) -> void:
	var server: Walker = Walker.new(get_tree(), _char(1), 1)
	var cook: Walker = Walker.new(get_tree(), _char(2), 2)
	var done: Array[bool] = [false, false]
	var cook_job: Callable = func() -> void:
		var pots: int = mini(2, ceili(n / 2.0))
		for _p: int in pots:
			await _use(cook, _node("OctopusStorage"), _kitchen_front("OctopusStorage"))
			await _use(cook, _node("Kitchen"), _kitchen_front("Kitchen"))
		var taken: int = 0
		for i: int in n:
			var slot: Slot = _slot(_chain_slots[i % _chain_slots.size()])
			if cook.holder().get_held_item() == null:
				taken += 1
				var need: int = taken
				await _wait_until(func() -> bool: return _cooked >= need)
				await _use(cook, _node("Kitchen"), _kitchen_front("Kitchen"))
			await _cut_in_slot(cook, recipe, slot, _slot(_left_slot), true)
		done[0] = true
	var server_job: Callable = func() -> void:
		for i: int in mini(2, n):
			await _box_to_slot(server, recipe, _slot(_chain_slots[i % _chain_slots.size()]))
		for i: int in n:
			var slot: Slot = _slot(_chain_slots[i % _chain_slots.size()])
			await _season_and_deliver(server, slot, seasonings)
			if i + 2 < n:
				await _box_to_slot(
					server, recipe, _slot(_chain_slots[(i + 2) % _chain_slots.size()])
				)
		done[1] = true
	cook_job.call()
	server_job.call()
	await _wait_until(func() -> bool: return done[0] and done[1])
