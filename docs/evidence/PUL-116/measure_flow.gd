extends Node
## PUL-116: medición del flujo D25 (caja única de 6 cortes, aliño de una pulsación, cubo, comandas
## por fase) en `level_01.tscn`. Adaptación de `docs/evidence/PUL-102/measure_flow.gd`: mismo bot
## (teclado simulado y detector real de `level_walker.gd`; nunca llama a `interact()`) y mismas
## columnas, con el circuito nuevo:
##   - una sola caja del rack (`BoxShelf/BoxSpawner`), 6 cortes, 1 pulpo = 2 cajas;
##   - aliño: una pulsación en `SweetDressing` o `HotDressing` con la caja llena en la mano;
##   - cachelos: cuenco como en D23 (2 raciones por cachelo cocido);
##   - 4 comandas reales de `data/orders/` (Á feira, Picante, Con cachelos, Bravo cachelos).
##
## Uso (desde la raíz del repo):
##   godot --audio-driver Dummy --resolution 1920x1080 --fixed-fps 60 --path godot \
##     -s "$PWD/docs/evidence/PUL-116/run_measure.gd" -- solo|coop|chain|recover|round
## Escribe `docs/evidence/PUL-116/metrics_<parte>[_<caja>_<sobrante>].json` y un resumen por stdout.
##
## Partes (cada escenario: 2 pedidos seguidos de la misma comanda; el 2.º usa lo sobrante):
##   solo     Individual, un solo personaje; las 4 comandas.
##   coop     Coop 2P, J1 emplata (WASD) y J2 cocina (flechas) a la vez; las 4 comandas.
##   chain    Coop 2P, 4 pedidos «Á feira» seguidos (R17): `chain_seq` (protocolo de PUL-102,
##            pedidos pares con el sobrante) y `chain_pipe` (flujo adelantado).
##   recover  T7: caja errónea en la mano frente al puesto; `bin` (cubo y rehacer) y `swap`
##            (volver a la estación y pulsar el otro aliño).
##   round    Partida completa (300 s, fases reales) de un bot Individual secuencial: recaudación.
## Un bot anda en línea recta entre puntos y no duda: los tiempos son una cota inferior.

const LEVEL: PackedScene = preload("res://scenes/levels/level_01.tscn")
const Walker: GDScript = preload("res://tests/integration/level_walker.gd")
const BOX: BoxData = preload("res://data/boxes/box.tres")
const CACHELOS: SeasoningData = preload("res://data/seasonings/cachelos.tres")
const HOT: SeasoningData = preload("res://data/seasonings/hot_dressing.tres")
const SWEET: SeasoningData = preload("res://data/seasonings/sweet_dressing.tres")
const A_FEIRA: OrderData = preload("res://data/orders/a_feira.tres")
const PICANTE: OrderData = preload("res://data/orders/picante.tres")
const CON_CACHELOS: OrderData = preload("res://data/orders/con_cachelos.tres")
const BRAVO: OrderData = preload("res://data/orders/bravo_cachelos.tres")

const TICKS: float = 60.0
## Distancia de uso desde el frente de una pieza (m).
const ACCESS: float = 1.0
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
var _trashed: int = 0
var _expired: int = 0
var _results: Array[Dictionary] = []
var _part: String = "all"
var _legs: Array[String] = []
var _floor_left: Node3D
var _box_slot: String = "PassSlot01"
var _left_slot: String = "PassSlot02"
var _chain_slots: Array[String] = ["PassSlot01", "PassSlot02", "PassSlot03"]
## Comanda que se prepara ahora (para `_stand_for_order`).
var _current: OrderData
var _current_slot_id: int = 1


func _ready() -> void:
	_main.call_deferred()


func _main() -> void:
	for bus: int in AudioServer.bus_count:
		AudioServer.set_bus_mute(bus, true)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_part = args[0]
	if args.size() > 1:
		_box_slot = args[1]
		if args.size() > 2:
			_left_slot = args[2]
		if _box_slot == "PassSlot04":
			_chain_slots = ["PassSlot04", "PassSlot05", "PassSlot06"]
	var orders: Array[OrderData] = [A_FEIRA, PICANTE, CON_CACHELOS, BRAVO]
	PhaselessConfig.disable()
	for mode: String in ["solo", "coop"]:
		if _part != "all" and _part != mode:
			continue
		for order: OrderData in orders:
			var result: Dictionary = await _run(mode, order)
			_results.append(result)
			print(JSON.stringify(result))
	if _part == "all" or _part == "chain":
		for mode: String in ["chain_seq", "chain_pipe"]:
			var result: Dictionary = await _run(mode, A_FEIRA)
			_results.append(result)
			print(JSON.stringify(result))
	if _part == "all" or _part == "recover":
		for mode: String in ["recover_bin", "recover_bin4", "recover_swap"]:
			var result: Dictionary = await _run(mode, A_FEIRA)
			_results.append(result)
			print(JSON.stringify(result))
	PhaselessConfig.restore()
	if _part == "all" or _part == "round":
		var result: Dictionary = await _run("round", A_FEIRA)
		_results.append(result)
		print(JSON.stringify(result))
	var file_name: String = "metrics_%s.json" % _part
	if args.size() > 1:
		file_name = "metrics_%s_%s_%s.json" % [_part, _box_slot, _left_slot]
	var path: String = ProjectSettings.globalize_path("res://").path_join(
		"../docs/evidence/PUL-116/" + file_name
	)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(_results, "  "))
	file.close()
	print("OK ", path)
	get_tree().quit(0)


# --- Montaje ------------------------------------------------------------------------------------


func _run(mode: String, order_template: OrderData) -> Dictionary:
	_current = order_template.duplicate() as OrderData
	_current.max_time = 600.0
	_current_slot_id = 1
	GameState.set_paused(false)
	_level = LEVEL.instantiate()
	if mode == "round":
		_current = order_template
	else:
		var catalog: OrderCatalog = OrderCatalog.new()
		catalog.orders = [_current] as Array[OrderData]
		catalog.max_active_orders = 1
		_level.set("order_catalog", catalog)
	if mode.ends_with("4"):
		# Solo el puesto 4 (el más lejano al cubo del servicio): la comanda cae allí.
		var only: Array[Node] = [_level.get_node("Stations/OrderStand4")]
		_level.set("stands", only)
	var switcher: CharacterSwitcher = _level.get_node("CharacterSwitcher")
	var coop: bool = mode == "coop" or mode.begins_with("chain")
	switcher.set_mode(GameMode.Mode.COOP_2P if coop else GameMode.Mode.SINGLE)
	get_tree().root.add_child(_level)
	await _frames(2)
	var config: RoundConfig = _level.get("round_config")
	if mode != "round":
		RoundManager.round_state.advance(config.first_order_delay)
	_cooked = 0
	_completed = 0
	_completed_at.clear()
	_rejections = 0
	_delivery_rejections = 0
	_trashed = 0
	_expired = 0
	_stats = {"presses": 0, "retargets": 0, "dist1": 0.0, "dist2": 0.0, "still1": 0, "still2": 0}
	_frame = 0
	_last_pos = {1: _xz(_char(1)), 2: _xz(_char(2))}
	for pot: String in ["Kitchen", "Kitchen2"]:
		_level.get_node("Stations/" + pot).cooking_finished.connect(_on_cooked.unbind(1))
	var station: SeasoningStation = _station()
	for child: Node in station.get_node("Dispensers").get_children():
		child.rejected.connect(_on_rejected.unbind(1))
	station.get_node("CachelosBowl").rejected.connect(_on_rejected.unbind(1))
	for bin: String in ["TrashBinKitchen", "TrashBinService"]:
		_node(bin).trashed.connect(_on_trashed.unbind(1))
	EventBus.order_completed.connect(_on_completed)
	EventBus.order_expired.connect(_on_expired)
	EventBus.delivery_rejected.connect(_on_delivery_rejected)
	get_tree().physics_frame.connect(_track)

	var per_order: Array[Dictionary] = []
	var extra: Dictionary = {}
	if mode == "chain_pipe":
		await _chain_pipe(4)
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
	elif mode.begins_with("recover"):
		extra = await _recover(mode != "recover_swap")
	elif mode == "round":
		extra = await _round()
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
					await _solo(leftover)
				"coop", "chain_seq":
					await _coop(leftover)
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
	EventBus.order_expired.disconnect(_on_expired)
	EventBus.delivery_rejected.disconnect(_on_delivery_rejected)
	_level.queue_free()
	await _frames(3)
	GameState.reset_input()
	var result: Dictionary = {
		"mode": mode,
		"kind": order_template.display_name,
		"cuts": BOX.presses_to_fill,
		"slots": "%s/%s" % [_box_slot, _left_slot],
		"orders": per_order,
		"station_rejections": _rejections,
		"delivery_rejections": _delivery_rejections,
		"trashed": _trashed,
	}
	result.merge(extra)
	if mode.begins_with("chain"):
		var rest: Array[Dictionary] = per_order.slice(1)
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


func _on_expired(_order: ActiveOrder, _penalty: int) -> void:
	_expired += 1


func _on_trashed() -> void:
	_trashed += 1


func _on_rejected() -> void:
	_rejections += 1


func _on_delivery_rejected(_slot: int, _order: int, _penalty: int) -> void:
	_delivery_rejections += 1


# --- Acciones medidas ---------------------------------------------------------------------------


## Anda a `stand`, se gira hacia `expected` y pulsa. Si el detector no apunta a `expected`, lo
## corrige empujando hacia él (cuenta como `retarget`).
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
	return expected is Slot and target != null and target == (expected as Slot).get_item()


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().physics_frame


func _round_over() -> bool:
	return RoundManager.round_state != null and RoundManager.round_state.is_finished()


func _wait_until(condition: Callable) -> void:
	var guard: int = 0
	while not condition.call():
		if _round_over():
			return
		await get_tree().physics_frame
		guard += 1
		if guard > 60 * 120:
			push_error("espera agotada (120 s de juego)")
			return


func _station() -> SeasoningStation:
	return _node("SeasoningStation") as SeasoningStation


func _bowl() -> CachelosBowl:
	return _station().get_node("CachelosBowl") as CachelosBowl


func _kitchen_front(node: String) -> Vector2:
	return _xz(_node(node)) + Vector2(0.0, 0.9)


func _side(part: Node3D, side: float) -> Vector2:
	return Vector2(_xz(part).x, _station().global_position.z + side * ACCESS)


func _slot(slot_name: String) -> Slot:
	return _node(slot_name) as Slot


func _spawner() -> Node3D:
	return _node("BoxShelf/BoxSpawner")


func _dispenser(seasoning: SeasoningData) -> Node3D:
	for child: Node in _station().get_node("Dispensers").get_children():
		if (child as SeasoningDispenser).seasoning.same_as(seasoning):
			return child as Node3D
	return null


func _piece(seasoning: SeasoningData) -> Node3D:
	return _bowl() if seasoning.same_as(CACHELOS) else _dispenser(seasoning)


func _box_in(slot: Slot) -> Box:
	return slot.get_item() as Box


func _wants_cachelos(order: OrderData) -> bool:
	for seasoning: SeasoningData in order.seasonings:
		if seasoning.same_as(CACHELOS):
			return true
	return false


# --- Bloques del flujo ---------------------------------------------------------------------------


## Servicio: caja del rack a un pasaplatos, por el lado de condimentar.
func _box_to_slot(w: Walker, slot: Slot) -> void:
	var spawner: Node3D = _spawner()
	await _use(w, spawner, _xz(spawner) + Vector2(0.9, 0.0))
	await _use(w, slot, _side(slot, 1.0))


func _start_cooking(w: Walker, cachelos: bool) -> void:
	await _use(w, _node("OctopusStorage"), _kitchen_front("OctopusStorage"))
	await _use(w, _node("Kitchen"), _kitchen_front("Kitchen"))
	if cachelos:
		await _use(w, _node("CachelosStorage"), _kitchen_front("CachelosStorage"))
		await _use(w, _node("Kitchen2"), _kitchen_front("Kitchen2"))


func _collect_cooked(w: Walker, cachelos: bool, needed: int) -> void:
	await _wait_until(func() -> bool: return _cooked >= needed)
	if cachelos:
		await _use(w, _node("Kitchen2"), _kitchen_front("Kitchen2"))
		await _use(w, _bowl(), _side(_bowl(), -1.0))
	await _use(w, _node("Kitchen"), _kitchen_front("Kitchen"))


func _cut_in_slot(w: Walker, slot: Slot, left: Slot, keep: bool = false) -> void:
	await _wait_until(func() -> bool: return _box_in(slot) != null)
	await _use(w, slot, _side(slot, -1.0), BOX.presses_to_fill)
	if not keep and w.holder().get_held_item() != null:
		await _use(w, left, _side(left, -1.0))


func _take_leftover(w: Walker, left: Slot) -> void:
	await _use(w, left.get_item(), _side(left, -1.0))


func _season_and_deliver(w: Walker, slot: Slot) -> void:
	await _wait_until(func() -> bool: return _box_in(slot) != null and _box_in(slot).is_full())
	if _round_over():
		return
	await _use(w, slot.get_item(), _side(slot, 1.0))
	await _season_and_deliver_held(w, _current.seasonings)


## Con la caja llena en la mano: aliño (1 pulsación), cachelos si los pide y entrega.
func _season_and_deliver_held(w: Walker, seasonings: Array[SeasoningData]) -> void:
	var pieces: Array[Node3D] = []
	for seasoning: SeasoningData in seasonings:
		pieces.append(_piece(seasoning))
	pieces.sort_custom(
		func(a: Node3D, b: Node3D) -> bool: return a.global_position.x < b.global_position.x
	)
	var reversed: Array[Node3D] = pieces.duplicate()
	reversed.reverse()
	var edge: Vector2 = _zone_edge_from(_stand_for_order(), _side(pieces[pieces.size() - 1], 1.0))
	var edge_rev: Vector2 = _zone_edge_from(
		_stand_for_order(), _side(reversed[reversed.size() - 1], 1.0)
	)
	if _route_cost(w.position(), reversed, edge_rev) < _route_cost(w.position(), pieces, edge):
		pieces = reversed
	for piece: Node3D in pieces:
		await _use(w, piece, _side(piece, 1.0))
	await _deliver(w)


func _route_cost(start: Vector2, pieces: Array[Node3D], end: Vector2) -> float:
	var total: float = 0.0
	var here: Vector2 = start
	for piece: Node3D in pieces:
		var stand: Vector2 = _side(piece, 1.0)
		total += here.distance_to(stand)
		here = stand
	return total + here.distance_to(end)


func _zone_edge_from(stand: Node3D, from: Vector2) -> Vector2:
	var zone: Node3D = stand.get_node("%DeliveryZone") as Node3D
	var half: Vector2 = Vector2(0.5, 0.5)
	for child: Node in zone.get_children():
		var shape: CollisionShape3D = child as CollisionShape3D
		if shape != null and shape.shape is BoxShape3D:
			var size: Vector3 = (shape.shape as BoxShape3D).size
			half = Vector2(size.x, size.z) * 0.5
	var center: Vector2 = _xz(zone)
	var inset: Vector2 = Vector2(maxf(half.x - 0.15, 0.0), maxf(half.y - 0.15, 0.0))
	return Vector2(
		clampf(from.x, center.x - inset.x, center.x + inset.x),
		clampf(from.y, center.y - inset.y, center.y + inset.y)
	)


func _deliver(w: Walker) -> void:
	var stand: Node3D = _stand_for_order()
	var zone: Node3D = stand.get_node("%DeliveryZone") as Node3D
	var zone_xz: Vector2 = _xz(zone)
	var done: int = _completed
	var before_m: float = float(_stats["dist%d" % w.player_index])
	await w.walk_to(_zone_edge_from(stand, w.position()))
	for _i: int in 20:
		if _completed > done:
			break
		await w.push_towards(zone_xz, 6)
	_legs.append("Zone:%.1f" % (float(_stats["dist%d" % w.player_index]) - before_m))
	if _completed > done:
		return
	push_warning("la zona no entregó; pulsa en el puesto")
	await w.push_towards(_xz(stand), 4)
	await w.tap_interact()
	_stats.presses += 1


## Puesto cuya comanda viva coincide con la que se prepara (el primero si hay varios).
func _stand_for_order() -> Node3D:
	var orders: Array = OrderService.get_active_orders()
	var found: int = -1
	for order: ActiveOrder in orders:
		if order.data.display_name == _current.display_name:
			found = order.slot_id
			break
	if found < 0:
		found = (orders[0] as ActiveOrder).slot_id if not orders.is_empty() else 1
	_current_slot_id = found
	return _node("OrderStand%d" % found)


# --- Escenarios ----------------------------------------------------------------------------------


func _cook_part(w: Walker, slot: Slot, left: Slot, leftover: bool) -> void:
	var need_cachelos: bool = _wants_cachelos(_current) and _bowl().stock < 1
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
	await _cut_in_slot(w, slot, left)


func _solo(leftover: bool) -> void:
	var w: Walker = Walker.new(get_tree(), _char(1), 1)
	if _box_slot.begins_with("floor"):
		await _solo_floor(w, leftover)
		return
	var slot: Slot = _slot(_box_slot)
	var left: Slot = _slot(_left_slot)
	await _box_to_slot(w, slot)
	await _cook_part(w, slot, left, leftover)
	await _season_and_deliver(w, slot)


## Caja al suelo de la cocina (junto a las ollas, x -1,3), corte allí, sobrante al suelo.
func _solo_floor(w: Walker, leftover: bool) -> void:
	var spawner: Node3D = _spawner()
	await _use(w, spawner, _xz(spawner) + Vector2(0.9, 0.0))
	var box: Box = w.holder().get_held_item() as Box
	await _drop_facing(w, Vector2(-1.3, -1.6), Vector2(-1.0, 0.0))
	var need_cachelos: bool = _wants_cachelos(_current) and _bowl().stock < 1
	var needed: int = _cooked
	if leftover:
		await _use(w, _floor_left, _xz(_floor_left) + Vector2(0.9, 0.0))
	else:
		await _start_cooking(w, need_cachelos)
		needed += 2 if need_cachelos else 1
		await _collect_cooked(w, need_cachelos, needed)
	await _use(w, box, _xz(box) + Vector2(0.9, 0.0), BOX.presses_to_fill)
	var rest: Node3D = w.holder().get_held_item() as Node3D
	if rest != null:
		_floor_left = rest
		await _drop_facing(w, _xz(box) + Vector2(0.9, 0.0), Vector2(1.0, 0.0))
	await _use(w, box, _xz(box) + Vector2(0.9, 0.0))
	await _season_and_deliver_held(w, _current.seasonings)


func _drop_facing(w: Walker, stand: Vector2, dir: Vector2) -> void:
	var before_m: float = float(_stats["dist%d" % w.player_index])
	await w.walk_to(stand)
	_legs.append("Drop:%.1f" % (float(_stats["dist%d" % w.player_index]) - before_m))
	await w.push_towards(stand + dir * 2.0, Walker.FACE_FRAMES)
	await w.tap_interact()
	_stats.presses += 1
	await _frames(45)


func _coop(leftover: bool) -> void:
	var server: Walker = Walker.new(get_tree(), _char(1), 1)
	var cook: Walker = Walker.new(get_tree(), _char(2), 2)
	var slot: Slot = _slot(_box_slot)
	var left: Slot = _slot(_left_slot)
	var done: Array[bool] = [false, false]
	var cook_job: Callable = func() -> void:
		await _cook_part(cook, slot, left, leftover)
		done[0] = true
	var server_job: Callable = func() -> void:
		await _box_to_slot(server, slot)
		await _season_and_deliver(server, slot)
		done[1] = true
	cook_job.call()
	server_job.call()
	await _wait_until(func() -> bool: return done[0] and done[1])


## R17: `n` pedidos «Á feira» seguidos en coop con el flujo adelantado.
func _chain_pipe(n: int) -> void:
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
			await _cut_in_slot(cook, slot, _slot(_left_slot), true)
		done[0] = true
	var server_job: Callable = func() -> void:
		for i: int in mini(2, n):
			await _box_to_slot(server, _slot(_chain_slots[i % _chain_slots.size()]))
		for i: int in n:
			var slot: Slot = _slot(_chain_slots[i % _chain_slots.size()])
			await _season_and_deliver(server, slot)
			if i + 2 < n:
				await _box_to_slot(server, _slot(_chain_slots[(i + 2) % _chain_slots.size()]))
		done[1] = true
	cook_job.call()
	server_job.call()
	await _wait_until(func() -> bool: return done[0] and done[1])


## T7: Individual, «Á feira». El bot prepara la caja 1 CON ALIÑO PICANTE (error), la lleva al puesto
## y llega a la zona sin entregar (la zona está apagada). Desde ahí mide la recuperación:
##   bin  = cubo del servicio, caja nueva del rack, sobrante del pulpo en el pasaplatos, corte,
##          aliño dulce, entrega.
##   swap = volver a la estación y pulsar el aliño dulce (sustituye), entrega.
func _recover(use_bin: bool) -> Dictionary:
	var w: Walker = Walker.new(get_tree(), _char(1), 1)
	var slot: Slot = _slot("PassSlot01")
	var left: Slot = _slot("PassSlot02")
	await _box_to_slot(w, slot)
	await _cook_part(w, slot, left, false)
	await _wait_until(func() -> bool: return _box_in(slot) != null and _box_in(slot).is_full())
	await _use(w, slot.get_item(), _side(slot, 1.0))
	await _use(w, _piece(HOT), _side(_piece(HOT), 1.0))
	var stand: Node3D = _stand_for_order()
	var zone: Node3D = stand.get_node("%DeliveryZone") as Node3D
	await w.walk_to(_zone_edge_from(stand, w.position()))
	await w.push_towards(_xz(zone), 6)
	var wrong_at: int = _frame
	var revenue_before: int = RoundManager.round_state.get_revenue()
	var rejected_before: int = _delivery_rejections
	var completed_before: int = _completed
	if use_bin:
		var bin: Node3D = _nearest_bin(w)
		await _use(w, bin, _bin_stand(bin))
		var trashed_at: int = _frame
		await _box_to_slot(w, slot)
		await _take_leftover(w, left)
		await _cut_in_slot(w, slot, left)
		await _season_and_deliver(w, slot)
		var out: Dictionary = {
			"recover_s": snappedf((_frame - wrong_at) / TICKS, 0.01),
			"to_bin_s": snappedf((trashed_at - wrong_at) / TICKS, 0.01),
		}
		return _recover_out(out, revenue_before, rejected_before, completed_before)
	var sweet: Node3D = _piece(SWEET)
	await _use(w, sweet, _side(sweet, 1.0))
	await _deliver(w)
	var swap_out: Dictionary = {"recover_s": snappedf((_frame - wrong_at) / TICKS, 0.01)}
	return _recover_out(swap_out, revenue_before, rejected_before, completed_before)


## Cubo con el camino más corto desde donde está el jugador (rodeando la barra por el hueco).
func _nearest_bin(w: Walker) -> Node3D:
	var best: Node3D = null
	var best_len: float = INF
	for bin_name: String in ["TrashBinKitchen", "TrashBinService"]:
		var bin: Node3D = _node(bin_name)
		var length: float = _path_len(w.position(), _bin_stand(bin))
		if length < best_len:
			best_len = length
			best = bin
	return best


## Punto de uso de un cubo: 0,9 m hacia el centro del nivel (x) del lado de su zona.
func _bin_stand(bin: Node3D) -> Vector2:
	var at: Vector2 = _xz(bin)
	return at + Vector2(-0.9 if at.x > 0.0 else 0.9, 0.0)


func _path_len(from: Vector2, to: Vector2) -> float:
	if Walker.side_of(from) == Walker.side_of(to):
		return from.distance_to(to)
	var offset: float = Walker.BAR_HALF_DEPTH + Walker.GAP_CLEARANCE
	var a: Vector2 = Vector2(Walker.GAP_X, Walker.BAR_Z + Walker.side_of(from) * offset)
	var b: Vector2 = Vector2(Walker.GAP_X, Walker.BAR_Z + Walker.side_of(to) * offset)
	return from.distance_to(a) + a.distance_to(b) + b.distance_to(to)


func _recover_out(out: Dictionary, revenue: int, rejected: int, completed: int) -> Dictionary:
	out["rejections_during"] = _delivery_rejections - rejected
	out["completed_after"] = _completed - completed
	out["revenue_delta"] = RoundManager.round_state.get_revenue() - revenue
	out["meters_p1_total"] = snappedf(_stats.dist1, 0.1)
	out["presses_total"] = _stats.presses
	return out


## Partida completa (fases reales, 300 s) de un bot Individual secuencial: siempre la comanda con
## menos paciencia restante; pedidos pares con el sobrante del pulpo del impar.
func _round() -> Dictionary:
	var w: Walker = Walker.new(get_tree(), _char(1), 1)
	var slot: Slot = _slot(_box_slot)
	var left: Slot = _slot(_left_slot)
	var leftover: bool = false
	var served: Dictionary = {}
	while not _round_over():
		var live: Array[ActiveOrder] = OrderService.get_active_orders()
		if live.is_empty():
			await _frames(10)
			continue
		var pick: ActiveOrder = live[0]
		for order: ActiveOrder in live:
			if order.time_left < pick.time_left:
				pick = order
		_current = pick.data
		_legs.clear()
		var target: int = _completed + 1
		await _box_to_slot(w, slot)
		await _cook_part(w, slot, left, leftover)
		await _season_and_deliver(w, slot)
		if _completed >= target:
			served[_current.display_name] = int(served.get(_current.display_name, 0)) + 1
		leftover = not leftover
	var result: RoundResult = RoundManager.round_state.get_result()
	return {
		"revenue": RoundManager.round_state.get_revenue(),
		"delivered": RoundManager.round_state.get_boxes_delivered(),
		"stars": result.stars if result != null else -1,
		"expired": _expired,
		"served": served,
		"meters_p1_total": snappedf(_stats.dist1, 0.1),
		"presses_total": _stats.presses,
	}
