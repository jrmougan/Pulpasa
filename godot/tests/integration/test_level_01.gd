# gdlint: disable=max-public-methods
extends GutTest
## PUL-024: `level_01.tscn` montado con los autoloads reales; PUL-061: planta B · barra partida
## (D19, `docs/design/level-layouts.md`; scene-tree.md §2).
##
## Cuadrícula de 16 × 11 celdas de 1 m: columna `c` → x = c − 6,3 (centro); fila `r` → z = r − 4,0.
## Arriba (z−) la cocina, abajo (z+) el servicio; la barra de la fila 4 los separa y solo se cruza
## por el hueco de x 2,8…4,2 (D23, PUL-101). Las posiciones son orientativas (±1 m, AC2 de
## PUL-061); la cámara sigue siendo la del prototipo (D14).

const LEVEL: PackedScene = preload("res://scenes/levels/level_01.tscn")
const LEVEL_SCRIPT: GDScript = preload("res://scenes/levels/level.gd")
const CAMERA_RIG: PackedScene = preload("res://entities/camera/camera_rig.tscn")
const MENU_SCENE: String = "res://ui/menus/main_menu.tscn"
## Tolerancia de las posiciones de la planta (AC2 de PUL-061: ±1 m).
const POSITION_TOLERANCE: float = 1.0
const ANGLE_TOLERANCE_DEG: float = 2.0
const STAND_COUNT: int = 4
## Celdas de la planta B (scene-tree.md §2): nodo → [columna, fila, yaw en grados]. El yaw 180
## pone el frente de las estaciones de la fila 0 hacia el servicio (+Z); la estantería de cajas
## mira a +X (yaw −90).
const PLAN: Dictionary[String, Array] = {
	"Stations/OctopusStorage": [2, 0, 180.0],
	"Stations/CachelosStorage": [3, 0, 180.0],
	"Stations/Kitchen": [5, 0, 180.0],
	"Stations/Kitchen2": [7, 0, 180.0],
	"Stations/SeasoningStation": [6.5, 4, 0.0],
	"Stations/BoxShelf": [0, 6.5, -90.0],
	"Stations/OrderStand1": [3, 10, 180.0],
	"Stations/OrderStand2": [5, 10, 180.0],
	"Stations/OrderStand3": [8, 10, 180.0],
	"Stations/OrderStand4": [10, 10, 180.0],
	"Characters/Player1": [11, 7, 0.0],
	"Characters/Player2": [2, 2, 0.0],
}
## Pasaplatos (D23): 3 al oeste de la estación (que ocupa x −2,4…2,8) y 3 al este del hueco.
const PASS_X: Array[float] = [-5.3, -4.3, -3.3, 4.7, 5.7, 6.7]
const PASS_COUNT: int = 6
const PASS_MARK_PATH: String = "res://assets/models/furniture/counters/pass_mark.glb"
## Estación al paso (5,2 m en x = 0,2) y hueco de la barra (centro 3,5; R14 pide x ∈ [2,7; 3,7]).
const STATION_MIN_X: float = -2.4
const GAP_MIN_X: float = 2.8
const GAP_MAX_X: float = 4.2
const BAR_Z: float = 0.0
## R11: ancho mínimo de la marca de un pasaplatos a 1280 × 720 (px).
const MARK_MIN_PX: float = 18.0
## R14: rodeo de la cara de condimentar a la cara de pase de la estación (m).
const DETOUR_MIN: float = 6.0
const DETOUR_MAX: float = 10.0
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const SMALL_BOX: BoxData = preload("res://data/boxes/small.tres")
const CAMERA_PITCH_DEG: float = -37.7
const CAMERA_SIZE: float = 12.74
## Rejilla del recorrido (AC4): paso y límites del suelo jugable (Godot).
const GRID_STEP: float = 0.2
const GRID_MIN: Vector2 = Vector2(-7.0, -5.0)
const GRID_MAX: Vector2 = Vector2(9.4, 6.6)
## Capas que frenan al jugador (`world` + `interactable`, máscara de `player.tscn`).
const BLOCKING_MASK: int = 1 | (1 << 2)
## AC2 de PUL-061: distancias de la columna B de `docs/evidence/PUL-041/distancias.md` (m) y
## tolerancia (±1 m: la cuadrícula del diseño no modela la cápsula).
const DISTANCE_TOLERANCE: float = 1.0
const B_BOXES_TO_PASS: float = 1.0
const B_FRIDGE_TO_POT: float = 3.0
const B_CACHELERA_TO_POT: float = 2.0
const B_POT_TO_PASS: float = 2.0
const B_PASS_TO_STATION: float = 1.0
const B_POT_TO_STATION: float = 2.0
const B_STATION_TO_STANDS: Array[float] = [5.0, 4.0, 4.0, 5.0]
## D23 (PUL-101): el hueco pasa de x 7,7 a x 3,5 y el rodeo de salida a salida baja de 18,2 m a
## 12,3 m (medido con la rejilla de este test).
const B_EXIT_J2_TO_J1: float = 12.3
## Del centro de una estación a la celda desde la que se usa (la de al lado, 1 m).
const ACCESS_OFFSET: float = 1.0
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
	PhaselessConfig.disable()
	GameState.set_paused(false)
	_window_size = get_tree().root.size


func after_each() -> void:
	GameState.set_paused(false)
	GameState.reset_input()
	get_tree().root.size = _window_size
	if is_instance_valid(_level):
		var was_current: bool = _level == get_tree().current_scene
		_level.free()
		if was_current:
			get_tree().current_scene = null
	_level = null
	PhaselessConfig.restore()


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


func test_ac1_level_has_players_four_stands_with_orders_hud_and_tickets() -> void:
	await _enter_level(func() -> Error: return GameState.start_level(GameMode.Mode.SINGLE))
	assert_eq(_level.scene_file_path, LEVEL.resource_path, "start_level carga level_01")
	var players: Array[Node] = _level.get_node("Characters").get_children()
	assert_eq(players.size(), 2, "dos personajes desde M2 (PUL-037)")
	var player: Player = _player()
	var control: ControlComponent = player.get_node("%Control")
	assert_eq(control.player_index, 1)
	assert_eq(control.controlled_by, 1)
	assert_eq(player.items_root, _level.get_node("Items"))
	assert_eq(player.camera, _level.get_node("CameraRig"))

	var stands: Array[OrderStand] = _stands()
	assert_eq(_level.get("stands").size(), STAND_COUNT)
	# M1: las comandas iniciales se generan tras first_order_delay (5 s, dato).
	RoundManager.round_state.advance(5.0)
	for i: int in STAND_COUNT:
		assert_eq(stands[i].slot_id, i + 1)
		assert_eq(_level.get("stands")[i], stands[i])
		var label: String = (stands[i].get_node("%OrderLabel") as Label3D).text
		assert_ne(label, "–", "el puesto %d tiene comanda" % (i + 1))
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


## Centro de la celda (`col`, `row`) en el suelo (`x`, `z`).
static func _cell_center(col: float, row: float) -> Vector2:
	return Vector2(col - 6.3, row - 4.0)


func test_ac2_positions_and_rotations_follow_planta_b() -> void:
	await _load_level()
	for path: String in PLAN:
		var node: Node3D = _level.get_node(path) as Node3D
		assert_not_null(node, path)
		var expected: Vector2 = _cell_center(PLAN[path][0], PLAN[path][1])
		var expected_yaw: float = PLAN[path][2]
		var actual: Vector2 = _flat(node.global_position)
		assert_lt(actual.distance_to(expected), POSITION_TOLERANCE, "%s: %s" % [path, actual])
		var yaw: float = rad_to_deg(node.global_basis.get_euler().y)
		assert_lt(
			absf(rad_to_deg(angle_difference(deg_to_rad(yaw), deg_to_rad(expected_yaw)))),
			ANGLE_TOLERANCE_DEG,
			"%s: yaw %.1f" % [path, yaw]
		)


func test_ac2_pass_slots_sit_on_the_bar_with_their_own_mark() -> void:
	await _load_level()
	for i: int in PASS_COUNT:
		var slot: Slot = _level.get_node("Stations/PassSlot%02d" % (i + 1)) as Slot
		assert_not_null(slot, "PassSlot%02d" % (i + 1))
		var expected: Vector2 = Vector2(PASS_X[i], BAR_Z)
		assert_lt(_flat(slot.global_position).distance_to(expected), 0.05, slot.name)
		assert_almost_eq(slot.global_position.y, 0.0, 0.001, "%s sobre el suelo" % slot.name)
		assert_null(slot.initial_item, "%s sin objeto inicial" % slot.name)
		assert_eq(slot.accepted_group, &"", "%s acepta cualquier objeto" % slot.name)
		assert_true((slot.get_node("Model") as Node3D).visible, "%s: marca visible" % slot.name)
		var anchor: Node3D = slot.get_node("%Anchor")
		assert_almost_eq(
			anchor.global_position.y, 1.14, 0.02, "%s: a la altura de la barra" % slot.name
		)


## R11 (L1): exactamente 6 `PassSlot` con su marca, ninguno en el tramo de la estación ni en el
## hueco, y ningún otro `Slot` en el nivel.
func test_r11_exactly_six_marked_pass_slots_outside_station_and_gap() -> void:
	await _load_level()
	var slots: Array[Node] = _level.find_children("*", "Slot", true, false)
	assert_eq(slots.size(), PASS_COUNT, "ningún otro Slot en el nivel")
	var names: Array[String] = []
	for node: Node in slots:
		names.append(node.name)
		var x: float = (node as Node3D).global_position.x
		assert_true(
			x < STATION_MIN_X - 0.4 or x > GAP_MAX_X + 0.4,
			"%s (x %.1f) fuera del tramo de la estación y del hueco" % [node.name, x]
		)
		var mark: Node3D = node.get_node("Model") as Node3D
		assert_eq(mark.scene_file_path, PASS_MARK_PATH, "%s lleva pass_mark" % node.name)
	names.sort()
	var expected: Array[String] = []
	for i: int in PASS_COUNT:
		expected.append("PassSlot%02d" % (i + 1))
	assert_eq(names, expected)


## R11: cada marca mide >= 18 px de ancho a 1280 × 720 con la cámara real del nivel.
func test_r11_pass_marks_are_at_least_18_px_with_the_game_camera() -> void:
	await _load_level_at_project_size()
	var camera: Camera3D = _level.get_node("CameraRig")
	for i: int in PASS_COUNT:
		var slot: Slot = _level.get_node("Stations/PassSlot%02d" % (i + 1)) as Slot
		var bounds: AABB = AABB()
		var first: bool = true
		for mesh: Node in (slot.get_node("Model") as Node).find_children(
			"*", "MeshInstance3D", true, false
		):
			var instance: MeshInstance3D = mesh as MeshInstance3D
			var box: AABB = instance.global_transform * instance.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
		assert_false(first, "%s tiene malla" % slot.name)
		var left: Vector2 = camera.unproject_position(bounds.position)
		var right: Vector2 = camera.unproject_position(
			bounds.position + Vector3(bounds.size.x, 0, 0)
		)
		assert_gte(left.distance_to(right), MARK_MIN_PX, "%s: marca estrecha" % slot.name)


## R11: con algo en la mano frente a la barra, fuera de los pasaplatos y de la estación, interactuar
## no suelta nada: la mano no cambia y ningún `Slot` guarda la caja.
func test_r11_pressing_in_front_of_the_bar_changes_nothing_in_the_hand() -> void:
	await _load_level()
	var player: Player = _player()
	var actor: InteractionComponent = player.get_node("%InteractionComponent")
	var hold: Holder = player.get_node("%HoldComponent")
	var items: Node = _level.get_node("Items")
	var checked: int = 0
	var x: float = -5.5
	while x <= 8.0:
		for side: float in [1.0, -1.0]:
			if x > GAP_MIN_X - 0.7 and x < GAP_MAX_X + 0.7:
				continue
			player.global_position = Vector3(x, player.global_position.y, BAR_Z + side * 0.85)
			player.rotation.y = 0.0 if side > 0.0 else PI
			var box: Box = BOX_SCENE.instantiate()
			box.data = SMALL_BOX
			items.add_child(box)
			assert_true(hold.pick_up(box))
			await wait_physics_frames(3)
			var target: Node = _detector(player).get_target()
			if not (target is Slot or target is SeasoningDispenser or target is CachelosBowl):
				actor.interact_pressed()
				checked += 1
				assert_eq(
					hold.get_held_item(), box, "x %.1f lado %.0f: la mano no cambia" % [x, side]
				)
				for slot: Node in _level.find_children("*", "Slot", true, false):
					assert_false((slot as Slot).has_item(), "ningún pasaplatos guarda la caja")
			box.free()
			await wait_physics_frames(1)
		x += 0.5
	assert_gt(checked, 8, "barrido de la barra fuera de pasaplatos y estación")


func test_r11_bar_is_closed_except_the_gap_and_the_old_gap_is_sealed() -> void:
	await _load_level()
	for body: Node in _level.get_node("KitchenLayout").find_children(
		"*", "StaticBody3D", true, false
	):
		assert_eq((body as StaticBody3D).collision_layer, 1, "%s en capa world" % body.name)
	var reachable: Dictionary[Vector2i, bool] = _reachable_cells(_player())
	var x: float = -5.6
	while x <= 8.0:
		var cell: Vector2i = _cell_of(Vector2(x, BAR_Z))
		if x > GAP_MIN_X + 0.35 and x < GAP_MAX_X - 0.35:
			assert_true(reachable.has(cell), "hueco libre en x %.1f" % x)
		elif x < GAP_MIN_X - 0.1 or x > GAP_MAX_X + 0.1:
			assert_false(reachable.has(cell), "la barra cierra x %.1f" % x)
		x += 0.2
	assert_false(reachable.has(_cell_of(Vector2(7.7, BAR_Z))), "el hueco antiguo (x 7,7) cerrado")


## El hueco libre mide >= 1,0 m entre la estación y la barra del este, y lleva el umbral (PUL-095).
func test_r14_gap_is_at_least_one_metre_wide_and_has_the_threshold() -> void:
	await _load_level()
	var east: StaticBody3D = _level.get_node("KitchenLayout/Bar/BarServiceSide")
	var station: SeasoningStation = _level.get_node("Stations/SeasoningStation")
	var station_box: BoxShape3D = (station.get_node("CollisionShape3D") as CollisionShape3D).shape
	var east_box: BoxShape3D = (east.get_node("CollisionShape3D") as CollisionShape3D).shape
	var station_end: float = station.global_position.x + station_box.size.x / 2.0
	var east_start: float = east.global_position.x - east_box.size.x / 2.0
	assert_gte(east_start - station_end, 1.0, "hueco libre de la barra")
	var centre: float = (east_start + station_end) / 2.0
	assert_between(centre, 2.7, 3.7, "centro del hueco")
	var threshold: Node3D = _level.get_node("KitchenLayout/Bar/GapThreshold") as Node3D
	assert_not_null(threshold)
	assert_almost_eq(threshold.global_position.x, centre, 0.3, "umbral en el hueco")
	assert_almost_eq(threshold.global_position.y, 0.0, 0.001)
	assert_true(threshold.is_visible_in_tree())
	assert_eq(threshold.find_children("*", "CollisionObject3D", true, false).size(), 0)


## R14 (L2): camino más corto de la cara de condimentar a la cara de pase de la estación.
func test_r14_detour_from_operator_face_to_pass_face_is_six_to_ten_metres() -> void:
	await _load_level()
	var reachable: Dictionary[Vector2i, bool] = _reachable_cells(_player())
	var station: SeasoningStation = _level.get_node("Stations/SeasoningStation")
	var operator_face: Array[Vector2] = [
		_flat((station.get_node("%OperatorSide") as Node3D).global_position)
	]
	var pass_face: Array[Vector2] = [
		_flat((station.get_node("%PassSide") as Node3D).global_position)
	]
	var walked: float = _walk_distance(reachable, operator_face, pass_face)
	gut.p("R14 cara de condimentar -> cara de pase: %.2f m" % walked)
	assert_between(walked, DETOUR_MIN, DETOUR_MAX, "rodeo de %.2f m" % walked)


## Las placas `SizePanel_*` / `SizeFront_*` del rack (PUL-095) sobresalen de su colisión: el jugador
## no puede quedar dentro de ellas.
func test_rack_plates_cannot_be_walked_into() -> void:
	await _load_level()
	var reachable: Dictionary[Vector2i, bool] = _reachable_cells(_player())
	var shelf: Node3D = _level.get_node("Stations/BoxShelf")
	var plates: Array[Node] = shelf.find_children("Size*_*", "MeshInstance3D", true, false)
	assert_gt(plates.size(), 0, "placas del rack")
	for node: Node in plates:
		var plate: MeshInstance3D = node as MeshInstance3D
		var bounds: AABB = plate.global_transform * plate.get_aabb()
		for cell: Vector2i in reachable:
			var pos: Vector2 = _cell_pos(cell)
			var inside: bool = (
				pos.x > bounds.position.x
				and pos.x < bounds.end.x
				and pos.y > bounds.position.z
				and pos.y < bounds.end.z
			)
			assert_false(inside, "el jugador atraviesa %s en %s" % [plate.name, pos])


## AC2 de PUL-061: recorridos más cortos andando (8 direcciones, sin cortar esquinas) sobre las
## celdas libres para la cápsula real, entre los puntos de acceso de cada estación, frente a la
## columna B de `docs/evidence/PUL-041/distancias.md` (±1 m).
func test_ac2_planta_b_distances_match_pul041_within_one_metre() -> void:
	await _load_level()
	var reachable: Dictionary[Vector2i, bool] = _reachable_cells(_player())
	var fridge: Array[Vector2] = _front_access("Stations/OctopusStorage")
	var cachelera: Array[Vector2] = _front_access("Stations/CachelosStorage")
	var pots: Array[Vector2] = _front_access("Stations/Kitchen")
	pots.append_array(_front_access("Stations/Kitchen2"))
	var pass_kitchen: Array[Vector2] = _pass_access(-1.0)
	var pass_service: Array[Vector2] = _pass_access(1.0)
	var pass_both: Array[Vector2] = pass_kitchen + pass_service
	var station_pass: Array[Vector2] = _station_access(-1.0)
	var station_operator: Array[Vector2] = _station_access(1.0)
	var boxes: Array[Vector2] = []
	for spawner: Node in _level.get_node("Stations/BoxShelf").get_children():
		if spawner is ItemSpawner:
			boxes.append(_flat((spawner as Node3D).global_position) + Vector2(ACCESS_OFFSET, 0.0))
	assert_eq(boxes.size(), 3)

	_assert_walk(reachable, boxes, pass_service, B_BOXES_TO_PASS, "cajas → pasaplatos")
	_assert_walk(reachable, fridge, pots, B_FRIDGE_TO_POT, "nevera → olla")
	_assert_walk(reachable, cachelera, pots, B_CACHELERA_TO_POT, "cachelera → olla")
	_assert_walk(reachable, pots, pass_kitchen, B_POT_TO_PASS, "olla → pasaplatos")
	_assert_walk(
		reachable, pass_both, station_pass + station_operator, B_PASS_TO_STATION, "pase → estación"
	)
	_assert_walk(reachable, pots, station_pass, B_POT_TO_STATION, "olla → estación (cachelos)")
	for i: int in STAND_COUNT:
		var stand: Node3D = _stands()[i]
		var front: Array[Vector2] = [_flat(stand.global_position) + Vector2(0.0, -ACCESS_OFFSET)]
		_assert_walk(
			reachable,
			station_operator,
			front,
			B_STATION_TO_STANDS[i],
			"estación → puesto %d" % (i + 1)
		)
	var exit_j2: Array[Vector2] = [_flat(_level.get_node("Characters/Player2").global_position)]
	var exit_j1: Array[Vector2] = [_flat(_player().global_position)]
	_assert_walk(reachable, exit_j2, exit_j1, B_EXIT_J2_TO_J1, "salida J2 → salida J1")


## Celda de acceso delante (+Z) de una estación de la fila 0.
func _front_access(path: String) -> Array[Vector2]:
	var node: Node3D = _level.get_node(path)
	return [_flat(node.global_position) + Vector2(0.0, ACCESS_OFFSET)]


## Celdas de acceso de los pasaplatos por un lado (`side` −1 cocina, +1 servicio).
func _pass_access(side: float) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for i: int in PASS_COUNT:
		var slot: Node3D = _level.get_node("Stations/PassSlot%02d" % (i + 1))
		points.append(_flat(slot.global_position) + Vector2(0.0, side * ACCESS_OFFSET))
	return points


## Celdas de acceso de la estación por un lado: bandeja, cuenco y, del lado de condimentar,
## los dispensadores.
func _station_access(side: float) -> Array[Vector2]:
	var station: SeasoningStation = _level.get_node("Stations/SeasoningStation")
	var parts: Array[Node3D] = [station.get_node("CachelosBowl")]
	if side > 0.0:
		for dispenser: Node in station.get_node("Dispensers").get_children():
			parts.append(dispenser as Node3D)
	var points: Array[Vector2] = []
	for part: Node3D in parts:
		points.append(
			Vector2(part.global_position.x, station.global_position.z + side * ACCESS_OFFSET)
		)
	return points


func _assert_walk(
	reachable: Dictionary[Vector2i, bool],
	from: Array[Vector2],
	to: Array[Vector2],
	expected: float,
	label: String
) -> void:
	var walked: float = _walk_distance(reachable, from, to)
	gut.p("AC2 %s: %.1f m (planta B: %.1f m)" % [label, walked, expected])
	assert_almost_eq(walked, expected, DISTANCE_TOLERANCE, "%s: %.1f m" % [label, walked])


## Dijkstra de varias fuentes sobre `reachable` (8 vecinos, diagonal √2, sin cortar esquinas).
## Cada punto se lleva a la celda libre más cercana.
func _walk_distance(
	reachable: Dictionary[Vector2i, bool], from: Array[Vector2], to: Array[Vector2]
) -> float:
	var goals: Dictionary[Vector2i, bool] = {}
	for point: Vector2 in to:
		goals[_nearest_reachable(reachable, point)] = true
	var dist: Dictionary[Vector2i, float] = {}
	var open: Array[Vector2i] = []
	for point: Vector2 in from:
		var cell: Vector2i = _nearest_reachable(reachable, point)
		dist[cell] = 0.0
		open.append(cell)
	while not open.is_empty():
		var best: int = 0
		for i: int in open.size():
			if dist[open[i]] < dist[open[best]]:
				best = i
		var cell: Vector2i = open[best]
		open.remove_at(best)
		if goals.has(cell):
			return dist[cell] * GRID_STEP
		for dx: int in [-1, 0, 1]:
			for dz: int in [-1, 0, 1]:
				if dx == 0 and dz == 0:
					continue
				var next: Vector2i = cell + Vector2i(dx, dz)
				if not reachable.has(next):
					continue
				if dx != 0 and dz != 0:
					if not reachable.has(cell + Vector2i(dx, 0)):
						continue
					if not reachable.has(cell + Vector2i(0, dz)):
						continue
				var step: float = sqrt(2.0) if dx != 0 and dz != 0 else 1.0
				var candidate: float = dist[cell] + step
				if candidate < dist.get(next, INF):
					if not dist.has(next):
						open.append(next)
					dist[next] = candidate
	return INF


func _nearest_reachable(reachable: Dictionary[Vector2i, bool], point: Vector2) -> Vector2i:
	var best: Vector2i = _cell_of(point)
	var best_d: float = INF
	for cell: Vector2i in reachable:
		var d: float = _cell_pos(cell).distance_squared_to(point)
		if d < best_d:
			best_d = d
			best = cell
	return best


func test_ac2_camera_matches_unity_main_camera() -> void:
	await _load_level()
	var camera: Camera3D = _level.get_node("CameraRig") as Camera3D
	assert_eq(camera.projection, Camera3D.PROJECTION_ORTHOGONAL)
	assert_almost_eq(camera.size, CAMERA_SIZE, 0.01)
	var pitch: float = rad_to_deg(camera.global_basis.get_euler().x)
	assert_almost_eq(pitch, CAMERA_PITCH_DEG, ANGLE_TOLERANCE_DEG)
	assert_true(camera.current)


func test_ac1_stations_have_unit_scale() -> void:
	await _load_level()
	for station: Node in _level.get_node("Stations").get_children():
		var node: Node3D = station as Node3D
		if node == null:
			continue
		var scale: Vector3 = node.basis.get_scale()
		assert_almost_eq(scale.x, 1.0, 0.001, "%s escala x" % node.name)
		assert_almost_eq(scale.y, 1.0, 0.001, "%s escala y" % node.name)
		assert_almost_eq(scale.z, 1.0, 0.001, "%s escala z" % node.name)


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
	# M1: los tickets aparecen con las comandas, tras first_order_delay (5 s, dato).
	RoundManager.round_state.advance(5.0)
	await wait_process_frames(2)
	var camera: Camera3D = _level.get_node("CameraRig")
	var screen: Rect2 = Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	var rects: Array[Rect2] = _ui_rects()
	assert_eq(rects.size(), STAND_COUNT + 1)
	for path: String in [
		"OctopusStorage", "CachelosStorage", "Kitchen", "Kitchen2", "BoxShelf", "SeasoningStation"
	]:
		var station: Node3D = _level.get_node("Stations/%s" % path)
		var pos: Vector2 = camera.unproject_position(station.global_position + Vector3.UP * 0.5)
		assert_true(screen.has_point(pos), "%s en pantalla: %s" % [path, pos])
		for rect: Rect2 in rects:
			assert_false(rect.has_point(pos), "%s tapada por %s" % [path, rect])


func test_ui_layout_matches_unity_strip_and_corner() -> void:
	await _load_level_at_project_size()
	# M1: los tickets aparecen con las comandas, tras first_order_delay (5 s, dato).
	RoundManager.round_state.advance(5.0)
	await wait_process_frames(2)
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
	assert_eq(after["round_finished"] - before["round_finished"], 0)
	assert_almost_eq(RoundManager.round_state.get_time_left(), config.duration, 0.1)
	# M1: las comandas iniciales se generan tras first_order_delay (5 s, dato).
	RoundManager.round_state.advance(5.0)
	var after_delay: Dictionary[String, int] = _emit_counts()
	assert_eq(after_delay["order_generated"] - after["order_generated"], STAND_COUNT)
	assert_eq(_slot_ids(OrderService.get_active_orders()), [1, 2, 3, 4] as Array[int])
	var new_kitchen: CookingStation = _level.get_node("Stations/Kitchen")
	assert_false(new_kitchen.is_cooking(), "olla libre")
	assert_null(new_kitchen.get_ingredient())
	assert_eq(_level.get_node("Items").get_child_count(), 0)
	assert_false((_level.get_node("UI/GameOver") as GameOver).visible)


# --- M1: penalizaciones cableadas en el nivel (PUL-027, D2/D8) -----------------------------------


## La configuración real del nivel llega al tablero (`OrderService.setup(order_catalog, null,
## round_config)`): una entrega ingresa y cada caducidad resta el `expire_penalty` de los datos.
## Robusto al rng del nivel: cuenta las caducidades emitidas en vez de asumir plantillas.
func test_m1_level_wires_expire_penalty_from_data() -> void:
	await _enter_level(func() -> Error: return GameState.start_level(GameMode.Mode.SINGLE))
	RoundManager.round_state.advance(5.0)
	var order: ActiveOrder = OrderService.get_active_orders()[0]
	var contents: BoxContents = BoxContents.new(
		order.data.recipe.box,
		order.data.recipe.ingredient,
		IngredientData.CookingState.COOKED,
		1.0,
		order.data.seasonings.duplicate()
	)
	OrderService.try_deliver(order.slot_id, contents)
	var revenue: int = RoundManager.round_state.get_revenue()
	assert_gt(revenue, 0, "la entrega ingresa base + bonus")

	var config: RoundConfig = _level.get("round_config")
	var max_times: Array[float] = []
	for active: ActiveOrder in OrderService.get_active_orders():
		max_times.append(active.max_time)
	watch_signals(EventBus)
	RoundManager.round_state.advance(max_times.min() + 0.1)
	var expiries: int = get_signal_emit_count(EventBus, "order_expired")
	assert_gt(expiries, 0, "al menos la comanda más impaciente caduca")
	assert_eq(
		RoundManager.round_state.get_revenue(),
		maxi(0, revenue - config.expire_penalty * expiries),
		"cada caducidad resta expire_penalty de los datos"
	)


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
	var kitchen2: CookingStation = _level.get_node("Stations/Kitchen2")
	var shelf: Node3D = _level.get_node("Stations/BoxShelf")
	var cachelera: Node3D = _level.get_node("Stations/CachelosStorage")

	# Nevera → olla.
	assert_true(await _reach(player, storage, reachable), "alcanza la nevera")
	assert_true(actor.interact_pressed())
	assert_true(hold.get_held_item() is Ingredient)
	assert_true(await _reach(player, kitchen, reachable), "alcanza la olla")
	assert_true(actor.interact_pressed())
	assert_true(kitchen.is_cooking())
	# M1: cachelera → olla (segunda plaza, D9/D10): cuecen a la vez.
	assert_true(await _reach(player, cachelera, reachable), "alcanza la cachelera")
	assert_true(actor.interact_pressed())
	var cachelos: Ingredient = hold.get_held_item() as Ingredient
	assert_not_null(cachelos, "la cachelera da cachelos")
	assert_eq(cachelos.data.type, IngredientData.IngredientType.CACHELOS)
	assert_true(await _reach(player, kitchen, reachable), "vuelve a la olla")
	assert_true(actor.interact_pressed())
	assert_null(hold.get_held_item(), "la olla acepta los cachelos junto al pulpo")
	assert_eq(_pot_contents(kitchen), 2, "pulpo y cachelos a la vez en la olla")
	# La segunda olla (D9) también se alcanza y cuece.
	assert_true(await _reach(player, storage, reachable), "vuelve a la nevera")
	assert_true(actor.interact_pressed())
	assert_true(await _reach(player, kitchen2, reachable), "alcanza la segunda olla")
	assert_true(actor.interact_pressed())
	assert_true(kitchen2.is_cooking())

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

	# Pasaplatos: una caja en cada slot de la barra, dejada desde un lado y recogida desde el otro.
	for i: int in PASS_COUNT:
		var slot: Slot = _level.get_node("Stations/PassSlot%02d" % (i + 1))
		var spawner: Node3D = shelf.get_node(spawners[i % spawners.size()])
		assert_true(await _reach(player, spawner, reachable), "alcanza %s" % spawner.name)
		assert_true(actor.interact_pressed())
		var box: Box = hold.get_held_item() as Box
		assert_not_null(box)
		var side: float = 1.0 if i % 2 == 0 else -1.0
		assert_true(await _reach(player, slot, reachable, null, side), "deja en %s" % slot.name)
		assert_true(actor.interact_pressed())
		assert_eq(slot.get_item(), box, "%s guarda la caja" % slot.name)
		assert_true(await _reach(player, box, reachable, slot, -side), "recoge de %s" % slot.name)
		assert_true(actor.interact_pressed())
		assert_eq(hold.get_held_item(), box, "%s: caja recogida por el otro lado" % slot.name)
		box.free()

	# Estación: caja llena a la bandeja por el pase, sal por el lado de condimentar, cuenco.
	var station: SeasoningStation = _level.get_node("Stations/SeasoningStation")
	assert_true(await _reach(player, shelf.get_node("SmallSpawner"), reachable))
	assert_true(actor.interact_pressed())
	var full: Box = hold.get_held_item() as Box
	full.fill = 1.0
	var pass_slot: Slot = _level.get_node("Stations/PassSlot01")
	assert_true(await _reach(player, pass_slot, reachable, null, -1.0), "pasaplatos (pase)")
	assert_true(actor.interact_pressed())
	assert_true(await _reach(player, full, reachable, pass_slot, 1.0), "caja (servicio)")
	assert_true(actor.interact_pressed())
	assert_eq(hold.get_held_item(), full)
	for dispenser: Node in station.get_node("Dispensers").get_children():
		var target: SeasoningDispenser = dispenser as SeasoningDispenser
		assert_true(await _reach(player, target, reachable, null, 1.0), "alcanza %s" % target.name)
		assert_true(actor.interact_pressed())
		assert_true(full.has_seasoning(target.seasoning), "%s condimenta" % target.name)
	var bowl: CachelosBowl = station.get_node("CachelosBowl")
	assert_true(await _reach(player, bowl, reachable, null, 1.0), "alcanza el cuenco")
	assert_eq(hold.get_held_item(), full, "la caja sigue en la mano")


## Ingredientes que hay dentro de la olla (en sus anclas).
func _pot_contents(kitchen: CookingStation) -> int:
	var count: int = 0
	for node: Node in kitchen.find_children("*", "", true, false):
		if node is Ingredient:
			count += 1
	return count


func _detector(player: Player) -> InteractionDetector:
	return player.get_node("%InteractionDetector") as InteractionDetector


## Lleva al jugador a la celda alcanzable más cercana desde la que su detector elige `target`
## mirándolo. `aim` es el nodo al que mira (por defecto, `target`). `side` limita las celdas a un
## lado de la barra: −1 cocina (z menor que `aim`), +1 servicio, 0 cualquiera.
func _reach(
	player: Player,
	target: Node3D,
	reachable: Dictionary[Vector2i, bool],
	aim: Node3D = null,
	side: float = 0.0
) -> bool:
	if aim == null:
		aim = target
	var goal: Vector2 = _flat(aim.global_position)
	var cells: Array[Vector2i] = reachable.keys()
	if side != 0.0:
		cells = cells.filter(
			func(c: Vector2i) -> bool: return (_cell_pos(c).y - goal.y) * side > 0.0
		)
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
