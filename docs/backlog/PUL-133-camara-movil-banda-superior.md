---
id: PUL-133
title: Cámara móvil que respeta la banda superior; aro inactivo fino en móvil; game over sin cajas/minuto
status: in_progress
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
- [ ] AC1 A 2340×1080, 1920×1080 y 800×370 `--touch`, con el personaje activo en cualquier plaza de olla, el
  anillo de cocción, su prompt y el personaje quedan enteros por debajo de la banda superior y dentro de la
  safe area (test con medidas en px reales, no solo de canvas).
- [ ] AC2 Ningún punto alcanzable del suelo queda tapado por la banda con el seguimiento en reposo (test que
  recorre los bordes del área de juego).
- [ ] AC3 Aro inactivo ≤ 3 px y activo ≥ 8 px de trazo a 1080 en perfil móvil y en escritorio (test con las dos cámaras).
- [ ] AC4 Game over sin la línea de cajas/minuto; test.
- [ ] AC5 Capturas antes/después en `docs/evidence/PUL-133/` (al menos `touch-09` equivalente a 2340×1080 y 800×370).
- [ ] AC6 `tools/verify.sh` completo en verde; `check_owns` limpio.

## Plan

## Evidence
