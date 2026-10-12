---
id: PUL-134
title: Flecha de borde y zona de botones como zonas tapadas en la cámara móvil
status: in_progress
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
- [x] AC1 Inactivo en la fila de ollas y activo al sur: hay flecha y queda bajo la banda (px reales, 3 resoluciones).
- [x] AC2 (opción C, decisión del responsable) Con el activo en reposo en la plaza de cada estación con widget
  (contador N/6 de cada pasaplatos, anillos de cada olla, medidor del cuenco), ningún widget de esa estación ni el
  propio activo quedan bajo la zona de botones, a 2340×1080, 1920×1080 y 800×370. El caso 09 (caja ajena lejos del
  activo) queda documentado como limitación para una ficha de diseño (opción B).
- [x] AC3 B-1, B-2 y B-3 con test.
- [x] AC4 Capturas antes/después; `tools/verify.sh` en verde; `check_owns` limpio.

## Plan
- `entities/camera/camera_rig.gd`: `_top_cover_units` (safe area superior + `top_band_max_px`, 0 sin
  `respect_top_band`) compartido por `top_cover_m`, `_update_arrow` (un inactivo bajo la banda cuenta como fuera
  de cuadro) y `_place_arrow` (el rectángulo de la flecha empieza bajo la banda). Recorte este: si los pies del
  activo, con el foco ya recortado, caen en la franja de botones (`y > button_zone_top`), `clear_east_cover`.
  Sin campos nuevos en `CameraProfile` (va con `respect_top_band`, solo móvil); sin señales nuevas.
- `core/camera_follow.gd`: `clear_east_cover` (puro) mueve el foco al este lo justo para dejar el objetivo (+
  media anchura y 16 px) a la izquierda de la zona, con la vista hasta `margin + ancho de la zona` fuera del
  límite este; si no hace falta, no toca el foco. B-3: `clamp_focus_covered` centra la parte visible
  (`mid − cover/2`) cuando la vista es mayor que el área.
- Tests: AC1 → `test_camera_top_band.gd::test_m2_arrow_for_inactive_hidden_under_the_band` (3 tamaños × safe
  superior 0/80 × 2 ollas). AC2 → `test_camera_button_zone.gd` (widgets desde su plaza, activo en el borde este,
  encuadre sin cambios fuera de la franja) y unit `test_clear_east_cover_*`. AC3 → B-1
  `test_ac1_prompt_icons_stay_below_the_band_at_every_pot` (tamaños × ollas × plazas), B-2
  `test_b2_ring_and_character_clear_the_band_with_top_safe_area`, B-3
  `test_covered_clamp_centers_when_view_is_larger_than_area`.

## Evidence
- Detalle, medidas y capturas: `docs/evidence/PUL-134/README.md` (`<res>-{antes,despues}-0{1..4}-*.jpg` y
  `*-medidas.json`; script `capture_pul134.gd`).
- AC1 (px reales): sin M-2 no había flecha con el inactivo tapado (centro en y = 2 px); ahora hay flecha con su
  borde superior en y = 232 px a 2340×1080 y 1920×1080 (banda 200) y 100,5 px a 800×370 (banda 68,5). El test
  falla con el código anterior (flecha en y = 0).
- AC2: 0 cruces en las 3 resoluciones con el activo en la plaza de cada estación. Activo en (9,4, 3,0): borde
  derecho 2242,6 → 1913,0 px (zona en x ≥ 1950) a 2340; 1823,2 → 1493,7 (≥ 1530) a 1920; 766,3 → 653,4 (≥ 666) a
  800×370.
- Limitación (opción B, ficha de diseño posterior): caso 09, activo en las ollas y caja en los pasaplatos del
  este. Contador bajo los botones en los pasaplatos 04-06 a 2340×1080 y 800×370, y en el 04 a 1920×1080.
- AC3: B-1, B-2 y B-3 con test; los tests de B-3 y M-2 fallan con el código anterior.
- `tools/verify.sh` verde; `tools/check_owns.py` limpio.
- Desviación: `test_camera_follow.gd::test_view_never_leaves_level_margin` admite ahora que la vista salga por el
  este el ancho de la zona de botones (efecto buscado de la opción A). Con el activo pegado al este y a media
  altura, la esquina superior derecha enseña el exterior del nivel (captura `02`).
