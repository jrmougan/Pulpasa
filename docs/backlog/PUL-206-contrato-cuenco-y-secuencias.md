---
id: PUL-206
title: Corregir ADR-003 §9.1 (cuenco) y las secuencias de entrega de signals.md §3
status: ready
milestone: M4
role: godot-architect
deps: []
orca_task: null
unity_sources: []
owns: [docs/arch/ADR-003-arbol-escenas-composicion.md, docs/arch/signals.md]
touches_scenes: []
---

## Target
Dos frases de contrato que no coinciden con el código, vistas al cerrar PUL-205 y fuera de su alcance.

## Change
- **ADR-003 §9.1:** la tabla dice que el cuenco «no es objetivo» con la caja a medio cortar, y la nota que «las dos son de `is_reachable_from`». Hoy `ActionRules.for_bowl` da `BLOCKED` `BOX_NOT_FULL` con esa caja (`godot/core/action_rules.gd:101`), y lo decide `get_action_hint`, no `is_reachable_from`. Reescribir la fila y la nota según el código.
- **`signals.md` §3, «Entrega errónea» y «Entrega en el tick de caducidad»:** describen el núcleo (`OrderBoard.try_deliver`) sin decirlo, y en el juego no se alcanzan desde D26 (§2, `delivery_rejected`). Decir que son secuencias del núcleo, con la precondición `OrderData.max_time > 0` igual que §2.

## Constraints
**Requiere gate humano antes del merge**: es contrato. Solo cambia esas frases; no cambia código ni otras secciones. Cada frase nueva cita `ruta:línea`. Si el código contradice lo que pide el diseño (no solo el texto del contrato), status=blocked y pregúntalo.

## Acceptance
- [ ] AC1 Given cada frase, When se abre la ruta citada, Then el código coincide → tabla en docs/evidence/PUL-206/
- [ ] AC2 Given el cuenco con una caja a medio cortar en `level_01`, When se pide el hint, Then es el que dice la frase nueva → salida de un test o sonda en docs/evidence/PUL-206/

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker: salida de verify.sh, capturas, notas.)
