class_name CachelosBowl
extends StaticBody3D
## Cuenco de cachelos de la estación al paso (D10, D23, D26; scene-tree.md §3, ADR-003 §11.7).
## Guarda raciones (`stock`, máximo `cachelos_stock_max`). Solo pone: con cachelos cocidos en la
## mano, desde cualquier lado, repone `cachelos_portions_per_item` raciones si caben (`stock + 2 <=
## 4`); con una caja llena en la mano y desde el lado de condimentar, le pone cachelos (gasta 1
## ración). No quita nunca. Una sola regla (`_resolve` → `ActionRules.for_bowl`) decide el hint y
## la pulsación (ADR-003 §11.2): `NONE` no es objetivo; `BLOCKED` emite `rejected` sin cambiar nada
## y consume; `OK` ejecuta. Ninguna estación suena un cue de error: lo hace el jugador.
## El modelo trae `Portions0..4` (estados exclusivos): solo se ve el de `stock`. `%StockMeter`
## repite `stock` con 4 muescas legibles desde lejos (D26.6).

## Pulsación consumida sin cambiar nada (signals.md §4): `BOWL_EMPTY`, `BOWL_FULL`,
## `ALREADY_APPLIED` o `BOX_NOT_FULL`.
signal rejected(reason: SeasoningRules.Rejection)
## Raciones nuevas; también una vez en `_ready()`.
signal stock_changed(stock: int)

## Estados de raciones del modelo: `Portions0..4`.
const PORTION_STATES: int = 5
const DEFAULT_SEASONING: SeasoningData = preload("res://data/seasonings/cachelos.tres")
## Alto de referencia de las medidas en px de los datos y tamaño ortográfico sin cámara.
const REFERENCE_HEIGHT_PX: float = 1080.0
const DEFAULT_CAMERA_SIZE: float = 12.74

@export var seasoning: SeasoningData = DEFAULT_SEASONING
@export var station: SeasoningStation

## Raciones en el cuenco (0..`cachelos_stock_max`). Asignarlas actualiza el modelo y el medidor, y
## emite `stock_changed`.
var stock: int = 0:
	set = _set_stock
## En desuso (D26: el cuenco ya no tiene antirrebote); solo evita romper flujos que aún lo asignan.
## Se retira con el montaje (PUL-131).
var clock: Callable = Callable()

## Estados del modelo (`Portions0` = fondo vacío … `Portions4`), uno visible a la vez.
@onready var _portions: Array[Node3D] = _find_portions()
@onready var _meter: Sprite3D = get_node_or_null(^"%StockMeter") as Sprite3D


func _ready() -> void:
	var config: SeasoningStationData = _data()
	_set_stock(clampi(config.cachelos_initial_stock, 0, config.cachelos_stock_max))


func _process(_delta: float) -> void:
	_fit_meter()


## Cachelos cocidos (u otra mano sin caja): desde cualquier lado. Con una caja, solo desde el lado
## de condimentar (o los dos con `operator_side_only` = false). Lo que la mano permita lo decide
## `get_action_hint`, no esta consulta de lado (ADR-003 §11.2).
func is_reachable_from(floor_position: Vector2, holder: Holder) -> bool:
	if station == null or holder == null:
		return false
	if not holder.get_held_item() is Box:
		return true
	if not station.data.operator_side_only:
		return true
	return station.side_of(floor_position) == StationSide.Side.OPERATOR


func get_action_hint(actor: InteractionComponent) -> ActionHint:
	if actor == null or actor.holder == null:
		return ActionHint.none()
	return _resolve(actor.holder)


func can_interact(actor: InteractionComponent) -> bool:
	return get_action_hint(actor).is_target()


func interact(actor: InteractionComponent) -> bool:
	if actor == null or actor.holder == null:
		return false
	var hint: ActionHint = _resolve(actor.holder)
	match hint.state:
		ActionHint.State.OK:
			var held: Node = actor.holder.get_held_item()
			if held is Box:
				_put_on_box(held as Box)
			else:
				_restock(actor.holder)
			return true
		ActionHint.State.BLOCKED:
			rejected.emit(_rejection_of(hint.reason))
			return true
	return false


## Única resolución de la mano contra el cuenco (ADR-003 §11.2).
func _resolve(holder: Holder) -> ActionHint:
	var item: Node = holder.get_held_item()
	var box: Box = item as Box
	var config: SeasoningStationData = _data()
	return ActionRules.for_bowl(
		HeldKind.of(item),
		stock,
		config.cachelos_stock_max,
		config.cachelos_portions_per_item,
		box != null and box.has_seasoning(seasoning)
	)


func _restock(holder: Holder) -> void:
	var config: SeasoningStationData = _data()
	var dropped: Node = holder.drop()
	if dropped != null:
		dropped.queue_free()
	_set_stock(
		SeasoningRules.restocked(
			stock, config.cachelos_portions_per_item, config.cachelos_stock_max
		)
	)


func _put_on_box(box: Box) -> void:
	if box.apply_seasoning(seasoning) == SeasoningRules.Rejection.NONE:
		_set_stock(stock - 1)


## `rejected` local de cada motivo del hint (ADR-003 §11.7).
static func _rejection_of(reason: StringName) -> SeasoningRules.Rejection:
	match reason:
		ActionReason.EMPTY:
			return SeasoningRules.Rejection.BOWL_EMPTY
		ActionReason.FULL:
			return SeasoningRules.Rejection.BOWL_FULL
		ActionReason.ALREADY_APPLIED:
			return SeasoningRules.Rejection.ALREADY_APPLIED
	return SeasoningRules.Rejection.BOX_NOT_FULL


func _set_stock(value: int) -> void:
	stock = clampi(value, 0, _data().cachelos_stock_max)
	var shown: int = clampi(stock, 0, _portions.size() - 1)
	for index: int in _portions.size():
		_portions[index].visible = index == shown
	_redraw_meter()
	stock_changed.emit(stock)


func _find_portions() -> Array[Node3D]:
	var found: Array[Node3D] = []
	for index: int in PORTION_STATES:
		var node: Node3D = find_child("Portions%d" % index, true, false) as Node3D
		if node != null:
			found.append(node)
	return found


func _data() -> SeasoningStationData:
	if station != null and station.data != null:
		return station.data
	return SeasoningStation.DEFAULT_DATA


## Medidor de raciones: una muesca por ración posible; `stock` llenas, el resto huecas.
func _redraw_meter() -> void:
	if _meter == null:
		return
	var config: SeasoningStationData = _data()
	_meter.texture = ImageTexture.create_from_image(
		build_meter_image(stock, config.cachelos_stock_max, config)
	)
	_fit_meter()


## 1 texel = 1 px a 1080 de alto: con cámara ortográfica `size / 1080` m por texel.
func _fit_meter() -> void:
	if _meter == null:
		return
	var camera: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null
	var size: float = DEFAULT_CAMERA_SIZE
	if camera != null and camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		size = camera.size
	_meter.pixel_size = size / REFERENCE_HEIGHT_PX


## Imagen del medidor (px a 1080 de alto). Estática y pura: la prueban los tests sin escena.
static func build_meter_image(filled: int, notches: int, config: SeasoningStationData) -> Image:
	var notch: int = config.stock_notch_px
	var gap: int = config.stock_notch_gap_px
	var width: int = notches * notch + (notches + 1) * gap
	var height: int = notch + 2 * gap
	var image: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	var plate: Color = config.stock_empty_color
	plate.a = config.stock_plate_alpha
	image.fill(plate)
	var radius: float = notch / 2.0
	for index: int in notches:
		var center: Vector2 = Vector2(gap + index * (notch + gap) + radius, height / 2.0)
		var is_filled: bool = index < filled
		for y: int in height:
			for x: int in width:
				var distance: float = Vector2(x + 0.5, y + 0.5).distance_to(center)
				if distance > radius:
					continue
				if is_filled:
					image.set_pixel(x, y, config.stock_fill_color)
				elif distance > radius - config.stock_notch_outline_px:
					image.set_pixel(x, y, config.stock_outline_color)
	return image
