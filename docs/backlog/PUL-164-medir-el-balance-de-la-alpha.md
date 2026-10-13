---
id: PUL-164
title: Medir el balance de la alpha con el bot y proponer valores
status: in_progress
milestone: M4
role: qa-tester
deps: []
orca_task: null
unity_sources: []
owns: [godot/tests/tools/balance_*.gd*, docs/evidence/PUL-164/**, docs/backlog/PUL-164-medir-el-balance-de-la-alpha.md]
touches_scenes: []
---

## Target
Balance pendiente de M3/M3d: `order_2` en fase 3 (80 s × 0,7 = 56 s) frente a ~54 s de ruta óptima
(PUL-070); umbrales de estrellas 30/60/90 € con un bot que recauda 150–195 € (propuesta 40/90/150 €,
`m3d-gate.md`); límites de fase en tercios (`dificultad-progresiva.md`, pregunta 1); `presses_to_fill` = 6 y
precios de las 4 recetas provisionales (GDD §11, preguntas 1, 5, 7). Datos en `round_config.tres` y `data/orders/`.
Medidas previas en `docs/evidence/PUL-116/`.

## Change
1. Con el bot de rutas (`godot/tests/tools/`, `level_walker.gd`), medir con el estado actual (D26/D27) en
   Individual y Local 2P: tiempo por receta desde cero y en flujo, holgura de cada receta frente a su
   paciencia en cada fase, recaudación en 300 s y estrellas obtenidas.
2. Proponer una tabla de valores (umbrales, multiplicadores de paciencia, límites de fase, precios) con el
   efecto esperado de cada cambio, y lo que solo puede decidir un playtest humano.

## Constraints
- No se cambian datos (`.tres`) ni código de juego: la propuesta pasa por el responsable (gate) y la aplica PUL-166.
- Las herramientas de medida no entran en `verify.sh` (no son tests).

## Acceptance
- [ ] AC1 Given el bot de rutas sobre el estado actual (D26/D27), When se mide cada receta (4) en cada fase donde existe, Then hay tabla
  con tiempo del bot (s), paciencia (s) y holgura (s), y toda holgura < 5 s aparece marcada → tabla + JSON en `docs/evidence/PUL-164/`.
- [ ] AC2 Given 3 semillas por modo (Individual, Local 2P), When se juegan 300 s con el bot, Then se registran recaudación (€), entregas y
  estrellas con los umbrales actuales 30/60/90 → JSON y tabla en la evidencia.
- [ ] AC3 Given la propuesta de valores, When se presenta al gate G2, Then cada valor (umbrales, multiplicadores, límites de fase, precios,
  `presses_to_fill`) tiene antes, después y efecto esperado numérico (holgura o € previstos) → tabla en la evidencia.
- [ ] AC4 Given la rama de la ficha, When se ejecutan `tools/verify.sh --quick` y `python3 tools/check_owns.py <rama>`, Then ambos salen con código 0 y 0 rutas fuera de `owns` → salida pegada en `docs/evidence/PUL-164/README.md`.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
