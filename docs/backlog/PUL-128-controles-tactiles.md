---
id: PUL-128
title: Controles táctiles
status: done
milestone: M3e
role: ui-engineer
deps: [PUL-121, PUL-122, PUL-123]
orca_task: null
unity_sources: []
owns: [godot/ui/touch/**, godot/core/touch_input.gd*, godot/resources/touch_config.gd*, godot/data/config/touch_config.tres, godot/tests/unit/test_touch_input_rules.gd*, godot/tests/integration/test_touch_input.gd*, godot/tests/integration/test_virtual_stick.gd*, godot/tests/integration/test_touch_multitouch.gd*, godot/tests/integration/test_action_button.gd*, godot/tests/integration/test_touch_layout.gd*, docs/evidence/PUL-128/**, docs/backlog/PUL-128-controles-tactiles.md]
touches_scenes: [godot/ui/touch/touch_controls.tscn]
---

## Target
D26 (`docs/design/decisions.md`), contrato en `docs/arch/` (ADR-003 §11, ADR-004 §6, ADR-005 Enmienda D26,
ADR-006 §4.1, `signals.md`, `scene-tree.md` §9). Partición original y notas de propietarios entre oleadas:
`docs/backlog/PUL-120-contratos-d26.md` («Partición en fichas»). Oleada 2. Diseño:
`docs/design/features/lenguaje-acciones.md` y `controles-tactiles.md`. Touches scenes original: `godot/ui/touch/touch_controls.tscn` (nueva) y su sandbox en `godot/ui/touch/sandbox/`

## Change
ADR-004 §6.1–§6.4 con las medidas de `controles-tactiles.md`.

## Constraints
- Solo las rutas de `owns`/`touches_scenes`. Si un cambio rompe un test fuera de tus owns, para y avisa al producer.
- Tipado estático, datos en `.tres`, lógica en `core/` RefCounted; no inventes `uid://`.
- Nombres exactos del contrato (manda sobre el diseño; equivalencias en PUL-120).

## Acceptance
- [x] AC2/AC3/AC17/AC21 maquetación: acción 180 px en (2070, 879) con safe area y (1782, 942) sin ella; cambiar 120 px a 24 px; pausa 120 px en (2100, 108); zonas táctiles sin solape; desktop libera los controles (`test_touch_layout.gd`).
- [x] AC4 stick flotante: base 300 px en el contacto, 0,5 a 75 px, zona muerta, base que sigue, recorte a la safe area (282, 867), fundido 0,15 s, zona y bloqueadores (`test_virtual_stick.gd`).
- [x] AC5 multitáctil por `event.index` (`test_touch_multitouch.gd`). Matiz: la fuerza analógica del stick llega a las acciones `p1_move_*`; la velocidad analógica del personaje (hoy `PlayerInput` normaliza) la hará PUL-131 en `player.gd`.
- [x] AC6/AC7/AC20 mismas acciones de J1, 5 m/s, mismo frame, mando oculta y toque restaura (`test_touch_input.gd`).
- [x] AC8/AC9 botón de acción: gris / aro blanco / aro ámbar + aspa + motivo; mantener solo repite CORTAR (6 cortes en 1,05 s); respuesta y háptica (`test_action_button.gd`).
- [x] Reglas puras y datos (`test_touch_input_rules.gd`).
- [x] Capturas a 2340x1080 y 1920x1080 en `docs/evidence/PUL-128/`.

## Plan
1. `TouchConfig` + `touch_config.tres`; `TouchInput` puro (fuente, visibilidad, vector, base que sigue, recorte).
2. `TouchButton` / `ActionButton` / `VirtualStick` / `TouchControls` y `touch_controls.tscn`; sandbox con capturas.
3. Tests GUT y capturas.

## Evidence
`docs/evidence/PUL-128/`: `<ancho>x1080_{idle,pick_up,cut,season_hot,blocked,drop,stick_and_press}.png`, generadas con
`godot --path godot --resolution 2340x1080 res://ui/touch/sandbox/touch_sandbox.tscn -- --touch --capture=<dir>`.
105 tests GUT nuevos; `tools/verify.sh` en verde (1115 tests).
Notas: se añade el nodo `%Content` (Control, `top_level`) bajo `%SafeArea` porque un MarginContainer reencaja a sus hijos; los pictogramas de cambiar y pausa se dibujan por código (no hay assets en `owns`); el movimiento sigue normalizado por `PlayerInput` (la magnitud analógica llega a las acciones, pero la velocidad es la máxima como con el mando); el prompt del mundo aún no existe, "mismo icono" se verifica contra `ActionIconSet`.

Revisión: los controles hijos consultan `TouchControls.accepts_input(event)` (puerta que anota la fuente), así que el toque que los hace reaparecer tras un mando actúa en ese mismo toque; `release_all()` también con `APPLICATION_FOCUS_OUT`, `APPLICATION_PAUSED` y `WM_WINDOW_FOCUS_OUT`; `top_level` de `%Content` en el `.tscn`; valores visuales y de respuesta en `TouchConfig`; zona muerta del mando desde `InputConfig`; tests de coherencia con `UiProfile` (zona del stick y zona de botones a 2340 y 1920).
