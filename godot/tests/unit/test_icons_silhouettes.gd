extends GutTest
## PUL-123 AC1 (diseño AC4): las siluetas de los iconos se distinguen en gris a tamaño de uso. Se
## rasteriza cada SVG a 64 px (verbos) o 32 px (motivos), se pasa a gris, se binariza al 50 % y se
## exige IoU <= 0,6 entre cualquier par.

const ICON_DIR: String = "res://assets/textures/ui/actions/"
const MAX_IOU: float = 0.6
## Fracción mínima de la máscara que debe sobrevivir a la apertura.
const MIN_KEPT: float = 0.85
const MARKS: Array[String] = [
	"cross",
	"replace",
	"ready",
	"burn_warning",
	"active",
	"offscreen",
	"player_1",
	"player_2",
	"plate",
]


## Los ids del contrato (`ActionVerb.ALL`, `ActionReason.ALL`) como nombres de fichero.
func _ids(values: Array[StringName]) -> Array[String]:
	var ids: Array[String] = []
	for value: StringName in values:
		ids.append(String(value))
	return ids


func test_verb_silhouettes_are_distinct_at_64px() -> void:
	_check_group("verb", _ids(ActionVerb.ALL), 64)


func test_reason_silhouettes_are_distinct_at_32px() -> void:
	_check_group("reason", _ids(ActionReason.ALL), 32)


func test_strokes_survive_an_opening_of_radius_5() -> void:
	## Trazo >= 8 % del lado (11 px a 128): una apertura (erosión y dilatación) de radio 5 conserva
	## al menos el 85 % de la máscara; las líneas más finas desaparecen.
	for icon_name: String in _all_names():
		var mask: PackedByteArray = mask_of(icon_name, 128)
		var opened: PackedByteArray = _dilate(_erode(mask, 128, 5), 128, 5)
		var kept: float = float(_count(opened)) / float(maxi(_count(mask), 1))
		assert_gte(
			kept, MIN_KEPT, "%s conserva %.1f %% tras la apertura" % [icon_name, kept * 100.0]
		)


## IoU de dos máscaras binarias del mismo tamaño.
static func iou(a: PackedByteArray, b: PackedByteArray) -> float:
	var inter: int = 0
	var union: int = 0
	for i: int in a.size():
		var in_a: bool = a[i] != 0
		var in_b: bool = b[i] != 0
		if in_a and in_b:
			inter += 1
		if in_a or in_b:
			union += 1
	return float(inter) / float(maxi(union, 1))


## Máscara binaria (1 = gris >= 0,5 sobre negro) del icono rasterizado a `px`.
static func mask_of(icon_name: String, px: int) -> PackedByteArray:
	var image: Image = Image.new()
	var svg: String = FileAccess.get_file_as_string(ICON_DIR + icon_name + ".svg")
	var err: Error = image.load_svg_from_string(svg, float(px) / 128.0)
	assert(err == OK, "SVG ilegible: " + icon_name)
	image.convert(Image.FORMAT_RGBA8)
	var out: PackedByteArray = PackedByteArray()
	out.resize(image.get_width() * image.get_height())
	for y: int in image.get_height():
		for x: int in image.get_width():
			var c: Color = image.get_pixel(x, y)
			var gray: float = (c.r * 0.299 + c.g * 0.587 + c.b * 0.114) * c.a
			out[y * image.get_width() + x] = 1 if gray >= 0.5 else 0
	return out


func _check_group(kind: String, ids: Array[String], px: int) -> void:
	var masks: Dictionary[String, PackedByteArray] = {}
	for id: String in ids:
		masks[id] = mask_of("icon_%s_%s" % [kind, id], px)
		assert_gt(_count(masks[id]), 0, "%s no está vacío" % id)
	var worst: float = 0.0
	for i: int in ids.size():
		for j: int in range(i + 1, ids.size()):
			var value: float = iou(masks[ids[i]], masks[ids[j]])
			worst = maxf(worst, value)
			assert_lte(value, MAX_IOU, "IoU %s/%s = %.3f" % [ids[i], ids[j], value])
	gut.p("%s a %d px: IoU máximo %.3f" % [kind, px, worst])


func _all_names() -> Array[String]:
	var names: Array[String] = []
	for id: String in _ids(ActionVerb.ALL):
		names.append("icon_verb_" + id)
	for id: String in _ids(ActionReason.ALL):
		names.append("icon_reason_" + id)
	for id: String in MARKS:
		names.append("icon_mark_" + id)
	return names


func _count(mask: PackedByteArray) -> int:
	var total: int = 0
	for value: int in mask:
		total += value
	return total


## Erosión con elemento circular de radio `r`: un píxel sobrevive si todo el disco está dentro.
func _erode(mask: PackedByteArray, side: int, r: int) -> PackedByteArray:
	return _sweep(mask, side, r, true)


## Dilatación con elemento circular de radio `r`.
func _dilate(mask: PackedByteArray, side: int, r: int) -> PackedByteArray:
	return _sweep(mask, side, r, false)


func _sweep(mask: PackedByteArray, side: int, r: int, erode: bool) -> PackedByteArray:
	var offsets: Array[Vector2i] = []
	for dy: int in range(-r, r + 1):
		for dx: int in range(-r, r + 1):
			if dx * dx + dy * dy <= r * r:
				offsets.append(Vector2i(dx, dy))
	var out: PackedByteArray = PackedByteArray()
	out.resize(mask.size())
	for y: int in side:
		for x: int in side:
			var result: bool = erode
			for off: Vector2i in offsets:
				var xx: int = x + off.x
				var yy: int = y + off.y
				# Fuera de la imagen cuenta como vacío.
				var value: bool = (
					xx >= 0 and xx < side and yy >= 0 and yy < side and mask[yy * side + xx] != 0
				)
				if erode and not value:
					result = false
					break
				if not erode and value:
					result = true
					break
			out[y * side + x] = 1 if result else 0
	return out
