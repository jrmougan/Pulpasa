---
id: PUL-047
title: Modelar las tres cajas/platos de madera y sus distintivos
status: done
milestone: M3
role: asset-pipeline
agent: claude + MCP de Blender (PUL-043)
deps: [PUL-042, PUL-043, PUL-040]
orca_task: task_65b8c37dbc89
unity_sources: []
owns: [art/blender/box.blend, godot/assets/models/items/box/**, godot/entities/items/box.tscn, godot/entities/items/box_model.gd, godot/entities/items/box_model.gd.uid, godot/tests/integration/test_box_model.gd, godot/tests/integration/test_box_model.gd.uid, docs/evidence/PUL-047/**, docs/backlog/PUL-047-asset-cajas.md]
touches_scenes: [godot/entities/items/box.tscn]
---

## Target
D20: arte propio en Blender con un agente con MCP de Blender (pipeline de PUL-043), siguiendo la
biblia de arte (`docs/art/art-bible.md`, PUL-042).

## Change
1. Plato/caja de madera en tres tamaños (pequeña, mediana, grande) con relleno progresivo de pulpo y huecos para los distintivos de D18 (pegatinas por condimento).
2. Fuente en `art/blender/box.blend`; export `.glb` en `godot/assets/models/items/box/` con
   `tools/blender_export.py`.
3. Sustituir el placeholder en su escena (`Model`), sin cambiar colisiones ni nodos de contrato
   (`scene-tree.md` §3) salvo que se pida. Depende también del diseño de distintivos (PUL-040).
4. Registrar la licencia (propia) en `docs/assets/licenses.md` → pedirlo al coordinador (fuera de `owns`).

## Ajustes de la biblia de arte (PUL-042)
Ajuste de la biblia (§4): objeto `sticker` reutilizable (disco 0,10 m con atlas de 5 iconos ≤ 256×256) y anclas `Anchor_Sticker_*`; tres niveles de relleno como objetos ocultables. La fila de pegatinas en juego es la de PUL-059 (billboard): las pegatinas de la tapa son decorativas.

## Constraints
- Presupuesto de polígonos, escala, frente −Z y paleta de la biblia de arte.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [x] AC1 Escala y frente correctos frente a `scale_check.tscn` → `test_assets_models.gd`
- [x] AC2 Legible desde la cámara del nivel: captura en `docs/evidence/PUL-047/`
- [x] AC3 `.blend` y `.glb` versionados; escena sin errores de import
- [x] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. Investigación: `box.tscn` no elegía modelo por tamaño (el `Model` era siempre `box_medium`
   placeholder); el tamaño solo llega por `data` (`ItemSpawner` asigna `small/medium/large.tres`
   antes de entrar al árbol) y `box.gd` solo emite `fill_changed`/`seasoned`/`seasoning_removed`.
2. Opción A aprobada por el coordinador (sin tocar `box.gd` ni `BoxData`): script de vista nuevo
   `entities/items/box_model.gd` (`BoxModel`, en el nodo `Model`) que reacciona a las señales de la
   caja (sin sondeo) y elige variante con una clave estable (nombre del `.tres`); `owns` ampliado con
   `box_model.gd(.uid)` y `test_box_model.gd(.uid)`. Plato abierto **sin `LidMesh`** (el relleno se ve
   desde arriba; `Lid` y `AnimationPlayer` se quedan); pegatinas 3D en el `.glb` pero ocultas en
   juego (la fila real es `%BadgeRow`).
3. `art/blender/box.blend` desde `_template.blend` con el MCP de Blender (`build_box.py`); atlas de
   pegatinas con `build_sticker_atlas.py` (empaquetado en el `.blend`). Export a
   `godot/assets/models/items/box/box.glb`.
4. `box.tscn`: `Model` = `BoxModel` con `Plate` (`box.glb`), `Octopus` (`octopus_pieces.glb`) y
   `Cachelos` (`cachelos_pieces.glb`). Colisión, `AnchorPoint`, `FillBar`, `BadgeRow`, grupos, audio y
   animaciones sin cambios.
5. Tests (`test_box_model.gd`) y capturas desde la cámara de `level_01` + render del `.blend`.

## Evidence
- **Modelo** (`docs/evidence/PUL-047/blender_render.png`; de izquierda a derecha pequeña vacía,
  mediana a medias, grande llena con cachelos; pegatinas de revisión de la colección `render_only`,
  que no se exporta). Raíz `box` con tres platos hermanos (art-bible §2.1/§3.4): madera
  `mat_wood_light`, fondo `mat_wood_mid` (da hondura vista desde arriba), pie oscuro `mat_wood_dark`
  de 0,014 m (borde de contacto, §3.1.3) y corona plana de 0,022 m con el aro del tamaño:
  `mat_bunting_blue` `#2F6FB5` / `mat_bunting_green` `#4E9B5F` / `mat_canvas_stripe` `#C9483D`.
  Sin cara inferior (§2.2).
  | Objeto | Triángulos | Medidas (Ø × alto, m) |
  |---|---|---|
  | `box_small` | 216 (≤ 600) | 0,34 × 0,10 |
  | `box_medium` | 216 | 0,42 × 0,10 |
  | `box_large` | 216 | 0,49 × 0,10 |
  | `sticker` (disco 0,10 m, atlas 256×128 con 5 iconos en celdas de 64 px) | 16 | 0,10 |
  Anclas por tamaño: `Anchor_Fill_<tamaño>` (suelo del plato, z = 0,022) y
  `Anchor_Sticker_<tamaño>_0..3` (arco sobre la pared frontal-superior; los empties no pueden girar,
  así que la pegatina se orienta en Godot). Atlas: disco del color del condimento (§3.4) con icono
  blanco/negro de `assets/textures/icons` (los de `%BadgeRow`/tickets); el picante lleva llama; sal
  y cachelos con borde oscuro. Geometría reproducible: `build_box.py` y `build_sticker_atlas.py`.
- **Export**: `blender -b art/blender/box.blend --python tools/blender_export.py -- --category items --max-tris 700`
  → `OK godot/assets/models/items/box/box.glb (21 objetos, 664 triángulos)` (216 por variante; solo
  se ve una). Godot extrae `box_box_stickers.png`. `godot --headless --import` sin errores.
- **Escena**: `Model` (y = −0,1665, base en el fondo de la colisión, como antes) con `BoxModel`:
  muestra `box_<tamaño>` según `data` (clave = nombre del `.tres`; otro recurso → `medium`); coloca
  rodajas y cachelos en `Anchor_Fill_<tamaño>` con escala 0,95/1,15/1,35 (`fill_scale`, export);
  niveles de relleno: vacía, `a` (> 0), `a+b` (≥ 0,5), `a+b+c` (llena); cachelos (`a+b`, ×0,55)
  encima si lleva el condimento `cachelos` (export `cachelos`). Se rehace en `_ready` y con
  `fill_changed`/`seasoned`/`seasoning_removed`; si alguien cambia `data` después, `refresh()`.
  `LidMesh` y su material/malla eliminados; `Lid` y `box_open/box_close` siguen.
- **AC1**: `test_assets_models.gd` valida `box.glb` (escala aplicada, base y = 0, `Anchor_Front`
  en −Z, sin cámaras/luces); `test_box_model.gd` comprueba Ø de cada variante (±10 %), alto 0,10 y
  base en el origen.
- **AC2** (cámara de `level_01`, 1920×1080): `level_camera_boxes.png` y `level_camera_zoom_crop.png`
  (×2). En la barra de pase, de izquierda a derecha: pequeña vacía / 0,4 / llena (dulce+sal),
  mediana vacía; bandeja de la estación con mediana llena (dulce+cachelos); mediana 0,6 / llena
  (picante+aceite+cachelos), grande vacía / 0,5 / llena (dulce+sal+aceite+cachelos). J1 (abajo)
  sostiene una grande a medias y J2 una pequeña llena con sal. El aro de color distingue el tamaño
  y el relleno se lee en tres pasos; la fila `%BadgeRow` sigue encima.
- **Tests**: `test_box_model.gd` (8): clave de tamaño, variante visible y medidas, `refresh()` tras
  cambiar `data`, niveles de relleno, rodajas en el suelo del plato, cachelos con el condimento,
  pegatina 3D oculta y anclas, nodos de contrato (`%BadgeRow`, `%AnimationPlayer`, `%Lid`, grupo
  `box`, colisión). `tools/verify.sh` verde (626/626).
- **Observaciones**: en la mano el plato queda a la altura del `HoldPoint` placeholder (como el
  pulpo, PUL-045): para la captura se giró a los personajes hacia la cámara; lo resuelve el
  `Anchor_Hold` de PUL-044. La colisión (0,396 × 0,333 × 0,375) no se cambió, aunque el plato grande
  (0,49) la sobrepasa en planta. `placeholders/box_*.tscn` y `assets/materials/*_box.tres` siguen en
  uso por `box_shelf.tscn`/`scale_check` (no se tocan). Pendiente del coordinador: licencia propia
  en `docs/assets/licenses.md` (Change 4).
