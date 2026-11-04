---
id: PUL-197
title: Aplicar las decisiones del gate de enmiendas a los contratos
status: done
milestone: M4
role: godot-architect
deps: []
orca_task: null
unity_sources: []
owns: [docs/arch/ADR-002-*.md, docs/arch/ADR-003-*.md, docs/arch/ADR-004-*.md, docs/arch/ADR-005-*.md, docs/arch/ADR-006-*.md, docs/arch/signals.md, docs/arch/scene-tree.md, docs/arch/README.md, docs/arch/gate-enmiendas.md, docs/design/decisions.md, docs/design/features/audio-y-fx.md]
touches_scenes: []
---

## Target
Contratos de `docs/arch`, T3 de `decisions.md` y AC2 de `audio-y-fx`.

## Change
Gate humano del responsable, 2026-11-04, sobre `docs/arch/gate-enmiendas.md`:
- **Tabla**: «Aplicar todas». Cada fila se acepta como recomienda, con sus cambios de texto. Incluye ratificar D23 (G49, G55) y que `presses_to_fill` = 6 deje de ser provisional (G11).
- **Rechazo tras caducar (G22, G51)**: «Corregir el guard». El contrato no se matiza; el código lo corrige PUL-198.
- **R2 (G45)**: «Aprobar la lectura»: AC2 de `audio-y-fx` es «su señal, de `EventBus` o local». Se registra y se retira «Pendiente de R2».
- **T3**: «Solo lo de Unity»: se marca «Superada por D17» solo lo que dice de Unity; lo de `godot/` sigue vigente.

## Constraints
No cambia código ni tests. Si al aplicar una fila su frase resulta falsa contra el código, no la aceptes tal cual: corrígela si la fila ya lo prevé; si no, déjala pendiente y anótala. El texto de G22 y G51 no afirma como cierto lo que PUL-198 aún no ha corregido.

## Acceptance
- [x] AC1 Given las 58 filas, When se revisa cada documento, Then cada una consta aplicada o pendiente con motivo → tabla en docs/evidence/PUL-197/
- [x] AC2 Given `git diff` de la rama, When se revisa, Then no cambia nada bajo `godot/` → salida en docs/evidence/PUL-197/
- [x] AC3 Given `docs/arch`, When `grep -inE "propuest|pendiente"`, Then cada aparición vigente se explica → salida en docs/evidence/PUL-197/

## Plan
1. Leer `gate-enmiendas.md`, el índice y todos los contratos afectados.
2. Aplicar las filas por documento (ADR-002 a ADR-006, `signals.md`, `scene-tree.md`), corrigiendo lo que dice cada fila, tras contrastar cada frase nueva con el código citado. Lo falso que la fila no prevea queda pendiente con motivo.
3. G22 y G51 no se matizan: se conserva «sin emisión en el juego» con una nota de que `order_stand.gd:156` lo incumple hasta PUL-198.
4. G45 en `signals.md` y AC2 de `audio-y-fx`; T3 en `decisions.md`, solo lo de Unity; D23 ratificada y `presses_to_fill` = 6 sin «provisional».
5. Índice `README.md` y resolución arriba de `gate-enmiendas.md`, sin borrar el análisis.
6. Evidencia en `docs/evidence/PUL-197/`: tabla de 58 filas, `git diff --name-only`, `grep` explicado, `verify.sh --quick`, `check_owns.py`.

## Evidence
En `docs/evidence/PUL-197/`:
- `ac1-filas.md`: las 58 filas, 55 aplicadas y 3 pendientes (G08, G13, G57), con motivo y ruta:línea.
- `ac2-diff.txt`: `git diff --name-only` de la rama; nada bajo `godot/`.
- `ac3-grep.txt` y `ac3-grep.md`: salida del `grep` y explicación de cada aparición.
- `verify-quick.txt` y `check-owns.txt`: `tools/verify.sh --quick` y `tools/check_owns.py`, en verde.

Pendientes: las frases de G08 (cinco, en ADR-003 §8.2) y G13/G57 son falsas contra el código y las filas no prevén la corrección. Hace falta otra decisión del responsable. `verify.sh --quick` no ejecuta tests: esta ficha solo cambia documentos.

Revisión de PUL-197, contrastada contra el código, por lectura:
- B1, N1, N2, N5, N6, N7 y N9: ciertos y corregidos. N9 se aplicó a las seis copias de la nota, con el mismo antecedente, no solo a `signals.md`. N8 no requería cambio.
- Ningún hallazgo resultó falso. Una precisión: la revisión sitúa N4 fuera de `owns`, pero `docs/design/features/audio-y-fx.md` está en `owns` de esta ficha. No se ha tocado, como pidió el coordinador, y sigue como tarjeta propuesta. N3 sí está fuera de `owns`.
- Hallazgo nuevo, sin corregir porque ninguna fila lo prevé: `docs/arch/scene-tree.md:241` dice que la caja, «con cualquier otra cosa en la mano», consume la pulsación; `box.gd` devuelve `false` con hint `NONE` (`godot/entities/items/box.gd:121`). Es el mismo caso que G08.
