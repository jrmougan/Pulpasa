extends Node
## Alcance al norte de PUL-136: el activo camina al norte 2,5 s (acción `p1_move_up`, como el stick)
## desde varias x de la fila de ollas y se anota la z mínima. Uso como `probe_boot.gd` con
## `--reach` (ver `probe_boot.gd`). Escribe `reach.json`.

const LEVEL: PackedScene = preload("res://scenes/levels/level_01.tscn")
const XS: Array[float] = [-6.0, -4.5, -3.0, -2.2, -1.3, -0.3, 0.7, 1.6, 2.6, 4.0, 5.5, 7.0, 8.5]

var _out: String = "."


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	_run.call_deferred()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _run() -> void:
	await _wait(0.3)
	var level: Node3D = LEVEL.instantiate()
	get_tree().root.add_child(level)
	await _wait(0.5)
	var p1: Node3D = level.get_node(^"Characters/Player1") as Node3D
	var out: Dictionary = {}
	for x: float in XS:
		p1.global_position = Vector3(x, 0.005, -2.6)
		await _wait(0.2)
		Input.action_press(&"p1_move_up")
		await _wait(2.5)
		Input.action_release(&"p1_move_up")
		await _wait(0.2)
		out[str(x)] = [snappedf(p1.global_position.x, 0.01), snappedf(p1.global_position.z, 0.01)]
	var file: FileAccess = FileAccess.open(_out + "/reach.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(out, "\t"))
	file.close()
	print("ALCANCE ", out)
	get_tree().quit()
