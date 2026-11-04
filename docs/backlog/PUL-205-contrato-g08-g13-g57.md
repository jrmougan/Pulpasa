---
id: PUL-205
title: Corregir las frases de contrato pendientes del gate (G08, G13, G57)
status: ready
milestone: M4
role: godot-architect
deps: [PUL-202]
orca_task: null
unity_sources: []
owns: [docs/arch/ADR-003-arbol-escenas-composicion.md, docs/arch/scene-tree.md, docs/arch/README.md, docs/arch/gate-enmiendas.md]
touches_scenes: []
---

## Target
Las seis frases de G08 y la atribución a test de G13 y G57.

## Change
Reescribir esas frases según el código (D26): `interact_pressed()`, dispensador, cuenco, `Slot.accepted_group`, la caja guardada y la caja con la mano llena. G13 y G57 citan el test que prueba la regla tras PUL-202. Retirar las salvedades de cabeceras e índice.

## Constraints
**Requiere gate humano antes del merge**: es contrato. Solo cambia esas frases y sus marcas; no cambia código. Cada frase nueva cita `ruta:línea`.

## Acceptance
- [ ] AC1 Given cada frase, When se abre la ruta citada, Then el código coincide → tabla en docs/evidence/PUL-205/
- [ ] AC2 Given `docs/arch`, When se busca G08, G13 y G57, Then no queda ninguna salvedad vigente → salida en docs/evidence/PUL-205/

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker: salida de verify.sh, capturas, notas.)
