# gdlint: disable=max-public-methods
extends GutTest
## PUL-015 AC1: el detector del jugador elige el objetivo que dicta `InteractionScoring`, lo
## resalta y, al girar, cambia el resaltado sin dejar dos objetos resaltados.
## PUL-121 AC4 (D26): solo son objetivo las entidades con hint, con histéresis, sin control no hay
## objetivo, y con la mano llena sin candidatos se publica SOLTAR / ocupado.

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


class BoxLikeItem:
	extends Item
	## Como la caja: con la mano llena su consulta sigue en `true` (consume la pulsación).

	func can_interact(actor: InteractionComponent) -> bool:
		return not is_held and (actor.holder.get_held_item() != null or actor.holder.can_hold(self))


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
## compitiendo si su consulta lo admite (la caja, hasta migrar a `get_action_hint`, D26).
func test_ac1_occupied_slot_resolves_to_its_item_with_full_hand() -> void:
	var slot: Slot = SLOT_SCENE.instantiate()
	# Colocado antes de entrar al árbol: nunca existe en el origen, dentro del jugador.
	slot.position = Vector3(0.0, 0.0, -1.0)
	_level.add_child(slot)
	var stored: Item = BoxLikeItem.new()
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


## PUL-063: con la mano vacía, un objeto guardado en un slot no tiene prioridad de cogible:
## un interactuable mejor apuntado le gana. Uno suelto en el mismo sitio sí la conserva.
func test_pul063_stored_item_loses_to_better_aimed_interactable_with_empty_hand() -> void:
	var slot: Slot = SLOT_SCENE.instantiate()
	slot.position = Vector3(0.6, 0.0, -1.5)
	_level.add_child(slot)
	var stored: Item = Item.new()
	_level.add_child(stored)
	stored.global_position = AWAY
	_hold.pick_up(stored)
	slot.interact(_player.get_node("%InteractionComponent"))
	var front: Target = _add_target(Vector3(0.0, 0.8, -1.0))
	await _settle()
	assert_eq(_detector.get_target(), front, "gana lo que está delante")
	assert_false((stored.get_child(1) as Highlightable).is_highlighted())


func test_pul063_loose_item_keeps_priority_over_better_aimed_interactable() -> void:
	var loose: Item = Item.new()
	_level.add_child(loose)
	loose.global_position = Vector3(0.6, 1.0, -1.5)
	loose.freeze = true
	var front: Target = _add_target(Vector3(0.0, 0.8, -1.0))
	await _settle()
	assert_eq(_detector.get_target(), loose, "el cogible suelto conserva la prioridad")
	assert_false(front.highlight.is_highlighted())


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


class SidedTarget:
	extends Target
	## Interactuable con `is_reachable_from` (ADR-003 §8.1): solo desde z > 0.

	var asked_holder: Holder

	func is_reachable_from(floor_position: Vector2, holder: Holder) -> bool:
		asked_holder = holder
		return floor_position.y > 0.0


## PUL-058 (ADR-003 §8.1): una entidad que no es alcanzable desde la posición del portador no es
## candidata: ni objetivo ni resaltado; desde el otro lado sí.
func test_pul058_unreachable_entity_is_neither_target_nor_highlighted() -> void:
	var sided: SidedTarget = SidedTarget.new()
	_level.add_child(sided)
	sided.global_position = Vector3(0.0, 0.8, -1.0)
	_player.global_position = Vector3(0.0, 0.0, -0.1)
	await _settle()
	assert_null(_detector.get_target())
	assert_false(sided.highlight.is_highlighted())
	assert_eq(sided.asked_holder, _hold, "recibe la mano del detector")
	_player.global_position = Vector3(0.0, 0.0, 0.1)
	sided.global_position = Vector3(0.0, 0.8, -0.8)
	await _settle()
	assert_eq(_detector.get_target(), sided)
	assert_true(sided.highlight.is_highlighted())


## PUL-058: sin el método, todo sigue igual (alcanzable desde cualquier sitio).
func test_pul058_entity_without_method_is_reachable() -> void:
	var target: Target = _add_target(Vector3(0.0, 0.8, -1.0))
	_player.global_position = Vector3(0.0, 0.0, -0.1)
	await _settle()
	assert_eq(_detector.get_target(), target)


# --- PUL-121 AC4 (D26): filtro honesto, histéresis, sin control, suelo y hint --------------------


class HintedTarget:
	extends Target
	## Interactuable con `get_action_hint` (ADR-003 §11.2): publica el `hint` que se le ponga.

	var hint: ActionHint = ActionHint.ok(ActionVerb.PICK_UP)

	func get_action_hint(_actor: InteractionComponent) -> ActionHint:
		return hint


class LegacyTarget:
	extends Target
	## Interactuable sin `get_action_hint`: la equivalencia transitoria usa `can_interact`.

	var accepts: bool = true

	func can_interact(_actor: InteractionComponent) -> bool:
		return accepts


class WallBody:
	extends StaticBody3D
	## Cuerpo de la capa `world` (barra, pared): bloquea el punto de soltar.

	func _init() -> void:
		collision_layer = 1
		collision_mask = 0
		var shape: CollisionShape3D = CollisionShape3D.new()
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(2.0, 2.0, 0.1)
		shape.shape = box
		add_child(shape)


func _add_hinted(pos: Vector3, hint: ActionHint) -> HintedTarget:
	var target: HintedTarget = HintedTarget.new()
	target.hint = hint
	_level.add_child(target)
	target.global_position = pos
	return target


func _carry() -> Item:
	var carried: Item = Item.new()
	_level.add_child(carried)
	carried.global_position = AWAY
	assert_true(_hold.pick_up(carried))
	return carried


func test_ac4_detector_is_wired_to_its_interaction_component() -> void:
	assert_eq(_detector.actor, _player.get_node("%InteractionComponent"))


func test_ac4_none_candidate_is_neither_target_nor_highlighted() -> void:
	var none: HintedTarget = _add_hinted(Vector3(0.0, 0.8, -1.0), ActionHint.none())
	await _settle()
	assert_null(_detector.get_target())
	assert_false(none.highlight.is_highlighted())
	assert_false(_detector.get_hint().is_target())


func test_ac4_none_candidate_does_not_hide_a_worse_valid_one() -> void:
	var none: HintedTarget = _add_hinted(Vector3(0.0, 0.8, -1.0), ActionHint.none())
	var valid: HintedTarget = _add_hinted(Vector3(0.0, 0.8, -1.8), ActionHint.ok(ActionVerb.COOK))
	await _settle()
	assert_eq(_detector.get_target(), valid)
	assert_false(none.highlight.is_highlighted())
	assert_true(valid.highlight.is_highlighted())


func test_ac4_legacy_entity_follows_can_interact() -> void:
	var closed: LegacyTarget = LegacyTarget.new()
	closed.accepts = false
	_level.add_child(closed)
	closed.global_position = Vector3(0.0, 0.8, -1.0)
	var open: LegacyTarget = LegacyTarget.new()
	_level.add_child(open)
	open.global_position = Vector3(0.0, 0.8, -1.8)
	await _settle()
	assert_eq(_detector.get_target(), open, "el heredado que no puede interactuar no es candidato")
	assert_false(closed.highlight.is_highlighted())
	assert_eq(_detector.get_hint().state, ActionHint.State.OK)
	assert_eq(_detector.get_hint().verb, ActionVerb.NONE, "objetivo heredado sin verbo")


func test_ac4_blocked_candidate_is_a_target_with_amber_outline() -> void:
	var blocked: HintedTarget = _add_hinted(
		Vector3(0.0, 0.8, -1.0), ActionHint.blocked(ActionVerb.COOK, ActionReason.BUSY)
	)
	await _settle()
	assert_eq(_detector.get_target(), blocked)
	assert_true(blocked.highlight.is_highlighted())
	assert_true(blocked.highlight.is_blocked())
	var mesh: MeshInstance3D = blocked.get_child(1) as MeshInstance3D
	assert_eq(mesh.material_overlay, blocked.highlight.blocked_material)
	assert_eq(_detector.get_hint().reason, ActionReason.BUSY)
	blocked.hint = ActionHint.ok(ActionVerb.COOK)
	await _settle()
	assert_false(blocked.highlight.is_blocked(), "OK <-> BLOQUEADO no invalida al actual")
	assert_eq(_detector.get_target(), blocked)
	assert_eq(mesh.material_overlay, blocked.highlight.material)


func test_ac4_hint_changed_only_when_target_or_hint_change() -> void:
	var target: HintedTarget = _add_hinted(Vector3(0.0, 0.8, -1.0), ActionHint.ok(ActionVerb.CUT))
	watch_signals(_detector)
	await _settle()
	assert_signal_emit_count(_detector, "hint_changed", 1, "al aparecer el objetivo")
	var params: Array = get_signal_parameters(_detector, "hint_changed", 0)
	assert_eq(params[0], target)
	assert_eq((params[1] as ActionHint).verb, ActionVerb.CUT)
	await _settle()
	assert_signal_emit_count(_detector, "hint_changed", 1, "sin cambios no emite")
	target.hint = ActionHint.ok(ActionVerb.CUT, 0.5)
	await _settle()
	assert_signal_emit_count(_detector, "hint_changed", 1, "solo cambia el progreso")
	assert_almost_eq(_detector.get_hint().progress, 0.5, 0.001, "pero get_hint() lo lee")
	target.hint = ActionHint.blocked(ActionVerb.CUT, ActionReason.FULL)
	await _settle()
	assert_signal_emit_count(_detector, "hint_changed", 2, "cambia el estado")
	var replacing: ActionHint = ActionHint.blocked(ActionVerb.CUT, ActionReason.FULL)
	replacing.replaces = true
	target.hint = replacing
	await _settle()
	assert_signal_emit_count(_detector, "hint_changed", 3, "cambia replaces")


func test_ac4_hint_changed_follows_target_changed_in_the_same_refresh() -> void:
	var order: Array[String] = []
	_detector.target_changed.connect(func(_p: Node, _c: Node) -> void: order.append("target"))
	_detector.hint_changed.connect(func(_t: Node, _h: ActionHint) -> void: order.append("hint"))
	_add_hinted(Vector3(0.0, 0.8, -1.0), ActionHint.ok(ActionVerb.CUT))
	await _settle()
	assert_eq(order, ["target", "hint"] as Array[String])


func test_ac4_hint_changed_when_the_target_changes_even_with_the_same_hint() -> void:
	var first: HintedTarget = _add_hinted(Vector3(0.0, 0.8, -1.0), ActionHint.ok(ActionVerb.CUT))
	var second: HintedTarget = _add_hinted(Vector3(0.0, 0.8, 1.0), ActionHint.ok(ActionVerb.CUT))
	await _settle()
	assert_eq(_detector.get_target(), first)
	watch_signals(_detector)
	_player.rotation.y = PI
	await _settle()
	assert_eq(_detector.get_target(), second)
	assert_signal_emit_count(_detector, "hint_changed", 1)
	assert_eq(get_signal_parameters(_detector, "hint_changed", 0)[0], second)


func test_ac4_losing_the_target_publishes_none() -> void:
	var target: HintedTarget = _add_hinted(Vector3(0.0, 0.8, -1.0), ActionHint.ok(ActionVerb.CUT))
	await _settle()
	watch_signals(_detector)
	target.hint = ActionHint.none()
	await _settle()
	assert_null(_detector.get_target())
	assert_signal_emit_count(_detector, "hint_changed", 1)
	assert_null(get_signal_parameters(_detector, "hint_changed", 0)[0])
	assert_false(_detector.get_hint().is_target())


func test_ac4_without_control_there_is_no_target_nor_outline() -> void:
	var target: HintedTarget = _add_hinted(Vector3(0.0, 0.8, -1.0), ActionHint.ok(ActionVerb.CUT))
	await _settle()
	assert_true(target.highlight.is_highlighted())
	watch_signals(_detector)
	var control: ControlComponent = _player.get_node("%Control")
	control.controlled_by = 0
	await _settle()
	assert_null(_detector.get_target())
	assert_false(target.highlight.is_highlighted())
	assert_false(_detector.get_hint().is_target())
	assert_signal_emitted_with_parameters(_detector, "target_changed", [target, null])
	control.controlled_by = 1
	await _settle()
	assert_eq(_detector.get_target(), target, "al recuperar el control vuelve el objetivo")


func test_ac4_without_control_and_with_a_full_hand_there_is_no_floor_hint() -> void:
	_carry()
	(_player.get_node("%Control") as ControlComponent).controlled_by = 0
	await _settle()
	assert_false(_detector.get_hint().is_target())


func test_ac4_detector_without_actor_publishes_nothing() -> void:
	_add_target(Vector3(0.0, 0.8, -1.0))
	_detector.actor = null
	await _settle()
	assert_null(_detector.get_target())


func test_ac4_full_hand_without_candidates_publishes_the_drop_hint() -> void:
	_carry()
	watch_signals(_detector)
	await _settle()
	assert_null(_detector.get_target())
	var hint: ActionHint = _detector.get_hint()
	assert_eq(hint.verb, ActionVerb.DROP)
	assert_eq(hint.state, ActionHint.State.OK)
	assert_signal_emit_count(_detector, "hint_changed", 1)
	assert_null(get_signal_parameters(_detector, "hint_changed", 0)[0])


func test_ac4_full_hand_facing_a_wall_publishes_blocked_busy() -> void:
	# El jugador se queda quieto: una pared junto a su cápsula lo empujaría fuera de su sitio.
	_player.set_physics_process(false)
	_carry()
	var wall: WallBody = WallBody.new()
	_level.add_child(wall)
	wall.global_position = _hold.get_drop_position()
	await _settle()
	assert_false(_hold.can_drop_freely())
	var hint: ActionHint = _detector.get_hint()
	assert_eq(hint.verb, ActionVerb.DROP)
	assert_eq(hint.state, ActionHint.State.BLOCKED)
	assert_eq(hint.reason, ActionReason.BUSY)
	wall.global_position = Vector3(10.0, 0.0, 10.0)
	await _settle()
	assert_eq(_detector.get_hint().state, ActionHint.State.OK, "al apartarse la pared, SOLTAR")


func test_ac4_empty_hand_without_candidates_publishes_none() -> void:
	await _settle()
	assert_false(_detector.get_hint().is_target())
	assert_not_null(_detector.get_hint(), "nunca null")


func test_ac4_a_candidate_replaces_the_floor_hint() -> void:
	_carry()
	var target: HintedTarget = _add_hinted(Vector3(0.0, 0.8, -1.0), ActionHint.ok(ActionVerb.DROP))
	await _settle()
	assert_eq(_detector.get_target(), target)


# --- Histéresis (D26.4, lenguaje-acciones AC10) --------------------------------------------------


## Dos objetivos rectos al frente: `a` fijo a 1 m (puntuación 3,0) y `b` a la distancia que da la
## puntuación `ratio × 3,0`.
func _place_b(b: HintedTarget, ratio: float) -> void:
	b.global_position = Vector3(0.0, 0.8, -1.0 / (3.0 * ratio - 2.0))


func test_ac4_scores_oscillating_ten_percent_for_five_seconds_never_change_target() -> void:
	var a: HintedTarget = _add_hinted(Vector3(0.0, 0.8, -1.0), ActionHint.ok(ActionVerb.CUT))
	var b: HintedTarget = _add_hinted(Vector3(0.0, 0.8, -1.4), ActionHint.ok(ActionVerb.COOK))
	_place_b(b, 0.9)
	await _settle()
	assert_eq(_detector.get_target(), a)
	watch_signals(_detector)
	for frame: int in 300:
		_place_b(b, 1.0 + 0.1 * (1.0 if frame % 2 == 0 else -1.0))
		await wait_physics_frames(1)
	assert_signal_emit_count(_detector, "target_changed", 0)
	assert_eq(_detector.get_target(), a)


func test_ac4_without_hysteresis_the_same_oscillation_does_flap() -> void:
	_detector.config = _detector.config.duplicate() as PlayerConfig
	_detector.config.hysteresis_margin = 0.0
	var a: HintedTarget = _add_hinted(Vector3(0.0, 0.8, -1.0), ActionHint.ok(ActionVerb.CUT))
	var b: HintedTarget = _add_hinted(Vector3(0.0, 0.8, -1.4), ActionHint.ok(ActionVerb.COOK))
	_place_b(b, 0.9)
	await _settle()
	assert_eq(_detector.get_target(), a)
	watch_signals(_detector)
	for frame: int in 60:
		_place_b(b, 1.0 + 0.1 * (1.0 if frame % 2 == 0 else -1.0))
		await wait_physics_frames(1)
	assert_gt(get_signal_emit_count(_detector, "target_changed"), 10)


func test_ac4_approaching_the_other_target_changes_exactly_once() -> void:
	var a: HintedTarget = _add_hinted(Vector3(0.0, 0.8, -1.0), ActionHint.ok(ActionVerb.CUT))
	var b: HintedTarget = _add_hinted(Vector3(0.0, 0.8, -1.4), ActionHint.ok(ActionVerb.COOK))
	_place_b(b, 0.9)
	await _settle()
	watch_signals(_detector)
	for step: int in 61:
		_place_b(b, 0.9 + 0.6 * float(step) / 60.0)
		await wait_physics_frames(1)
	assert_signal_emit_count(_detector, "target_changed", 1)
	assert_eq(_detector.get_target(), b)
	assert_signal_emitted_with_parameters(_detector, "target_changed", [a, b])


func test_ac4_invalid_current_is_replaced_in_the_same_tick() -> void:
	var a: HintedTarget = _add_hinted(Vector3(0.0, 0.8, -1.0), ActionHint.ok(ActionVerb.CUT))
	var b: HintedTarget = _add_hinted(Vector3(0.0, 0.8, -1.4), ActionHint.ok(ActionVerb.COOK))
	_place_b(b, 0.9)
	await _settle()
	assert_eq(_detector.get_target(), a)
	a.hint = ActionHint.none()
	await wait_physics_frames(2)
	assert_eq(
		_detector.get_target(), b, "el actual deja de ser válido: cambia aunque no supere 1,2"
	)
