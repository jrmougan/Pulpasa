---
id: PUL-134
title: Flecha de borde y zona de botones como zonas tapadas en la cámara móvil
status: todo
milestone: M3e
role: gameplay-engineer
deps: [PUL-133]
orca_task: null
unity_sources: []
owns: [godot/entities/camera/camera_rig.gd*, godot/core/camera_follow.gd*, godot/resources/camera_profile.gd*, godot/data/config/camera_mobile.tres, godot/tests/unit/test_camera*, godot/tests/integration/test_camera*, docs/evidence/PUL-134/**, docs/backlog/PUL-134-flecha-y-zona-de-botones-tapadas.md]
touches_scenes: []
---

## Target
Revisión de PUL-133 (M-2, B-1, B-2, B-3 y observación del producer). Contrato: ADR-005 Enmienda D26 E5 (nota
«Banda superior tapada»). Diseño: `features/controles-tactiles.md`.

## Change
1. **M-2.** `_update_arrow` y `_place_arrow` (`camera_rig.gd`) recortan arriba con la banda tapada cuando
   `respect_top_band`: un inactivo bajo la banda cuenta como fuera de pantalla y la flecha va por debajo de la banda.
2. **Zona de botones.** En `2340x1080-touch-09` (PUL-133) el botón de cambiar tapa el contador N/6 de una caja en el
   pasaplatos del borde este. Tratar el rectángulo de botones (`UiProfile`/`TouchConfig`) como zona tapada en el
   recorte este cuando el objetivo esté en la franja inferior (opción A de la revisión), sin perder encuadre en el
   resto. Si la opción no basta, avisar al producer (opción B: mover widgets del mundo, decisión de diseño).
3. **B-1/B-2/B-3.** Prompt en el bucle tamaños × ollas de `test_camera_top_band.gd`; caso con safe area superior
   no nula; `clamp_focus_covered` centra descontando la banda cuando la vista es mayor que el área.

## Acceptance
- [ ] AC1 Inactivo en la fila de ollas y activo al sur: hay flecha y queda bajo la banda (px reales, 3 resoluciones).
- [ ] AC2 Ningún widget de estación alcanzable (contador N/6, anillos, medidor del cuenco) queda bajo la zona de
  botones con el seguimiento en reposo, a 2340×1080, 1920×1080 y 800×370.
- [ ] AC3 B-1, B-2 y B-3 con test.
- [ ] AC4 Capturas antes/después; `tools/verify.sh` en verde; `check_owns` limpio.

## Plan

## Evidence
