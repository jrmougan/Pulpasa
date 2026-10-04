extends GutTest
## PUL-024: `level_01.tscn` montado como `Level_01.unity`, con los autoloads reales.
##
## Conversión Unity → Godot (Unity zurdo, +Z adelante; Godot diestro, −Z adelante): espejo
## en Z. Posición `(x, y, z)` → `(x, y, −z)`; cuaternión `(x, y, z, w)` → `(−x, −y, z, w)`:
## yaw y pitch cambian de signo. El frente +Z de un prefab queda en −Z, el de las escenas Godot.
##
## Tabla de referencia (`REFERENCE`): valores de `Level_01.unity` ya convertidos.
## - OctopusStorage: raíz del prefab (−4,758; 0,021; 4,076), yaw 180°.
## - Kitchen: la raíz del prefab está desplazada (0,604; −0,382; 4,38) y la olla cuelga a
##   (−4,03; …; −0,463) de ella; la escena Godot tiene el origen en el fogón, así que la
##   referencia es el centro del collider (−3,426; 3,917) apoyado en el suelo (Y 0). Fogón con
##   yaw 180° en Unity.
## - BoxShelf / SpiceShelf: `Mueblecajas.fbx` tiene el frente en −X local; con yaw −90° de
##   Unity mira a −Z Unity (+Z Godot). El envoltorio `Mueblecajas.tscn` tiene el frente en −Z,
##   de ahí yaw 180°. Raíces (3,42; 0; 4,73) y (5,249; 0,075; 4,646).
## - OrderStand1..4: `DeliverySlots` (2,37; −0,04; −5,38) + x local −4,68 / −3,12 / −1,56 / 0,
##   yaw 180° y escala (0,78; 0,975; 0,975), con `deliverySlotId` 1–4.
## - Player1: (3,62; 0,005; 0), yaw 0.
## - CameraRig: `Main Camera` (0,7; 7,49; −5,86), pitch 37,7° hacia abajo, ortográfica de
##   tamaño 6,37 (semialto en Unity; `Camera3D.size` es el alto total, 12,74).

const LEVEL: PackedScene = preload("res://scenes/levels/level_01.tscn")
const LEVEL_SCRIPT: GDScript = preload("res://scenes/levels/level.gd")
const CAMERA_RIG: PackedScene = preload("res://entities/camera/camera_rig.tscn")
const MENU_SCENE: String = "res://ui/menus/main_menu.tscn"
const POSITION_TOLERANCE: float = 0.1
const ANGLE_TOLERANCE_DEG: float = 2.0
const STAND_COUNT: int = 4
## Nodo → [posición Godot, yaw en grados].
const REFERENCE: Dictionary[String, Array] = {
	"Stations/OctopusStorage": [Vector3(-4.758, 0.021, -4.076), 180.0],
	"Stations/Kitchen": [Vector3(-3.426, 0.0, -3.917), 180.0],
	"Stations/BoxShelf": [Vector3(3.42, 0.0, -4.73), 180.0],
	"Stations/SpiceShelf": [Vector3(5.249, 0.075, -4.646), 180.0],
	"Stations/OrderStand1": [Vector3(-2.31, -0.04, 5.38), 180.0],
	"Stations/OrderStand2": [Vector3(-0.75, -0.04, 5.38), 180.0],
	"Stations/OrderStand3": [Vector3(0.81, -0.04, 5.38), 180.0],
	"Stations/OrderStand4": [Vector3(2.37, -0.04, 5.38), 180.0],
	"Characters/Player1": [Vector3(3.62, 0.005, 0.0), 0.0],
	"CameraRig": [Vector3(0.7, 7.49, 5.86), 0.0],
}
const CAMERA_PITCH_DEG: float = -37.7
const CAMERA_SIZE: float = 12.74
## Rejilla del recorrido (AC4): paso y límites del suelo jugable (Godot).
const GRID_STEP: float = 0.2
const GRID_MIN: Vector2 = Vector2(-7.0, -6.0)
const GRID_MAX: Vector2 = Vector2(8.0, 6.5)
## Capas que frenan al jugador (`world` + `interactable`, máscara de `player.tscn`).
const BLOCKING_MASK: int = 1 | (1 << 2)
## Cuánto puede acercarse el jugador a cada slot de especias (centro a centro, en el suelo).
const SLOT_APPROACH: float = 0.75
## Señales del bus que escuchan el nivel y la UI (AC3).
const BUS_SIGNALS: Array[String] = [
	"orders_reset",
	"order_generated",
	"order_completed",
	"order_expired",
	"round_started",
	"round_time_changed",
	"round_finished",
	"score_changed",
	"pause_changed",
]

## Tamaño de ventana del proyecto (`project.godot`): el headless arranca a 100×100.
const SCREEN_SIZE: Vector2i = Vector2i(1280, 720)

var _level: Node
var _window_size: Vector2i


func before_each() -> void:
	GameState.set_paused(false)
	_window_size = get_tree().root.size


func after_each() -> void:
	GameState.set_paused(false)
	get_tree().root.size = _window_size
	if is_instance_valid(_level):
		var was_current: bool = _level == get_tree().current_scene
		_level.free()
		if was_current:
			get_tree().current_scene = null
	_level = null


func _load_level() -> Node:
	_level = LEVEL.instantiate()
	add_child(_level)
	await wait_physics_frames(2)
	return _level


## Cambia de nivel como el juego (`GameState`) y devuelve la escena actual ya lista. El runner de
## GUT (`gut_cmdln.gd`) es un `SceneTree` sin `current_scene`, así que el cambio no lo destruye.
func _enter_level(start: Callable) -> Node:
	var previous: Node = get_tree().current_scene
	assert_eq(start.call(), OK)
	for _i: int in 120:
		await wait_process_frames(1)
		var current: Node = get_tree().current_scene
		if current != null and current != previous and current.is_node_ready():
			break
	await wait_physics_frames(2)
	_level = get_tree().current_scene
	return _level


func _stands() -> Array[OrderStand]:
	var stands: Array[OrderStand] = []
	for i: int in STAND_COUNT:
		stands.append(_level.get_node("Stations/OrderStand%d" % (i + 1)) as OrderStand)
	return stands


func _player() -> Player:
	return _level.get_node("Characters/Player1") as Player


func _slot_ids(orders: Array[ActiveOrder]) -> Array[int]:
	var ids: Array[int] = []
	for order: ActiveOrder in orders:
		ids.append(order.slot_id)
	return ids


# --- AC1 ---------------------------------------------------------------------------------------


func test_ac1_play_target_is_level_01() -> void:
	assert_eq(GameState.LEVEL_SCENE, LEVEL.resource_path)
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), MENU_SCENE)


func test_ac1_level_has_one_player_four_stands_with_orders_hud_and_tickets() -> void:
	await _enter_level(func() -> Error: return GameState.start_level(GameMode.Mode.SINGLE))
	assert_eq(_level.scene_file_path, LEVEL.resource_path, "start_level carga level_01")
	var players: Array[Node] = _level.get_node("Characters").get_children()
	assert_eq(players.size(), 1, "un solo personaje en M0")
	var player: Player = _player()
	var control: ControlComponent = player.get_node("%Control")
	assert_eq(control.player_index, 1)
	assert_eq(control.controlled_by, 1)
	assert_eq(player.items_root, _level.get_node("Items"))
	assert_eq(player.camera, _level.get_node("CameraRig"))

	var stands: Array[OrderStand] = _stands()
	assert_eq(_level.get("stands").size(), STAND_COUNT)
	for i: int in STAND_COUNT:
		assert_eq(stands[i].slot_id, i + 1)
		assert_eq(_level.get("stands")[i], stands[i])
		var label: String = (stands[i].get_node("%OrderLabel") as Label3D).text
		assert_ne(label, "–", "el puesto %d tiene comanda" % (i + 1))
	RoundManager.round_state.advance(5.0)
	assert_eq(_slot_ids(OrderService.get_active_orders()), [1, 2, 3, 4] as Array[int])

	var hud: Control = _level.get_node("UI/HUD")
	var tickets: OrderTicketsPanel = _level.get_node("UI/OrderTicketsPanel")
	assert_true(hud is RoundHUD and hud.is_visible_in_tree(), "HUD visible")
	assert_true(tickets.is_visible_in_tree(), "tickets visibles")
	assert_eq(tickets.get_node("%Tickets").get_child_count(), STAND_COUNT)
	assert_false((_level.get_node("UI/GameOver") as GameOver).visible)
	assert_false((_level.get_node("UI/PauseMenu") as PauseMenu).visible)
	assert_true(_level.get_node("UI") is CanvasLayer)


func test_ac1_level_root_only_uses_level_script() -> void:
	var state: SceneState = LEVEL.get_state()
	assert_eq(_level_script_path(state), "res://scenes/levels/level.gd")
	for i: int in range(1, state.get_node_count()):
		for p: int in state.get_node_property_count(i):
			var prop: StringName = state.get_node_property_name(i, p)
			assert_ne(prop, &"script", "sin scripts propios en %s" % state.get_node_path(i))


func _level_script_path(state: SceneState) -> String:
	for p: int in state.get_node_property_count(0):
		if state.get_node_property_name(0, p) == &"script":
			return (state.get_node_property_value(0, p) as Script).resource_path
	return ""


# --- AC2 ---------------------------------------------------------------------------------------


func test_ac2_positions_and_rotations_match_unity_level() -> void:
	await _load_level()
	for path: String in REFERENCE:
		var node: Node3D = _level.get_node(path) as Node3D
		assert_not_null(node, path)
		var expected: Vector3 = REFERENCE[path][0]
		var expected_yaw: float = REFERENCE[path][1]
		var actual: Vector3 = node.global_position
		assert_lt(actual.distance_to(expected), POSITION_TOLERANCE, "%s: %s" % [path, actual])
		var yaw: float = rad_to_deg(node.global_basis.get_euler().y)
		assert_lt(
			absf(rad_to_deg(angle_difference(deg_to_rad(yaw), deg_to_rad(expected_yaw)))),
			ANGLE_TOLERANCE_DEG,
			"%s: yaw %.1f" % [path, yaw]
		)


func test_ac2_camera_matches_unity_main_camera() -> void:
	await _load_level()
	var camera: Camera3D = _level.get_node("CameraRig") as Camera3D
	assert_eq(camera.projection, Camera3D.PROJECTION_ORTHOGONAL)
	assert_almost_eq(camera.size, CAMERA_SIZE, 0.01)
	var pitch: float = rad_to_deg(camera.global_basis.get_euler().x)
	assert_almost_eq(pitch, CAMERA_PITCH_DEG, ANGLE_TOLERANCE_DEG)
	assert_true(camera.current)


func test_ac2_stand_scale_matches_unity() -> void:
	await _load_level()
	for stand: OrderStand in _stands():
		var scale: Vector3 = stand.global_basis.get_scale()
		assert_almost_eq(scale.x, 0.78, 0.01)
		assert_almost_eq(scale.y, 0.975, 0.01)
		assert_almost_eq(scale.z, 0.975, 0.01)


func test_ac2_kitchen_layout_has_floor_and_17_tables_on_world_layer() -> void:
	await _load_level()
	var layout: Node3D = _level.get_node("KitchenLayout")
	var tables: Node = layout.get_node("Tables")
	assert_eq(tables.get_child_count(), 17)
	var bodies: Array[Node] = layout.find_children("*", "StaticBody3D", true, false)
	assert_eq(bodies.size(), 18, "suelo + 17 mesas")
	for body: Node in bodies:
		assert_eq((body as StaticBody3D).collision_layer, 1, "%s en capa world" % body.name)


func test_ac2_environment_has_world_environment_and_sun() -> void:
	await _load_level()
	var env: Node = _level.get_node("Environment")
	assert_eq(env.find_children("*", "WorldEnvironment", true, false).size(), 1)
	var suns: Array[Node] = env.find_children("*", "DirectionalLight3D", true, false)
	assert_eq(suns.size(), 1)
	var sun: DirectionalLight3D = suns[0]
	assert_almost_eq(sun.light_energy, 1.34, 0.01)
	assert_true(sun.shadow_enabled)
	# Unity: euler (57,97; −18,3; 7,8) → la luz apunta hacia abajo y hacia −Z de Godot.
	var direction: Vector3 = -sun.global_basis.z
	assert_lt(direction.y, -0.8)
	assert_lt(direction.z, 0.0)


# --- Layout, cámara y validaciones (PUL-026) ---------------------------------------------------


## Rects de pantalla que ocupa la UI de partida: HUD y cada ticket (el panel de tickets es
## transparente al ratón y solo "tapa" donde hay tickets).
func _load_level_at_project_size() -> Node:
	get_tree().root.size = SCREEN_SIZE
	await _load_level()
	await wait_process_frames(2)
	return _level


func _ui_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = [(_level.get_node("UI/HUD") as Control).get_global_rect()]
	var panel: Control = _level.get_node("UI/OrderTicketsPanel")
	for ticket: Node in panel.get_node("%Tickets").get_children():
		rects.append((ticket as Control).get_global_rect())
	return rects


func test_ui_does_not_cover_fridge_pot_or_shelves_with_game_camera() -> void:
	await _load_level_at_project_size()
	var camera: Camera3D = _level.get_node("CameraRig")
	var screen: Rect2 = Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	var rects: Array[Rect2] = _ui_rects()
	assert_eq(rects.size(), STAND_COUNT + 1)
	for path: String in ["OctopusStorage", "Kitchen", "BoxShelf", "SpiceShelf"]:
		var station: Node3D = _level.get_node("Stations/%s" % path)
		var pos: Vector2 = camera.unproject_position(station.global_position + Vector3.UP * 0.5)
		assert_true(screen.has_point(pos), "%s en pantalla: %s" % [path, pos])
		for rect: Rect2 in rects:
			assert_false(rect.has_point(pos), "%s tapada por %s" % [path, rect])


func test_ui_layout_matches_unity_strip_and_corner() -> void:
	await _load_level_at_project_size()
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var hud: Rect2 = (_level.get_node("UI/HUD") as Control).get_global_rect()
	assert_lt(hud.position.x, screen_size.x * 0.25, "HUD a la izquierda")
	assert_gt(hud.position.y, screen_size.y * 0.6, "HUD abajo")
	var panel: Rect2 = (_level.get_node("UI/OrderTicketsPanel") as Control).get_global_rect()
	assert_almost_eq(panel.position.y, 8.0, 0.5)
	assert_lte(panel.size.y, 250.0)
	for rect: Rect2 in _ui_rects().slice(1):
		assert_lte(rect.end.y, 260.0, "ticket dentro de la franja superior")


func test_camera_rig_default_pose_is_unity_view_and_level_overrides_it() -> void:
	var rig: Camera3D = CAMERA_RIG.instantiate()
	assert_lt(rig.position.distance_to(Vector3(0.7, 7.49, 5.86)), 0.01, "pose por defecto")
	assert_almost_eq(rad_to_deg(rig.rotation.x), CAMERA_PITCH_DEG, ANGLE_TOLERANCE_DEG)
	assert_eq(rig.projection, Camera3D.PROJECTION_ORTHOGONAL)
	assert_almost_eq(rig.size, CAMERA_SIZE, 0.01)
	rig.free()
	var state: SceneState = LEVEL.get_state()
	var found: bool = false
	for i: int in state.get_node_count():
		if str(state.get_node_path(i)).ends_with("CameraRig"):
			for p: int in state.get_node_property_count(i):
				if state.get_node_property_name(i, p) == &"transform":
					found = true
					var pose: Transform3D = state.get_node_property_value(i, p)
					assert_lt(pose.origin.distance_to(Vector3(0.7, 7.49, 5.86)), 0.01)
	assert_true(found, "level_01 sobrescribe el transform de CameraRig")


func test_level_script_reports_missing_configuration() -> void:
	var level: Node = LEVEL_SCRIPT.new()
	add_child_autofree(level)
	assert_push_error("faltan round_config u order_catalog")


func test_level_script_reports_stand_without_slot_id() -> void:
	var level: Node = LEVEL_SCRIPT.new()
	var bad: Node = Node.new()
	bad.name = "SinSlot"
	var good: OrderStand = OrderStand.new()
	level.set("stands", [bad, good] as Array[Node])
	var ids: Array[int] = level.get_slot_ids()
	assert_push_error("SinSlot no tiene slot_id")
	assert_eq(ids.size(), 1)
	bad.free()
	good.free()
	level.free()


# --- AC3 ---------------------------------------------------------------------------------------


func test_ac3_retry_after_round_finished_leaves_clean_state() -> void:
	watch_signals(EventBus)
	var baseline: Dictionary[String, int] = _bus_connections()
	await _enter_level(func() -> Error: return GameState.start_level(GameMode.Mode.SINGLE))
	var with_level: Dictionary[String, int] = _bus_connections()
	# Ensucia la ronda: un pulpo en la olla y el reloj a cero.
	var actor: InteractionComponent = _player().get_node("%InteractionComponent")
	var storage: ItemSpawner = _level.get_node("Stations/OctopusStorage")
	var kitchen: CookingStation = _level.get_node("Stations/Kitchen")
	assert_true(storage.interact(actor))
	assert_true(kitchen.interact(actor))
	assert_true(kitchen.is_cooking())
	var config: RoundConfig = _level.get("round_config")
	RoundManager.round_state.advance(config.duration + 1.0)
	assert_signal_emit_count(EventBus, "round_finished", 1)
	assert_true((_level.get_node("UI/GameOver") as GameOver).visible)

	# Reintentar = `GameState.restart_level()`: se libera el nivel y entra uno nuevo.
	var old_level: Node = _level
	var before: Dictionary[String, int] = _emit_counts()
	await _enter_level(func() -> Error: return GameState.restart_level())
	assert_ne(_level, old_level, "escena nueva")
	assert_false(is_instance_valid(old_level) and old_level.is_inside_tree(), "nivel viejo fuera")
	assert_eq(_bus_connections(), with_level, "sin señales duplicadas")
	var after: Dictionary[String, int] = _emit_counts()
	assert_eq(after["orders_reset"] - before["orders_reset"], 1)
	assert_eq(after["round_started"] - before["round_started"], 1)
	assert_eq(after["order_generated"] - before["order_generated"], STAND_COUNT)
	assert_eq(after["round_finished"] - before["round_finished"], 0)
	RoundManager.round_state.advance(5.0)
	assert_eq(_slot_ids(OrderService.get_active_orders()), [1, 2, 3, 4] as Array[int])
	assert_almost_eq(RoundManager.round_state.get_time_left(), config.duration, 0.1)
	var new_kitchen: CookingStation = _level.get_node("Stations/Kitchen")
	assert_false(new_kitchen.is_cooking(), "olla libre")
	assert_null(new_kitchen.get_ingredient())
	assert_eq(_level.get_node("Items").get_child_count(), 0)
	assert_false((_level.get_node("UI/GameOver") as GameOver).visible)


## Conexiones por señal del bus que usan nivel y UI.
func _bus_connections() -> Dictionary[String, int]:
	var counts: Dictionary[String, int] = {}
	for signal_name: String in BUS_SIGNALS:
		counts[signal_name] = EventBus.get_signal_connection_list(signal_name).size()
	return counts


func _emit_counts() -> Dictionary[String, int]:
	var counts: Dictionary[String, int] = {}
	for signal_name: String in BUS_SIGNALS:
		counts[signal_name] = get_signal_emit_count(EventBus, signal_name)
	return counts


# --- AC4 ---------------------------------------------------------------------------------------


func test_ac4_player_reaches_and_interacts_with_every_station_and_slot() -> void:
	await _load_level()
	var player: Player = _player()
	var actor: InteractionComponent = player.get_node("%InteractionComponent")
	var hold: Holder = player.get_node("%HoldComponent")
	var reachable: Dictionary[Vector2i, bool] = _reachable_cells(player)
	assert_gt(reachable.size(), 100, "el jugador tiene suelo libre")

	var storage: Node3D = _level.get_node("Stations/OctopusStorage")
	var kitchen: CookingStation = _level.get_node("Stations/Kitchen")
	var shelf: Node3D = _level.get_node("Stations/BoxShelf")
	var spices: Node3D = _level.get_node("Stations/SpiceShelf")

	# Nevera → olla.
	assert_true(await _reach(player, storage, reachable), "alcanza la nevera")
	assert_true(actor.interact_pressed())
	assert_true(hold.get_held_item() is Ingredient)
	assert_true(await _reach(player, kitchen, reachable), "alcanza la olla")
	assert_true(actor.interact_pressed())
	assert_true(kitchen.is_cooking())

	# Cajas: coge cada una y la entrega (vacía) en cada puesto.
	var stands: Array[OrderStand] = _stands()
	var spawners: Array[String] = ["SmallSpawner", "MediumSpawner", "LargeSpawner"]
	for i: int in STAND_COUNT:
		var spawner: Node3D = shelf.get_node(spawners[i % spawners.size()])
		assert_true(await _reach(player, spawner, reachable), "alcanza %s" % spawner.name)
		assert_true(actor.interact_pressed())
		assert_true(hold.get_held_item() is Box)
		assert_true(await _reach(player, stands[i], reachable), "alcanza %s" % stands[i].name)
		assert_true(actor.interact_pressed(), "interactúa con %s" % stands[i].name)
		(hold.get_held_item() as Node).free()

	# Especias: coger y devolver cada bote a su slot.
	for slot_name: String in ["SaltSlot", "PaprikaSlot", "HotPaprikaSlot"]:
		var slot: Slot = spices.get_node(slot_name)
		var jar: Node3D = slot.get_item()
		assert_true(await _reach(player, jar, reachable, slot), "alcanza %s" % slot_name)
		assert_true(actor.interact_pressed())
		assert_eq(hold.get_held_item(), jar)
		await wait_physics_frames(2)
		assert_eq(
			_detector(player).get_target(), slot, "%s: el slot vacío gana al resto" % slot_name
		)
		assert_true(actor.interact_pressed())
		assert_eq(slot.get_item(), jar, "%s: bote devuelto" % slot_name)


func test_ac4_spice_slots_do_not_stop_player_far_from_the_shelf() -> void:
	await _load_level()
	var player: Player = _player()
	var reachable: Dictionary[Vector2i, bool] = _reachable_cells(player)
	var spices: Node3D = _level.get_node("Stations/SpiceShelf")
	for slot_name: String in ["SaltSlot", "PaprikaSlot", "HotPaprikaSlot"]:
		var slot: Node3D = spices.get_node(slot_name)
		var nearest: float = INF
		for cell: Vector2i in reachable:
			nearest = minf(nearest, _cell_pos(cell).distance_to(_flat(slot.global_position)))
		assert_lt(nearest, SLOT_APPROACH, "%s: el jugador llega a %.2f m" % [slot_name, nearest])


func _detector(player: Player) -> InteractionDetector:
	return player.get_node("%InteractionDetector") as InteractionDetector


## Lleva al jugador a la celda alcanzable más cercana desde la que su detector elige `target`
## mirándolo. `aim` es el nodo al que mira (por defecto, `target`).
func _reach(
	player: Player, target: Node3D, reachable: Dictionary[Vector2i, bool], aim: Node3D = null
) -> bool:
	if aim == null:
		aim = target
	var goal: Vector2 = _flat(aim.global_position)
	var cells: Array[Vector2i] = reachable.keys()
	cells.sort_custom(
		func(a: Vector2i, b: Vector2i) -> bool:
			return _cell_pos(a).distance_squared_to(goal) < _cell_pos(b).distance_squared_to(goal)
	)
	for cell: Vector2i in cells.slice(0, 12):
		var pos: Vector2 = _cell_pos(cell)
		player.global_position = Vector3(pos.x, player.global_position.y, pos.y)
		var to_goal: Vector2 = goal - pos
		player.rotation.y = atan2(-to_goal.x, -to_goal.y)
		await wait_physics_frames(3)
		if _detector(player).get_target() == target:
			return true
	return false


## Celdas del suelo libres para la cápsula del jugador, conectadas con su posición inicial (BFS).
func _reachable_cells(player: Player) -> Dictionary[Vector2i, bool]:
	var space: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	var capsule: CollisionShape3D = player.get_node("CollisionShape3D")
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = capsule.shape
	query.collision_mask = BLOCKING_MASK
	query.exclude = [player.get_rid()]
	var start: Vector2i = _cell_of(_flat(player.global_position))
	var seen: Dictionary[Vector2i, bool] = {}
	var reachable: Dictionary[Vector2i, bool] = {}
	var queue: Array[Vector2i] = [start]
	seen[start] = true
	var lift: float = capsule.position.y + 0.02
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		var pos: Vector2 = _cell_pos(cell)
		if pos.x < GRID_MIN.x or pos.x > GRID_MAX.x or pos.y < GRID_MIN.y or pos.y > GRID_MAX.y:
			continue
		query.transform = Transform3D(Basis.IDENTITY, Vector3(pos.x, lift, pos.y))
		if not space.intersect_shape(query, 1).is_empty():
			continue
		reachable[cell] = true
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if not seen.has(next):
				seen[next] = true
				queue.append(next)
	return reachable


func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


func _cell_of(pos: Vector2) -> Vector2i:
	return Vector2i(roundi(pos.x / GRID_STEP), roundi(pos.y / GRID_STEP))


func _cell_pos(cell: Vector2i) -> Vector2:
	return Vector2(cell) * GRID_STEP
