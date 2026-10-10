---
id: PUL-116
title: Re-medir R15/R17 tras D25 y preparar el playtest de M3d
status: todo
milestone: M3d
role: qa-tester
deps: [PUL-115]
orca_task: null
unity_sources: []
owns: [docs/evidence/PUL-116/**, docs/design/m3d-gate.md, godot/tests/tools/**, docs/backlog/PUL-116-qa-d25.md]
touches_scenes: []
---

## Target
Rehacer las mediciones del bot de PUL-102 (`docs/evidence/PUL-102/`) con la caja única de 6 cortes, el aliño de una pulsación y el cubo: R15 (Individual sin cambio, pedido desde cero ≤ 50 m), R17 (Coop, media de pedidos 2–4 ≤ 4,6 s), pulsaciones por comanda, recuperación con el cubo (T7 de `cubo-basura.md`) y umbrales de estrellas 30/60/90 € con los precios nuevos.

## Change
Tabla antes (PUL-102) / después en `docs/evidence/PUL-116/README.md`, capturas, y guía de playtest `docs/design/m3d-gate.md` (25 min, qué mirar y qué decidir: aliño, caja única, cubos, fases, precios, largo del mostrador).

## Acceptance
- [ ] AC1 Tabla de R15, R17, pulsaciones y recuperación con cubo
- [ ] AC2 Propuesta de umbrales de estrellas si cambian
- [ ] AC3 `docs/design/m3d-gate.md`
- [ ] AC4 `tools/verify.sh` en verde

## Plan

## Evidence
