---
id: PUL-097
title: Implementar la estación de condimentos al paso
status: ready
milestone: M3c
role: gameplay-engineer
deps: [PUL-092, PUL-093, PUL-094]
orca_task: null
unity_sources: []
owns: [godot/entities/stations/seasoning_station.gd, godot/entities/stations/seasoning_station.tscn, godot/entities/stations/seasoning_dispenser.*, godot/entities/stations/cachelos_bowl.*, godot/entities/stations/sandbox/seasoning_station_sandbox.*, godot/core/seasoning_rules.gd, godot/resources/seasoning_station_data.gd, godot/data/config/seasoning_station.tres, godot/tests/unit/test_seasoning_rules.gd, godot/tests/integration/test_seasoning_station.gd, godot/tests/integration/test_cachelos.gd, docs/evidence/PUL-097/**, docs/backlog/PUL-097-estacion-al-paso.md]
touches_scenes: [godot/entities/stations/seasoning_station.tscn, godot/entities/stations/seasoning_dispenser.tscn, godot/entities/stations/cachelos_bowl.tscn, godot/entities/stations/sandbox/seasoning_station_sandbox.tscn]
---

## Target
Estación de condimentos (D23, C-B): sin `Tray`; dispensadores y cuenco actúan sobre la caja en la mano del actor.

## Change
Quita `Tray`. Dispensador: con caja llena en la mano y desde el lado de servicio alterna su condimento (toggle, `paprika_swap`, antirrebote con **reloj de juego**). Mano vacía: no es objetivo. Cuenco: reponer con cachelos cocidos desde cualquier lado (+2 raciones, máx. 4, en `.tres`); alternar cachelos con caja llena en la mano; con cualquier otra cosa no es objetivo; muestra `Portions0..4`. Decisiones del producer sobre preguntas de PUL-092: reponer con el cuenco por debajo del máximo se acepta y se recorta a 4 (con 3 queda en 4); con el cuenco en 4 se rechaza. Las raciones siempre se ven en el modelo. Integra los modelos de PUL-094.

## Constraints
- `tools/verify.sh` en verde; GDScript tipado; datos en `.tres`. Godot con `--audio-driver Dummy`; con el MCP, silencia los buses.
- Diseño: D23 en `docs/design/decisions.md` y `docs/design/rediseno-estaciones.md` (R1–R17). Las features reescritas (PUL-092) y los contratos (PUL-093) mandan.
- No toques `level_01.tscn` (PUL-101). `seasoned`/`seasoning_removed` sin cambios de firma.

## Acceptance
- [ ] AC1 R1–R4 (toggle con caja en mano, antirrebote, caja a medio cortar rechazada, mano vacía sin objetivo) → tests
- [ ] AC2 R5–R6 (cuenco solo con cachelos; 2 raciones, máx. 4) → tests
- [ ] AC3 R7–R8 (sin `Tray`; franjas ≥ 0,6 m sin huecos en el sandbox) → test + mapa de objetivos
- [ ] AC4 Captura del sandbox con los modelos nuevos y cuenco a 0/2/4

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
