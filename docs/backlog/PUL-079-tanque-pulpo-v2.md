---
id: PUL-079
title: Convertir el arcón en tanque de pulpos
status: review
milestone: M3b
role: asset-pipeline
deps: [PUL-072, PUL-074, PUL-076]
orca_task: null
unity_sources: []
owns: [art/blender/octopus_storage.blend, godot/assets/models/stations/octopus_storage/**, godot/entities/stations/octopus_storage.tscn, docs/evidence/PUL-079/**]
touches_scenes: [godot/entities/stations/octopus_storage.tscn]
---

## Target
Adaptar este asset a la estética elegida por el responsable (`docs/art/style-refs/referencia-elegida-2026-10-06.png`).

## Change
Tanque/acuario azul con agua, burbujas y pulpos dentro (lectura «de aquí sale el pulpo crudo»), mangueras; misma huella y acceso.

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
1. Rehacer `art/blender/octopus_storage.blend` desde `_template.blend` (materiales v2 enlazados) con un
   script reproducible (`docs/evidence/PUL-079/build_tank.py`, copia como Text en el `.blend`),
   ejecutado con el MCP de Blender por CLI (sin el puerto 9876). Misma huella que el arcón (≈ 1,6 × 0,9 m,
   la de `CollisionShape3D`), frente +Y, origen en el centro de la base.
2. Tanque de plástico azul (`mat_plastic_blue`) abierto por arriba sobre bancada `mat_steel_dark`; agua
   `mat_glass_water` (transparente, §3.2) con burbujas; tres pulpos crudos con la malla `octopus_raw` de
   `art/blender/octopus.blend` (PUL-076, copiada con su atlas) flotando a ras para que el agua no les
   quite el rosa (§6.2); una pata colgando por el labio; aireador y mangueras negras al suelo por detrás
   (§5 regla 4); grifo y etiqueta con pictograma sin texto (§3.2) en el frente (Z2).
3. Exportar con `tools/blender_export.py --category stations --max-tris 6000` e importar fijando los
   `.png.import` (pipeline §8).
4. `octopus_storage.tscn`: sin tocar colisión, script ni `%Highlightable`; adaptar `OutlineHull` al tanque.
5. Capturas antes/después desde la cámara de `level_01` (sin y con resaltado) y renders del `.blend`.

## Evidence
Rama `jrmougan/pul-079`. Luz: la actual de `level_01` (PUL-073/089 ya mergeados).

**Modelo** (`art/blender/octopus_storage.blend` → `godot/assets/models/stations/octopus_storage/octopus_storage.glb`, 496 KiB):
| Malla | Tris | Materiales |
|---|---|---|
| `tank_body` (tanque redondeado con labio y 2 nervios, paredes y fondo interiores, agua, burbujas, bancada, grifo, etiqueta con pictograma) | 1 134 | `mat_plastic_blue`, `mat_glass_water`, `mat_steel_dark`, `mat_steel_brushed`, `mat_plastic_red`, `mat_canvas_paper`, `mat_rubber` |
| `octopus_0..2` (pulpo crudo v2 de PUL-076 a escala 0,62 horneada) | 3 × 1 172 | `mat_food_octopus_raw`, `atlas_octopus` |
| `tentacle` (pata que cuelga por el labio delantero) | 102 | `mat_food_octopus_raw` |
| `pump` (aireador en el labio trasero, manguera de aire al agua, cable y desagüe al suelo por detrás) | 164 | `mat_steel_dark`, `mat_rubber`, `mat_steel_brushed` |
| **Total** | **4 916** (≤ 6 000, §4.1) | |

- Medidas: tanque 1,60 × 0,88 m (labio incluido), borde a 1,0 m, agua a 0,91 m; huella dentro de la
  colisión de 1,61 × 0,91 m. Frente −Z (`Anchor_Front`), sin luces ni cámaras; `test_assets_models.gd`
  en verde (AC1).
- Texturas embebidas y extraídas junto al `.glb`: las de la biblioteca (`plastic`, `canvas`,
  `steel_brushed`, 512²) y el atlas del pulpo de PUL-076 (256²); `.png.import` con VRAM + mipmaps
  (+ `normal_map` en los normales). Sin atlas propio nuevo: UV de caja a 1 UV = 2 m (256 px/m); los
  pulpos conservan las UV de su atlas.
- Burbujas en `mat_canvas_paper` (espuma blanca): en `mat_glass_water` no se veían desde la cámara.
- Legibilidad (AC2): los pulpos del tanque son la misma malla y material que el crudo de la mano
  (comparación con el de `PassSlot01` en las capturas); flotan con patas a 1–2 cm bajo la lámina y la
  cabeza fuera, así el agua (alfa 0,55) no les quita el rosa. El azul `plastic_blue` destaca contra el
  granito/encimeras y casa con la referencia (tanque azul con pulpos rosas, arriba a la izquierda).
- Contratos intactos: colisión, script `item_spawner.gd`, `scene`, grupo, capa y posición en `level_01`
  sin cambios. `OutlineHull`: una sola caja de 1,6 × 0,98 × 0,86 m (sin la tapa del arcón) con material
  totalmente transparente: el tanque es abierto y el agua transparente, así que la caja no cabe escondida
  dentro del modelo como en PUL-049; el contorno (overlay) se sigue pintando sobre ella.
- Lo que no se hizo: burbujas animadas (partículas) y cartel aparte: la etiqueta con pictograma del frente
  hace de cartel pequeño sin texto.

Ficheros en `docs/evidence/PUL-079/`:
- `blender_render_game.png` (ortográfica tipo nivel) y `blender_render_three.png` (3/4), Cycles con luz
  neutra: `render_tank.py`.
- `level_camera_{before,after}_{plain,highlight}[_zoom].png` (`capture_tank.gd`; «antes» desde un
  worktree de la base). Con un pulpo crudo en `PassSlot01` para comparar.
- `build_tank.py`: geometría (reproducible).

Verificación: `tools/verify.sh` verde (726/726 tests, smoke OK);
`tools/check_owns.py jrmougan/pul-079 jrmougan/agentica-migracion-godot-alpha` limpio.
Licencia: modelo propio (D20) que reutiliza el pulpo propio de PUL-076; la registra el coordinador.
