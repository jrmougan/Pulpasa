---
id: PUL-138
title: Colocar los botones táctiles en fila y bajar la zona de botones
status: done
milestone: M3e
role: ui-engineer
deps: [PUL-137]
orca_task: task_082861f85b51
unity_sources: []
owns: [godot/ui/touch/touch_controls.gd*, godot/resources/ui_profile.gd*, godot/data/config/ui_profile_mobile.tres, godot/data/config/ui_profile_desktop.tres, godot/entities/camera/camera_rig.gd*, godot/ui/hud/hud_sandbox.gd*, godot/tests/unit/test_game_state.gd*, godot/tests/integration/test_touch_layout.gd*, godot/tests/integration/test_touch_button_zone.gd*, godot/tests/integration/test_camera_button_zone.gd*, godot/tests/integration/test_touch_hud_layout.gd*, godot/tests/integration/test_camera_follow.gd*, godot/tests/integration/test_touch_input.gd*, godot/tests/integration/test_touch_multitouch.gd*, godot/tests/integration/test_d26_touch_flow.gd*, docs/evidence/PUL-138/**, docs/backlog/PUL-138-botones-tactiles-en-fila.md]
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
- [x] AC1 B-AC1 (botones en fila: posiciones y tamaños a 2340×1080, sin solape táctil) → `test_touch_layout.gd`.
- [x] AC2 B-AC2 (cada botón con margen de toque dentro de la zona, 3 resoluciones × 2 safe areas; zona en
  y = alto − 240 × alto/1080) → `test_touch_button_zone.gd`.
- [x] AC3 B-AC3 (caso 09: 0 contadores en la zona con el activo en la plaza de cada olla; en z −3,4,
  0 a 2340/1920 y ≤ 8 px a 800×370), con safe area inferior nula; con la de diseño se registra el
  solape (limitación D27.3, no se exige) → `test_camera_button_zone.gd`.
- [x] AC4 B-AC4 (sin regresión de AC2 de PUL-134; escritorio sin `TouchControls`) y B-AC5 (capturas del
  caso 09 en las 3 resoluciones en `docs/evidence/PUL-138/`); `tools/verify.sh` en verde; `check_owns` limpio.

## Plan
1. Datos: `UiProfile.button_zone_top_px` → `button_zone_height_px = 240` (móvil y escritorio).
2. `TouchControls.refresh_layout`: cambiar a la izquierda de acción, bordes inferiores alineados, hueco
   `button_gap_px_1080`.
3. `CameraRig._button_zone` y `hud_sandbox.gd`: zona anclada a la esquina inferior derecha de la safe
   area (D27.2).
4. Tests de la lista de PUL-137 y caso 09 (B-AC3) en `test_camera_button_zone.gd`; capturas (B-AC5).

## Evidence
- Código: `touch_controls.gd` (switch en fila), `camera_rig.gd` (`_button_zone` con `_safe_margins`),
  `hud_sandbox.gd`, `ui_profile.gd` + `.tres` (móvil y escritorio).
- Tests: B-AC1 `test_touch_layout.gd` (`test_bac1_*`), B-AC2 `test_touch_button_zone.gd`
  (`test_bac2_*`, tabla de holguras), B-AC3 `test_camera_button_zone.gd` (`test_bac3_*`: 0 px en
  z −3,1 y z −3,4 con safe inferior nula; con la de diseño se registra 6,6 / 35,1 px a 1080 y
  2,2 / 12,0 px a 800×370, limitación D27.3), B-AC4 `test_bac4_ac2_*` con safe nula y de diseño.
- Tolerancia de 1 unidad de lienzo en B-AC2: `SafeAreaMargin` redondea los márgenes a enteros
  (21,6 → 22 a 800×370), la cámara no; el botón de acción queda 0,4 px por encima de la zona.
- Owns ampliados con aprobación del coordinador: `test_touch_input.gd`, `test_touch_multitouch.gd` y
  `test_d26_touch_flow.gd` tenían `SWITCH_PX` fijo en la posición antigua (2070, 705); pasa a
  (1896, 909) (D27.1 con la safe de diseño). Solo esa constante.
- B-AC5: capturas y medidas en `docs/evidence/PUL-138/` (README con tabla): en juego real 0 px a
  2340 y 1920, 6,4 px a 800×370 en z −3,4 (≤ 8, residuo de D27).
- `tools/verify.sh` en verde; `python3 tools/check_owns.py` limpio.
