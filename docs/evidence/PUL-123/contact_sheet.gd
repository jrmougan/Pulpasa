extends SceneTree
## Hoja de contacto de los iconos de PUL-123: verbos a 64 px, motivos a 32 px y marcas a 64 px, en
## gris sobre fondo oscuro (como los ve la binarización del test). Uso, desde `godot/`:
##   godot --headless -s ../docs/evidence/PUL-123/contact_sheet.gd -- <ruta absoluta del PNG>

const DIR: String = "res://assets/textures/ui/actions/"
const ROWS: Array = [
	[
		64,
		[
			"verb_pick_up",
			"verb_drop",
			"verb_cook",
			"verb_cut",
			"verb_season_sweet",
			"verb_season_hot",
			"verb_cachelos",
			"verb_trash"
		]
	],
	[
		32,
		[
			"reason_box_not_full",
			"reason_busy",
			"reason_empty",
			"reason_full",
			"reason_already_applied",
			"reason_not_cooked"
		]
	],
	[
		64,
		[
			"mark_cross",
			"mark_replace",
			"mark_ready",
			"mark_burn_warning",
			"mark_active",
			"mark_offscreen",
			"mark_player_1",
			"mark_player_2"
		]
	],
]


func _init() -> void:
	var out_path: String = OS.get_cmdline_user_args()[0]
	var cell: int = 88
	var sheet: Image = Image.create(cell * 8, cell * 3, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.12, 0.12, 0.14))
	for r: int in ROWS.size():
		var px: int = ROWS[r][0]
		var names: Array = ROWS[r][1]
		for i: int in names.size():
			var img: Image = Image.new()
			var svg: String = FileAccess.get_file_as_string(DIR + "icon_" + names[i] + ".svg")
			img.load_svg_from_string(svg, float(px) / 128.0)
			img.convert(Image.FORMAT_RGBA8)
			for y: int in img.get_height():
				for x: int in img.get_width():
					var c: Color = img.get_pixel(x, y)
					var g: float = (c.r * 0.299 + c.g * 0.587 + c.b * 0.114) * c.a
					img.set_pixel(x, y, Color(g, g, g, 1.0))
			var pos: Vector2i = Vector2i(i * cell + (cell - px) / 2, r * cell + (cell - px) / 2)
			sheet.blit_rect(img, Rect2i(0, 0, px, px), pos)
	sheet.save_png(out_path)
	quit()
