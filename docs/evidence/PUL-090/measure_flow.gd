extends Node
## PUL-090: medición reproducible del flujo actual de un pedido en `level_01.tscn` (planta B).
## Juega el nivel real con teclado simulado y el detector real (`level_walker.gd`, el mismo que
## usan los tests AC16/AC17 de PUL-061): nunca llama a `interact()`.
##
## Uso (desde la raíz del repo):
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path godot \
##     -s "$PWD/docs/evidence/PUL-090/run_measure.gd"
## Escribe `docs/evidence/PUL-090/metrics.json` y un resumen por stdout.
##
## Escenarios (cada uno: 2 pedidos seguidos del mismo tipo; el 2.º usa el pulpo sobrante):
##   solo   Individual, un solo personaje que rodea la barra por el hueco.
##   switch Individual, cocinero en la cocina y emplatador en el servicio, con `p1_switch`.
##   coop   Coop 2P, J1 emplata (WASD) y J2 cocina (flechas) a la vez.
## Tipos: S/M/L con sal + aceite, y S con aceite + cachelos.
## Un bot anda en línea recta entre puntos y no duda: los tiempos son una cota inferior de los de
## una persona.

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
## z del punto de uso frente a la encimera del fondo (frente en z −3,5).
const BACK_STAND_Z: float = -2.9
const SWITCH_FRAMES: int = 18
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
var _results: Array = []


func _ready() -> void:
	_main.call_deferred()


func _main() -> void:
	for bus: int in AudioServer.bus_count:
		AudioServer.set_bus_mute(bus, true)
	var kinds: Array = [
		["S", SMALL, [SALT, OIL]],
		["M", MEDIUM, [SALT, OIL]],
		["L", LARGE, [SALT, OIL]],
		["S+cachelos", SMALL, [OIL, CACHELOS]],
	]
	for mode: String in ["solo", "switch", "coop"]:
		for kind: Array in kinds:
			var result: Dictionary = await _run(mode, kind[0], kind[1], kind[2])
			_results.append(result)
			print(JSON.stringify(result))
	var path: String = ProjectSettings.globalize_path("res://").path_join(
		"../docs/evidence/PUL-090/metrics.json"
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
	switcher.set_mode(GameMode.Mode.COOP_2P if mode == "coop" else GameMode.Mode.SINGLE)
	get_tree().root.add_child(_level)
	await _frames(2)
	var config: RoundConfig = _level.get("round_config")
	RoundManager.round_state.advance(config.first_order_delay)
	_cooked = 0
	_completed = 0
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
	_last_pos = {1: _xz(_char(1)), 2: _xz(_char(2))}
	for pot: String in ["Kitchen", "Kitchen2"]:
		_level.get_node("Stations/" + pot).cooking_finished.connect(_on_cooked.unbind(1))
	var station: SeasoningStation = _level.get_node("Stations/SeasoningStation")
	for child: Node in station.get_node("Dispensers").get_children():
		child.rejected.connect(_on_rejected.unbind(1))
		# Antirrebote con el reloj de juego: con `--fixed-fps` el de pared corre más despacio.
		child.set("clock", _game_seconds)
	station.get_node("CachelosBowl").rejected.connect(_on_rejected.unbind(1))
	station.get_node("CachelosBowl").set("clock", _game_seconds)
	EventBus.order_completed.connect(_on_completed)
	EventBus.delivery_rejected.connect(_on_delivery_rejected)
	get_tree().physics_frame.connect(_track)

	var per_order: Array = []
	var leftover: bool = false
	for i: int in ORDERS_PER_RUN:
		var before: Dictionary = _stats.duplicate()
		var start: int = _frame
		var target: int = _completed + 1
		match mode:
			"solo":
				await _solo(recipe, seasonings, leftover)
			"switch":
				await _switch_flow(recipe, seasonings, leftover)
			"coop":
				await _coop(recipe, seasonings, leftover)
		var ok: bool = _completed >= target
		leftover = true
		(
			per_order
			. append(
				{
					"order": i + 1,
					"completed": ok,
					"seconds": snappedf((_frame - start) / TICKS, 0.01),
					"presses": _stats.presses - before.presses,
					"switches": _stats.switches - before.switches,
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
	return {
		"mode": mode,
		"kind": kind,
		"cuts": int(round(1.0 / recipe.box.fill_per_press)),
		"orders": per_order,
		"station_rejections": _rejections,
		"delivery_rejections": _delivery_rejections,
	}


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


func _game_seconds() -> float:
	return _frame / TICKS


func _on_cooked() -> void:
	_cooked += 1


func _on_completed(_order: ActiveOrder, _points: int) -> void:
	_completed += 1


func _on_rejected() -> void:
	_rejections += 1


func _on_delivery_rejected(_slot: int, _order: int, _penalty: int) -> void:
	_delivery_rejections += 1


# --- Acciones medidas ---------------------------------------------------------------------------


## Anda a `stand`, se gira hacia `expected` y pulsa. Si el detector no apunta a `expected`, lo
## corrige empujando hacia él (cuenta como `retarget`: un jugador tendría que recolocarse).
func _use(w: Walker, expected: Node, stand: Vector2, presses: int = 1) -> void:
	var aim: Vector2 = _xz(expected as Node3D)
	await w.walk_to(stand)
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
	while not condition.call():
		await get_tree().physics_frame


func _back(node: String) -> Vector2:
	return Vector2(_node(node).global_position.x, BACK_STAND_Z)


func _station() -> SeasoningStation:
	return _node("SeasoningStation") as SeasoningStation


func _tray_stand(side: float) -> Vector2:
	var tray: Vector2 = _xz(_station().get_tray())
	return Vector2(tray.x, side * ACCESS)


func _shelf_spawner(recipe: RecipeData) -> Node3D:
	for name: String in ["SmallSpawner", "MediumSpawner", "LargeSpawner"]:
		var spawner: Node3D = _node("BoxShelf/" + name)
		if spawner.get("data") == recipe.box:
			return spawner
	return null


func _shelf_stand(spawner: Node3D) -> Vector2:
	return Vector2(_node("BoxShelf").global_position.x + 1.7, spawner.global_position.z)


func _dispenser(seasoning: SeasoningData) -> Node3D:
	for child: Node in _station().get_node("Dispensers").get_children():
		if (child as SeasoningDispenser).seasoning == seasoning:
			return child as Node3D
	return null


func _leftover_slot() -> Slot:
	return _node("PassSlot04") as Slot


# --- Bloques del flujo ---------------------------------------------------------------------------


## Caja del tamaño de la receta de la estantería a la bandeja, por el lado del servicio.
func _box_to_tray(w: Walker, recipe: RecipeData) -> void:
	var spawner: Node3D = _shelf_spawner(recipe)
	await _use(w, spawner, _shelf_stand(spawner))
	await _use(w, _station().get_tray(), _tray_stand(1.0))


## Pulpo de la nevera a la olla 1 (y cachelos a la olla 2 si hacen falta).
func _start_cooking(w: Walker, cachelos: bool) -> void:
	await _use(w, _node("OctopusStorage"), _back("OctopusStorage"))
	await _use(w, _node("Kitchen"), _back("Kitchen"))
	if cachelos:
		await _use(w, _node("CachelosStorage"), _back("CachelosStorage"))
		await _use(w, _node("Kitchen2"), _back("Kitchen2"))


## Recoge lo cocido; los cachelos al cuenco por el lado de pase; deja el pulpo en la mano.
func _collect_cooked(w: Walker, cachelos: bool, needed: int) -> void:
	await _wait_until(func() -> bool: return _cooked >= needed)
	if cachelos:
		await _use(w, _node("Kitchen2"), _back("Kitchen2"))
		var bowl: Node3D = _station().get_node("CachelosBowl")
		await _use(w, bowl, Vector2(_xz(bowl).x, -ACCESS))
	await _use(w, _node("Kitchen"), _back("Kitchen"))


## Pulpo de la mano: corta la caja de la bandeja desde el pase y deja el sobrante en un pasaplatos.
func _cut_on_tray(w: Walker, recipe: RecipeData) -> void:
	var presses: int = int(round(1.0 / recipe.box.fill_per_press))
	await _wait_until(func() -> bool: return _station().get_box() != null)
	await _use(w, _station().get_tray(), _tray_stand(-1.0), presses)
	if w.holder().get_held_item() != null:
		var slot: Slot = _leftover_slot()
		await _use(w, slot, Vector2(_xz(slot).x, -ACCESS))


## Recoge el sobrante del pasaplatos.
func _take_leftover(w: Walker) -> void:
	var slot: Slot = _leftover_slot()
	await _use(w, slot.get_item(), Vector2(_xz(slot).x, -ACCESS))


func _season_and_deliver(w: Walker, seasonings: Array) -> void:
	await _wait_until(
		func() -> bool: return _station().get_box() != null and _station().get_box().is_full()
	)
	for seasoning: SeasoningData in seasonings:
		var piece: Node3D = (
			_station().get_node("CachelosBowl") if seasoning == CACHELOS else _dispenser(seasoning)
		)
		await _use(w, piece, Vector2(_xz(piece).x, ACCESS))
	await _use(w, _station().get_tray(), _tray_stand(1.0))
	var stand: Node3D = _stand_for_order()
	var front: Vector2 = _xz(stand) + Vector2(0.0, -2.2)
	var done: int = _completed
	await w.walk_to(front)
	# Entra en la `%DeliveryZone`: con la caja correcta entrega sin pulsar.
	await w.walk_to(_xz(stand) + Vector2(0.0, -1.2))
	for _i: int in 30:
		if _completed > done:
			return
		await get_tree().physics_frame
	await w.push_towards(_xz(stand), 4)
	await w.tap_interact()
	_stats.presses += 1


func _stand_for_order() -> Node3D:
	var orders: Array = OrderService.get_active_orders()
	var slot_id: int = (orders[0] as ActiveOrder).slot_id if not orders.is_empty() else 1
	return _node("OrderStand%d" % slot_id)


# --- Escenarios ----------------------------------------------------------------------------------


## Individual con un solo personaje (Player1, empieza en el servicio).
func _solo(recipe: RecipeData, seasonings: Array, leftover: bool) -> void:
	var w: Walker = Walker.new(get_tree(), _char(1), 1)
	var cachelos: bool = seasonings.has(CACHELOS)
	await _box_to_tray(w, recipe)
	var needed: int = _cooked
	if leftover:
		if cachelos:
			await _start_cooking_cachelos_only(w)
			needed += 1
			await _collect_cachelos_only(w, needed)
		await _take_leftover(w)
	else:
		await _start_cooking(w, cachelos)
		needed += 2 if cachelos else 1
		await _collect_cooked(w, cachelos, needed)
	await _cut_on_tray(w, recipe)
	await _season_and_deliver(w, seasonings)


## Individual con cambio: Player1 emplata (servicio) y Player2 cocina (cocina). J1 empieza en P1.
func _switch_flow(recipe: RecipeData, seasonings: Array, leftover: bool) -> void:
	var server: Walker = Walker.new(get_tree(), _char(1), 1)
	var cook: Walker = Walker.new(get_tree(), _char(2), 1)
	var cachelos: bool = seasonings.has(CACHELOS)
	await _box_to_tray(server, recipe)
	await _switch(server)
	var needed: int = _cooked
	if leftover:
		if cachelos:
			await _start_cooking_cachelos_only(cook)
			needed += 1
			await _collect_cachelos_only(cook, needed)
		await _take_leftover(cook)
	else:
		await _start_cooking(cook, cachelos)
		needed += 2 if cachelos else 1
		await _collect_cooked(cook, cachelos, needed)
	await _cut_on_tray(cook, recipe)
	await _switch(cook)
	await _season_and_deliver(server, seasonings)


## Coop 2P: J1 (WASD) emplata con Player1 y J2 (flechas) cocina con Player2, a la vez.
func _coop(recipe: RecipeData, seasonings: Array, leftover: bool) -> void:
	var server: Walker = Walker.new(get_tree(), _char(1), 1)
	var cook: Walker = Walker.new(get_tree(), _char(2), 2)
	var cachelos: bool = seasonings.has(CACHELOS)
	var done: Array[bool] = [false, false]
	var cook_job: Callable = func() -> void:
		var needed: int = _cooked
		if leftover:
			if cachelos:
				await _start_cooking_cachelos_only(cook)
				needed += 1
				await _collect_cachelos_only(cook, needed)
			await _take_leftover(cook)
		else:
			await _start_cooking(cook, cachelos)
			needed += 2 if cachelos else 1
			await _collect_cooked(cook, cachelos, needed)
		await _cut_on_tray(cook, recipe)
		done[0] = true
	var server_job: Callable = func() -> void:
		await _box_to_tray(server, recipe)
		await _season_and_deliver(server, seasonings)
		done[1] = true
	cook_job.call()
	server_job.call()
	await _wait_until(func() -> bool: return done[0] and done[1])


func _start_cooking_cachelos_only(w: Walker) -> void:
	await _use(w, _node("CachelosStorage"), _back("CachelosStorage"))
	await _use(w, _node("Kitchen2"), _back("Kitchen2"))


func _collect_cachelos_only(w: Walker, needed: int) -> void:
	await _wait_until(func() -> bool: return _cooked >= needed)
	await _use(w, _node("Kitchen2"), _back("Kitchen2"))
	var bowl: Node3D = _station().get_node("CachelosBowl")
	await _use(w, bowl, Vector2(_xz(bowl).x, -ACCESS))
