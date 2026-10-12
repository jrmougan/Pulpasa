---
id: PUL-136
title: Decidir cómo evitar que los botones táctiles tapen los contadores del pasaplatos este
status: in_progress
milestone: M3e
role: game-designer
deps: [PUL-134]
orca_task: null
unity_sources: []
owns: [docs/design/features/controles-tactiles.md, docs/evidence/PUL-136/**, docs/backlog/PUL-136-widgets-del-pasaplatos-bajo-los-botones.md]
touches_scenes: []
---

## Target
Limitación conocida de PUL-134 (caso 09 de PUL-133; ADR-005 E5, nota «Zonas tapadas de la flecha y de
los botones»). Con el activo en las ollas, la banda superior empuja la vista al norte, la fila de
pasaplatos cae en la franja de botones y el recorte este no actúa: el contador N/6 de una caja en los
pasaplatos 04-06 queda bajo los botones (04-06 a 2340×1080 y 800×370; 04 a 1920×1080). Medidas y capturas
en `docs/evidence/PUL-134/README.md`. Un sesgo de cámara al este no lo resuelve a 1920×1080.

## Change
Propuesta de diseño (opción B de la revisión de PUL-134) con 2-3 alternativas comparadas, por ejemplo:
mover el contador N/6 (lado oeste de la caja, encima), reordenar los pasaplatos o la disposición del
mapa móvil, cambiar la forma o posición de la zona de botones, o aceptar la limitación. Para cada una:
coste (fichas, contratos y escenas que tocaría), riesgo para escritorio y Local 2P, y cómo se mediría.
Recomendación y criterios de aceptación verificables para la ficha de implementación.

## Constraints
- Solo diseño: no se toca código, escenas ni contratos. Lo que cambie un contrato (E4/E5, `UiProfile`)
  necesita ADR del arquitecto y gate humano.
- La elección final es del responsable (gate humano antes de pasar a `ready` la ficha de implementación).

## Acceptance
- [ ] AC1 `features/controles-tactiles.md` recoge el problema, las alternativas y la recomendación, con
  medidas en px de las 3 resoluciones.
- [ ] AC2 Gate humano resuelto y ficha de implementación creada (o limitación aceptada y anotada en el
  roadmap).

## Plan

## Evidence
