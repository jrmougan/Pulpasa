# PUL-022 — Menú principal

- Entrada directa `main_menu.tscn`; `boot.tscn` también redirige al menú sin cubo.
- Logo vectorial propio en Control, tema PUL-009 y textos `tr()` con claves `MENU_*` y fallback castellano local; no se registran traducciones globales ni se altera el catálogo de señales.
- Jugar llama a `GameState.start_level(SINGLE)`; Salir llama a `SceneTree.quit()`.
- Foco inicial Jugar, vecinos explícitos y botones nativos. No hay polling de teclas ni contadores de selección.

## Comprobaciones

- `tools/verify.sh`: formato, lint, import, 334 tests GUT (1793 assertions) y smoke del menú, todo verde. Log: `verify.log`.
- `test_main_menu.gd`: escena inicial/foco/tema, SINGLE una vez por aceptación, salida una vez con doble, navegación circular ui_up/down/focus_next/focus_prev, eventos reales InputEventJoypadButton (cruceta + A) y recuperación de error.
- Ejecución gráfica con `xvfb-run`, Vulkan; MCP `attach_project`, `simulate_input`, `take_screenshot`, `stop_project`. Salir terminó el proceso externo con código 0.
- `ac1-menu.png`: arranque 1280×720, foco en Jugar. `ac2-level-pendiente.png`: aviso visible y foco recuperado.
- `runtime.log`: cero ERROR/SCRIPT ERROR; aviso esperado por nivel ausente y avisos de X11/MCP al cerrar.

## Nivel pendiente y limitaciones

`res://scenes/levels/level_01.tscn` aún no existe. El GameState existente devuelve `ERR_FILE_NOT_FOUND` y emite un warning; no ofrece fallback al sandbox. El menú muestra un aviso, rehabilita Jugar y mantiene Salir operativo. No se modifica GameState. Cuando fase 8 añada el nivel, la misma llamada lo cargará.

Este worker no tiene DISPLAY; el servidor MCP no pudo lanzar la ventana directamente, por eso se adjuntó a Godot bajo Xvfb. `get_debug_output` no está disponible en modo adjunto: se guardó stdout/stderr del proceso externo. Las acciones `simulate_input(type=action)` no llegaron al foco GUI en esta versión del bridge; la comprobación visual usó teclas mapeadas a ui_* (Down/Up/Space), mientras GUT inyectó ui_* y eventos de mando en el Viewport. No se comprobó un mando físico.

Escenas serializadas mediante PackedScene/ResourceSaver desde un script Godot tipado temporal; UIDs de scripts generados por el importador. `project.godot` cambia exclusivamente `application/run/main_scene`.
