---
id: PUL-029
title: Añadir los cachelos y la olla con varias plazas
status: review
milestone: M1
role: gameplay-engineer
agent: antigravity · gemini-3.1-pro-high (difícil)
deps: [PUL-028, PUL-031]
orca_task: null
unity_sources: []
owns: [godot/resources/seasoning_data.gd, godot/entities/stations/cooking_station.gd, godot/entities/stations/kitchen.tscn, godot/entities/stations/cachelos_storage.tscn, godot/entities/items/**, godot/resources/ingredient_data.gd, godot/data/ingredients/**, godot/data/seasonings/cachelos.tres, godot/core/box_contents.gd, godot/tests/integration/test_cooking_station.gd, godot/tests/integration/test_cachelos.gd, godot/tests/integration/test_box.gd, godot/tests/unit/test_data_*.gd, docs/evidence/PUL-029/**]
touches_scenes: [godot/entities/stations/kitchen.tscn, godot/entities/stations/cachelos_storage.tscn]
---

## Target
M1, decisiones D9 (olla con más de un elemento) y D10 (cachelos se cuecen en la olla y compiten con el pulpo).

## Change
1. Olla con `capacity` en datos (p. ej. 2): cada plaza con su propio progreso y barra; acepta pulpo crudo y
   cachelos crudos; devuelve lo cocido de una plaza por interacción (decide y documenta el orden).
2. `cachelos_storage.tscn` (spawner de cachelos crudos, placeholder de PUL-031).
3. Cachelos cocidos aplicables a una caja llena como condimento (tipo CACHELOS en `SeasoningData` o
   equivalente; `data/seasonings/cachelos.tres`); los crudos se rechazan.
4. El cachelo se consume al aplicarlo (es comida, no un bote).

## Constraints
- Desde M1 manda el diseño (`docs/design/gdd.md`, `features/`, `decisions.md`), no Unity (D17). Donde una feature cite «paridad», prevalecen D8–D10 y D17.
- Capa común (ADR-003 §0) y núcleos `RefCounted` con dependencias inyectadas (ADR-002). Datos de balance en `.tres`.
- Cambios de firma de señales: solo si la ficha lo dice; actualiza `docs/arch/signals.md` en ese caso.
- Antes de cerrar: `tools/verify.sh` en verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio (los hooks de Claude Code no corren en tu agente: el merge gate sí).
- No colocar todavía la cachelera en `level_01.tscn` (lo hace PUL-032).

## Acceptance
- [x] AC1 Olla: dos elementos cociendo a la vez con progreso independiente; pausa los congela; capacidad respetada.
- [x] AC2 Cachelos: crudo → olla → cocido → caja llena: aparece en los condimentos de la caja; crudo rechazado.
- [x] AC3 `condimentacion` AC5 (caja con pimentón, sal, aceite y cachelos = 4 entradas).
- [x] AC4 Captura de la olla con dos plazas en `docs/evidence/PUL-029/`. `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. Se refactorizó `CookingStation` para usar un array de `SlotData` en base a su `capacity`, con progreso y gráficos individuales.
2. Se generó la escena de los cachelos (`cachelos.tscn`) y de su almacén (`cachelos_storage.tscn`).
3. Se actualizó la caja (`box.gd`) para aplicar cachelos cocidos como condimento usando un archivo `.tres`.
4. Se solicitaron permisos al coordinador para actualizar `seasoning_data.gd` y se añadieron tests para validar todos los Criterios de Aceptación.

## Evidence
- Captura de la olla guardada en `docs/evidence/PUL-029/olla_con_dos_plazas.png`.
- Tests añadidos (`test_cachelos.gd` y refactor en `test_cooking_station.gd`).
