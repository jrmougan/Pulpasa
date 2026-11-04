---
id: PUL-197
title: Aplicar las decisiones del gate de enmiendas a los contratos
status: ready
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
- [ ] AC1 Given las 58 filas, When se revisa cada documento, Then cada una consta aplicada o pendiente con motivo → tabla en docs/evidence/PUL-197/
- [ ] AC2 Given `git diff` de la rama, When se revisa, Then no cambia nada bajo `godot/` → salida en docs/evidence/PUL-197/
- [ ] AC3 Given `docs/arch`, When `grep -inE "propuest|pendiente"`, Then cada aparición vigente se explica → salida en docs/evidence/PUL-197/

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker: salida de verify.sh, capturas, notas.)
