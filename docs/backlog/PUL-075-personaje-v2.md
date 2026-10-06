---
id: PUL-075
title: Rehacer el personaje con la estética de referencia
status: done
milestone: M3b
role: asset-pipeline
deps: [PUL-072, PUL-074, PUL-088]
orca_task: task_5f2388f86fae
unity_sources: []
owns: [art/blender/cook.blend, godot/assets/models/characters/cook/**, godot/entities/player/player.tscn, docs/evidence/PUL-075/**]
touches_scenes: [godot/entities/player/player.tscn]
---

## Target
Adaptar este asset a la estética elegida por el responsable (`docs/art/style-refs/referencia-elegida-2026-10-06.png`).

## Change
Cocineros con uniforme de puesto (gorra/gorro, delantal, camiseta) con materiales v2; J1/J2 distinguibles por color y por un rasgo de forma (rasgo para daltónicos, PUL-044). Mismo rig, clips y anclas (`Anchor_Hold`) o compatibles con `player_animation.gd`.

## Constraints
- Referencia visual: `docs/art/style-refs/referencia-elegida-2026-10-06.png`; reglas en `docs/art/art-bible.md` v2 (PUL-072) y materiales de PUL-074.
- Modela con el MCP de Blender (por CLI; no uses el puerto 9876 si hay un Blender del responsable).
  Godot para capturas siempre con `--audio-driver Dummy`.
- No cambies la jugabilidad: colisiones, anclas, nodos de contrato (`scene-tree.md`), posiciones en
  `level_01` y los tests de selección/entrega deben seguir en verde. Resaltado con contorno fino
  (`OutlineHull` si el modelo es abierto, nota de PUL-049).
- Conserva la legibilidad (biblia §3): siluetas, crudo/cocido/quemado, pegatinas, colores por puesto.
- Capturas desde la cámara de `level_01` (antes/después, con resaltado) y render del `.blend` en
  `docs/evidence/<id>/`. La licencia propia la registra el coordinador.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [x] AC1 Escala, frente y presupuesto de la biblia v2 → `test_assets_models.gd`
- [x] AC2 Legible y coherente con la referencia junto a los assets v2 ya hechos
- [x] Captura antes/después desde la cámara del nivel y render del `.blend`
- [x] `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. Partir de `_template.blend` (materiales v2 enlazados) y regenerar `art/blender/cook.blend` con
   `docs/evidence/PUL-075/build_cook_v2.py`: **mismo esqueleto `cook_rig` (13 huesos), mismos seis
   clips y `Anchor_Hold` en (0; 0,62; 1,20)** que PUL-044, y los mismos nombres de malla
   (`cook_body_j1/j2`, `cook_hat_j1/j2`), así `player_animation.gd` y `player.tscn` no cambian.
2. Geometría nueva, más detallada (objetivo ≈ 4 000 tris por variante, ≤ 6 000): cabeza grande con
   orejas, cejas y pelo; camiseta de manga corta (`mat_cloth_shirt`) con cuello marino; pantalón
   y zapatos (`mat_cloth_pants`, `mat_rubber`); delantal con peto y falda en el color del jugador
   (`mat_cloth_player_1/2`), cinta del cuello y de la cintura marinas, bolsillo `brand_red`
   (`mat_canvas_red`); piel `mat_skin_light`/`mat_skin_dark` como en la v1.
3. Rasgo de forma (PUL-044/§6.5): **J1 gorra de visera** (copa `player_1`, visera y botón
   `brand_red`, insignia compacta delante); **J2 gorro alto** (copa `player_2` abombada, banda marina
   con la insignia). UV de caja a 1 UV = 2 m (`box_uv`).
4. Atlas propio 512² (`gen_cook_atlas.py`, empaquetado en el `.blend`): insignia compacta (gorra) y
   símbolo + logotipo en `brand_paper` (peto), en calcas recortadas por alfa (MASK).
5. Exportar con `blender_export.py --category characters --animations`, `ensure_tangents=true` en el
   `.import`, reimportar, extraer texturas con `.png.import` de la biblioteca.
6. Capturas desde la cámara de `level_01` antes/después (con un objeto resaltado al lado), render
   del `.blend`; `tools/verify.sh` y `check_owns`.

## Evidence
- Fuente: `art/blender/cook.blend`, regenerado desde `_template.blend` (materiales v2 **enlazados**,
  `//_materials_v2.blend`) con `docs/evidence/PUL-075/build_cook_v2.py` (copia como Text dentro del
  `.blend`, junto a `gen_cook_atlas.py` y `render_cook_v2.py`). Reproducible:
  `python3 docs/evidence/PUL-075/gen_cook_atlas.py <atlas.png>` y, en Blender sobre la plantilla,
  `ns = {"ATLAS_PNG": "<atlas.png>"}; exec(open(".../build_cook_v2.py").read(), ns); ns["build_all"]()`.
  Export: `blender -b art/blender/cook.blend --python tools/blender_export.py -- --category characters --animations --max-tris 8000`
  → `cook.glb` (8 objetos, 6 944 triángulos con las dos variantes, 762 KiB).
- **Contrato intacto**: mismo esqueleto `cook_rig` (13 huesos), mismos seis clips y duraciones
  (Idle 1,2 s en bucle, Walk, IdleHolding, WalkWhileHolding, Pick 0,4 s, Cut 0,3 s), `Anchor_Hold`
  en (0; 0,62; 1,20) y mismas mallas `cook_body_j1/j2` + `cook_hat_j1/j2`. **`player.tscn` y
  `player_animation.gd` no cambian** (colisiones, `%HoldPoint`, aro y AnimationTree iguales).
- **AC1 presupuesto y medidas** (biblia v2 §4.1/§4.2): **J1 3 530 tris** (cuerpo 3 204 + gorra 326),
  **J2 3 414** (cuerpo 3 204 + gorro 210), ≤ 6 000 y cerca del objetivo ≈ 4 000. Alto 1,70 m (J1,
  gorra) / 1,92 m (J2, gorro alto); 0,72 m de ancho con los brazos; base en 0, `Anchor_Front` en +Y
  (−Z en Godot). `test_assets_models.gd` valida escala, frente, base e import (el test no mide
  triángulos: se miden en el export, `--max-tris`, y se anotan aquí). Texturas: las de la biblioteca
  (`cloth`, `canvas`, `wood_dark`, 512² con albedo/ORM/normal) y el atlas propio **512²**
  (`cook_cook_atlas.png`, ≤ 1024²), todas embebidas en el `.glb` y extraídas con sus `.png.import`
  (VRAM, mipmaps, `normal_map=1` en las normales); `cook.glb.import` pasa a `ensure_tangents=true`.
- **Materiales** (solo biblioteca v2 + atlas): `mat_cloth_shirt` (camiseta de manga corta),
  `mat_cloth_pants` (pantalón, cuello, ribetes de manga, cintas del delantal, banda del gorro J2),
  `mat_cloth_player_1/2` (peto y falda del delantal, copa de gorra/gorro), `mat_canvas_red`
  (= `brand_red`: visera, botón de la gorra, bolsillo), `mat_skin_light/dark` (J1/J2, como la v1),
  `mat_rubber` (zapatos, ojos, boca), `mat_wood_dark` (pelo y cejas), `mat_cook_atlas` (calcas).
  UV de caja a 1 UV = 2 m.
- **Marca (§7)**: insignia compacta en la gorra (J1) y en la banda del gorro (J2); símbolo +
  logotipo apilados en `brand_paper` en el peto (calcas planas del atlas, alfa recortada → MASK en
  glTF/alpha scissor en Godot). Vista del atlas: `atlas_preview.png`.
- **J1/J2 distinguibles**: color (azul `player_1` / ámbar `player_2` en gorra y delantal, aro igual) y
  **rasgo de forma** para daltónicos: J1 gorra de visera roja baja; J2 gorro alto abombado con banda
  marina (≈ 0,22 m más alto).
- **Capturas** (1920×1080, cámara de `level_01`, `capture_pul075.gd`, `--audio-driver Dummy`):
  `before_*.png` / `after_*.png` en `spawn` (posiciones del nivel), `front`, `back` y
  `three_quarter` (J1 con pulpo cocido, J2 con bandeja grande llena), y recortes ×2 lado a lado
  `zoom_before_after_{front,back,three_quarter}.png`. El **resaltado** (`highlight_outline`) se
  enciende a la fuerza sobre el objeto resaltable más cercano a J1 (el pulpo de la mano) y se ve
  limpio junto al uniforme nuevo. Render del `.blend` (Cycles, J1 arriba y J2 abajo; frente, tres
  cuartos, espalda y ángulo de juego 38°): `blender_render.png`.
- **Luz**: las capturas usan la **luz actual del nivel**; la final de PUL-073 va en paralelo y el
  resto del nivel sigue con los assets v1 (otros workers): conviene repetir la captura con la oleada
  completa.
- Observaciones para el coordinador:
  - De espaldas (como en PUL-044, limitación aceptada) la bandeja la tapan cabeza y gorro; de
    espaldas el color del jugador se lee en la gorra/gorro y en el aro (la cinta del delantal es
    marina por la biblia §2.7).
  - Desde la cámara la visera tapa parte de la cara de J1 (como en la referencia); el gorro de J2 deja
    la cara a la vista.
  - Licencia propia (modelo, atlas derivado de los PNG de marca de PUL-088): la registra el coordinador.
  - `tools/verify.sh` verde (gdformat, gdlint, import, GUT 720/720, smoke).
