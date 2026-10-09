---
id: PUL-098
title: Aplicar los cortes 4/6/10 y el tamaño legible de las bandejas
status: done
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
- [x] AC1 R9: N = 4/6/10 pulsaciones llenan S/M/L y quedan 50 unidades → tests
- [x] AC2 `BoxData.short_label/icon` rellenos en los 3 `.tres` → test de datos
- [x] AC3 Captura del rack y de las 3 bandejas con los modelos nuevos

## Plan
Ficheros: `resources/box_data.gd` (+`short_label: String`, +`icon: Texture2D`, contrato ADR-003 §8), `data/boxes/{small,medium,large}.tres` (`fill_per_press` 0,25 / 0,1667 / 0,1; `short_label` S/M/L; `icon` = `assets/textures/ui/box_sizes/size_{s,m,l}.png`), tests. Sin señales nuevas. `box.tscn` y `box_shelf.tscn` ya apuntan a `box.glb`/`box_shelf.glb`, que PUL-095 sustituyó en sitio (mismos nodos y anclajes): no requieren cambio de escena; se verifica por captura.
API de tamaño para el ticket (PUL-099): `recipe.box.short_label` / `recipe.box.icon`, sin lógica extra.
Tests: AC1 `tests/integration/test_box.gd` (S/M/L llenan en 4/6/10 pulsaciones y gastan 50 unidades; un pulpo = 2 cajas con M 6+6 no, sigue 100 -> 50 por caja) actualizado; `tests/unit/test_data_boxes.gd` (fill_per_press nuevos). AC2 `test_data_boxes.gd` (short_label/icon rellenos, icono = size_x.png, distintos). AC3 captura `docs/evidence/PUL-098/` con script CLI.

## Evidence
- `tools/verify.sh` verde: 736/736 GUT ([verify.log](../evidence/PUL-098/verify.log)).
- AC1: `test_box.gd` y `test_box_on_slot.gd` (S/M/L llenan en 4/6/10, quedan 50 unidades; en la mesa también), `test_data_boxes.gd` (0,25 / 0,16666667 / 0,1). Medium usa 1/6 con 8 decimales para gastar 50,000 y no 50,01.
- AC2: `test_data_boxes.gd` (short_label S/M/L, icon = `size_{s,m,l}.png`, distintos).
- AC3: [rack + bandejas vacías/medias/llenas, 1080p](../evidence/PUL-098/rack_and_trays_1080.png) y [zoom](../evidence/PUL-098/rack_and_trays_zoom.png); script `capture_rack.gd`. Rack con letras S/M/L y bandejas con rótulo legibles en cámara de juego.
- Escenas: `box.tscn` y `box_shelf.tscn` no cambian; PUL-095 sustituyó `box.glb`/`box_shelf.glb` en sitio con los mismos nodos y anclajes.
- API para PUL-099: `recipe.box.short_label` / `recipe.box.icon` (`BoxData`).
