---
id: PUL-184
title: Aplicar la paleta v3 y números macizos legibles en móvil a los puestos de entrega
status: draft
milestone: M3f
role: ui-engineer
deps: [PUL-181]
orca_task: null
unity_sources: []
owns: [godot/data/config/stand_palette.tres, godot/entities/stations/order_stand.tscn, godot/entities/stations/order_stand_model.gd, godot/tests/unit/test_order_stand_model.gd, docs/evidence/PUL-184/**, docs/backlog/PUL-184-puestos-entrega-y-numeros-v3.md]
touches_scenes: [godot/entities/stations/order_stand.tscn]
---

## Target
Resolver el punto débil de los números de los puestos en móvil (`800×370`) y escritorio (`1920×1080`) detectado en la revisión de PUL-180, aplicando la regla de `docs/art/art-bible.md` §6.3 en `godot/entities/stations/order_stand.tscn`, `order_stand_model.gd` y `godot/data/config/stand_palette.tres`.

## Change
1. Actualizar `godot/data/config/stand_palette.tres` a los 4 colores planos de la v3 (§6.3):
   - Puesto 1: `#C8402F` (`brand_red`)
   - Puesto 2: `#2F6FB5` (`p1_blue`)
   - Puesto 3: `#F2C230` (`p2_amber`)
   - Puesto 4: `#4FA05A` (`meadow_green`)
2. En `godot/entities/stations/order_stand.tscn` y `godot/entities/stations/order_stand_model.gd` (§6.3):
   - Configurar los materiales del mostrador y la placa sin texturas PBR (`roughness = 0.85–0.90`, `metallic = 0.0`, `specular_mode = SPECULAR_DISABLED`): tablero en `#EDE8DF`, faldón frontal y `OrderPlateFrame` en `#1D3557`, y `OrderPlatePaper` en `#F7F4EC`.
   - Configurar `%OrderLabel` (`#1..#4`, `Label3D` sobre `OrderPlatePaper` `#F7F4EC`) como **glifo macizo oscuro sin contorno hueco**: `modulate = Color("#1D3557")`, `outline_size = 0`, `font_size = 76`, `pixel_size = 0.005`, `shaded = false` (contraste directo **11.24 : 1**).
   - Configurar `StandNumber` (`1..4`, `Label3D` sobre el faldón frontal `#1D3557`) como **glifo macizo claro sin contorno hueco**: `modulate = Color("#F7F4EC")`, `outline_size = 0`, `font_size = 96`, `pixel_size = 0.005`, `shaded = false` (contraste directo **11.24 : 1**).
3. Actualizar `godot/tests/unit/test_order_stand_model.gd` para verificar los 4 colores de `stand_palette.tres`, el contraste ≥ 11:1 de `%OrderLabel` sobre `OrderPlatePaper` y de `StandNumber` sobre el frente del puesto, y `outline_size == 0` en ambos `Label3D`.

## Constraints
- No cambiar la posición ni la animación de `%OrderLabel`, `StandNumber` ni `StandPopNumber` fijadas por `PUL-142` (`test_stand_pop_number.gd` debe seguir en verde).
- No modificar posiciones de `Marker3D` ni de `%DeliveryZone`.

## Acceptance
- [ ] AC1 Given `godot/data/config/stand_palette.tres`, When se comprueban sus 4 colores en `test_order_stand_model.gd`, Then coinciden con `#C8402F`, `#2F6FB5`, `#F2C230` y `#4FA05A`.
- [ ] AC2 Given `order_stand.tscn` instanciado con comanda activa, When `test_order_stand_model.gd` inspecciona `%OrderLabel` y `OrderPlatePaper`, Then `%OrderLabel.outline_size == 0`, `%OrderLabel.modulate` es `#1D3557`, el albedo de `OrderPlatePaper` es `#F7F4EC` y su contraste WCAG 2.1 es **≥ 11.0 : 1** (`11.24 : 1`).
- [ ] AC3 Given `order_stand.tscn`, When `test_order_stand_model.gd` inspecciona `StandNumber` y el faldón frontal del puesto, Then `StandNumber.outline_size == 0`, `StandNumber.modulate` es `#F7F4EC`, el faldón frontal es `#1D3557` y su contraste WCAG 2.1 es **≥ 11.0 : 1** (`11.24 : 1`).
- [ ] AC4 Given capturas de los 4 puestos a `1920×1080` y `800×370` en `docs/evidence/PUL-184/`, When se inspeccionan `#1..#4` y `1..4`, Then los números se ven macizos (no huecos ni delineados) y `tools/verify.sh` + `tools/check_owns.py` pasan en verde.

## Plan
(Lo escribe el worker antes de empezar.)

## Evidence
(Lo rellena el worker.)
