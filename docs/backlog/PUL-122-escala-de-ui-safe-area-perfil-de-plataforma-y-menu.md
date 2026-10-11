---
id: PUL-122
title: Escala de UI, safe area, perfil de plataforma y menús móviles
status: in_progress
milestone: M3e
role: ui-engineer
deps: [PUL-119, PUL-120]
orca_task: null
unity_sources: []
owns: [godot/project.godot, godot/core/platform_profile.gd*, godot/autoload/game_state.gd*, godot/resources/ui_profile.gd*, godot/data/config/ui_profile_desktop.tres, godot/data/config/ui_profile_mobile.tres, godot/ui/widgets/ui_scale.gd*, godot/ui/widgets/safe_area_margin.gd*, godot/ui/theme/**, godot/ui/menus/**, godot/ui/hud/hud.gd*, godot/ui/tickets/order_tickets_panel.gd*, godot/tests/unit/test_platform_profile.gd*, godot/tests/unit/test_ui_scale_math.gd*, godot/tests/unit/test_game_state.gd*, godot/tests/unit/test_project_settings.gd*, godot/tests/integration/test_main_menu.gd*, godot/tests/integration/test_main_menu_touch.gd*, godot/tests/integration/test_touch_menus.gd*, godot/tests/integration/test_pause_menu.gd*, godot/tests/integration/test_game_over.gd*, godot/tests/integration/test_ui_gamepad.gd*, godot/tests/integration/test_ui_scale.gd*, godot/tests/integration/test_app_lifecycle.gd*, godot/tests/integration/test_hud.gd*, godot/tests/integration/test_order_tickets.gd*, docs/evidence/PUL-122/**, docs/backlog/PUL-122-escala-de-ui-safe-area-perfil-de-plataforma-y-menu.md]
touches_scenes: [godot/ui/menus/main_menu.tscn, godot/ui/menus/pause_menu.tscn, godot/ui/menus/game_over.tscn, godot/ui/menus/menu_panel.tscn, godot/ui/menus/sandbox/**]
---

## Target
D26 (`docs/design/decisions.md`), contrato en `docs/arch/` (ADR-003 §11, ADR-004 §6, ADR-005 Enmienda D26,
ADR-006 §4.1, `signals.md`, `scene-tree.md` §9). Partición original y notas de propietarios entre oleadas:
`docs/backlog/PUL-120-contratos-d26.md` («Partición en fichas»). Oleada 1. Diseño:
`docs/design/features/lenguaje-acciones.md` y `controles-tactiles.md`. Touches scenes original: `godot/ui/menus/main_menu.tscn`, `godot/ui/menus/pause_menu.tscn`,
  `godot/ui/menus/game_over.tscn`, `godot/ui/menus/menu_panel.tscn`, `godot/ui/menus/sandbox/**`

## Change
ADR-005 E1–E4 (sin la disposición de HUD y tickets, que es de PUL-129: aquí solo se quita
  la línea de `UiScale.factor`), ADR-004 §6.5, ADR-002 Enmienda 2.2. Tema con mínimos de texto móviles;
  menús con botones ≥ 120 px en `MOBILE`; «Reiniciar» en la pausa si la feature lo mantiene.

## Constraints
- Solo las rutas de `owns`/`touches_scenes`. Si un cambio rompe un test fuera de tus owns, para y avisa al producer.
- Tipado estático, datos en `.tres`, lógica en `core/` RefCounted; no inventes `uid://`.
- Nombres exactos del contrato (manda sobre el diseño; equivalencias en PUL-120).

## Acceptance
- [x] AC1 `PlatformProfile.detect`: `--touch` o `--profile=mobile` -> `MOBILE`; `--profile=desktop` -> `DESKTOP`; features `mobile`/`web_android`/`web_ios` -> `MOBILE`; resto -> `DESKTOP` (`test_platform_profile.gd`)
- [x] AC2 `project.godot`: `stretch/mode` `canvas_items`, `aspect` `expand`, `handheld/orientation` 4 (`test_project_settings.gd`)
- [x] AC3 `UiScale`: 72 dp = 180 px a 1080 con cualquier lienzo; `px_to_units`; `safe_margins` 132 / 0 / 132 / 63 y safe area nula (`test_ui_scale_math.gd`)
- [x] AC4 Con `--touch`, el menú solo muestra «Individual» con foco y carga el nivel en `SINGLE`; en escritorio siguen los 3 botones (`test_main_menu_touch.gd`)
- [x] AC5 Perfil móvil a 2340x1080: ningún texto de menú, pausa o game over < 36 px; a 1600x720 < 24 px (`test_ui_scale.gd`)
- [x] AC6 Botones de menú, pausa y game over >= 120 px de alto y >= 24 px de separación en `MOBILE`; reanudar <= 0,1 s (`test_touch_menus.gd`)
- [x] AC7 Perder el foco o Atrás en ronda pausan en <= 1 frame y no se reanuda sola; solo en `MOBILE` (`test_app_lifecycle.gd`)
- [x] AC8 En escritorio, HUD y tickets conservan su tamaño a 1280x720 y 1920x1080 (`test_hud.gd`, `test_order_tickets.gd`); capturas de menús en `docs/evidence/PUL-122/`

## Plan
1. `core/platform_profile.gd`, `resources/ui_profile.gd` y dos `.tres`; `UiScale` nuevo; `SafeAreaMargin`.
2. `project.godot` (stretch, orientación, `quit_on_go_back=false`); `GameState`: `platform`, `ui_profile`, `set_platform`, ciclo de vida y pantalla encendida.
3. Menús: `SafeAreaMargin` raíz, `TextFloor`/`MenuMobile`/`FocusRing`, solo «Individual», «Reiniciar» en la pausa móvil.
4. Quitar `UiScale.factor` de `hud.gd` y `order_tickets_panel.gd`.
5. Tests GUT y capturas.

## Evidence
- `tools/verify.sh` en verde (ver commit final). Capturas en `docs/evidence/PUL-122/`: `main_menu_*`, `menu_touch_2340x1080`, `pause_*`, `gameover_*`, `pause_warning_touch_2340x1080`, `main_menu_touch_1280x720` (escritorio a 1280x720 y 1920x1080; táctil a 2340x1080 con `--touch`). Generadas con un script `SceneTree` (`godot --resolution WxH -s capture.gd -- <pantalla> <png> [--touch]`).
- Decisiones: «Reiniciar» solo en la pausa `MOBILE` (escritorio sin cambios); botón de salida se llama «Menú» en `MOBILE`; en `MOBILE` se oculta la insignia de la tarjeta y la tarjeta mide 720 u de ancho para que quepa en 720 de alto del lienzo; `quit_on_go_back=false` para que Atrás pause en vez de salir; `SafeAreaMargin.set_safe_rect(rect, window_size)` admite el tamaño de ventana para tests.
