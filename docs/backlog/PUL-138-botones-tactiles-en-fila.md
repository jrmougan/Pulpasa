---
id: PUL-138
title: Colocar los botones táctiles en fila y bajar la zona de botones
status: draft
milestone: M3e
role: ui-engineer
deps: [PUL-137]
orca_task: null
unity_sources: []
owns: [godot/ui/touch/touch_controls.gd*, godot/data/config/touch_config.tres, godot/data/config/ui_profile_mobile.tres, godot/entities/camera/camera_rig.gd*, godot/tests/integration/test_touch_layout.gd*, godot/tests/integration/test_touch_button_zone.gd*, godot/tests/integration/test_camera_button_zone.gd*, docs/evidence/PUL-138/**, docs/backlog/PUL-138-botones-tactiles-en-fila.md]
touches_scenes: [godot/ui/touch/touch_controls.tscn]
---

## Target
D27 y ADR-005 E4 enmendada en PUL-137. Diseño: `features/controles-tactiles.md` «Contadores del
pasaplatos bajo los botones» (B-AC1..B-AC5). Los owns se ajustan a la lista de ficheros de PUL-137 antes
de pasar a `ready`.

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
  0 a 2340/1920 y ≤ 8 px a 800×370) → `test_camera_button_zone.gd`.
- [ ] AC4 B-AC4 (sin regresión de AC2 de PUL-134; escritorio sin `TouchControls`) y B-AC5 (capturas del
  caso 09 en las 3 resoluciones en `docs/evidence/PUL-138/`); `tools/verify.sh` en verde; `check_owns` limpio.

## Plan

## Evidence
