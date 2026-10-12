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
- [x] AC1 `features/controles-tactiles.md` recoge el problema, las alternativas y la recomendación, con
  medidas en px de las 3 resoluciones.
- [ ] AC2 Gate humano resuelto y ficha de implementación creada (o limitación aceptada y anotada en el
  roadmap).

## Plan
1. Releer el caso 09 (PUL-134, ADR-005 E5) y medir con el nivel real, sin tocar código: sonda en
   `docs/evidence/PUL-136/` que simula las alternativas en tiempo de ejecución (contador desplazado,
   botón de cambiar en fila) a 2340×1080, 1920×1080 y 800×370, en la plaza de cada olla (z −3,1) y en
   el punto más al norte alcanzable (z −3,4, medido caminando).
2. Escribir en `features/controles-tactiles.md` el problema, la comparación de A (mover el contador),
   B (botones en fila) y C (aceptar), la recomendación y los criterios de aceptación de la ficha de
   implementación.
3. AC2 (gate humano y ficha de implementación) lo lleva el coordinador.

## Evidence
- `docs/evidence/PUL-136/README.md`: medidas, capturas (`<res>-01…04-*.jpg`), `<res>-medidas.json`,
  `reach.json` y las sondas (`probe_boot.gd`, `probe_pul136.gd`, `reach_pul136.gd`).
- Resultado: A no resuelve (al oeste sigue bajo los botones; +1,2 m no sale de la zona de E4); **B**
  deja 0 contadores en la zona en la plaza de las ollas en las 3 resoluciones y en z −3,4 a 1080 de
  alto, con 6,4 px de residuo a 800×370 en z −3,4 (0 con B + contador +0,6 m). Recomendación: B
  (cambia el contrato de E4, necesita ADR; sin riesgo para escritorio ni Local 2P).
- AC1 cumplido en `features/controles-tactiles.md` («Contadores del pasaplatos bajo los botones»).
  AC2 pendiente del gate humano.
