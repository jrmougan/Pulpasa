---
id: PUL-141
title: Planificar M4 (alpha) en fichas
status: done
milestone: M4
role: game-designer
deps: []
orca_task: task_46ffdef2ade9
unity_sources: []
owns: [docs/backlog/PUL-1[67][0-9]-*.md, docs/evidence/PUL-141/**, docs/backlog/PUL-141-plan-de-m4.md]
touches_scenes: []
---

## Target
Hito M4 de `docs/design/roadmap.md`: balanceo, opciones, gallego, builds Windows/Linux y playtests,
con puerta «Publicar alpha». Alcance aprobado (MoSCoW) en el roadmap; decisiones en
`docs/design/decisions.md`; GDD en `docs/design/gdd.md`. Pendientes de balance ya anotados (fase 3:
`order_2` 56 s frente a ~54 s de ruta óptima, PUL-070).

## Change
1. Repasar el alcance de la alpha frente a lo hecho (M0..M3e) y listar lo que falta para publicarla.
2. Partirlo en fichas `draft` con ids **PUL-160 a PUL-179**, formato de `_TEMPLATE.md`, en oleadas sin
   solapes de `owns`/`touches_scenes` (`level_01.tscn` solo en una ficha de integración), con `deps` reales
   y rol de `.claude/agents/`. Cada ficha cabe en una sesión (≤ 5 AC). Incluye las de diseño o ADR que
   preceden a la implementación (p. ej. contratos de opciones o de localización) y las de QA y playtest.
3. `docs/evidence/PUL-141/README.md`: plan de M4 (oleadas, grafo de deps, qué gates humanos hay y
   qué decisiones abiertas necesita el responsable antes de pasar fichas a `ready`).

## Constraints
- Solo crear fichas y el plan: no se toca código, escenas, datos ni contratos.
- **No edites** `docs/backlog/README.md`, `docs/design/roadmap.md` ni `decisions.md`: los actualiza el
  coordinador. Usa solo los ids PUL-160..179. Otros workers crean en paralelo fichas de triaje de
  pendientes (PUL-142..149) y de cierre de M3e (PUL-150..154): no las dupliques (balance sí es tuyo;
  defectos visuales sueltos y export Android no).
- Lo que dependa de una decisión del responsable (idiomas, opciones mínimas, plataformas, criterio de
  «alpha publicada») va como pregunta explícita en el plan, no como supuesto.

## Acceptance
- [x] AC1 Fichas PUL-160.. que cubren todo lo pendiente del alcance de la alpha para M4.
- [x] AC2 `docs/evidence/PUL-141/README.md` con oleadas, deps, gates y preguntas abiertas.
- [x] AC3 `tools/verify.sh --quick` en verde; `check_owns` limpio.

## Plan
1. Cruzar el alcance MoSCoW de la alpha con el código (`godot/`), las features y `export.md`.
2. Partir lo pendiente en 20 fichas `draft` (PUL-160..179): diseño → ADR-007 → núcleos → UI → integración
   en `level_01` (una ficha) → QA/smoke → publicación, con el balance y los builds en paralelo.
3. Escribir el plan (oleadas, grafo, gates, preguntas) en `docs/evidence/PUL-141/README.md`.

## Evidence
- Plan: `docs/evidence/PUL-141/README.md` (tabla alcance → estado → ficha, 8 oleadas sin solapes, grafo
  mermaid, gates G0–G5 y preguntas P1–P10 para el responsable).
- Fichas: PUL-160..179 (5 de diseño/ADR, 1 de medida y 1 de registro de balance, 9 de implementación, 1 de
  builds, 2 de QA/smoke, 1 de guía de playtest y 1 de publicación del producer).
- Hallazgos: opciones con núcleo de volumen pero sin UI ni persistencia; sin localización; tutorial sin
  implementar; sin pantalla de créditos pese a 9 entradas CC BY en `licenses.md`; build Windows nunca ejecutado.
- Ronda 2 (revisión con CHANGES): PUL-170 pasa a solo preparar (presets, versión de G0 fijada antes de exportar,
  `MANIFEST.txt` con commit y SHA-256, export release bloqueado con árbol sucio) y depende de PUL-160 (O2);
  PUL-176 exporta los builds finales tras PUL-177 y pasa el smoke sobre ellos (O8); PUL-179 publica esos mismos
  `.zip` sin cambiar versión ni reexportar (comprueba `git log` vacío y hashes). PUL-171 y PUL-175 implementan solo
  lo aprobado en G0 (P2, P5) y el botón «Tutorial», si se elige, es de PUL-171. Todos los AC de PUL-160..179 en
  Given/When/Then con números y test, captura o comprobación concreta. Oleadas O1–O9 y grafo actualizados.
- `tools/verify.sh --quick` en verde y `python3 tools/check_owns.py jrmougan/pul-141 HEAD~1` limpio en ambas rondas.
