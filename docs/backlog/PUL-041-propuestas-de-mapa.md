---
id: PUL-041
title: Proponer dos o tres distribuciones de la cocina
status: ready
milestone: M2
role: game-designer
deps: []
orca_task: null
unity_sources: []
owns: [docs/design/level-layouts.md, docs/design/level-layouts/**, docs/evidence/PUL-041/**]
touches_scenes: []
---

## Target
D19 (playtest de M2): al responsable no le convence la disposición de las estaciones de
`level_01`. Se proponen 2–3 plantas para que elija una.

## Change
`docs/design/level-layouts.md` con 2–3 propuestas. Cada una:
1. Planta con cuadrícula (ASCII o SVG en `docs/design/level-layouts/`) a escala de la cámara
   ortográfica actual: nevera, cachelera, olla(s), estantería de cajas, **estación de condimentos**
   (D18, PUL-040), puestos de entrega 1–4 y salidas de J1/J2.
2. Flujo nevera → olla → caja → corte → condimentos → entrega, con distancias aproximadas y dónde
   se cruzan los jugadores.
3. Qué coordinación provoca en coop y cómo se juega en Individual con cambio de personaje.
4. Riesgos (cuellos de botella, zonas muertas) y temática de romería (pulpería en carpa, etc.).
Una tabla comparativa final y una recomendación.

## Constraints
- Solo documentación. Sin editar escenas.
- Respeta la cámara ortográfica fija (D14) y que los puestos estén visibles en pantalla.

## Acceptance
- [ ] AC1 2–3 plantas legibles con todas las estaciones y salidas
- [ ] AC2 Flujo y distancias de cada propuesta; tabla comparativa y recomendación
- [ ] AC3 Incluye la estación de condimentos de D18

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
