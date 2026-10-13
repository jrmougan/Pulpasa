extends Node
## PUL-164: medida del balance de la alpha con el bot de rutas en `level_01.tscn` (estado D26/D27).
## Base: `docs/evidence/PUL-116/measure_flow.gd` (mismo bot: teclado simulado y detector real de
## `level_walker.gd`; nunca llama a `interact()`), con el flujo D26: entrega solo por zona (si la
## zona no entrega, la caja va al cubo; nunca se pulsa el puesto) y cuenco que solo pone cachelos.
## No es un test (no empieza por `test_`): `tools/verify.sh` solo lo formatea y lo analiza.
##
## Uso (desde la raíz del repo; sin ventana, con `--fixed-fps 60` el tiempo de juego es exacto):
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path godot \
##     -s res://tests/tools/balance_run.gd -- recipes [PassSlotNN PassSlotMM]
##   godot ... -s res://tests/tools/balance_run.gd -- round solo|coop <semilla> [proposal]
## Escribe `docs/evidence/PUL-164/metrics_<...>.json` y un resumen por stdout.
##
## Partes:
##   recipes  Individual y Local 2P (J1 emplata con WASD, J2 cocina con flechas), las 4 comandas,
##            2 pedidos seguidos de cada una: el 1.º desde cero (sale de la posición inicial, cuece
##            el pulpo) y el 2.º en flujo (con el pulpo sobrante del 1.º). Sin fases ni paciencia.
##   round    Partida completa de 300 s con las fases reales de `round_config.tres` y la semilla
##            dada (solo en memoria; el `.tres` no se toca). `solo`: bot Individual secuencial;
##            `coop`: dos bots en paralelo (cocinero y emplatador). Cada comanda queda registrada
##            (fase, paciencia, segundos que le quedaban al entregarla o si caducó).
## Un bot anda en línea recta, pulsa cada 4 frames y no duda: los tiempos son una cota inferior.

const LEVEL: PackedScene = preload("res://scenes/levels/level_01.tscn")
const Walker: GDScript = preload("res://tests/integration/level_walker.gd")
const BOX: BoxData = preload("res://data/boxes/box.tres")
const CACHELOS: SeasoningData = preload("res://data/seasonings/cachelos.tres")
const A_FEIRA: OrderData = preload("res://data/orders/a_feira.tres")
const PICANTE: OrderData = preload("res://data/orders/picante.tres")
const CON_CACHELOS: OrderData = preload("res://data/orders/con_cachelos.tres")
const BRAVO: OrderData = preload("res://data/orders/bravo_cachelos.tres")
const CONFIG_PATH: String = "res://data/config/round_config.tres"
const OUT_DIR: String = "../docs/evidence/PUL-164/"

## Variante `proposal` de `round` (PUL-164, AC3): límites de fase (fracción de la partida) y
## multiplicadores de paciencia propuestos, aplicados solo en memoria.
const PROPOSAL_STARTS: Array[float] = [0.0, 0.3, 0.6]
const PROPOSAL_MULTIPLIERS: Array[float] = [1.0, 0.85, 0.8]

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
var _rejections: int = 0
var _delivery_rejections: int = 0
var _trashed: int = 0
var _expired: int = 0
var _warnings: int = 0
var _burnt: int = 0
var _results: Array[Dictionary] = []
var _legs: Array[String] = []
var _box_slot: String = "PassSlot04"
var _left_slot: String = "PassSlot05"
## Comanda que se prepara ahora y su puesto (−1 = el primero con esa comanda).
var _current: OrderData
var _target_slot: int = -1
## Estado de las ollas en `round coop`: "idle", "cooking" o "ready".
var _pots: Dictionary = {"Kitchen": "idle", "Kitchen2": "idle"}
## Registro de comandas de la partida (id → datos).
var _log: Dictionary = {}


func _ready() -> void:
	_main.call_deferred()


func _main() -> void:
	for bus: int in AudioServer.bus_count:
		AudioServer.set_bus_mute(bus, true)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var part: String = args[0] if args.size() > 0 else "recipes"
	var file_name: String = ""
	if part == "recipes":
		if args.size() > 2:
			_box_slot = args[1]
			_left_slot = args[2]
		PhaselessConfig.disable()
		for mode: String in ["solo", "coop"]:
			for order: OrderData in [A_FEIRA, PICANTE, CON_CACHELOS, BRAVO]:
				var result: Dictionary = await _run(mode, order)
				_results.append(result)
				print(JSON.stringify(result))
		PhaselessConfig.restore()
		file_name = "metrics_recipes_%s_%s.json" % [_box_slot, _left_slot]
	elif part == "round":
		var mode: String = args[1] if args.size() > 1 else "solo"
		var seed_value: int = int(args[2]) if args.size() > 2 else 1
		if mode == "coop":
			_box_slot = "PassSlot01"
			_left_slot = "PassSlot02"
		var variant: String = args[3] if args.size() > 3 else "current"
		var config: RoundConfig = load(CONFIG_PATH) as RoundConfig
		var saved_seed: int = config.rng_seed
		var saved_phases: Array[Dictionary] = []
		for phase: PhaseData in config.phases:
			saved_phases.append({"start": phase.start_fraction, "mult": phase.patience_multiplier})
		config.rng_seed = seed_value
		if variant == "proposal":
			_apply_phases(config, PROPOSAL_STARTS, PROPOSAL_MULTIPLIERS)
		var result: Dictionary = await _run("round_" + mode, A_FEIRA)
		for i: int in saved_phases.size():
			config.phases[i].start_fraction = saved_phases[i].start
			config.phases[i].patience_multiplier = saved_phases[i].mult
		config.rng_seed = saved_seed
		result["seed"] = seed_value
		result["variant"] = variant
		_results.append(result)
		print(JSON.stringify(result))
		file_name = "metrics_round_%s_seed%d.json" % [mode, seed_value]
		if variant != "current":
			file_name = "metrics_round_%s_seed%d_%s.json" % [mode, seed_value, variant]
	else:
		push_error("parte desconocida: %s (recipes | round)" % part)
		get_tree().quit(1)
		return
	var path: String = ProjectSettings.globalize_path("res://").path_join(OUT_DIR + file_name)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(_results, "  "))
	file.close()
	print("OK ", path)
	get_tree().quit(0)


func _apply_phases(config: RoundConfig, starts: Array[float], mults: Array[float]) -> void:
	for i: int in config.phases.size():
		config.phases[i].start_fraction = starts[i]
		config.phases[i].patience_multiplier = mults[i]


# --- Montaje ------------------------------------------------------------------------------------


func _run(mode: String, order_template: OrderData) -> Dictionary:
	var is_round: bool = mode.begins_with("round")
	_current = order_template.duplicate() as OrderData
	_current.max_time = 600.0
	_target_slot = -1
	GameState.set_paused(false)
	_level = LEVEL.instantiate()
	if not is_round:
		var catalog: OrderCatalog = OrderCatalog.new()
		catalog.orders = [_current] as Array[OrderData]
		catalog.max_active_orders = 1
		_level.set("order_catalog", catalog)
	var switcher: CharacterSwitcher = _level.get_node("CharacterSwitcher")
	var coop: bool = mode == "coop" or mode == "round_coop"
	switcher.set_mode(GameMode.Mode.COOP_2P if coop else GameMode.Mode.SINGLE)
	get_tree().root.add_child(_level)
	await _frames(2)
	var config: RoundConfig = _level.get("round_config")
	if not is_round:
		RoundManager.round_state.advance(config.first_order_delay)
	_cooked = 0
	_completed = 0
	_rejections = 0
	_delivery_rejections = 0
	_trashed = 0
	_expired = 0
	_warnings = 0
	_burnt = 0
	_log.clear()
	_pots = {"Kitchen": "idle", "Kitchen2": "idle"}
	_stats = {"presses": 0, "retargets": 0, "dist1": 0.0, "dist2": 0.0, "still1": 0, "still2": 0}
	_frame = 0
	_last_pos = {1: _xz(_char(1)), 2: _xz(_char(2))}
	for pot: String in ["Kitchen", "Kitchen2"]:
		var station_pot: Node = _level.get_node("Stations/" + pot)
		station_pot.cooking_finished.connect(_on_cooked.bind(pot).unbind(1))
		station_pot.burnt.connect(_on_burnt.unbind(1))
	var station: SeasoningStation = _station()
	for child: Node in station.get_node("Dispensers").get_children():
		child.rejected.connect(_on_rejected.unbind(1))
	station.get_node("CachelosBowl").rejected.connect(_on_rejected.unbind(1))
	for bin: String in ["TrashBinKitchen", "TrashBinService"]:
		_node(bin).trashed.connect(_on_trashed.unbind(1))
	EventBus.order_generated.connect(_on_generated)
	EventBus.order_completed.connect(_on_completed)
	EventBus.order_expired.connect(_on_expired)
	EventBus.delivery_rejected.connect(_on_delivery_rejected)
	get_tree().physics_frame.connect(_track)

	var per_order: Array[Dictionary] = []
	var extra: Dictionary = {}
	if mode == "round_solo":
		extra = await _round_solo()
	elif mode == "round_coop":
		extra = await _round_coop()
	else:
		var leftover: bool = false
		for i: int in ORDERS_PER_RUN:
			var before: Dictionary = _stats.duplicate()
			var start: int = _frame
			var target: int = _completed + 1
			_legs.clear()
			if mode == "solo":
				await _solo(leftover)
			else:
				await _coop(leftover)
			leftover = true
			(
				per_order
				. append(
					{
						"order": i + 1,
						"from": "cero" if i == 0 else "flujo",
						"completed": _completed >= target,
						"seconds": snappedf((_frame - start) / TICKS, 0.01),
						"presses": _stats.presses - before.presses,
						"legs": _legs.duplicate(),
						"retargets": _stats.retargets - before.retargets,
						"meters_p1": snappedf(_stats.dist1 - before.dist1, 0.1),
						"meters_p2": snappedf(_stats.dist2 - before.dist2, 0.1),
					}
				)
			)

	get_tree().physics_frame.disconnect(_track)
	EventBus.order_generated.disconnect(_on_generated)
	EventBus.order_completed.disconnect(_on_completed)
	EventBus.order_expired.disconnect(_on_expired)
	EventBus.delivery_rejected.disconnect(_on_delivery_rejected)
	_level.queue_free()
	await _frames(3)
	GameState.reset_input()
	var result: Dictionary = {
		"mode": mode,
		"kind": order_template.display_name if not is_round else "partida",
		"cuts": BOX.presses_to_fill,
		"slots": "%s/%s" % [_box_slot, _left_slot],
		"station_rejections": _rejections,
		"delivery_rejections": _delivery_rejections,
		"trashed": _trashed,
		"bot_warnings": _warnings,
		"burnt": _burnt,
	}
	if not is_round:
		result["orders"] = per_order
	result.merge(extra)
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


func _on_cooked(pot: String) -> void:
	_cooked += 1
	_pots[pot] = "ready"


func _on_burnt() -> void:
	_burnt += 1


func _on_generated(order: ActiveOrder) -> void:
	var state: RoundState = RoundManager.round_state
	_log[order.id] = {
		"id": order.id,
		"kind": order.data.display_name,
		"slot": order.slot_id,
		"phase": state.get_phase() if state != null else 0,
		"patience": snappedf(order.max_time, 0.01),
		"at": snappedf(_frame / TICKS, 0.01),
	}


func _on_completed(order: ActiveOrder, points: int) -> void:
	_completed += 1
	var entry: Dictionary = _log.get(order.id, {})
	entry["points"] = points
	entry["time_left"] = snappedf(order.time_left, 0.01)
	entry["done_at"] = snappedf(_frame / TICKS, 0.01)
	_log[order.id] = entry


func _on_expired(order: ActiveOrder, _penalty: int) -> void:
	_expired += 1
	var entry: Dictionary = _log.get(order.id, {})
	entry["expired_at"] = snappedf(_frame / TICKS, 0.01)
	_log[order.id] = entry


func _on_trashed() -> void:
	_trashed += 1


func _on_rejected() -> void:
	_rejections += 1


func _on_delivery_rejected(_slot: int, _order: int, _penalty: int) -> void:
	_delivery_rejections += 1


func _warn(text: String) -> void:
	_warnings += 1
	push_warning(text)


# --- Acciones medidas ---------------------------------------------------------------------------


## Anda a `stand`, se gira hacia `expected` y pulsa. Si el detector no apunta a `expected`, lo
## corrige empujando hacia él (cuenta como `retarget`).
func _use(w: Walker, expected: Node, stand: Vector2, presses: int = 1) -> void:
	if _round_over() or expected == null:
		return
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
		_warn("objetivo %s no alcanzado desde %s" % [expected.name, stand])
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


func _held(w: Walker) -> Node:
	return w.holder().get_held_item()


func _wants_cachelos(order: OrderData) -> bool:
	for seasoning: SeasoningData in order.seasonings:
		if seasoning.same_as(CACHELOS):
			return true
	return false


# --- Bloques del flujo ---------------------------------------------------------------------------


## Servicio: caja del rack a un pasaplatos, por el lado de condimentar.
func _box_to_slot(w: Walker, slot: Slot) -> void:
	if slot.get_item() != null:
		return
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
	if not keep and _held(w) != null:
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
	var approach: Vector2 = _zone_approach(_stand_for_order())
	var cost: float = _route_cost(w.position(), pieces, approach)
	if _route_cost(w.position(), reversed, approach) < cost:
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


## Punto al norte de la `%DeliveryZone` desde el que se entra en ella sin cruzar la de otro puesto
## (`Walker.ZONE_APPROACH`, como `walk_into_zone`): una caja que encaja se entrega en cualquier zona
## iluminada que pisa, así que un camino en diagonal podía entregar en el puesto vecino.
func _zone_approach(stand: Node3D) -> Vector2:
	var center: Vector2 = _xz(stand.get_node("%DeliveryZone") as Node3D)
	return center - Vector2(0.0, Walker.ZONE_APPROACH)


## Entra en la zona del puesto (D26: la entrega es solo por zona). Si no entrega (la comanda
## caducó mientras tanto), la caja va al cubo más cercano: nunca se pulsa el puesto.
func _deliver(w: Walker) -> void:
	if _round_over():
		return
	var stand: Node3D = _stand_for_order()
	var zone_xz: Vector2 = _xz(stand.get_node("%DeliveryZone") as Node3D)
	var done: int = _completed
	var before_m: float = float(_stats["dist%d" % w.player_index])
	await w.walk_to(_zone_approach(stand))
	for _i: int in 20:
		if _completed > done or _round_over():
			break
		await w.push_towards(zone_xz, 6)
	_legs.append("Zone:%.1f" % (float(_stats["dist%d" % w.player_index]) - before_m))
	if _completed > done or _round_over():
		return
	_warn("la zona no entregó; caja al cubo")
	var bin: Node3D = _nearest_bin(w)
	await _use(w, bin, _bin_stand(bin))


## Puesto de la comanda elegida (`_target_slot`) si sigue viva; si no, el primero con la misma
## comanda; si no hay ninguna, el primero con comanda (la zona no entregará y la caja va al cubo).
func _stand_for_order() -> Node3D:
	var orders: Array[ActiveOrder] = OrderService.get_active_orders()
	var found: int = -1
	for order: ActiveOrder in orders:
		if order.slot_id == _target_slot and order.data.display_name == _current.display_name:
			found = order.slot_id
	if found < 0:
		for order: ActiveOrder in orders:
			if order.data.display_name == _current.display_name:
				found = order.slot_id
				break
	if found < 0:
		found = orders[0].slot_id if not orders.is_empty() else 1
	return _node("OrderStand%d" % found)


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


# --- Recetas -------------------------------------------------------------------------------------


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
	var slot: Slot = _slot(_box_slot)
	var left: Slot = _slot(_left_slot)
	await _box_to_slot(w, slot)
	await _cook_part(w, slot, left, leftover)
	await _season_and_deliver(w, slot)


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


# --- Partidas de 300 s ---------------------------------------------------------------------------


## Comanda viva con menos paciencia restante que se puede servir ahora (con cachelos solo si el
## cuenco tiene). `null` si no hay ninguna.
func _pick_order(need_stock: bool) -> ActiveOrder:
	var pick: ActiveOrder = null
	for order: ActiveOrder in OrderService.get_active_orders():
		if need_stock and _wants_cachelos(order.data) and _bowl().stock < 1:
			continue
		if pick == null or order.time_left < pick.time_left:
			pick = order
	return pick


## Con la caja llena en la mano: elige la comanda más urgente que puede servir, aliña y entrega.
func _serve_held(w: Walker) -> void:
	var pick: ActiveOrder = _pick_order(true)
	while pick == null and not _round_over():
		await _frames(10)
		pick = _pick_order(true)
	if pick == null:
		return
	_current = pick.data
	_target_slot = pick.slot_id
	await _season_and_deliver_held(w, _current.seasonings)


## Individual secuencial: elige la comanda más urgente (decide si cocer cachelos), lleva la caja al
## pasaplatos, cuece o usa el pulpo sobrante, corta y, con la caja llena, sirve la comanda más
## urgente que pueda en ese momento.
func _round_solo() -> Dictionary:
	var w: Walker = Walker.new(get_tree(), _char(1), 1)
	var slot: Slot = _slot(_box_slot)
	var left: Slot = _slot(_left_slot)
	while not _round_over():
		var pick: ActiveOrder = _pick_order(false)
		if pick == null:
			await _frames(10)
			continue
		_current = pick.data
		_target_slot = pick.slot_id
		_legs.clear()
		await _box_to_slot(w, slot)
		await _cook_part(w, slot, left, left.get_item() != null)
		await _wait_until(func() -> bool: return _box_in(slot) != null and _box_in(slot).is_full())
		if _round_over():
			break
		await _use(w, slot.get_item(), _side(slot, 1.0))
		await _serve_held(w)
	return _round_out()


## Local 2P: J2 cocina y corta en dos pasaplatos (adelanta el pulpo y repone cachelos cuando una
## comanda viva los pide); J1 pone cajas, recoge la primera llena y sirve la comanda más urgente.
func _round_coop() -> Dictionary:
	var server: Walker = Walker.new(get_tree(), _char(1), 1)
	var cook: Walker = Walker.new(get_tree(), _char(2), 2)
	var boxes: Array[Slot] = [_slot("PassSlot01"), _slot("PassSlot03")]
	var left: Slot = _slot(_left_slot)
	var done: Array[bool] = [false, false]
	var cook_job: Callable = func() -> void:
		while not _round_over():
			await _cook_step(cook, boxes, left)
		done[0] = true
	var server_job: Callable = func() -> void:
		while not _round_over():
			await _server_step(server, boxes)
		done[1] = true
	cook_job.call()
	server_job.call()
	# Sin el tope de `_wait_until`: la partida dura más de 120 s y los bots salen al acabar.
	while not (done[0] and done[1]):
		await get_tree().physics_frame
	return _round_out()


func _cachelos_wanted() -> bool:
	for order: ActiveOrder in OrderService.get_active_orders():
		if _wants_cachelos(order.data):
			return true
	return false


## Deja lo que lleva en la mano en el pasaplatos del sobrante (si está libre).
func _park(w: Walker, left: Slot) -> bool:
	if _held(w) == null:
		return true
	if left.get_item() != null:
		return false
	await _use(w, left, _side(left, -1.0))
	return _held(w) == null


func _cook_step(w: Walker, boxes: Array[Slot], left: Slot) -> void:
	# Cachelos listos: al cuenco (antes de que se quemen).
	var parked: bool = _held(w) == null
	if not parked and (_pots["Kitchen2"] == "ready" or _pots["Kitchen"] == "ready"):
		parked = await _park(w, left)
	if _pots["Kitchen2"] == "ready" and parked:
		await _use(w, _node("Kitchen2"), _kitchen_front("Kitchen2"))
		_pots["Kitchen2"] = "idle"
		await _use(w, _bowl(), _side(_bowl(), -1.0))
		return
	# Cachelos que pide una comanda viva y el cuenco no tiene.
	if _cachelos_wanted() and _bowl().stock < 1 and _pots["Kitchen2"] == "idle":
		var free: bool = await _park(w, left)
		if free:
			await _use(w, _node("CachelosStorage"), _kitchen_front("CachelosStorage"))
			await _use(w, _node("Kitchen2"), _kitchen_front("Kitchen2"))
			_pots["Kitchen2"] = "cooking"
			return
	# Pulpo cocido: se recoge antes de que se queme.
	if _pots["Kitchen"] == "ready" and _held(w) == null:
		await _use(w, _node("Kitchen"), _kitchen_front("Kitchen"))
		_pots["Kitchen"] = "idle"
		return
	var target: Slot = null
	for slot: Slot in boxes:
		if _box_in(slot) != null and not _box_in(slot).is_full():
			target = slot
			break
	if target != null:
		if _held(w) == null and left.get_item() != null:
			await _take_leftover(w, left)
		if _held(w) == null:
			if _pots["Kitchen"] == "idle":
				await _start_octopus(w)
			await _wait_until(func() -> bool: return _pots["Kitchen"] == "ready")
			await _use(w, _node("Kitchen"), _kitchen_front("Kitchen"))
			_pots["Kitchen"] = "idle"
		await _use(w, target, _side(target, -1.0), BOX.presses_to_fill)
		return
	# Sin caja que llenar: adelanta un pulpo si no hay ninguno a mano.
	if _held(w) == null and left.get_item() == null and _pots["Kitchen"] == "idle":
		await _start_octopus(w)
		return
	await _frames(10)


func _start_octopus(w: Walker) -> void:
	await _use(w, _node("OctopusStorage"), _kitchen_front("OctopusStorage"))
	await _use(w, _node("Kitchen"), _kitchen_front("Kitchen"))
	_pots["Kitchen"] = "cooking"


func _server_step(w: Walker, boxes: Array[Slot]) -> void:
	for slot: Slot in boxes:
		if slot.get_item() == null:
			await _box_to_slot(w, slot)
			return
	for slot: Slot in boxes:
		var box: Box = _box_in(slot)
		if box != null and box.is_full():
			await _use(w, box, _side(slot, 1.0))
			await _serve_held(w)
			return
	await _frames(10)


func _round_out() -> Dictionary:
	var state: RoundState = RoundManager.round_state
	var result: RoundResult = state.get_result()
	var orders: Array = _log.values()
	orders.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id)
	return {
		"revenue": state.get_revenue(),
		"delivered": state.get_boxes_delivered(),
		"stars": result.stars if result != null else -1,
		"expired": _expired,
		"orders_log": orders,
		"meters_p1_total": snappedf(_stats.dist1, 0.1),
		"meters_p2_total": snappedf(_stats.dist2, 0.1),
		"presses_total": _stats.presses,
	}
