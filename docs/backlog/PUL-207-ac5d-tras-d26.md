---
id: PUL-207
title: Decidir qué describe AC5d tras D26
status: draft
milestone: M4
role: game-designer
deps: []
orca_task: null
unity_sources: []
owns: [docs/design/features/entrega-y-puntuacion.md]
touches_scenes: []
---

## Target
AC5d de `docs/design/features/entrega-y-puntuacion.md:54`.

## Change
El cuerpo de AC5d sigue describiendo un rechazo por pulsación anterior a D26: «se emite `delivery_rejected(slot, id_de_la_caducada, 0)`». En el juego ya no se emite (`docs/arch/signals.md` §2): desde PUL-198 la zona espera al siguiente `advance` y la caja sigue en la mano. PUL-203 solo cambió su línea «Test:». Hay que decidir si AC5d describe el núcleo (`OrderBoard`, que sí rechaza) o lo que ve el jugador, y reescribirlo en consecuencia.

## Constraints
Es una decisión de diseño: la toma el responsable. La ficha no pasa a `ready` sin esa respuesta. No cambia valores ni `decisions.md` ni `docs/arch`.

## Acceptance
(Se concretan al pasar a `ready`, con la decisión.)

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker: salida de verify.sh, capturas, notas.)
