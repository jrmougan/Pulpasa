extends Node
## PUL-090: mapa de objetivos del detector real a lo largo de la barra de `level_01.tscn`.
## Coloca a Player1 en una rejilla delante de la barra (los dos lados), mirando a la barra, con la
## mano vacía, con una caja llena o con pulpo cocido, y anota qué objetivo elige el detector. La
## bandeja tiene una caja llena. Así se ve qué parte del mostrador «gana» desde cada punto.
##
## Uso (desde la raíz del repo):
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path godot \
##     -s "$PWD/docs/evidence/PUL-090/run_target_map.gd"
## Escribe `docs/evidence/PUL-090/target_map.txt`.

const LEVEL: PackedScene = preload("res://scenes/levels/level_01.tscn")
const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const SMALL_BOX: BoxData = preload("res://data/boxes/small.tres")
const X_MIN: float = -6.0
const X_MAX: float = 8.0
const X_STEP: float = 0.25
## Distancias al eje de la barra (z = 0) a las que se muestrea, por lado.
const DEPTHS: Array[float] = [0.85, 1.0, 1.3]
const DISPENSER_CODES: Dictionary[String, String] = {
	"paprika.tres": "d", "hot_paprika.tres": "p", "salt.tres": "s", "oil.tres": "a"
}

var _level: Node
var _lines: PackedStringArray = []


func _ready() -> void:
	_main.call_deferred()


func _main() -> void:
	for bus: int in AudioServer.bus_count:
		AudioServer.set_bus_mute(bus, true)
	_level = LEVEL.instantiate()
	(_level.get_node("CharacterSwitcher") as CharacterSwitcher).set_mode(GameMode.Mode.SINGLE)
	get_tree().root.add_child(_level)
	await _frames(2)
	var other: Player = _level.get_node("Characters/Player2")
	other.global_position = Vector3(7.5, 0.005, -3.0)
	var station: SeasoningStation = _level.get_node("Stations/SeasoningStation")
	var tray_box: Box = _full_box()
	_level.get_node("Items").add_child(tray_box)
	var dummy: Player = _level.get_node("Characters/Player1")
	var hold: Holder = dummy.get_node("%HoldComponent")
	assert(hold.pick_up(tray_box))
	assert(station.get_tray().interact(dummy.get_node("%InteractionComponent")))
	_lines.append("PUL-090 · mapa de objetivos del detector (level_01, planta B)")
	_lines.append(
		(
			"x de %.2f a %.2f cada %.2f m; un carácter por punto. Mira a la barra."
			% [X_MIN, X_MAX, X_STEP]
		)
	)
	_lines.append(_legend())
	_lines.append(_ruler())
	for hand: String in ["vacía", "caja llena", "pulpo cocido"]:
		_lines.append("")
		_lines.append("== Mano: %s" % hand)
		for side: float in [-1.0, 1.0]:
			for depth: float in DEPTHS:
				var row: String = ""
				for i: int in int((X_MAX - X_MIN) / X_STEP) + 1:
					var x: float = X_MIN + i * X_STEP
					row += await _sample(dummy, hand, Vector2(x, side * depth), side)
				var label: String = "cocina " if side < 0.0 else "servic."
				_lines.append("%s z=%+.2f  %s" % [label, side * depth, row])
	var path: String = ProjectSettings.globalize_path("res://").path_join(
		"../docs/evidence/PUL-090/target_map.txt"
	)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("\n".join(_lines) + "\n")
	file.close()
	print("\n".join(_lines))
	get_tree().quit(0)


func _full_box() -> Box:
	var box: Box = BOX_SCENE.instantiate()
	box.data = SMALL_BOX
	box.fill = 1.0
	return box


## Pone a `dummy` en `point` con `hand` en la mano, mirando a la barra, y devuelve el código del
## objetivo.
func _sample(dummy: Player, hand: String, point: Vector2, side: float) -> String:
	var hold: Holder = dummy.get_node("%HoldComponent")
	var held: Node = hold.get_held_item()
	if held != null:
		hold.drop()
		held.free()
	match hand:
		"caja llena":
			var box: Box = _full_box()
			_level.get_node("Items").add_child(box)
			hold.pick_up(box)
		"pulpo cocido":
			var octopus: Ingredient = OCTOPUS_SCENE.instantiate()
			_level.get_node("Items").add_child(octopus)
			octopus.set_cooked()
			hold.pick_up(octopus)
	dummy.global_position = Vector3(point.x, 0.005, point.y)
	# Kitchen side (z < 0) mira a +z (yaw PI); servicio mira a −z (yaw 0).
	dummy.rotation.y = PI if side < 0.0 else 0.0
	dummy.velocity = Vector3.ZERO
	await _frames(3)
	var detector: InteractionDetector = dummy.get_node("%InteractionDetector")
	return _code(detector.get_target())


func _code(target: Node) -> String:
	var code: String = "?"
	if target == null:
		code = "."
	elif target is Box:
		code = "T"
	elif target is SeasoningDispenser:
		var file: String = (target as SeasoningDispenser).seasoning.resource_path.get_file()
		code = DISPENSER_CODES.get(file, "?")
	elif target is CachelosBowl:
		code = "c"
	elif target is Slot:
		var station: SeasoningStation = _level.get_node("Stations/SeasoningStation")
		code = "t" if target == station.get_tray() else "_"
	elif target is OrderStand:
		code = "E"
	elif target is CookingStation:
		code = "O"
	return code


func _legend() -> String:
	return (
		"Leyenda: T caja de la bandeja · t bandeja vacía · d dulce · p picante · s sal · a aceite"
		+ " · c cuenco · _ pasaplatos · O olla · E puesto · ? otro · . nada"
	)


func _ruler() -> String:
	var row: String = ""
	for i: int in int((X_MAX - X_MIN) / X_STEP) + 1:
		var x: float = X_MIN + i * X_STEP
		row += "|" if is_equal_approx(fposmod(x, 1.0), 0.0) else " "
	return "x:               %s   (| = x entero, de %d a %d)" % [row, int(X_MIN), int(X_MAX)]


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().physics_frame
