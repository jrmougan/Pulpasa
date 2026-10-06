---
id: PUL-048
title: Modelar el caldero de cobre y el fogón
status: done
milestone: M3
role: asset-pipeline
agent: claude + MCP de Blender (PUL-043)
deps: [PUL-042, PUL-043]
orca_task: task_3f42e19c8e08
unity_sources: []
owns: [art/blender/pot.blend, godot/assets/models/stations/pot/**, godot/entities/stations/kitchen.tscn, docs/evidence/PUL-048/**]
touches_scenes: [godot/entities/stations/kitchen.tscn]
---

## Target
D20: arte propio en Blender con un agente con MCP de Blender (pipeline de PUL-043), siguiendo la
biblia de arte (`docs/art/art-bible.md`, PUL-042).

## Change
1. Caldeiro de cobre sobre fogón/trébede con fuego y vapor (partículas aparte), con plazas visibles para la capacidad de la olla (D9).
2. Fuente en `art/blender/pot.blend`; export `.glb` en `godot/assets/models/stations/pot/` con
   `tools/blender_export.py`.
3. Sustituir el placeholder en su escena (`Model`), sin cambiar colisiones ni nodos de contrato
   (`scene-tree.md` §3) salvo que se pida. 
4. Registrar la licencia (propia) en `docs/assets/licenses.md` → pedirlo al coordinador (fuera de `owns`).

## Ajustes de la biblia de arte (PUL-042)
Ajuste de la biblia (§4): separar `pot_body` y `stove_base`. La planta B usa dos ollas: el mismo modelo instanciado dos veces.

Nota de PUL-046: el caldeiro debe ser abierto y dejar ver su contenido (pulpo y cachelos cociendo) desde la cámara del nivel; el placeholder macizo lo tapa.

## Constraints
- Presupuesto de polígonos, escala, frente −Z y paleta de la biblia de arte.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [x] AC1 Escala y frente correctos frente a `scale_check.tscn` → `test_assets_models.gd`
- [x] AC2 Legible desde la cámara del nivel: captura en `docs/evidence/PUL-048/`
- [x] AC3 `.blend` y `.glb` versionados; escena sin errores de import
- [x] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. Investigación: `kitchen.tscn` tenía en `Model` dos placeholders (`stove.tscn`, caja de 1 m, y
   `pot.tscn`, cilindro macizo encima, total 1,69 m). `CookingStation` mete cada ingrediente en
   una copia de `%AnchorPoint` (y = 1,3) con su `AnchorPoint` (base del modelo) encima, y reparte
   las plazas en x = ∓`SLOT_SPACING`/2 = ∓0,15 (capacidad 2, `kitchen.tres`). El pulpo crudo mide
   0,65 × 0,66 m: a tamaño real no cabe en la boca de un caldeiro de 0,7 m sin atravesar el cobre.
2. `art/blender/pot.blend` desde `_template.blend` con el MCP de Blender (`build_pot.py`): raíz
   `pot` con `pot_body` (caldeiro abierto, borde, caldo, asas) y `stove_base` (trébede, leña,
   brasas, piedras) separados (ajuste §4); anclas `Anchor_Slot_0..1`, `Anchor_Steam`, `Anchor_Fire`.
   Boca a 1,0 m (§2.1). Export a `godot/assets/models/stations/pot/pot.glb`.
3. `kitchen.tscn`: `Model` = `pot.glb` + partículas `Fire` y `Steam` (paleta `fire`/`steam`).
   `%AnchorPoint` baja al caldo (y = 0,86) con escala 0,75 para que pulpo y cachelos queden
   dentro de la boca sin atravesar el cobre (el `HoldComponent` reinicia la transformación al
   recogerlos, así que solo cambia la vista en la olla); `%CookBar` baja de 2,3 a 1,6 (el
   conjunto mide 1,0 m). Colisión, nombres, grupos, `%Highlightable` y `%BoilAudio` sin cambios.
4. Capturas desde la cámara de `level_01` (`capture_pot.gd`) y render del `.blend`.

## Evidence
- **Modelo** (`docs/evidence/PUL-048/blender_render.png`, cámara ortográfica a 38° como la del
  nivel). Raíz `pot` con dos mallas hermanas (art-bible §4), solo materiales de la paleta:
  | Malla | Triángulos | Medidas (ancho × fondo × alto, m) | Materiales |
  |---|---|---|---|
  | `pot_body` (origen en su base, z = 0,40) | 896 | 0,97 (con asas) × 0,77 × 0,60 | `mat_copper`, `mat_copper_light` (borde grueso), `mat_copper_dark` (interior, caldo), `mat_iron_black` (asas de aro) |
  | `stove_base` | 356 | 0,85 × 0,90 × 0,39 | `mat_iron_black` (trébede: aro y 3 patas, ninguna delante), `mat_wood_dark` (3 troncos hacia atrás), `mat_fire` (brasas), `mat_ground_stone` (círculo de 10 piedras) |
  | **Total** | **1 252** (≤ 1 500) | 0,97 × 0,90 × 1,00 | |
  Caldeiro panzudo: vientre Ø 0,75, boca Ø 0,77 exterior / 0,69 de luz (§2.1: 0,7 ± 10 %); boca a
  1,00 m; caldo `copper_dark` a 0,10 m bajo el borde (desde la cámara se ve casi entero). **Plazas
  visibles** (D9, §3.5): un aro `copper_light` sobre el caldo en cada `Anchor_Slot_0..1`
  (x = ∓0,15, z = 0,86, como `CookingStation`). Ancho total 0,97 con asas (0,9 + 7,5 %, dentro
  del ±10 %). Sin cara inferior en piedras; frente +Y → −Z. Geometría reproducible:
  `docs/evidence/PUL-048/build_pot.py`.
- **Export**: `blender -b art/blender/pot.blend --python tools/blender_export.py -- --category stations --max-tris 1500`
  → `OK godot/assets/models/stations/pot/pot.glb (8 objetos, 1252 triángulos, 55 KiB)`.
  `godot --headless --import` sin errores.
- **Escena** `kitchen.tscn`: `Model/Pot` = `pot.glb`; `Model/Fire` (GPUParticles3D en
  `Anchor_Fire`, esferas `fire` → `copper` que se desvanecen) y `Model/Steam` (sobre la boca,
  `steam` con alfa 0,4). Las partículas están siempre encendidas (el fogón está prendido): que el
  vapor solo salga al cocer pide tocar `cooking_station.gd` (fuera de `owns`); queda para la ficha
  de VFX (art-bible §4.1). `%AnchorPoint` en y = 0,86 con escala 0,75 y `%CookBar` en y = 1,6
  (ver Plan 3). Colisión (0,9 × 1,69 × 0,78), grupos `interactable`/`kitchen`, capas,
  `%Highlightable`, `%BoilAudio` y `data` sin cambios. `level_01` (Kitchen y Kitchen2) instancia la
  misma escena: dos ollas idénticas.
- **AC1**: `test_assets_models.gd` valida `pot.glb` (escala aplicada, base y = 0, `Anchor_Front`
  en −Z, sin cámaras/luces, medidas en rango). `test_cooking_station.gd`/`test_cachelos.gd` siguen
  verdes (el ancla del ingrediente coincide con la de la olla).
- **AC2** (cámara de `level_01`, 1920×1080, `capture_pot.gd`): `level_camera_empty.png` y
  `level_camera_empty_zoom.png` (×2): las dos ollas vacías, boca abierta con las dos plazas;
  `level_camera_cooking.png` y `level_camera_cooking_zoom.png` (×2): Kitchen con pulpo y cachelos
  crudos cociendo (dos barras apiladas), Kitchen2 con cachelos ya cocidos y pulpo crudo cociendo
  (una barra). El contenido se ve dentro de la boca sin atravesar el cobre.
- **AC4**: `tools/verify.sh` verde (639/639); `tools/check_owns.py` limpio.
- **Observaciones**: a tamaño real el pulpo crudo (0,65 m) sobresalía por las paredes; con la
  escala 0,75 del ancla cabe. Si el responsable prefiere tamaño real dentro de la olla, habría que
  agrandar el caldeiro por encima de la biblia o separar más las plazas en `cooking_station.gd`.
  Los cachelos crudos (`#8E6B47`) contrastan poco con el caldo `#8A4220`; los separa su banda
  oscura y el aro de la plaza. `placeholders/pot.tscn` y `stove.tscn` siguen en uso por
  `scale_check.tscn` (no se tocan). Pendiente del coordinador: licencia propia en
  `docs/assets/licenses.md` (Change 4).
