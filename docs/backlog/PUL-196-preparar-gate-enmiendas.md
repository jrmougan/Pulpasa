---
id: PUL-196
title: Corregir el índice de contratos y preparar el gate de enmiendas pendientes
status: ready
milestone: M4
role: godot-architect
deps: []
orca_task: null
unity_sources: []
owns: [docs/arch/README.md, docs/arch/gate-enmiendas.md]
touches_scenes: []
---

## Target
`docs/arch/README.md` y documento nuevo `docs/arch/gate-enmiendas.md`.

## Change
- `README.md`: corregir solo hechos ya decididos. D14 ya no está pendiente (decisions.md: 3D, ADR-005 aceptado); ADR-002 está aceptado según su cabecera. Las enmiendas pendientes siguen como pendientes.
- `gate-enmiendas.md`: una tabla con **cada** enmienda propuesta o pendiente de ADR-002 a ADR-006, y el estado «propuesto» de `signals.md` y `scene-tree.md`. Columnas: documento y sección, ficha, qué decide, si el código ya la implementa (con ruta:línea o test comprobado), si hay divergencia entre código y texto, y recomendación (aceptar, aceptar con cambios o rechazar). Añadir la propuesta de marcar T3 de `decisions.md` como «Superada por D17».

## Constraints
**Ningún agente acepta nada**: no cambies estados de ADR, `signals.md`, `scene-tree.md` ni `decisions.md`. Una enmienda sin implementar o divergente no se recomienda aceptar sin más. Cada fila debe estar comprobada contra el código.

## Acceptance
- [ ] AC1 Given todas las cabeceras y secciones de docs/arch, When `grep -inE "propuest|pendiente"`, Then cada aparición vigente está en la tabla o se explica por qué no → salida en docs/evidence/PUL-196/
- [ ] AC2 Given una fila que dice «implementada», When se abre la ruta citada, Then el código coincide → cada fila cita ruta:línea
- [ ] AC3 Given `git diff` de la rama, When se revisa, Then solo cambian `README.md`, `gate-enmiendas.md`, la ficha y la evidencia → salida en docs/evidence/PUL-196/

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker: salida de verify.sh, capturas, notas.)
