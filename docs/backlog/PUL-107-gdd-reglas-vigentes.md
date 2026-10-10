---
id: PUL-107
title: Poner al día el GDD §9 (reglas vigentes) con decisions.md y el código
status: ready
milestone: M3c
role: game-designer
deps: []
orca_task: null
unity_sources: []
owns: [docs/design/gdd.md, docs/evidence/PUL-107/**, docs/backlog/PUL-107-gdd-reglas-vigentes.md]
touches_scenes: []
---

## Target
`docs/design/gdd.md` §9 «Reglas vigentes de paridad con Unity» (hallazgo de PUL-106).

## Change
§9 describe defaults del prototipo que ya no rigen: la caja errónea «no penaliza» (D8: se penaliza), «Cocción: sin quemado» (el quemado existe, ADR-006 §5, `set_burnt`). Revisar cada punto de §9 contra `decisions.md` (manda sobre el GDD) y el código de `godot/` (p. ej. capacidad de la olla, asignación por puesto, reposición), corregir lo superado citando la decisión o ficha, y renombrar la sección si ya no trata de paridad (D17).

## Constraints
Solo `gdd.md`. Si un punto contradice `decisions.md` y el código hace otra cosa distinta a ambos, no se decide aquí: se anota en Evidence para el coordinador. Sin tocar `docs/arch/` ni código.

## Acceptance
- [ ] AC1 Cada punto de §9 coincide con `decisions.md` y con el código, con referencia (D-xx, PUL-xxx o ADR)
- [ ] AC2 Las discrepancias que no se pueden resolver solo en el GDD quedan listadas en Evidence

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
