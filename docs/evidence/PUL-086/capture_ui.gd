extends SceneTree
## Capturas de PUL-086 (registro reproducible; no es parte del juego).
## Uso, desde la raíz del repo:
##   xvfb-run -a godot --audio-driver Dummy --path godot --resolution 1920x1080 \
##     -s "$PWD/docs/evidence/PUL-086/capture_ui.gd" -- <out_dir> <modo> <prefijo>
## Modos:
##   level     cámara de level_01 con HUD y tickets tras unos segundos de ronda (con resaltado de
##             la estación de condimentos para comprobar que la UI no lo tapa).
##   pause     level_01 en pausa.
##   gameover  level_01 con el resultado de fin de ronda.
##   alert     level con las comandas en paciencia baja (barra y reloj en neón); recorta los tickets.
##   menu      menú principal.


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0]
	var mode: String = args[1] if args.size() > 1 else "level"
	var prefix: String = args[2] if args.size() > 2 else "after"
	if mode == "menu":
		var menu: Node = (load("res://ui/menus/main_menu.tscn") as PackedScene).instantiate()
		root.add_child(menu)
		current_scene = menu
		for i in 10:
			await process_frame
	else:
		var level: Node = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
		root.add_child(level)
		current_scene = level
		# Deja que salgan comandas y corra la paciencia.
		var service: Node = root.get_node("OrderService")
		for i in 300:
			await physics_frame
		# Espera a tener al menos dos comandas activas (la generación es aleatoria).
		for i in 1200:
			if (service.call("get_active_orders") as Array).size() >= 2:
				break
			await physics_frame
		var bus: Node = root.get_node("EventBus")
		bus.score_changed.emit(7, 84)
		var station := level.get_node_or_null("Stations/SeasoningStation") as Node3D
		if station != null:
			var target := station.get_node_or_null("Dispensers/Salt") as Node3D
			if target != null and target.has_node("%Highlightable"):
				(target.get_node("%Highlightable") as Highlightable).acquire(self)
		if mode == "alert":
			paused = true
			for order: ActiveOrder in service.call("get_active_orders"):
				bus.order_patience_changed.emit(order.id, 6.0, 40.0)
		if mode == "pause":
			root.get_node("GameState").call("set_paused", true)
		elif mode == "gameover":
			var thresholds: Array[float] = [1.0, 2.0]
			var texts: Array[String] = ["Flojo", "Bien", "¡Gran turno!"]
			var stars: Array[int] = [40, 80, 120]
			var result := RoundResult.new(180.0, 7, 84, thresholds, texts, stars)
			bus.round_finished.emit(result)
	for i in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var tag := "%dx%d" % [img.get_width(), img.get_height()]
	img.save_png(out_dir + "/%s_%s_%s.png" % [prefix, mode, tag])
	if mode == "alert":
		var crop := img.get_region(Rect2i(0, 0, img.get_width() / 2, img.get_height() / 3))
		crop.save_png(out_dir + "/%s_%s_%s_zoom.png" % [prefix, mode, tag])
	paused = false
	quit()
