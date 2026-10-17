---
id: PUL-184
title: Aplicar la paleta v3 y números macizos legibles en móvil a los puestos de entrega
status: done
milestone: M3f
role: ui-engineer
deps: [PUL-181, PUL-182]
orca_task: task_8c32859718ab
unity_sources: []
owns: [godot/data/config/stand_palette.tres, godot/entities/stations/order_stand.tscn, godot/entities/stations/order_stand_model.gd, godot/tests/unit/test_order_stand_model.gd, godot/tests/integration/test_order_tickets.gd*, docs/evidence/PUL-184/**, docs/backlog/PUL-184-puestos-entrega-y-numeros-v3.md]
touches_scenes: [godot/entities/stations/order_stand.tscn]
---

## Target
Resolver el punto débil de los números de los puestos en móvil (`800×370`) y escritorio (`1920×1080`) detectado en la revisión de PUL-180, aplicando la regla de `docs/art/art-bible.md` §6.3 en `godot/entities/stations/order_stand.tscn`, `order_stand_model.gd` y `godot/data/config/stand_palette.tres`. Se ejecuta en la Oleada 2 tras crearse los materiales v3 en `PUL-182`.

## Change
1. Actualizar `godot/data/config/stand_palette.tres` a los 4 colores planos de la v3 (§6.3):
   - Puesto 1: `#C8402F` (`brand_red`)
   - Puesto 2: `#2F6FB5` (`p1_blue`)
   - Puesto 3: `#F2C230` (`p2_amber`)
   - Puesto 4: `#4FA05A` (`meadow_green`)
2. En `godot/entities/stations/order_stand.tscn` y `godot/entities/stations/order_stand_model.gd` (§6.3):
   - Configurar los materiales del mostrador y la placa vinculando los recursos compartidos de `res://assets/materials/v3/` creados por `PUL-182`: tablero en `mat_surface_top.tres` (`#EDE8DF`), faldón frontal y `OrderPlateFrame` en `mat_brand_navy.tres` (`#1D3557`), y `OrderPlatePaper` en `mat_ui_cream.tres` (`#F7F4EC`).
   - Configurar `%OrderLabel` (`#1..#4`, `Label3D` sobre `OrderPlatePaper` `#F7F4EC`) como **glifo macizo oscuro sin contorno hueco**: `modulate = Color("#1D3557")`, `outline_size = 0`, `font_size = 76`, `pixel_size = 0.005`, `shaded = false` (contraste directo **11.24 : 1**).
   - Configurar `StandNumber` (`1..4`, `Label3D` sobre el faldón frontal `#1D3557`) como **glifo macizo claro sin contorno hueco**: `modulate = Color("#F7F4EC")`, `outline_size = 0`, `font_size = 96`, `pixel_size = 0.005`, `shaded = false` (contraste directo **11.24 : 1**).
3. Actualizar `godot/tests/unit/test_order_stand_model.gd` para verificar los 4 colores de `stand_palette.tres`, el contraste ≥ 11:1 de `%OrderLabel` sobre `OrderPlatePaper` y de `StandNumber` sobre el frente del puesto, y `outline_size == 0` en ambos `Label3D`.

## Constraints
- No cambiar la posición ni la animación de `%OrderLabel`, `StandNumber` ni `StandPopNumber` fijadas por `PUL-142` (`test_stand_pop_number.gd` debe seguir en verde).
- No modificar posiciones de `Marker3D` ni de `%DeliveryZone`.

## Acceptance
- [x] AC1 Given `godot/data/config/stand_palette.tres`, When se comprueban sus 4 colores en `test_order_stand_model.gd`, Then coinciden con `#C8402F`, `#2F6FB5`, `#F2C230` y `#4FA05A`.
- [x] AC2 Given `order_stand.tscn` instanciado con comanda activa, When `test_order_stand_model.gd` inspecciona `%OrderLabel` y `OrderPlatePaper`, Then `%OrderLabel.outline_size == 0`, `%OrderLabel.modulate` es `#1D3557`, el albedo de `OrderPlatePaper` es `#F7F4EC` y su contraste WCAG 2.1 es **≥ 11.0 : 1** (`11.24 : 1`).
- [x] AC3 Given `order_stand.tscn`, When `test_order_stand_model.gd` inspecciona `StandNumber` y el faldón frontal del puesto, Then `StandNumber.outline_size == 0`, `StandNumber.modulate` es `#F7F4EC`, el faldón frontal es `#1D3557` y su contraste WCAG 2.1 es **≥ 11.0 : 1** (`11.24 : 1`).
- [x] AC4 Given capturas de los 4 puestos a `1920×1080` y `800×370` en `docs/evidence/PUL-184/`, When se inspeccionan `#1..#4` y `1..4`, Then los números se ven macizos (no huecos ni delineados) y `tools/verify.sh` + `tools/check_owns.py` pasan en verde.

## Plan
1. Inspeccionar el árbol real de `order_stand.glb` (nodos y superficies de `counter`) y localizar el
   tablero y el faldón frontal sobre el que va `StandNumber`.
2. `stand_palette.tres` a los 4 hex de la v3.
3. En `order_stand.tscn`, `surface_material_override` sobre los nodos del `.glb` instanciado con los
   `.tres` compartidos de `res://assets/materials/v3/` (sin tocar el `.glb.import`, que es de
   PUL-186), y los dos `Label3D` macizos de §6.3. Sin cambios de transform.
4. Tests en `test_order_stand_model.gd` (paleta, colores, `outline_size`, contraste WCAG 2.1 calculado
   en el test). Capturas a `1920×1080` y `800×370` con un script reproducible.

## Evidence
- **Árbol real** (`Model/order_stand/…`): `counter` tiene 6 superficies; la 2 (`mat_steel_brushed_top`,
  `y = 0.90–0.95`) es el tablero; el frente visible es la 0 (`mat_steel_dark`, cuerpo) más la 5
  (`order_stand_atlas`, chapa de `z = -0.23` con el círculo del número). Ambas van a
  `mat_brand_navy.tres`; la 2 a `mat_surface_top.tres`. `OrderPlateFrame` → `mat_brand_navy.tres`,
  `OrderPlatePaper` → `mat_ui_cream.tres` (las dos, slot `kiosk_delivery_signs`).
- **Label3D**: `%OrderLabel` `modulate #1D3557`, `outline_size 0` (se quita `outline_modulate`),
  `font_size 76`, `pixel_size 0.005`; `StandNumber` `modulate #F7F4EC`, `outline_size 0`,
  `font_size 96`, `pixel_size 0.005`. `shaded` queda en `false` (por defecto). Posiciones y
  `billboard`/`no_depth_test` sin cambios; `test_stand_pop_number.gd` en verde.
- `order_stand_model.gd` no necesitó cambios: los materiales son datos de la escena.
- **Tests** (`godot/tests/unit/test_order_stand_model.gd`): `test_pul184_palette_is_v3_flat` (AC1),
  `test_pul184_order_label_is_solid_dark_on_cream_plate` (AC2, con comanda activa pedida a
  `OrderService`) y `test_pul184_stand_number_is_solid_cream_on_navy_front` (AC3). Contraste WCAG
  2.1 calculado: 11.24 : 1 en ambos (umbral 11.0).
- **Owns ampliados** con aprobación del coordinador: `godot/tests/integration/test_order_tickets.gd*`.
  Solo cambian las 3 líneas hex de `test_pul099_palette_has_the_four_awning_colors_and_fallback`
  (`d2473f`/`3f7cc8`/`e8c23a` → `c8402f`/`2f6fb5`/`f2c230`).
- **Capturas** (AC4), `docs/evidence/PUL-184/`, hechas con `capture_stands_v3.gd` (uso en su
  cabecera; `xvfb-run -a`, `--audio-driver Dummy`): `stands_1920x1080.png`,
  `stands_1920x1080_zoom.png`, `stands_800x370.png`, `stands_800x370_zoom.png`. `#1..#4` y `1..4` se
  ven macizos, sin contorno, en las dos resoluciones.
- **Observaciones para el responsable**:
  - Los toldillos siguen con los colores v2 hasta que entre el mapeo de `order_stand.glb.import` de
    PUL-186 (`mat_canvas_stand_N`); no se duplicó aquí.
  - A `800×370` el `#` de `#1..#4` se lee algo apretado (parece `≠`) por el tamaño en pantalla
    (~33 px/m). Las cifras se leen bien. Si molesta, la salida sería quitar el `#` del texto o subir
    `font_size`, pero eso cambia el contrato de `%OrderLabel` (`"#%d"`) o §6.3: queda como pregunta.
- `tools/verify.sh` completo en verde (gdformat, gdlint, import, GUT 1360/1360, smoke) y `tools/check_owns.py jrmougan/pul-184 main` limpio.
