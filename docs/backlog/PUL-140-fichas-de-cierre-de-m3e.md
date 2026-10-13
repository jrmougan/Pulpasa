---
id: PUL-140
title: Crear las fichas de cierre de M3e (guía de playtest y export Android)
status: in_progress
milestone: M3e
role: game-designer
deps: []
orca_task: null
unity_sources: []
owns: [docs/backlog/PUL-15[0-4]-*.md, docs/evidence/PUL-140/**, docs/backlog/PUL-140-fichas-de-cierre-de-m3e.md]
touches_scenes: []
---

## Target
El cierre de M3e (D26, `docs/design/roadmap.md`): falta la guía del playtest humano (no existe
`docs/design/m3e-gate.md`; hay modelos en `m3c-gate.md` y `m3d-gate.md`) y la ficha futura del export
Android y el renderizador móvil (alcance de la alpha, punto 11), que debe incluir comprobar en teléfono la
limitación aceptada D27.3 (safe area inferior de 63 px). Diseño vigente: `docs/design/decisions.md`
(D26, D27), `features/controles-tactiles.md` y las fichas PUL-119..138.

## Change
Fichas `draft` con ids **PUL-150 a PUL-154**, formato de `_TEMPLATE.md`, por ejemplo:
1. Escribir `docs/design/m3e-gate.md`: guion del playtest del lenguaje de acciones en PC (y la parte de
   teléfono, condicionada al export), con qué mirar, qué medir y cómo anotar los resultados.
2. Export Android y renderizador móvil: toolchain, preset, renderizador, prueba en dispositivo real, y la
   comprobación de D27.3 y de los criterios de `controles-tactiles.md` que solo se ven en teléfono.
   Estado `blocked` con el motivo (falta toolchain y dispositivo).
3. Lo que encuentres al repasar D26/D27 que quede sin ficha (por ejemplo, criterios marcados para el
   playtest o para el teléfono).
Resumen en `docs/evidence/PUL-140/README.md`: qué fichas creas y por qué.

## Constraints
- Solo crear fichas y el resumen: **no escribas** la guía ni código.
- **No edites** `docs/backlog/README.md`, `docs/design/roadmap.md` ni otros docs de diseño: los
  actualiza el coordinador. Usa solo los ids PUL-150..154.
- Cada AC con números y su test o captura; `owns` mínimos sin solaparse entre fichas.

## Acceptance
- [ ] AC1 Ficha de la guía `m3e-gate.md` y ficha `blocked` del export Android con D27.3 incluida.
- [ ] AC2 `docs/evidence/PUL-140/README.md` lista las fichas y lo revisado de D26/D27.
- [ ] AC3 `tools/verify.sh --quick` en verde; `check_owns` limpio.

## Plan
(Lo escribe el worker antes de empezar.)

## Evidence
(Lo rellena el worker.)
