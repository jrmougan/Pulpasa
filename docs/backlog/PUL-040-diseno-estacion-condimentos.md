---
id: PUL-040
title: Diseñar la estación de condimentos y los distintivos de la caja
status: ready
milestone: M2
role: game-designer
deps: []
orca_task: null
unity_sources: []
owns: [docs/design/features/condimentacion.md, docs/design/features/estacion-condimentos.md, docs/evidence/PUL-040/**]
touches_scenes: []
---

## Target
D18 (playtest de M2): los botes de condimentos son incómodos. Se sustituyen por una **estación de
condimentos** a la que se lleva la caja; la caja muestra **distintivos** (pegatinas, como en la
comida rápida) con lo que lleva. El responsable quiere que **fuerce la coordinación** entre
jugadores.

## Change
Feature nueva `docs/design/features/estacion-condimentos.md` (formato de las demás features:
descripción, AC Given/When/Then verificables, datos en `.tres`, verificación) y actualización de
`condimentacion.md`. Debe concretar:
1. Interacción: dejar la caja en la estación, elegir condimento (pimentón dulce/picante
   exclusivos, sal, aceite, cachelos: D4, D10), quitar un condimento puesto por error o no.
2. Mecánica de coordinación en coop (p. ej. estación con dos lados, uno por jugador; o un jugador
   opera la estación mientras otro trae la caja) **y** cómo se juega en modo Individual con
   cambio de personaje (D3), sin hacerlo imposible.
3. Distintivos: qué se ve en la caja (icono por condimento, posición, legibilidad a la distancia de
   la cámara ortográfica) y cómo casa con los iconos del ticket.
4. Qué desaparece (botes, `SpiceShelf`, slots) y qué datos nuevos hacen falta.
5. Lista de fichas de implementación propuestas (gameplay, UI, nivel) con su orden.

## Constraints
- Solo documentación. No tocar código ni `decisions.md` (lo hace el producer).
- Coherente con D1 (corte sobre la caja), D4, D10, D12.

## Acceptance
- [ ] AC1 Feature con AC verificables y datos en `.tres` identificados
- [ ] AC2 Variante coop y variante Individual descritas, con el porqué de cada una
- [ ] AC3 Boceto de la estación y de los distintivos (imagen o ASCII) en la feature o en `docs/evidence/PUL-040/`
- [ ] AC4 Lista de fichas de implementación propuestas

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
