---
id: PUL-160
title: Especificar la pantalla de opciones, los créditos y la versión visible
status: draft
milestone: M4
role: game-designer
deps: []
orca_task: null
unity_sources: []
owns: [docs/design/features/opciones-de-volumen.md, docs/design/features/creditos-y-version.md, docs/evidence/PUL-160/**, docs/backlog/PUL-160-especificar-opciones-creditos-y-version.md]
touches_scenes: []
---

## Target
Should «opciones de volumen» (`features/opciones-de-volumen.md`, 4 AC sin UI ni persistencia todavía;
`AudioDirector.set_volume` ya existe, ADR-006 §2) y lo que la alpha necesita para publicarse: créditos con
las atribuciones de `docs/assets/licenses.md` (hay assets CC BY, que exigen atribución) y la versión visible.

## Change
1. Reescribir `opciones-de-volumen.md` como feature de **pantalla de opciones**: qué ajustes hay (los que
   decida el responsable, pregunta P2 del plan de M4), desde dónde se abre (menú principal y pausa), cómo se
   navega con teclado, mando y táctil (≥ 120 px de alto por fila a 1080, `controles-tactiles.md`), valores por
   defecto en `.tres` y persistencia en `user://settings.cfg`.
2. Nueva `features/creditos-y-version.md`: pantalla de créditos (equipo, herramientas, cada asset de
   `licenses.md` con autor, licencia y enlace), versión visible en el menú principal y en los resultados.
3. AC Given/When/Then con números, cada uno con su test GUT o captura.

## Constraints
- Solo `docs/design/`: no se toca código ni contratos (los fija PUL-163).
- No se supone el alcance de las opciones: si P2 sigue abierta, la feature lista las opciones candidatas
  con su coste y deja la elección en «Preguntas abiertas».

## Acceptance
- [ ] AC1 `opciones-de-volumen.md` cubre ajustes, acceso, navegación en los 3 perfiles de entrada, valores por
  defecto y persistencia, con ≥ 6 AC numéricos y su test.
- [ ] AC2 `creditos-y-version.md` exige una entrada por cada asset con licencia de atribución de `licenses.md`
  (test que cruza el registro con la pantalla) y la versión de `config/version` visible.
- [ ] AC3 Datos que van a `.tres` listados en cada feature; preguntas abiertas explícitas.
- [ ] AC4 `tools/verify.sh --quick` en verde; `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
