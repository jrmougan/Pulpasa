---
id: PUL-067
title: Retirar placeholders y escalas heredadas tras el arte
status: ready
milestone: M3
role: gameplay-engineer
deps: []
orca_task: null
unity_sources: []
owns: [godot/scenes/levels/level_01.tscn, godot/scenes/scale_check.tscn, godot/tests/integration/test_level_01.gd, godot/tests/integration/test_scale_check.gd, godot/tests/unit/test_assets_m1.gd, godot/tests/unit/test_assets_audio_ui.gd, godot/assets/models/placeholders/**, godot/assets/models/furniture/Mueblecajas*, godot/assets/models/furniture/order_stand*, godot/entities/items/box.tscn, godot/tests/integration/test_box_model.gd, docs/assets/licenses.md, godot/assets/CREDITS.md, docs/evidence/PUL-067/**]
touches_scenes: [godot/scenes/levels/level_01.tscn, godot/scenes/scale_check.tscn, godot/entities/items/box.tscn]
---

## Target
Pendientes del arte de M3 (`roadmap.md`, «Pendientes detectados en el arte»).

## Change
1. Quitar la escala 0,78×0,975 de las instancias `OrderStand` de `level_01.tscn` y ajustar el
   modelo/test para que el puesto mida 1,4×1,0 en el nivel sin escala de nodo (si hace falta tocar
   `order_stand.glb`/`order_stand_model.gd`, pregunta: son de PUL-053).
2. Retirar placeholders sin uso (`cachelera*`, `ph_octopus_*`, `condiment_jar`, etc.),
   `order_stand.fbx` de `scale_check.tscn` y sus comprobaciones en tests; actualizar
   `docs/assets/licenses.md` y `CREDITS.md` (filas de assets retirados → «Retirados»).
3. Colisión del plato grande acorde con el modelo (sin romper `test_box_model`).
4. Busca con `grep` cualquier otra referencia muerta a assets retirados.

## Constraints
- No cambiar posiciones jugables. Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [ ] AC1 Ningún nodo de `level_01` con escala distinta de 1 en estaciones → test
- [ ] AC2 Sin archivos de placeholder sin referencias; licencias al día
- [ ] AC3 Captura del nivel igual que antes (sin regresiones visuales) en `docs/evidence/PUL-067/`
- [ ] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
