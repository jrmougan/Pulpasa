---
id: PUL-067
title: Retirar placeholders y escalas heredadas tras el arte
status: done
milestone: M3
role: gameplay-engineer
deps: []
orca_task: task_78fd6e3a76fe
unity_sources: []
owns: [godot/scenes/levels/level_01.tscn, godot/scenes/scale_check.tscn, godot/tests/integration/test_level_01.gd, godot/tests/integration/test_scale_check.gd, godot/tests/unit/test_assets_m1.gd, godot/tests/unit/test_assets_audio_ui.gd, godot/assets/models/placeholders/**, godot/assets/models/furniture/Mueblecajas*, godot/assets/models/furniture/order_stand*, godot/entities/items/box.tscn, godot/tests/integration/test_box_model.gd, docs/assets/licenses.md, godot/assets/CREDITS.md, docs/evidence/PUL-067/**, art/blender/order_stand.blend, godot/assets/models/stations/order_stand/**, godot/entities/stations/order_stand.tscn, godot/tests/unit/test_order_stand_model.gd, godot/entities/items/box_model.gd]
touches_scenes: [godot/scenes/levels/level_01.tscn, godot/scenes/scale_check.tscn, godot/entities/items/box.tscn, godot/entities/stations/order_stand.tscn]
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
- [x] AC1 Ningún nodo de `level_01` con escala distinta de 1 en estaciones → test
- [x] AC2 Sin archivos de placeholder sin referencias; licencias al día
- [x] AC3 Captura del nivel igual que antes (sin regresiones visuales) en `docs/evidence/PUL-067/`
- [x] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. `order_stand.blend`: vértices ×(0,78; 0,975; 0,975) y anclas igual; re-exportar `order_stand.glb`. En `order_stand.tscn` colisión, `DeliveryZone`, `OutlineHull` y etiquetas con las dimensiones efectivas de antes (jugabilidad intacta). `level_01`: escala 1. Test: `test_ac1_stations_have_unit_scale`, `test_stand_measures_counter_1_4_by_1_0_without_node_scale`.
2. Retirar placeholders sin referencias (todos salvo `box_small` y `table_square`, usados por `sandbox_item`/`slot`), `Mueblecajas*`, `order_stand.fbx`; recortar `scale_check.tscn` y sus tests; licencias y CREDITS («Retirados»).
3. `box_model.gd`: forma de colisión propia por instancia con el tamaño de cada talla (`collision_size`); `test_collision_matches_the_model_of_each_size`.
4. grep de referencias muertas.

## Evidence
- `tools/verify.sh` verde (644+ tests). Captura del nivel: `docs/evidence/PUL-067/level_01.png` (puestos 1–4 con el mismo tamaño efectivo que antes).
- Ampliado `owns` con aprobación del coordinador: `order_stand.blend`, `order_stand/**`, `order_stand.tscn`, `test_order_stand_model.gd`, `box_model.gd`.
- Mostrador efectivo: 1,36×0,96 m (mismo factor que la escala anterior), ≈ 1,4×1,0.
- Pendiente fuera de owns: materiales `assets/materials/ph_*.tres` (solo los usan los placeholders restantes y `test_assets_m1`) y menciones históricas en `docs/arch` (ADR-003/005, scene-tree.md:297 `condiment_jar`, PUL-066).
