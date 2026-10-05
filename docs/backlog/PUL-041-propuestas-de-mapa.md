---
id: PUL-041
title: Proponer dos o tres distribuciones de la cocina
status: review
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
- [x] AC1 2–3 plantas legibles con todas las estaciones y salidas
- [x] AC2 Flujo y distancias de cada propuesta; tabla comparativa y recomendación
- [x] AC3 Incluye la estación de condimentos de D18

## Plan
1. Medir el encuadre real de la cámara (`camera_rig.tscn`) y las zonas tapadas por tickets y HUD
   para fijar una cuadrícula de 1 m que quepa en pantalla.
2. Dibujar tres conceptos distintos: U con isla (evolución de la actual), barra partida
   (coordinación forzada) y espejo (dos cocinas con centro compartido), todos con la estación de
   condimentos de D18 y sin `SpiceShelf`.
3. Generar los SVG y las distancias con un script (`gen_layouts.py`): recorrido más corto sobre la
   cuadrícula respetando mostradores, por tramo, por pedido y por rol.
4. Redactar flujo, cruces, coop/Individual, riesgos y temática; tabla comparativa y recomendación (B).

## Evidence
- `docs/design/level-layouts.md`: tres plantas (ASCII + SVG), flujo con distancias, coop/Individual,
  riesgos, temática, comparativa y recomendación (**B · Barra partida**; alternativa A).
- `docs/design/level-layouts/planta-{a,b,c}.svg` y `gen_layouts.py` (reproducible).
- `docs/evidence/PUL-041/`: PNG de las tres plantas y `distancias.md` (salida del script).
- AC1: las tres plantas tienen nevera, cachelera, 2 ollas, cajas, mesas de corte, estación de
  condimentos, puestos 1–4 y salidas J1/J2 dentro del encuadre. AC2: flujo y distancias por
  propuesta, más dos tablas comparativas y la recomendación. AC3: la estación `C` (D18) aparece en
  las tres y su número de caras queda como pregunta abierta para PUL-040.
- Solo documentación; no se tocan escenas.
