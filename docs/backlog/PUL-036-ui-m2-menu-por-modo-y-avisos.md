---
id: PUL-036
title: Menú por modo, avisos de mando y UI navegable solo con mando
status: review
milestone: M2
role: ui-engineer
deps: []
orca_task: null
unity_sources: []
owns: [godot/ui/**, godot/tests/integration/test_main_menu.gd, godot/tests/integration/test_pause_menu.gd, godot/tests/integration/test_game_over.gd, godot/tests/integration/test_hud.gd, godot/tests/integration/test_ui_gamepad.gd, godot/tests/integration/test_ui_gamepad.gd.uid, docs/evidence/PUL-036/**]
touches_scenes: [godot/ui/menus/main_menu.tscn, godot/ui/menus/pause_menu.tscn, godot/ui/menus/game_over.tscn, godot/ui/hud/hud.tscn]
---

## Target
M2, Must 5 y 7. Features `menu-principal` (AC1–AC5) y `mando-y-reasignacion` AC2 y AC5.
Contrato: ADR-004 §5, `scene-tree.md` §4, `signals.md` (`character_switched`, `device_assigned`,
`device_disconnected`; ya declaradas en `event_bus.gd`).

## Change
1. Menú principal: **Individual**, **Local 2P** y **Salir** (sustituye «Jugar»). Individual llama
   `start_level(GameMode.Mode.SINGLE)`, Local 2P `start_level(GameMode.Mode.COOP_2P)`. Foco inicial
   en Individual. Textos por clave (`tr`) con fallback, como ahora.
2. Pausa: aviso de mando desconectado («Mando de J<n> desconectado») al recibir
   `device_disconnected`; se oculta con `device_assigned` de ese jugador. El aviso aparece aunque
   la pausa ya estuviera abierta.
3. HUD: indicador de quién controla en modo individual (retrato/etiqueta del personaje activo con
   `character_switched`) y aviso breve «J2 conectado» con `device_assigned`. Discreto: no tapa tickets.
4. Mando sin teclado: menú, pausa y game over (Reintentar / Salir) navegables con `ui_*` y foco
   siempre en un botón al mostrarse. Revisar que ningún flujo dependa de ratón o teclado.

## Constraints
- Sin tipos 3D en `ui/`. Sin rutas absolutas de nodos; solo `EventBus` y órdenes a `GameState`.
- No cambiar firmas de `EventBus` ni editar `GameState` (PUL-034) ni `level_01.tscn` (PUL-037).
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [x] AC1 Individual → `start_level(SINGLE)`; Local 2P → `start_level(COOP_2P)`; Salir → `quit` → `test_main_menu.gd`
- [x] AC2 Foco inicial en Individual; las 3 opciones se alcanzan y activan con eventos de mando (`ui_down`/`ui_accept` como `InputEventJoypadButton`) → `test_ui_gamepad.gd`
- [x] AC3 `device_disconnected(2)` muestra el aviso en la pausa en el mismo frame; `device_assigned(2, id)` lo oculta → `test_pause_menu.gd`
- [x] AC4 Pausa y game over dan foco a un botón al mostrarse y se completan con eventos de mando → `test_ui_gamepad.gd`
- [x] AC5 HUD refleja `character_switched` y `device_assigned` → `test_hud.gd`
- [x] AC6 Capturas del menú con las 3 opciones y de la pausa con el aviso → `docs/evidence/PUL-036/`
- [x] AC7 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. Menú: botón `Local2P` entre Individual y Salir, foco cíclico, `_start(mode, source)` común.
2. Pausa: `DeviceWarning` (Label) con el conjunto de jugadores desconectados; `device_disconnected` lo añade, `device_assigned` lo quita.
3. HUD: `ActiveCharacter` (`character_switched`) y `DeviceNotice` temporal 2 s (`device_assigned`, ignora solo-teclado).
4. Tests en los 4 ficheros existentes + `test_ui_gamepad.gd` con eventos `InputEventJoypadButton`.

## Evidence
- `tools/verify.sh` verde (440 tests). Capturas: `docs/evidence/PUL-036/menu.png` y `pausa_aviso.png`.
- Jugadores 1-based (J1/J2) según `signals.md`. `DeviceAssignment` aún no existe (PUL-034): el HUD usa la constante local `NO_DEVICE = -2`; sustituir al mergear PUL-034.
- El HUD sube 32 px su borde superior para alojar las etiquetas nuevas.
