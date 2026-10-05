extends GutTest
## PUL-039 (revisión): un `Highlightable` lo pueden pedir varios detectores (uno por jugador).
## El contorno sigue mientras quede alguno apuntando y se apaga cuando se va el último.

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const INTERACTABLE_LAYER: int = 1 << 2
const SETTLE_FRAMES: int = 3

var _level: Node3D


class Target:
	extends StaticBody3D
	## Interactuable 3D mínimo con malla y `Highlightable`.

	var highlight: Highlightable

	func _init() -> void:
		collision_layer = INTERACTABLE_LAYER
		collision_mask = 0
		add_to_group(&"interactable")
		var shape: CollisionShape3D = CollisionShape3D.new()
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(0.3, 0.3, 0.3)
		shape.shape = box
		add_child(shape)
		var mesh: MeshInstance3D = MeshInstance3D.new()
		mesh.mesh = BoxMesh.new()
		add_child(mesh)
		highlight = Highlightable.new()
		add_child(highlight)

	func can_interact(_actor: InteractionComponent) -> bool:
		return true

	func interact(_actor: InteractionComponent) -> bool:
		return true


func before_each() -> void:
	_level = add_child_autofree(Node3D.new())


func _add_player(pos: Vector3) -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	_level.add_child(player)
	player.global_position = pos
	return player


func _detector(player: Player) -> InteractionDetector:
	return player.get_node("%InteractionDetector") as InteractionDetector


## Gira al jugador de espaldas al objetivo (mira hacia +z).
func _turn_away(player: Player) -> void:
	player.rotation.y = PI


func test_acquire_release_counts_owners() -> void:
	var target: Target = Target.new()
	_level.add_child(target)
	var first: Node = autofree(Node.new())
	var second: Node = autofree(Node.new())
	target.highlight.acquire(first)
	target.highlight.acquire(second)
	target.highlight.acquire(first)
	assert_true(target.highlight.is_highlighted())
	target.highlight.release(first)
	assert_true(target.highlight.is_highlighted(), "queda el segundo")
	target.highlight.release(first)
	assert_true(target.highlight.is_highlighted(), "soltar dos veces no cuenta doble")
	target.highlight.release(second)
	assert_false(target.highlight.is_highlighted(), "sin propietarios, apagado")
	var mesh: MeshInstance3D = target.get_child(1) as MeshInstance3D
	assert_null(mesh.material_overlay)


func test_two_detectors_on_same_target_keep_outline_until_both_leave() -> void:
	var target: Target = Target.new()
	_level.add_child(target)
	target.global_position = Vector3(0.0, 0.5, -1.2)
	var p1: Player = _add_player(Vector3.ZERO)
	var p2: Player = _add_player(Vector3(0.6, 0.0, 0.0))
	await wait_physics_frames(SETTLE_FRAMES)
	assert_eq(_detector(p1).get_target(), target)
	assert_eq(_detector(p2).get_target(), target)
	assert_true(target.highlight.is_highlighted())

	_turn_away(p1)
	await wait_physics_frames(SETTLE_FRAMES)
	assert_null(_detector(p1).get_target(), "el primero ya no apunta")
	assert_eq(_detector(p2).get_target(), target, "el segundo sigue apuntando")
	assert_true(target.highlight.is_highlighted(), "el contorno sigue con el segundo")

	_turn_away(p2)
	await wait_physics_frames(SETTLE_FRAMES)
	assert_null(_detector(p2).get_target())
	assert_false(target.highlight.is_highlighted(), "se va el último: se apaga")


func test_freed_detector_releases_its_outline() -> void:
	var target: Target = Target.new()
	_level.add_child(target)
	target.global_position = Vector3(0.0, 0.5, -1.2)
	var p1: Player = _add_player(Vector3.ZERO)
	await wait_physics_frames(SETTLE_FRAMES)
	assert_true(target.highlight.is_highlighted())
	p1.free()
	await wait_physics_frames(1)
	assert_false(target.highlight.is_highlighted(), "un jugador liberado no deja el contorno")
