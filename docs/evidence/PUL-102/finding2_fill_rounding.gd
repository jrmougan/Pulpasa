extends SceneTree
## PUL-102, hallazgo 2: `fill_per_press` de la caja M es 0.16666667. Si el redondeo fuera a la baja,
## dos cajas no vaciarían el pulpo (`Ingredient.take` compara `remaining <= 0.0` sin épsilon) y
## quedaría un resto que nunca se libera. Este script lo comprueba con la `Box` y el `Ingredient`
## reales (escenas de `entities/items/`), sin tocar código del juego:
##   - los `.tres` reales S / M / L;
##   - variantes de M con el valor redondeado a la baja y a la alta a distinta precisión.
## Uso: godot --headless --audio-driver Dummy --path godot
##   -s "$PWD/docs/evidence/PUL-102/finding2_fill_rounding.gd"

const BOX_SCENE: PackedScene = preload("res://entities/items/box.tscn")
const OCTOPUS_SCENE: PackedScene = preload("res://entities/items/octopus.tscn")
const DATA: Array[BoxData] = [
	preload("res://data/boxes/small.tres"),
	preload("res://data/boxes/medium.tres"),
	preload("res://data/boxes/large.tres"),
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for data: BoxData in DATA:
		_case(
			"real %s (%s)" % [data.short_label, String.num(data.fill_per_press, 10)],
			data.fill_per_press,
			data
		)
	var medium: BoxData = DATA[1]
	for value: float in [
		0.1666667, 0.16666667, 0.166666667, 0.16666666, 0.1666666, 0.166666, 0.1666, 0.17, 0.16
	]:
		_case("variante M (%s)" % String.num(value, 10), value, medium)
	quit(0)


## Dos cajas seguidas con un mismo pulpo cocido de 100 unidades (R9: 50 por caja).
func _case(label: String, fill: float, template: BoxData) -> void:
	var octopus: Ingredient = OCTOPUS_SCENE.instantiate() as Ingredient
	root.add_child(octopus)
	octopus.set_cooked()
	var presses: Array[int] = []
	var fills: Array[float] = []
	for _n: int in 2:
		var data: BoxData = template.duplicate() as BoxData
		data.fill_per_press = fill
		var box: Box = BOX_SCENE.instantiate() as Box
		box.data = data
		root.add_child(box)
		var count: int = 0
		while not box.is_full() and count < 40 and _alive(octopus):
			box.call("_cut", octopus)
			count += 1
		presses.append(count)
		fills.append(snappedf(box.fill, 0.000001))
		box.free()
	var freed: bool = not _alive(octopus)
	var left: float = octopus.remaining if is_instance_valid(octopus) else -1.0
	print(
		(
			"%-30s cortes %s | fill de cada caja %s | pulpo liberado: %s | resto %.9f"
			% [label, presses, fills, str(freed), left]
		)
	)
	if is_instance_valid(octopus):
		octopus.free()


## Vivo de verdad: `queue_free` no invalida la instancia hasta el final del frame.
func _alive(octopus: Ingredient) -> bool:
	return is_instance_valid(octopus) and not octopus.is_queued_for_deletion()
