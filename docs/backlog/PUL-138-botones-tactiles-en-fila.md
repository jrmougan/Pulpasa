---
id: PUL-138
title: Colocar los botones táctiles en fila y bajar la zona de botones
status: in_progress
milestone: M3e
role: ui-engineer
deps: [PUL-137]
orca_task: null
unity_sources: []
owns: [godot/ui/touch/touch_controls.gd*, godot/resources/ui_profile.gd*, godot/data/config/ui_profile_mobile.tres, godot/data/config/ui_profile_desktop.tres, godot/entities/camera/camera_rig.gd*, godot/ui/hud/hud_sandbox.gd*, godot/tests/unit/test_game_state.gd*, godot/tests/integration/test_touch_layout.gd*, godot/tests/integration/test_touch_button_zone.gd*, godot/tests/integration/test_camera_button_zone.gd*, godot/tests/integration/test_touch_hud_layout.gd*, godot/tests/integration/test_camera_follow.gd*, docs/evidence/PUL-138/**, docs/backlog/PUL-138-botones-tactiles-en-fila.md]
touches_scenes: []
---

## Target
D27 y ADR-005 «Enmienda D27» (D27.1-D27.4, PUL-137). Lista exacta de ficheros y campos: Evidence de
`docs/backlog/PUL-137-adr-005-e4-botones-en-fila.md` («Ficheros y campos para PUL-138»). Diseño: `features/controles-tactiles.md` «Contadores del
pasaplatos bajo los botones» (B-AC1..B-AC5).

## Change
Botón de cambiar a la izquierda del de acción y zona de botones según E4 enmendada, en datos (`.tres`) y
en la colocación de `TouchControls`; la cámara lee la zona nueva según E4.

## Constraints
- Solo perfil móvil: escritorio y Local 2P sin cambios. Datos en `.tres`. Tipado estático.
- Sin rutas absolutas de nodos; la cámara no conoce `TouchControls`.

## Acceptance
- [ ] AC1 B-AC1 (botones en fila: posiciones y tamaños a 2340×1080, sin solape táctil) → `test_touch_layout.gd`.
- [ ] AC2 B-AC2 (cada botón con margen de toque dentro de la zona, 3 resoluciones × 2 safe areas; zona en
  y = alto − 240 × alto/1080) → `test_touch_button_zone.gd`.
- [ ] AC3 B-AC3 (caso 09: 0 contadores en la zona con el activo en la plaza de cada olla; en z −3,4,
  0 a 2340/1920 y ≤ 8 px a 800×370), con safe area inferior nula; con la de diseño se registra el
  solape (limitación D27.3, no se exige) → `test_camera_button_zone.gd`.
- [ ] AC4 B-AC4 (sin regresión de AC2 de PUL-134; escritorio sin `TouchControls`) y B-AC5 (capturas del
  caso 09 en las 3 resoluciones en `docs/evidence/PUL-138/`); `tools/verify.sh` en verde; `check_owns` limpio.

## Plan

## Evidence
