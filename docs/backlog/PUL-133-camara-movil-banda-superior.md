---
id: PUL-133
title: Cámara móvil que respeta la banda superior; aro inactivo fino en móvil; game over sin cajas/minuto
status: done
milestone: M3e
role: gameplay-engineer
deps: [PUL-132]
orca_task: null
unity_sources: []
owns: [godot/entities/camera/camera_rig.gd*, godot/entities/camera/camera_rig.tscn, godot/core/camera_follow.gd*, godot/resources/camera_profile.gd*, godot/data/config/camera_mobile.tres, godot/data/config/camera_desktop.tres, godot/tests/unit/test_camera*, godot/tests/integration/test_camera*, godot/entities/player/player.tscn, godot/entities/player/player.gd*, godot/tests/*/test_player_ring.gd*, godot/ui/menus/game_over.gd*, godot/ui/menus/game_over.tscn, godot/tests/*/test_game_over.gd*, godot/tests/integration/test_level_01.gd*, godot/tests/integration/test_d26_touch_flow.gd*, docs/evidence/PUL-133/**, docs/backlog/PUL-133-camara-movil-banda-superior.md]
touches_scenes: [godot/entities/camera/camera_rig.tscn, godot/entities/player/player.tscn, godot/ui/menus/game_over.tscn]
---

## Target
Hallazgos del QA de D26 (`docs/backlog/PUL-132-qa-de-d26.md`, Evidence; capturas en `docs/evidence/PUL-132/`).
Diseño: `docs/design/features/controles-tactiles.md` (cámara móvil, banda superior) y
`lenguaje-acciones.md` (estado legible en el mundo). Contrato: ADR-005 Enmienda D26 (cámara, E4 banda
superior), `scene-tree.md` §9.4.

## Change
1. **H-01 (Alta).** En el perfil móvil la fila trasera de la cocina (ollas) y el personaje que está en ella
   quedan bajo la banda superior de HUD + tickets (`2340x1080-touch-09-aviso-de-quemado.jpg`: anillo de la
   olla en y = −65 px). La cámara móvil debe tratar la banda superior (y la safe area) como zona tapada:
   el foco se calcula sobre la parte visible de la pantalla y el límite del área de juego permite desplazar
   la vista lo bastante para que todo objetivo alcanzable (ollas incluidas, su anillo y su prompt) quede por
   debajo de la banda. Alto de la banda desde datos/perfil de UI (no números mágicos en código).
2. **H-02 (Media).** `%InactiveIndicator` mide 4,6 px de trazo a 1080 con la cámara móvil (máx. 3 px,
   `controles-tactiles.md`/D26.6). El grosor en pantalla no debe depender del zoom: escalar con el tamaño
   de la cámara activa (como `WorldProgressRing`) o alternativa equivalente; activo ≥ 8 px en ambos perfiles.
3. **H-03 (Baja).** Game over sin «Rendimiento: … cajas/minuto» (D26.7, texto vigente con D25: la métrica es
   la recaudación). El dato sigue en `RoundResult`.

## Constraints
- Solo `owns`/`touches_scenes`. Si rompe un test fuera, para y avisa al producer.
- Tipado estático, datos en `.tres`, lógica pura en `core/camera_follow.gd` con tests unitarios.
- No inventes `uid://`.
- El perfil de escritorio (cámara fija) no cambia de encuadre.

## Acceptance
- [x] AC1 A 2340×1080, 1920×1080 y 800×370 `--touch`, con el personaje activo en cualquier plaza de olla, el
  anillo de cocción, su prompt y el personaje quedan enteros por debajo de la banda superior y dentro de la
  safe area (test con medidas en px reales, no solo de canvas).
- [x] AC2 Ningún punto alcanzable del suelo queda tapado por la banda con el seguimiento en reposo (test que
  recorre los bordes del área de juego).
- [x] AC3 Aro inactivo ≤ 3 px y activo ≥ 8 px de trazo a 1080 en perfil móvil y en escritorio (test con las dos cámaras).
- [x] AC4 Game over sin la línea de cajas/minuto; test.
- [x] AC5 Capturas antes/después en `docs/evidence/PUL-133/` (al menos `touch-09` equivalente a 2340×1080 y 800×370).
- [x] AC6 `tools/verify.sh` completo en verde; `check_owns` limpio.

## Plan
- `core/camera_follow.gd`: `covered_focus`, `clamp_focus_covered`, `visible_top` (puros). Test: `tests/unit/test_camera_follow_math.gd` (AC1/AC2 en lógica).
- `resources/camera_profile.gd` + `camera_mobile.tres`: `respect_top_band`, `top_reach_height_m` (2,6 m). Escritorio sin cambios (defaults).
- `camera_rig.gd`: `top_cover_m()` (safe area superior + `UiProfile.top_band_max_px`, 200 px a 1080) y `top_reach_m()`; el foco se calcula sobre la parte visible.
- `player.gd`: trazo de aros constante en pantalla (`active_ring_px_1080` 10, `inactive_ring_px_1080` 2,5); malla propia por personaje. Test AC3: `test_player_ring.gd`.
- `game_over.gd`: oculta `ratio`. Test AC4: `test_game_over.gd`.
- AC1/AC2: `tests/integration/test_camera_top_band.gd` (level_01 real, 3 resoluciones, px reales, ollas, anillo, prompt, bordes del área). `test_camera_follow.gd` adaptado al nuevo foco.

## Evidence
- `bash tools/verify.sh` verde (1321 tests, smoke OK); `check_owns` limpio.
- Antes/despues (px reales; fuente `docs/evidence/PUL-132/*-medidas.json` y `docs/evidence/PUL-133/*-medidas.json`):

| Medida | 2340x1080 antes | despues | 800x370 antes | despues |
|---|---|---|---|---|
| Anillo de olla, centro y (banda = 174 px a 1080) | -65,3 | 299,2 | -22,4 | 102,5 |
| Aro inactivo (px a 1080) | 4,6 | 2,5 | 4,6 | 2,5 |
| Aro activo (px a 1080) | 18,5 | 10,0 | 18,5 | 10,0 |
| Cocinero (px) | 194,5 | 194,5 | 66,6 | 66,6 |

- Capturas `docs/evidence/PUL-133/<tag>-touch-{01,07,09,10,13}`: antes en `docs/evidence/PUL-132/`. En `09` la olla con su anillo y el prompt quedan bajo los tickets; `13` sin «cajas/minuto».
- Reproducir: `godot --path godot --resolution 2340x1080 --position 0,0 -s ../docs/evidence/PUL-132/capture_boot.gd -- --touch --safe --out=<dir> --tag=<tag>`.
- Desviaciones: la banda usa `top_band_max_px` (200) y no los 174 reales, por prudencia (26 px de holgura). El aro activo baja de 18,5 a 10 px en movil (sigue >= 8). Los tests de camara existentes (`test_camera_follow.gd`) se adaptaron: el foco ya no coincide con el personaje, sino con el centro de la parte visible.
