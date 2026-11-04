extends Node
## Reproducción para G22 y G51 de docs/arch/gate-enmiendas.md (PUL-196). Fuera del proyecto a propósito.
## Escenas, catálogo y `round_config.tres` reales, y el autoload real `RoundManager` hace `advance`.
## Lo forzado: `first_order_delay` a 0, la paciencia de la comanda y el teletransporte del jugador a
## `%DeliveryZone`, con la antelación de `REPRO_LEAD` ticks respecto a la caducidad. No es una partida completa de `level_01`.
## Se lanza con repro_lanzador.gd (un `--script` directo no resuelve los autoloads al compilar).

const SLOT_ID: int = 2
const ZONE: Vector3 = Vector3(0, 0, 3.40)
const FAR: Vector3 = Vector3(20, 0, 20)

var _bus: Node
var _ticks: int = 0
var _player: Player
## Ticks de antelación con que el jugador entra en la zona respecto al `advance` que caduca.
var _lead: int = int(OS.get_environment("REPRO_LEAD"))
var _board: OrderBoard
var _rejected: int = 0


func _ready() -> void:
	var root: Node = get_tree().root
	_bus = root.get_node("EventBus")
	var service: Node = root.get_node("OrderService")
	var manager: Node = root.get_node("RoundManager")
	var catalog: OrderCatalog = load("res://data/orders/order_catalog.tres")
	var config: RoundConfig = load("res://data/config/round_config.tres")
	config = config.duplicate() as RoundConfig
	config.first_order_delay = 0.0
	print("wrong_delivery_penalty de round_config.tres = ", config.wrong_delivery_penalty)
	service.setup(catalog, null, config)
	_board = service.board
	var level: Node3D = Node3D.new()
	add_child(level)
	var stand: OrderStand = (load("res://entities/stations/order_stand.tscn") as PackedScene).instantiate()
	stand.slot_id = SLOT_ID
	level.add_child(stand)
	_player = (load("res://entities/player/player.tscn") as PackedScene).instantiate()
	_player.position = FAR
	level.add_child(_player)
	var hold: HoldComponent = _player.get_node("%HoldComponent")
	hold.items_root = level
	var zone: Area3D = stand.get_node("%DeliveryZone")
	zone.body_entered.connect(func(_b: Node3D) -> void: _log("body_entered"))
	_bus.order_expired.connect(_on_expired)
	_bus.order_generated.connect(func(o: ActiveOrder) -> void: _log("order_generated id=%d slot=%d" % [o.id, o.slot_id]))
	_bus.order_completed.connect(func(o: ActiveOrder, _p: int) -> void: _log("order_completed id=%d" % o.id))
	_bus.delivery_rejected.connect(_on_rejected)
	manager.start_round(config, [1, 2, 3, 4] as Array[int])
	get_tree().physics_frame.connect(_on_physics_frame)


## Caja real llena con la API de juego, en la mano, con lo que pide `data`.
func _box_in_hand(data: OrderData) -> void:
	var level: Node3D = _player.get_parent() as Node3D
	var hold: HoldComponent = _player.get_node("%HoldComponent")
	var actor: InteractionComponent = _player.get_node("%InteractionComponent")
	var box: Box = (load("res://entities/items/box.tscn") as PackedScene).instantiate()
	level.add_child(box)
	box.data = load("res://data/boxes/box.tres")
	var guard: int = 0
	while not box.is_full() and guard < 200:
		var octopus: Ingredient = (load("res://entities/items/octopus.tscn") as PackedScene).instantiate()
		level.add_child(octopus)
		octopus.set_cooked()
		hold.pick_up(octopus)
		while octopus.is_inside_tree() and not box.is_full() and guard < 200:
			box.interact(actor)
			guard += 1
		if is_instance_valid(octopus):
			hold.drop()
			octopus.free()
	for seasoning: SeasoningData in data.seasonings:
		box.apply_seasoning(seasoning)
	hold.pick_up(box)


func _on_physics_frame() -> void:
	_ticks += 1
	if _ticks == 5:
		_box_in_hand((_board._orders[SLOT_ID] as ActiveOrder).data)
	if _ticks == 10 - _lead:
		_player.global_position = ZONE
		_log("jugador movido a la zona")
	if _ticks == 10:
		# Solo se fuerza esta paciencia: caduca en el `advance` del tick siguiente.
		var order: ActiveOrder = _board._orders[SLOT_ID]
		order.time_left = 0.001
		_log("paciencia forzada id=%d" % order.id)
	if _ticks == 20:
		print("RESULTADO: delivery_rejected emitidas = %d" % _rejected)
		get_tree().quit(0)


func _on_expired(order: ActiveOrder, penalty: int) -> void:
	_log("order_expired id=%d slot=%d penalty=%d" % [order.id, order.slot_id, penalty])


func _on_rejected(slot_id: int, order_id: int, penalty: int) -> void:
	_rejected += 1
	_log("delivery_rejected slot=%d order=%d penalty=%d" % [slot_id, order_id, penalty])


func _log(message: String) -> void:
	print("physics_frame=%d %s" % [Engine.get_physics_frames(), message])
