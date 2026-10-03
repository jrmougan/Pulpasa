---
id: PUL-022
title: Crear el menú principal y el flujo de escenas
status: review
milestone: M0
role: ui-engineer
deps: []
orca_task: null
unity_sources: [Assets/Scripts/UI/MainMenu.cs, Assets/Scenes/MainMenu/**, Assets/Art/Logo/**]
owns: [godot/ui/menus/main_menu.tscn, godot/ui/menus/main_menu.gd, godot/ui/menus/main_menu.gd.uid, godot/project.godot, godot/scenes/boot.tscn, godot/scenes/boot.gd, godot/tests/integration/test_main_menu.gd, godot/tests/integration/test_main_menu.gd.uid, godot/tests/unit/test_smoke.gd, docs/evidence/PUL-022/**]
touches_scenes: [godot/ui/menus/main_menu.tscn, godot/scenes/boot.tscn]
---

## Target
Fase 7 de M0, `scene-tree.md` §4 y ADR-003 §7 (flujo `boot → main_menu → level_01`).

## Change
1. `ui/menus/main_menu.tscn` + `main_menu.gd`: logo propio, botones **Jugar** (= Individual con un
   personaje en M0; Local 2P llega en M2) y **Salir**, foco inicial en Jugar. Jugar →
   `GameState.start_level(GameMode.Mode.SINGLE)`; Salir → cerrar el juego.
2. `project.godot`: `run/main_scene` pasa a apuntar al menú (directamente o vía `boot.tscn`, que deja de
   ser el cubo provisional). Toca solo esa clave.
3. Mientras no exista `level_01.tscn` (fase 8), `start_level` debe fallar de forma controlada (sin
   crash) o cargar el sandbox de cocina si `GameState` ya lo permite; documenta lo que ocurra. No
   cambies `GameState`: si hace falta, pregunta al coordinador.
4. Ajusta `test_smoke.gd` si dependía del cubo de `boot.tscn`.

## Constraints
- Capa común (ADR-003 §0): nada de tipos 3D en `ui/`. La UI escucha señales de `EventBus` y llama métodos de los autoloads; nunca consulta sistemas por ruta (B16). Sin contadores propios (B2).
- Navegable con teclado y mando: `Button` con foco nativo, `focus_neighbor_*`, `grab_focus()` al abrir y acciones `ui_*` (ADR-004; sustituye B13/B14).
- Textos con `tr()` y claves (preparado para gallego, Should de la alpha). Tema `ui/theme/default_theme.tres` (PUL-009).
- `.tscn` con un script tipado propio o el editor; las tools headless del MCP fallan por `untyped_declaration=error`. No inventes uid.

## Acceptance
- [x] AC1 Al arrancar el proyecto aparece el menú con foco en Jugar → `test_main_menu.gd`.
- [x] AC2 Jugar llama a `GameState.start_level(SINGLE)` exactamente una vez; Salir cierra el árbol → `test_main_menu.gd` (con doble de `GameState` o señal).
- [x] AC3 Se navega solo con `ui_*` (teclado y mando).
- [x] AC4 Captura del menú en `docs/evidence/PUL-022/`. El smoke de `verify.sh` arranca con el menú sin errores; `check_owns` limpio.

## Plan

- Crear menú Control con logo propio, tema común, textos traducibles y foco nativo.
- Arranque directo al menú; boot conserva una entrada alternativa sin cubo.
- Tests AC1–AC3: foco, activación única SINGLE, salida con doble, navegación ui_* y error recuperable.
- AC4: verify completo, captura e interacción MCP, check_owns.

## Evidence

- [Informe y limitaciones](../evidence/PUL-022/README.md), capturas y logs en `docs/evidence/PUL-022/`.
- `tools/verify.sh`: 334 tests verdes y smoke del menú sin errores.
- Nivel aún ausente: retorno controlado de GameState, aviso visible y foco recuperado.
- Salir comprobado con doble GUT y proceso gráfico real (código 0).
