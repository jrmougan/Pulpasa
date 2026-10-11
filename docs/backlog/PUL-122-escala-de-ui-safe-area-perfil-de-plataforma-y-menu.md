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


## Plan

## Evidence
