---
id: PUL-092
title: Reescribir las features de estaciones según D23
status: done
milestone: M3c
role: game-designer
deps: []
orca_task: task_53ea92b0f279
unity_sources: []
owns: [docs/design/features/estacion-condimentos.md, docs/design/features/condimentacion.md, docs/design/features/corte-pulpo.md, docs/design/features/entrega-y-puntuacion.md, docs/design/features/comandas.md, docs/design/level-layouts.md, docs/evidence/PUL-092/**, docs/backlog/PUL-092-features-estaciones-d23.md]
touches_scenes: []
---

## Target
Features afectadas por D23 (rediseño de estaciones aprobado el 2026-10-07): `estacion-condimentos.md`, `condimentacion.md`, `corte-pulpo.md`, `entrega-y-puntuacion.md`, `comandas.md` y `level-layouts.md`.

## Change
Reescribe las features con el paquete aprobado de `docs/design/rediseno-estaciones.md` §4 (C-B línea al paso, B-A, E-A, N-A, cachelos ×2). Traslada R1–R17 como AC numerados y verificables en cada feature. Recoge las preguntas abiertas §7: `operator_side_only` se mantiene (los dispensadores solo desde el lado de servicio), el antirrebote usa el reloj de juego, y el precio de la L lo decide el playtest. Marca como «sustituido por D23» lo que cambie de D18.

## Constraints
Solo documentación. No toques `godot/` ni `docs/arch/`.

## Acceptance
- [x] AC1 Cada feature refleja D23 sin contradicciones con `decisions.md` (D3, D4, D13, D18 modificada)
- [x] AC2 R1–R17 repartidos como AC Given/When/Then con números y su test previsto
- [x] AC3 Boceto actualizado de la línea al paso y de la planta con el hueco a x≈3,2 (`level-layouts.md`)

## Plan
1. Leer `rediseno-estaciones.md` §4/§7, D23 y las seis features.
2. Reescribir `estacion-condimentos.md` (C-B, R1–R8, R16) y ajustar `condimentacion.md` (R3, R6),
   `corte-pulpo.md` (R9, cortes 4/6/10), `comandas.md` (R10, R13), `entrega-y-puntuacion.md`
   (R12, R13, zona iluminada) y `level-layouts.md` (planta vigente, R11, R14–R17).
3. Marcar «Sustituido por D23» y recoger §7 (lado, antirrebote, precio de la L).
4. Resolver con el coordinador la contradicción R5 / C-B del cuenco.
5. Evidencia de reparto y coherencia en `docs/evidence/PUL-092/README.md`; `tools/verify.sh`.

## Evidence
- `docs/evidence/PUL-092/README.md`: tabla R1–R17 → feature/AC/test, preguntas §7 y coherencia con D3, D4, D8, D13, D18/D23.
- Concreción del cuenco acordada con el coordinador (2026-10-07): (a) cachelos cocidos, cualquier lado → reponer +2 (máx. 4); (b) caja llena, solo lado de condimentar → alternar; otra cosa → no es objetivo. El coordinador corrige D23 en `decisions.md`.
- Corregido `entrega-y-puntuacion.md` AC13 (contradecía D8: ahora −2 €).
- Nuevas decisiones pendientes anotadas como preguntas abiertas: reposición que no cabe entera (cuenco en 3), raciones visibles en el cuenco, precio de la L.
- `tools/verify.sh`: OK (gdformat, gdlint, import, GUT todos verdes, smoke OK) el 2026-10-07.
