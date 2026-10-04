---
id: PUL-032
title: Integrar las novedades de M1 en level_01 y pasar el QA de M1
status: review
milestone: M1
role: qa-tester
agent: kimi (media)
deps: [PUL-030]
orca_task: null
unity_sources: []
owns: [godot/scenes/levels/level_01.tscn, godot/tests/integration/test_level_01.gd, godot/tests/integration/test_m1_flow.gd, godot/tests/integration/test_m1_flow.gd.uid, godot/tests/integration/test_cooking_station.gd, docs/evidence/PUL-032/**]
touches_scenes: [godot/scenes/levels/level_01.tscn]
---

## Target
Cierre de M1: las mecánicas de PUL-027/028/029 y la UI de PUL-030 jugables en `level_01`.

## Change
1. `level_01.tscn`: añade la cachelera (`cachelos_storage.tscn`) junto a la nevera, alcanzable por el jugador
   (el recorrido de `test_level_01.gd` AC4 debe incluirla). Comprueba que la estantería de especias de 4
   botes y la olla de 2 plazas caben y son alcanzables.
2. `test_m1_flow.gd`: partida M1 con datos reales: comanda con aceite y cachelos (cocer cachelos en la olla
   junto a un pulpo, aplicarlos), entrega con bonus por tiempo, una caducidad (−3), una caja errónea (−2),
   recaudación final y estrellas en el game over.
3. Pendientes de M1 del roadmap: test FIFO discriminante (A en plaza 0, B en plaza 1 a t=2,5, recoger A, C en
   plaza 0 → sale B) en `test_cooking_station.gd`.
4. Partida manual vía MCP con capturas de cada paso e informe `docs/evidence/PUL-032/report.md`.

## Constraints
- Rol QA: no corrijas código de otras fichas; documenta y escala con `orca ask`.
- `.tscn` con script tipado; no inventes uid.

## Acceptance
- [ ] AC1 La cachelera está en el nivel y el recorrido AC4 la alcanza → `test_level_01.gd`.
- [ ] AC2 `test_m1_flow.gd` cubre aceite, cachelos, bonus, caducidad, caja errónea y estrellas con datos reales.
- [ ] AC3 Test FIFO discriminante.
- [ ] AC4 Informe con capturas de una partida M1 manual. `tools/verify.sh` (estricto) en verde, `check_owns` limpio.

## Plan

## Evidence
