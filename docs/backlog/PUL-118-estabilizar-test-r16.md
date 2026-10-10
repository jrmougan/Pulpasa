---
id: PUL-118
title: Estabilizar test_level_01_r16 (intermitente bajo carga)
status: todo
milestone: M3d
role: gameplay-engineer
deps: [PUL-115]
orca_task: null
unity_sources: []
owns: [godot/tests/integration/test_level_01_r16.gd, godot/tests/integration/level_walker.gd, docs/evidence/PUL-118/**, docs/backlog/PUL-118-estabilizar-test-r16.md]
touches_scenes: []
---

## Target
`godot/tests/integration/test_level_01_r16.gd`, en especial `test_r16_single_with_switch_two_s_orders_one_octopus_two_switches`: falla de forma intermitente (espera 2 `order_completed` y llega 1). Visto en el verify de un worker de PUL-105, en un merge gate de PUL-111 (2026-10-10) y en el verify de PUL-112; pasa al repetir.

## Change
Encontrar la causa (dependencia del tiempo real o de frames, esperas por tiempo de reloj, carga de CPU con varias instancias de Godot, orden de físicas, aleatoriedad sin semilla) y hacer el test determinista sin debilitar lo que comprueba (R16). Si la causa está en el juego y no en el test, no se arregla aquí: se documenta y se avisa al coordinador.

## Constraints
- No reducir el número de comandas ni quitar aserciones para que pase.
- Prueba de estabilidad: ejecutar el fichero ≥ 20 veces seguidas (y alguna vez con otro proceso de Godot cargando la CPU) sin fallos; dejar el comando y el resultado en Evidence.
- `tools/verify.sh` en verde.

## Acceptance
- [ ] AC1 Causa documentada en Evidence
- [ ] AC2 20 ejecuciones seguidas sin fallos
- [ ] AC3 `tools/verify.sh` en verde

## Plan

## Evidence
