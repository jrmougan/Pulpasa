---
id: PUL-205
title: Corregir las frases de contrato pendientes del gate (G08, G13, G57)
status: ready
milestone: M4
role: godot-architect
deps: [PUL-202]
orca_task: null
unity_sources: []
owns: [docs/arch/ADR-003-arbol-escenas-composicion.md, docs/arch/scene-tree.md, docs/arch/README.md, docs/arch/gate-enmiendas.md, docs/arch/signals.md, docs/arch/ADR-006-audio-feedback.md]
touches_scenes: []
---

## Target
Las seis frases de G08 y la atribución a test de G13 y G57.

## Change
Reescribir esas frases según el código (D26): `interact_pressed()`, dispensador, cuenco, `Slot.accepted_group`, la caja guardada y la caja con la mano llena. G13 y G57 citan el test que prueba la regla tras PUL-202. Retirar las salvedades de cabeceras e índice.

Tras PUL-198:
- `signals.md:90` y `:271`: añadir `order_stand.gd` como receptor de `order_patience_changed` (`order_stand.gd:65`).
- Retirar o pasar a pasado las notas de que `order_stand.gd:156` incumple «sin emisión en el juego»: `signals.md` (2), `scene-tree.md`, ADR-003 (2) y ADR-006.

## Constraints
**Requiere gate humano antes del merge**: es contrato. Solo cambia esas frases y sus marcas; no cambia código. Cada frase nueva cita `ruta:línea`.

## Acceptance
- [ ] AC1 Given cada frase, When se abre la ruta citada, Then el código coincide → tabla en docs/evidence/PUL-205/
- [ ] AC2 Given `docs/arch`, When se busca G08, G13 y G57, Then no queda ninguna salvedad vigente → salida en docs/evidence/PUL-205/

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker: salida de verify.sh, capturas, notas.)
