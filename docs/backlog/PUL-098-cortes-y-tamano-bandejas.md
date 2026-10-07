---
id: PUL-098
title: Aplicar los cortes 4/6/10 y el tamaño legible de las bandejas
status: ready
milestone: M3c
role: gameplay-engineer
deps: [PUL-092, PUL-093, PUL-095]
orca_task: null
unity_sources: []
owns: [godot/data/boxes/**, godot/resources/box_data.gd, godot/entities/items/box.gd, godot/entities/items/box.tscn, godot/entities/items/box_model.gd, godot/entities/stations/box_shelf.tscn, godot/tests/unit/test_box*.gd, godot/tests/integration/test_box*.gd, godot/tests/**/test_data_boxes.gd, docs/evidence/PUL-098/**, docs/backlog/PUL-098-cortes-y-tamano-bandejas.md]
touches_scenes: [godot/entities/items/box.tscn, godot/entities/stations/box_shelf.tscn]
---

## Target
Datos y escenas de bandejas (D23, B-A).

## Change
`fill_per_press` 0,25 / 0,1667 / 0,1 (4/6/10 pulsaciones; 1 pulpo = 2 cajas). `BoxData.short_label` y `BoxData.icon` (iconos de PUL-095). Integra los modelos nuevos de bandeja y rack de PUL-095 en `box.tscn` y `box_shelf.tscn`.

## Constraints
- `tools/verify.sh` en verde; GDScript tipado; datos en `.tres`. Godot con `--audio-driver Dummy`; con el MCP, silencia los buses.
- Diseño: D23 en `docs/design/decisions.md` y `docs/design/rediseno-estaciones.md` (R1–R17). Las features reescritas (PUL-092) y los contratos (PUL-093) mandan.

## Acceptance
- [ ] AC1 R9: N = 4/6/10 pulsaciones llenan S/M/L y quedan 50 unidades → tests
- [ ] AC2 `BoxData.short_label/icon` rellenos en los 3 `.tres` → test de datos
- [ ] AC3 Captura del rack y de las 3 bandejas con los modelos nuevos

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
