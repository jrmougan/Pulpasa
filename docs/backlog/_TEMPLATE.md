---
id: PUL-000
title: Título corto en imperativo
status: draft        # draft | ready | in_progress | review | done | blocked
milestone: M0        # F0 | M0 | M1 | M2 | M3 | M4
role: gameplay-engineer
deps: []
orca_task: null      # lo rellena el producer
unity_sources: []    # scripts/prefabs de Assets/ que sirven de especificación
owns: []             # globs editables en exclusiva (lo hace cumplir guard_ownership.py)
touches_scenes: []   # .tscn editables en exclusiva durante esta oleada
---

## Target
Qué componente, ficheros o entorno están en alcance.

## Change
El resultado concreto que hay que producir.

## Constraints
Invariantes, contratos (docs/arch/signals.md) y lo que no se toca.

## Acceptance
- [ ] AC1 Given … When … Then … → `test_nombre` (tests/…)
- [ ] AC2 … → captura en docs/evidence/PUL-000/

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker: salida de verify.sh, capturas, notas.)
