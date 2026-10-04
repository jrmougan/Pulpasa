---
id: PUL-033
title: Cerrar M1 - comandas con cachelos y legibilidad de los cachelos
status: ready
milestone: M1
role: gameplay-engineer
agent: Claude sonnet (kimi y antigravity sin cuota)
deps: []
orca_task: null
unity_sources: []
owns: [godot/data/orders/**, godot/data/recipes/**, godot/entities/items/cachelos.tscn, godot/entities/stations/cachelos_storage.tscn, godot/assets/materials/ph_cachelo_raw.tres, godot/assets/materials/ph_cachelo_cooked.tres, godot/tests/unit/test_data_*.gd, godot/tests/integration/test_m1_flow.gd, godot/tests/integration/test_cachelos.gd, godot/tests/integration/test_level_01.gd, docs/evidence/PUL-033/**]
touches_scenes: [godot/entities/items/cachelos.tscn, godot/entities/stations/cachelos_storage.tscn]
---

## Target
Hallazgos del QA de M1 (PUL-032, `docs/evidence/PUL-032/report.md`).

## Change
1. Catálogo: al menos 2 plantillas con cachelos (feature `comandas.md` AC5: «pulpo+pimentón picante+cachelos»
   y otra con cachelos+sal o aceite), `max_time` 40–90 y `base_points` 8–14 coherentes. Que el catálogo
   siga teniendo ≥ 4 plantillas variadas.
2. `test_m1_flow.gd`: el caso de cachelos usa una comanda del catálogo real (ya no sintética).
3. Legibilidad: el cachelo (crudo y cocido) se ve dentro de la olla junto a un pulpo (malla un poco mayor o
   anclaje elevado) y los colores crudo/cocido se distinguen claramente; test del cambio de material.
4. `cachelos_storage.tscn`: colisión proporcionada al modelo (no excesiva); el recorrido de `test_level_01`
   AC4 sigue alcanzándola.

## Acceptance
- [ ] AC1 Test de datos: ≥ 2 comandas con cachelos y rangos válidos.
- [ ] AC2 `test_m1_flow.gd` entrega una comanda real con cachelos.
- [ ] AC3 Captura de la olla con pulpo y cachelo visibles en `docs/evidence/PUL-033/`.
- [ ] AC4 `tools/verify.sh` (estricto) en verde y `check_owns` limpio.

## Plan

## Evidence
