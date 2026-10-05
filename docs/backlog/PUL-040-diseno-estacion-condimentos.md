---
id: PUL-040
title: Diseñar la estación de condimentos y los distintivos de la caja
status: done
milestone: M2
role: game-designer
deps: []
orca_task: task_a3222f975d9a
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
- [x] AC1 Feature con AC verificables y datos en `.tres` identificados
- [x] AC2 Variante coop y variante Individual descritas, con el porqué de cada una
- [x] AC3 Boceto de la estación y de los distintivos (imagen o ASCII) en la feature o en `docs/evidence/PUL-040/`
- [x] AC4 Lista de fichas de implementación propuestas

## Plan
1. Leer D1, D3, D4, D10–D12, D18, `condimentacion.md`, `jugadores-y-cambio.md` y el código actual
   (`box.gd`, `seasoning_item.gd`, `spice_shelf.tscn`, `ticket_entry.gd`, cámara, InputMap) para
   partir de lo que existe y de sus límites (una sola tecla de acción, `size` 12,74 m a 720p).
2. Elegir una mecánica de coordinación que funcione en Individual con el inactivo quieto (D3):
   mostrador de pase con dos lados (dejar/recoger desde los dos; dispensadores solo desde uno).
3. Escribir `estacion-condimentos.md` (interacción, coop/Individual con su porqué, distintivos
   medidos en píxeles, AC Given/When/Then, datos `.tres`, qué desaparece, contratos afectados,
   fichas propuestas, preguntas abiertas) y adaptar `condimentacion.md` (alternar, intercambio de
   pimentón, orden canónico, solo en la estación).
4. Boceto SVG (+ PNG) en `docs/evidence/PUL-040/` y ASCII dentro de la feature.

## Evidence
- Feature: `docs/design/features/estacion-condimentos.md` (18 AC; datos nuevos `SeasoningStationData`,
  `BoxBadgeStyle` y `SeasoningData.sort_order`) → AC1.
- Coop vs Individual con su porqué y alternativas descartadas: sección «Por qué un mostrador de pase
  con dos lados» (AC16–AC17 lo verifican) → AC2.
- Boceto: `docs/evidence/PUL-040/boceto-estacion.svg` (+ `.png`) y ASCII en la feature → AC3.
- 7 fichas propuestas en orden (contratos → núcleo → estación ∥ distintivos ∥ ticket → nivel → QA)
  más PUL-052 de arte → AC4.
- `condimentacion.md` actualizada a D18 (alternar, intercambio de pimentón, solo en la estación).
- Para el producer: AC2 de `condimentacion.md` cambia de «rechaza» a «intercambia» (pregunta abierta
  2, `paprika_swap` en datos); las fichas 1 y 6 necesitan gate humano (contratos) y la planta de
  PUL-041; PUL-052 puede citar los nodos `Tray`, `Dispensers/*` y `CachelosBowl`.
- `tools/verify.sh` verde y `tools/check_owns.py` limpio (ver commit).
