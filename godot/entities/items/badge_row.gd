class_name BadgeRow
extends Node3D
## Fila de pegatinas de condimento sobre la caja (D18, ADR-003 §8.4, scene-tree.md §3). 3D de
## mundo: cada pegatina es un disco `SeasoningData.color` con su icono en blanco (`Sprite3D`
## billboard sin test de profundidad); el picante lleva además `style.hot_mark`. Orden canónico
## (`SeasoningRules.canonical_order`), compactada y centrada; se rehace al oír `seasoned` /
## `seasoning_removed` de la caja. Sin condimentos, oculta.
## La fila va en `top_level`: sigue a la caja sin heredar su rotación, y se reparte a lo largo del
## eje derecho de la cámara para verse horizontal en pantalla.

## Resolución y cámara de referencia del tamaño en px (1280×720, `size` 12,74 m).
const REFERENCE_HEIGHT_PX: float = 720.0
const DEFAULT_CAMERA_SIZE: float = 12.74
## Tapa de la caja sobre su origen (m).
const LID_HEIGHT: float = 0.1665
const DISC_TEXTURE_PX: int = 64
const ICON_RATIO: float = 0.6
const HOT_MARK_RATIO: float = 0.5

static var _disc_texture: ImageTexture

@export var box: Box
@export var style: BoxBadgeStyle = preload("res://data/config/box_badges.tres")

var _shown: Array[SeasoningData] = []


func _ready() -> void:
	top_level = true
	if box == null:
		box = get_parent() as Box
	if box == null:
		return
	box.seasoned.connect(_on_changed)
	box.seasoning_removed.connect(_on_changed)
	_rebuild()
	_follow()


func _process(_delta: float) -> void:
	_follow()


## Lo que muestra la fila, en orden (para tests).
func get_shown() -> Array[SeasoningData]:
	return _shown.duplicate()


func _on_changed(_seasoning: SeasoningData) -> void:
	_rebuild()


func _follow() -> void:
	if box != null and is_instance_valid(box):
		global_position = box.global_position + Vector3.UP * (LID_HEIGHT + style.badge_height)


func _rebuild() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_shown = SeasoningRules.canonical_order(box.get_contents().seasonings)
	visible = not _shown.is_empty()
	var metres_per_px: float = _metres_per_px()
	var side: float = style.badge_icon_px * metres_per_px
	var step: float = (style.badge_icon_px + style.badge_gap_px) * metres_per_px
	var right: Vector3 = _screen_right()
	var origin: float = -step * (_shown.size() - 1) / 2.0
	for i: int in _shown.size():
		var badge: Node3D = _make_badge(_shown[i], side)
		badge.position = right * (origin + step * i)
		add_child(badge)


func _make_badge(seasoning: SeasoningData, side: float) -> Node3D:
	var badge: Node3D = Node3D.new()
	badge.name = "Badge"
	var disc: Sprite3D = _make_sprite(_get_disc_texture(), side, 10)
	disc.modulate = seasoning.color
	badge.add_child(disc)
	if seasoning.icon != null:
		var icon: Sprite3D = _make_sprite(seasoning.icon, side * ICON_RATIO, 11)
		icon.modulate = Color.WHITE
		badge.add_child(icon)
	if style.hot_mark != null and style.has_hot_mark(seasoning):
		var mark: Sprite3D = _make_sprite(style.hot_mark, side * HOT_MARK_RATIO, 12)
		mark.position = Vector3(side * 0.35, side * 0.35, 0.0)
		badge.add_child(mark)
	return badge


## Sprite que ocupa `side` metros en su lado mayor.
func _make_sprite(texture: Texture2D, side: float, priority: int) -> Sprite3D:
	var sprite: Sprite3D = Sprite3D.new()
	sprite.texture = texture
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.no_depth_test = true
	sprite.shaded = false
	sprite.render_priority = priority
	var largest: float = maxf(texture.get_width(), texture.get_height())
	sprite.pixel_size = side / maxf(largest, 1.0)
	return sprite


func _metres_per_px() -> float:
	var camera: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null
	var size: float = DEFAULT_CAMERA_SIZE
	var height_px: float = REFERENCE_HEIGHT_PX
	if camera != null and camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		size = camera.size
		height_px = get_viewport().get_visible_rect().size.y
	return size / height_px if camera != null else size / REFERENCE_HEIGHT_PX


func _screen_right() -> Vector3:
	var camera: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null
	return camera.global_basis.x if camera != null else Vector3.RIGHT


static func _get_disc_texture() -> ImageTexture:
	if _disc_texture == null:
		var image: Image = Image.create(DISC_TEXTURE_PX, DISC_TEXTURE_PX, false, Image.FORMAT_RGBA8)
		var centre: float = (DISC_TEXTURE_PX - 1) / 2.0
		for y: int in DISC_TEXTURE_PX:
			for x: int in DISC_TEXTURE_PX:
				var dist: float = Vector2(x - centre, y - centre).length()
				var alpha: float = clampf(centre + 0.5 - dist, 0.0, 1.0)
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
		_disc_texture = ImageTexture.create_from_image(image)
	return _disc_texture
