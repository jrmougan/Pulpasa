extends GutTest
## PUL-123 AC1 (diseño AC4): las siluetas de los iconos se distinguen en gris a tamaño de uso. Se
## rasteriza cada SVG a 64 px (verbos) o 32 px (motivos), se pasa a gris, se binariza al 50 % y se
## exige IoU <= 0,6 entre cualquier par.

const ICON_DIR: String = "res://assets/textures/ui/actions/"
const MAX_IOU: float = 0.6
const VERBS: Array[String] = [
	"pick_up",
	"drop",
	"cook",
	"cut",
	"season_sweet",
	"season_hot",
	"cachelos",
	"trash",
]
const REASONS: Array[String] = [
	"box_not_full", "busy", "empty", "full", "already_applied", "not_cooked"
]


func test_verb_silhouettes_are_distinct_at_64px() -> void:
	_check_group("verb", VERBS, 64)


func test_reason_silhouettes_are_distinct_at_32px() -> void:
	_check_group("reason", REASONS, 32)


func test_solid_areas_are_thick() -> void:
	## Trazo grueso: tras erosionar la máscara de 128 px con un radio de 4 px (trazo >= 9 px, el
	## 7 % del lado) queda algo en pie; una silueta hecha solo de líneas finas desaparecería.
	for icon_name: String in _all_names():
		var mask: PackedByteArray = mask_of(icon_name, 128)
		assert_gt(_count(_erode(mask, 128, 4)), 0, "%s tiene trazo grueso" % icon_name)


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
	for id: String in VERBS:
		names.append("icon_verb_" + id)
	for id: String in REASONS:
		names.append("icon_reason_" + id)
	return names


func _count(mask: PackedByteArray) -> int:
	var total: int = 0
	for value: int in mask:
		total += value
	return total


## Erosión cuadrada de radio `r`: un píxel sobrevive si todo su entorno (2r+1)² está dentro.
func _erode(mask: PackedByteArray, side: int, r: int) -> PackedByteArray:
	var out: PackedByteArray = PackedByteArray()
	out.resize(mask.size())
	for y: int in range(r, side - r):
		for x: int in range(r, side - r):
			var keep: bool = true
			for dy: int in range(-r, r + 1):
				for dx: int in range(-r, r + 1):
					if mask[(y + dy) * side + x + dx] == 0:
						keep = false
						break
				if not keep:
					break
			out[y * side + x] = 1 if keep else 0
	return out
