extends GutTest
## PUL-015 AC1: el detector del jugador elige el objetivo que dicta `InteractionScoring`, lo
## resalta y, al girar, cambia el resaltado sin dejar dos objetos resaltados.

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const SLOT_SCENE: PackedScene = preload("res://entities/stations/slot.tscn")
const INTERACTABLE_LAYER: int = 1 << 2
const SETTLE_FRAMES: int = 3
## Donde nacen los objetos antes de cogerlos: sin solapar la cápsula del jugador.
const AWAY: Vector3 = Vector3(5.0, 0.5, 5.0)

var _level: Node3D
var _player: Player
var _detector: InteractionDetector
var _hold: HoldComponent


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


class Item:
	extends RigidBody3D
	## Objeto cogible e interactuable (como la caja o el pulpo).

	var is_held: bool = false

	func _init() -> void:
		collision_layer = INTERACTABLE_LAYER
		add_to_group(&"interactable")
		add_to_group(&"pickable")
		var shape: CollisionShape3D = CollisionShape3D.new()
		shape.shape = BoxShape3D.new()
		add_child(shape)
		add_child(Highlightable.new())

	func can_interact(actor: InteractionComponent) -> bool:
		return not is_held and actor.holder.can_hold(self)

	func interact(actor: InteractionComponent) -> bool:
		return Slot.pick_up_item(actor, self)

	func on_picked_up(_holder: Holder) -> void:
		is_held = true

	func on_dropped() -> void:
		is_held = false


func before_each() -> void:
	_level = add_child_autofree(Node3D.new())
	_player = PLAYER_SCENE.instantiate()
	_level.add_child(_player)
	_detector = _player.get_node("%InteractionDetector")
	_hold = _player.get_node("%HoldComponent")
	_hold.items_root = _level


func _add_target(pos: Vector3) -> Target:
	var target: Target = Target.new()
	_level.add_child(target)
	target.global_position = pos
	return target


func _settle() -> void:
	await wait_physics_frames(SETTLE_FRAMES)


func _highlighted(nodes: Array[Node]) -> int:
	var count: int = 0
	for node: Node in nodes:
		for child: Node in node.get_children():
			if child is Highlightable and (child as Highlightable).is_highlighted():
				count += 1
	return count


func test_ac1_one_detector_per_player_wired_to_interaction_component() -> void:
	var detectors: Array[Node] = _player.find_children("*", "InteractionDetector", true, false)
	assert_eq(detectors.size(), 1, "B7: un solo detector")
	var component: InteractionComponent = _player.get_node("%InteractionComponent")
	assert_eq(component.detector, _detector)
	assert_eq(component.holder, _hold)
	assert_eq(component.control, _player.get_node("%Control"))


func test_ac1_detector_masks_interactable_with_config_radius() -> void:
	assert_eq(_detector.collision_mask, INTERACTABLE_LAYER)
	assert_eq(_detector.collision_layer, 0)
	var shape: CollisionShape3D = _detector.get_child(0) as CollisionShape3D
	var sphere: SphereShape3D = shape.shape as SphereShape3D
	assert_almost_eq(sphere.radius, _player.config.detector_radius, 0.001)


func test_ac1_selects_target_dictated_by_scoring() -> void:
	var front: Target = _add_target(Vector3(0.3, 0.5, -1.2))
	var side: Target = _add_target(Vector3(1.4, 0.5, -0.4))
	var back: Target = _add_target(Vector3(0.0, 0.5, 1.0))
	await _settle()
	var cfg: PlayerConfig = _player.config
	var origin: Vector3 = _player.global_position + Vector3.UP * cfg.detector_origin_height
	var candidates: Array[InteractionScoring.Candidate] = []
	for target: Target in [front, side, back]:
		var pos: Vector3 = target.global_position
		candidates.append(
			InteractionScoring.Candidate.new(Vector2(pos.x, pos.z), pos.distance_to(origin))
		)
	var expected: int = InteractionScoring.pick_best(
		Vector2.ZERO,
		Vector2(0.0, -1.0),
		candidates,
		false,
		cfg.detector_cone_half_angle,
		cfg.detector_near_distance,
		cfg.detector_kitchen_bonus
	)
	assert_eq(expected, 0, "el de delante gana en InteractionScoring")
	assert_eq(_detector.get_target(), front)


func test_ac1_target_is_highlighted() -> void:
	var front: Target = _add_target(Vector3(0.0, 0.5, -1.0))
	var back: Target = _add_target(Vector3(0.0, 0.5, 1.0))
	await _settle()
	assert_true(front.highlight.is_highlighted())
	assert_false(back.highlight.is_highlighted())
	var mesh: MeshInstance3D = front.get_child(1) as MeshInstance3D
	assert_not_null(mesh.material_overlay, "contorno en material_overlay")


func test_ac1_turning_switches_highlight_without_two_highlighted() -> void:
	var front: Target = _add_target(Vector3(0.0, 0.5, -1.0))
	var back: Target = _add_target(Vector3(0.0, 0.5, 1.0))
	await _settle()
	watch_signals(_detector)
	_player.rotation.y = PI
	await _settle()
	assert_eq(_detector.get_target(), back)
	assert_true(back.highlight.is_highlighted())
	assert_false(front.highlight.is_highlighted())
	assert_null((front.get_child(1) as MeshInstance3D).material_overlay)
	assert_eq(_highlighted([front, back]), 1)
	assert_signal_emit_count(_detector, "target_changed", 1)
	assert_signal_emitted_with_parameters(_detector, "target_changed", [front, back])


func test_ac1_no_target_clears_highlight_and_emits_null() -> void:
	var front: Target = _add_target(Vector3(0.0, 0.5, -1.0))
	await _settle()
	watch_signals(_detector)
	front.global_position = Vector3(0.0, 0.5, 10.0)
	await _settle()
	assert_null(_detector.get_target())
	assert_false(front.highlight.is_highlighted())
	assert_signal_emitted_with_parameters(_detector, "target_changed", [front, null])


func test_ac1_target_changed_not_emitted_every_frame() -> void:
	_add_target(Vector3(0.0, 0.5, -1.0))
	await _settle()
	watch_signals(_detector)
	await _settle()
	assert_signal_emit_count(_detector, "target_changed", 0)


## PUL-016 (InteractionDetector.cs:57): el slot ocupado se sustituye por su objeto.
func test_ac1_occupied_slot_resolves_to_its_item_and_highlights_it() -> void:
	var slot: Slot = SLOT_SCENE.instantiate()
	# Colocado antes de entrar al árbol: nunca existe en el origen, dentro del jugador.
	slot.position = Vector3(0.0, 0.0, -1.0)
	_level.add_child(slot)
	var item: Item = Item.new()
	_level.add_child(item)
	item.global_position = AWAY
	_hold.pick_up(item)
	slot.interact(_player.get_node("%InteractionComponent"))
	await _settle()
	assert_eq(_detector.get_target(), item, "con la mano vacía, el objeto (para cogerlo)")
	var item_highlight: Highlightable = item.get_child(1) as Highlightable
	assert_true(item_highlight.is_highlighted(), "se resalta el objeto guardado")


## Paridad Unity (InteractionDetector.cs:57/:80): con la mano llena el objeto guardado sigue
## compitiendo aunque no acepte lo que se lleva; el rechazo es suyo (`can_interact`/`interact`).
func test_ac1_occupied_slot_resolves_to_its_item_with_full_hand() -> void:
	var slot: Slot = SLOT_SCENE.instantiate()
	# Colocado antes de entrar al árbol: nunca existe en el origen, dentro del jugador.
	slot.position = Vector3(0.0, 0.0, -1.0)
	_level.add_child(slot)
	var stored: Item = Item.new()
	_level.add_child(stored)
	stored.global_position = AWAY
	_hold.pick_up(stored)
	slot.interact(_player.get_node("%InteractionComponent"))
	var carried: Item = Item.new()
	_level.add_child(carried)
	carried.global_position = AWAY
	_hold.pick_up(carried)
	await _settle()
	assert_eq(_detector.get_target(), stored)


func test_ac1_taking_item_from_slot_moves_highlight_off_the_item() -> void:
	var slot: Slot = SLOT_SCENE.instantiate()
	# Colocado antes de entrar al árbol: nunca existe en el origen, dentro del jugador.
	slot.position = Vector3(0.0, 0.0, -1.0)
	_level.add_child(slot)
	var item: Item = Item.new()
	_level.add_child(item)
	item.global_position = AWAY
	_hold.pick_up(item)
	var actor: InteractionComponent = _player.get_node("%InteractionComponent")
	slot.interact(actor)
	await _settle()
	slot.interact(actor)
	await _settle()
	assert_eq(_hold.get_held_item(), item)
	assert_false((item.get_child(1) as Highlightable).is_highlighted())
	assert_eq(_detector.get_target(), slot, "slot vacío y mano llena: se puede dejar")


## Revisión: liberar el objetivo publica la transición, sin objetos liberados
## ni resaltados colgados.
func test_ac1_freeing_only_target_emits_null_once() -> void:
	var front: Target = _add_target(Vector3(0.0, 0.5, -1.0))
	await _settle()
	watch_signals(_detector)
	front.free()
	await _settle()
	assert_null(_detector.get_target())
	assert_signal_emit_count(_detector, "target_changed", 1)
	assert_signal_emitted_with_parameters(_detector, "target_changed", [null, null])


func test_ac1_queue_freeing_only_target_emits_null_once() -> void:
	var front: Target = _add_target(Vector3(0.0, 0.5, -1.0))
	await _settle()
	watch_signals(_detector)
	front.queue_free()
	await _settle()
	assert_null(_detector.get_target())
	assert_signal_emit_count(_detector, "target_changed", 1)
	assert_signal_emitted_with_parameters(_detector, "target_changed", [null, null])


func test_ac1_freeing_target_switches_to_substitute() -> void:
	var front: Target = _add_target(Vector3(0.0, 0.5, -1.0))
	var other: Target = _add_target(Vector3(0.0, 0.5, -1.8))
	await _settle()
	assert_eq(_detector.get_target(), front)
	watch_signals(_detector)
	front.free()
	await _settle()
	assert_eq(_detector.get_target(), other)
	assert_true(other.highlight.is_highlighted())
	assert_signal_emit_count(_detector, "target_changed", 1)
	assert_signal_emitted_with_parameters(_detector, "target_changed", [null, other])


func test_ac1_queue_freeing_target_switches_to_substitute() -> void:
	var front: Target = _add_target(Vector3(0.0, 0.5, -1.0))
	var other: Target = _add_target(Vector3(0.0, 0.5, -1.8))
	await _settle()
	watch_signals(_detector)
	front.queue_free()
	await _settle()
	assert_eq(_detector.get_target(), other)
	assert_true(other.highlight.is_highlighted())
	assert_eq(_highlighted([other]), 1)
	assert_signal_emit_count(_detector, "target_changed", 1)
	assert_signal_emitted_with_parameters(_detector, "target_changed", [null, other])


## Revisión: la distancia es 3D desde el jugador + 0,8 m, no la del suelo.
func test_ac1_origin_height_changes_choice_against_flat_distance() -> void:
	# En el suelo, `low` está más cerca (0,5 m frente a 0,6 m); en 3D desde 0,8 m, `high` gana.
	var low: Target = _add_target(Vector3(0.0, 0.0, -0.5))
	var high: Target = _add_target(Vector3(0.0, 0.8, -0.6))
	await _settle()
	assert_eq(_detector.get_target(), high)
	assert_false(low.highlight.is_highlighted())


## Revisión: por debajo de 0,7 m (3D) se ignora el cono.
func test_ac1_near_exception_allows_target_outside_cone() -> void:
	var side: Target = _add_target(Vector3(0.5, 0.8, 0.0))
	await _settle()
	assert_eq(_detector.get_target(), side, "a 0,5 m en 3D, fuera del cono")


func test_ac1_near_exception_uses_3d_distance_not_flat() -> void:
	# A 0,5 m en el suelo pero ~0,94 m desde la altura de mira: fuera del cono y no cercano.
	_add_target(Vector3(0.5, 0.0, 0.0))
	await _settle()
	assert_null(_detector.get_target())


## Revisión: el bonus del grupo `kitchen` cambia el ganador solo con la mano vacía.
func _kitchen_setup() -> Array[Target]:
	var kitchen: Target = _add_target(Vector3(0.0, 0.8, -1.5))
	kitchen.add_to_group(InteractionDetector.KITCHEN_GROUP)
	var near: Target = _add_target(Vector3(0.1, 0.8, -1.0))
	return [kitchen, near]


func test_ac1_kitchen_bonus_wins_with_empty_hand() -> void:
	var targets: Array[Target] = _kitchen_setup()
	await _settle()
	assert_eq(_detector.get_target(), targets[0])


func test_ac1_kitchen_bonus_ignored_with_full_hand() -> void:
	var targets: Array[Target] = _kitchen_setup()
	var carried: Item = Item.new()
	_level.add_child(carried)
	carried.global_position = AWAY
	assert_true(_hold.pick_up(carried))
	await _settle()
	assert_eq(_detector.get_target(), targets[1])
