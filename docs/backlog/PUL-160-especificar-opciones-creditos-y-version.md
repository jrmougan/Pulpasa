---
id: PUL-160
title: Especificar la pantalla de opciones, los créditos y la versión visible
status: review
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
- [x] AC1 Given `opciones-de-volumen.md` reescrita, When se cuentan sus AC, Then hay ≥ 6, todos Given/When/Then con números
  (fila ≥ 120 px a 1080, paso de slider, valores por defecto) y cada uno nombra su test o captura → tabla AC → prueba en `docs/evidence/PUL-160/README.md`.
- [x] AC2 Given la lista de ajustes candidatos (volumen ×3, idioma, pantalla completa, vsync, tilt-shift, repetir tutorial…), When P2 sigue
  abierta en G0, Then cada candidato figura como **propuesta** con su coste estimado (nº de AC y ficheros) y la elección queda en «Preguntas
  abiertas»; 0 ajustes dados por aprobados sin gate → revisión de la sección en la evidencia.
- [x] AC3 Given `creditos-y-version.md`, When se cruza con `docs/assets/licenses.md`, Then exige 1 entrada por cada licencia de atribución
  (hoy 9 CC BY + OFL), fija el formato del fichero de créditos/`LICENSES.txt` que consumirá PUL-170 y la versión visible en 2 pantallas
  → conteo `grep -c` de `licenses.md` frente a la feature, en la evidencia.
- [x] AC4 Given ambas features, When se buscan valores numéricos, Then cada valor configurable figura en una tabla «Datos (`.tres`)»
  (0 valores solo en prosa) → lista en la evidencia.
- [x] AC5 Given la rama de la ficha, When se ejecutan `tools/verify.sh --quick` y `python3 tools/check_owns.py <rama>`, Then ambos salen con código 0 y 0 rutas fuera de `owns` → salida pegada en `docs/evidence/PUL-160/README.md`.

## Plan
1. Leer el estado: P2/P4 siguen abiertas (G0 sin decidir; `decisions.md` llega a D27), `AudioMix` ya tiene
   `set_volume`/`get_volume` (ADR-006 §2), `render_config.tres` ya tiene `tilt_shift_enabled`, `licenses.md`
   tiene 9 filas CC BY, 4 SIL OFL y 2 MIT con atribución.
2. Reescribir `opciones-de-volumen.md` como pantalla de opciones: núcleo fijo (volumen ×3, apertura,
   navegación, táctil, persistencia) con AC numerados y candidatos de P2 como **propuestas** con coste
   (nº de AC y ficheros) y la elección en «Preguntas abiertas».
3. Nueva `creditos-y-version.md`: fuente única de créditos (`credits.tres`), formato exacto de `LICENSES.txt`
   para PUL-170, tabla fila de `licenses.md` → entrada, versión visible en menú principal y resultados.
4. Tablas «Datos (`.tres`)» con todos los valores configurables; evidencia con conteos `grep -c`,
   revisión de AC2/AC4 y salida de `verify.sh --quick` y `check_owns.py`.

## Evidence
- `docs/evidence/PUL-160/README.md`: tabla AC → prueba (AC1), revisión de candidatos (AC2), conteos `grep -c` y cruce
  fila a fila con `licenses.md` (AC3), lista de valores → tabla «Datos» (AC4), salida de `verify.sh --quick` y
  `check_owns.py` (AC5).
- `opciones-de-volumen.md`: pantalla de opciones con 10 AC del núcleo aprobado (volumen ×3) y 7 ACp condicionados a G0;
  candidatos C1–C9 con coste; preguntas P2, O1–O4 (incluye que «Opciones» en el menú táctil cambia `menu-principal.md` AC6).
- `creditos-y-version.md`: `credits.tres` como fuente única, 17 filas de `licenses.md` → 11 entradas + Godot,
  formato de `LICENSES.txt` y `licenses/` para PUL-170, versión `v` + `config/version` en menú y resultados; 8 AC;
  preguntas C1–C6 y P4.
- Hallazgos: Godot (MIT y componentes) exige aviso en el binario y no estaba previsto; `godot/assets/CREDITS.md`
  desfasado (sin Montserrat, DSEG7, Godot); PUL-170 debe excluir `addons/gut` del export.
