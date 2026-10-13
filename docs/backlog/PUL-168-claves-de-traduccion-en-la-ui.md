---
id: PUL-168
title: Pasar los textos de la UI a claves de traducción (castellano)
status: draft
milestone: M4
role: ui-engineer
deps: [PUL-163]
orca_task: null
unity_sources: []
owns: [godot/data/i18n/**, godot/project.godot, godot/ui/menus/*.gd*, godot/ui/hud/*.gd*, godot/ui/tickets/*.gd*, godot/ui/touch/*.gd*, godot/tests/unit/test_translation_keys.gd*, docs/evidence/PUL-168/**, docs/backlog/PUL-168-claves-de-traduccion-en-la-ui.md]
touches_scenes: [godot/ui/menus/main_menu.tscn, godot/ui/menus/pause_menu.tscn, godot/ui/menus/game_over.tscn, godot/ui/menus/menu_panel.tscn, godot/ui/hud/hud.tscn, godot/ui/tickets/order_ticket.tscn, godot/ui/tickets/ticket_entry.tscn, godot/ui/tickets/order_tickets_panel.tscn, godot/ui/touch/touch_controls.tscn]
---

## Target
ADR-007 (PUL-163), parte de localización; inventario de cadenas de PUL-161. En `project.godot` solo la
sección `[internationalization]`.

## Change
Sustituir cada texto visible por su clave de traducción, crear el fichero de traducciones con la columna
castellana completa (la gallega la rellena PUL-173) y registrarlo. Incluye textos que vienen de `.tres`
según el mecanismo de ADR-007. Crea además, vacíos y registrados, un fichero por área que se rellenará en
paralelo (`options`, `credits`, `tutorial`), para que PUL-171, 172 y 174 no compartan fichero ni toquen
`project.godot`. (Si ADR-007 elige otro formato que CSV, el producer ajusta los globs de `data/i18n/`.)

## Constraints
- En castellano la UI se ve igual que antes (sin regresión visual).
- `level_01.tscn` no se toca (es de PUL-175). Si un texto vive en una escena del mundo, se anota para PUL-175.

## Acceptance
- [ ] AC1 Given cada cadena del inventario de PUL-161, Then tiene clave y texto castellano en el fichero → `test_translation_keys.gd`.
- [ ] AC2 Given las escenas y scripts de `ui/`, Then 0 textos visibles literales fuera de claves (test que
  recorre los `Label`/`Button` de las escenas instanciadas) → `test_translation_keys.gd`.
- [ ] AC3 Given el idioma castellano, Then menú, pausa, HUD con 4 tickets y resultados se ven igual que
  antes → capturas antes/después a 1920×1080 en `docs/evidence/PUL-168/`.
- [ ] AC4 `tools/verify.sh` en verde; `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
