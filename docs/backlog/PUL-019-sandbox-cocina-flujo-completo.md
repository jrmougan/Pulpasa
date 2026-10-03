---
id: PUL-019
title: Montar el sandbox de cocina y probar el flujo completo
status: review
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
- [x] AC1 El flujo completo produce exactamente 1 `order_completed` y el puesto recibe comanda nueva → `test_kitchen_flow.gd`.
- [x] AC2 Una caja con condimentos de menos se rechaza; con condimentos de más se acepta (paridad B15) → `test_kitchen_flow.gd`.
- [x] AC3 Partida manual vía MCP con capturas de cada paso en `docs/evidence/PUL-019/` y un informe AC → resultado. `tools/verify.sh` en verde.

## Plan
1. Escena del sandbox generada con un script tipado propio (fuera del repo) y limpiada a mano; el
   script del sandbox va embebido en la `.tscn` porque `owns` no incluye un `.gd`.
2. Test de integración sobre la escena con los autoloads reales (`rng_seed` fijo).
3. Dos sesiones MCP con `simulate_input` + capturas; informe en `docs/evidence/PUL-019/report.md`.

## Evidence
Informe completo: `docs/evidence/PUL-019/report.md`.

| AC | Resultado | Evidencia |
|---|---|---|
| AC1 | Pasa | `test_kitchen_flow.gd::test_ac1_…`; MCP s2: `order_completed(#1, slot 1)` → `order_generated(#3, slot 1)`, `s2-02-ac1-entregada-puesto-1-comanda-nueva-3.png` |
| AC2 | Pasa | `test_kitchen_flow.gd::test_ac2_…` (de menos → `delivery_rejected`; de más → `order_completed`); MCP s2: rechazo con solo sal, `s2-01-ac2-rechazo-falta-pimenton.png`. «De más» solo verificado por test |
| AC3 | Pasa | Capturas `s1-00`…`s1-07` (la ronda de 180 s terminó antes de entregar) y `s2-01`, `s2-02`; `tools/verify.sh` → `✓ verify OK` (328/328); 0 errores en `get_debug_output` |

Observaciones para triage (no se tocó código ajeno): el detector prefiere botes y objetos sueltos
a un slot de especia vacío; `round_config.tres` dura 180 s y `scene-tree.md` dice 300 (D5); color
de la caja pequeña frente al de su cajón; `verify.sh` analiza los temporales de `godot/.mcp/`.
