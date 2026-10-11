class_name SeasoningDispenser
extends StaticBody3D
## Dispensador fijo de un aliño completo en la estación al paso (D25, D26; ADR-003 §10.2 y §11.2;
## scene-tree.md §3). Con una caja en la mano y desde el lado de condimentar aplica su aliño en esa
## caja (`Box.apply_seasoning`): llena sin aliño lo añade, con el otro aliño lo sustituye
## (`hint.replaces`). La caja no se suelta. Con la mano vacía o con cualquier otra cosa no es
## objetivo. Una sola regla (`_resolve` → `ActionRules.for_dispenser`) decide el hint y la
## pulsación: `BLOCKED` (caja a medias, o ya lleva el aliño) emite `rejected` sin cambiar nada y
## consume. Ninguna estación suena un cue de error: lo hace el jugador. Sin antirrebote: aplicar es
## idempotente.

## Pulsación consumida sin cambios (signals.md §4): `BOX_NOT_FULL` o `ALREADY_APPLIED`.
signal rejected(reason: SeasoningRules.Rejection)

## Placa del icono propio sobre el frontal (D26.7); `PLATE` es `icon_mark_plate.svg`.
const PLATE: Texture2D = preload("res://assets/textures/ui/actions/icon_mark_plate.svg")
const SIGN_MATERIAL: StringName = &"seasoning_signs"
const PLATE_COLOR: Color = Color("F2EBDD")
const ICON_COLOR: Color = Color("1B1B1F")
const ICON_RATIO: float = 0.72

@export var seasoning: SeasoningData
@export var station: SeasoningStation

## Gesto visual de sal gorda, aceite y pimentón (>= 0,3 s); `%Gesture` es el pimentón y sus hijos
## `Salt` y `Oil` la sal gorda y el aceite. Opcional en escenas de prueba.
@onready var _gesture: GPUParticles3D = get_node_or_null(^"%Gesture") as GPUParticles3D


func _ready() -> void:
	_tint_paprika()
	_show_own_icon()


## Solo desde el lado de condimentar (o los dos con `operator_side_only` = false). ADR-003 §8.1.
## Qué hace la mano lo decide `get_action_hint`: aquí solo se filtra el lado (§11.2).
func is_reachable_from(floor_position: Vector2, _holder: Holder) -> bool:
	if station == null:
		return false
	if not station.data.operator_side_only:
		return true
	return station.side_of(floor_position) == StationSide.Side.OPERATOR


func get_action_hint(actor: InteractionComponent) -> ActionHint:
	if actor == null or actor.holder == null or seasoning == null:
		return ActionHint.none()
	return _resolve(actor.holder)


func can_interact(actor: InteractionComponent) -> bool:
	return get_action_hint(actor).is_target()


func interact(actor: InteractionComponent) -> bool:
	if actor == null or actor.holder == null or seasoning == null:
		return false
	var hint: ActionHint = _resolve(actor.holder)
	match hint.state:
		ActionHint.State.OK:
			var box: Box = actor.holder.get_held_item() as Box
			var result: SeasoningRules.Rejection = box.apply_seasoning(seasoning)
			if result == SeasoningRules.Rejection.NONE:
				_play_gesture()
			else:
				rejected.emit(result)
			return true
		ActionHint.State.BLOCKED:
			rejected.emit(_rejection_of(hint.reason))
			return true
	return false


## Única resolución de la mano contra el dispensador (ADR-003 §11.2).
func _resolve(holder: Holder) -> ActionHint:
	var item: Node = holder.get_held_item()
	var box: Box = item as Box
	var has_it: bool = box != null and box.has_seasoning(seasoning)
	var has_other: bool = (
		box != null and not has_it and box.has_seasoning_in_group(seasoning.exclusivity_group)
	)
	return ActionRules.for_dispenser(HeldKind.of(item), seasoning.verb, has_it, has_other)


## `rejected` local de cada motivo del hint (ADR-003 §11.7).
static func _rejection_of(reason: StringName) -> SeasoningRules.Rejection:
	if reason == ActionReason.ALREADY_APPLIED:
		return SeasoningRules.Rejection.ALREADY_APPLIED
	return SeasoningRules.Rejection.BOX_NOT_FULL


## Lanza el `%Gesture` (y sal y aceite) desde el principio.
func _play_gesture() -> void:
	if _gesture == null:
		return
	_gesture.restart()
	for child: Node in _gesture.get_children():
		var particles: GPUParticles3D = child as GPUParticles3D
		if particles != null:
			particles.restart()


## El pimentón del gesto sale del color del aliño (dulce rojo, picante oscuro).
func _tint_paprika() -> void:
	if _gesture == null or seasoning == null:
		return
	var mesh: SphereMesh = _gesture.draw_pass_1 as SphereMesh
	if mesh == null or not mesh.material is StandardMaterial3D:
		return
	var paint: StandardMaterial3D = (mesh.material as StandardMaterial3D).duplicate()
	paint.albedo_color = seasoning.color
	_gesture.material_override = paint


## El modelo trae el mismo cartel (guindilla) en los dos dispensadores: se tapa y se coloca en su
## sitio una placa con `seasoning.icon` (pimentonera o guindilla), la del ticket y la pegatina.
func _show_own_icon() -> void:
	if seasoning == null or seasoning.icon == null:
		return
	for mesh: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		if not mesh.visible or mesh.mesh == null:
			continue
		for surface: int in mesh.mesh.get_surface_count():
			var material: Material = mesh.get_active_material(surface)
			if material == null or material.resource_name != SIGN_MATERIAL:
				continue
			_cover_sign(mesh, surface)
			return


func _cover_sign(mesh: MeshInstance3D, surface: int) -> void:
	var arrays: Array = mesh.mesh.surface_get_arrays(surface)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	if vertices.is_empty():
		return
	var bounds: AABB = AABB(vertices[0], Vector3.ZERO)
	var normal: Vector3 = Vector3.ZERO
	for index: int in vertices.size():
		bounds = bounds.expand(vertices[index])
		if index < normals.size():
			normal += normals[index]
	var hidden: StandardMaterial3D = StandardMaterial3D.new()
	hidden.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hidden.albedo_color = Color(1.0, 1.0, 1.0, 0.0)
	mesh.set_surface_override_material(surface, hidden)
	var side: float = maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	var plate: Sprite3D = _make_sprite(PLATE, side / PLATE.get_width(), 30)
	plate.modulate = PLATE_COLOR
	var icon: Sprite3D = _make_sprite(
		seasoning.icon, side * ICON_RATIO / maxf(seasoning.icon.get_width(), 1.0), 31
	)
	icon.modulate = ICON_COLOR
	plate.name = "FrontPlate"
	icon.name = "FrontIcon"
	mesh.add_child(plate)
	plate.add_child(icon)
	plate.position = bounds.get_center() + normal.normalized() * 0.01
	plate.basis = Basis.looking_at(-normal.normalized()) if normal.length() > 0.001 else Basis()


func _make_sprite(texture: Texture2D, pixel_size: float, priority: int) -> Sprite3D:
	var sprite: Sprite3D = Sprite3D.new()
	sprite.texture = texture
	sprite.pixel_size = pixel_size
	sprite.shaded = false
	sprite.double_sided = true
	sprite.render_priority = priority
	return sprite
