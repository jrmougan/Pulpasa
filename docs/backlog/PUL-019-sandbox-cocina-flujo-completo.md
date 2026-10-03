---
id: PUL-019
title: Montar el sandbox de cocina y probar el flujo completo
status: ready
milestone: M0
role: qa-tester
deps: [PUL-017, PUL-018]
orca_task: null
unity_sources: [Assets/Scenes/Levels/Level_01.unity]
owns: [godot/scenes/sandbox/kitchen_sandbox.tscn, godot/scenes/sandbox/kitchen_sandbox.tscn.uid, godot/tests/integration/test_kitchen_flow.gd, godot/tests/integration/test_kitchen_flow.gd.uid, docs/evidence/PUL-019/**]
touches_scenes: [godot/scenes/sandbox/kitchen_sandbox.tscn]
---

## Target
Cierre de la fase 6 de M0: verificación "flujo completo = comanda completada una vez" (`docs/design/roadmap.md`).

## Change
1. `kitchen_sandbox.tscn`: jugador, cámara, nevera, olla, estanterías de cajas y especias, un slot
   libre y dos puestos de entrega, con `OrderService.setup` + `RoundManager.start_round` llamados
   desde un script mínimo del sandbox (el `level.gd` genérico es de la fase 8).
2. `test_kitchen_flow.gd`: recorre el flujo con llamadas de interacción (sin física de movimiento):
   nevera → olla → esperar cocción → caja → llenar → condimentos de la comanda → entrega.
3. Sesión con el MCP (`simulate_input`) jugando el flujo de verdad, con capturas de cada paso.

## Constraints
- Rol QA: no corrijas código de otras fichas. Si algo falla, documenta el fallo con evidencia y
  escala al coordinador.

## Acceptance
- [ ] AC1 El flujo completo produce exactamente 1 `order_completed` y el puesto recibe comanda nueva → `test_kitchen_flow.gd`.
- [ ] AC2 Una caja con condimentos de menos se rechaza; con condimentos de más se acepta (paridad B15) → `test_kitchen_flow.gd`.
- [ ] AC3 Partida manual vía MCP con capturas de cada paso en `docs/evidence/PUL-019/` y un informe AC → resultado. `tools/verify.sh` en verde.

## Plan

## Evidence
