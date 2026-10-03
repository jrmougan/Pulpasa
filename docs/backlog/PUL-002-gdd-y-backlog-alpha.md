---
id: PUL-002
title: Escribir el GDD de trabajo y el backlog de la alpha
status: ready
milestone: F0
role: game-designer
deps: []
orca_task: null
unity_sources: []
owns: [docs/design/gdd.md, docs/design/features/**]
touches_scenes: []
---

## Target
GDD original en `/home/jeromo/vibedora/dev/pulpasa_docs/main.tex` (gallego, solo lectura) y
`docs/design/decisions.md`.

## Change
1. `docs/design/gdd.md` en castellano: resumen operativo del GDD aplicando D1–D7 y corrigiendo
   erratas (regla «atacar enemigos», objetivo del nivel confuso).
2. `docs/design/features/<slug>.md` por cada feature Must y Should de la alpha, con criterios
   de aceptación verificables (Given/When/Then) y números concretos.

## Constraints
No tocar `main.tex`. No crear fichas de backlog (eso lo hace el producer a partir de features/).
Alcance según la propuesta: Must/Should/Could/Won't.

## Acceptance
- [ ] AC1 Cada decisión D1–D7 está reflejada en el GDD de trabajo.
- [ ] AC2 Hay una feature por cada Must (8) con al menos 2 criterios medibles.
- [ ] AC3 Lista de preguntas abiertas al final de gdd.md, si las hay.

## Plan

## Evidence
