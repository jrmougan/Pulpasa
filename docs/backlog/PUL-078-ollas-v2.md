---
id: PUL-078
title: Rehacer las ollas como cocedores de acero
status: review
milestone: M3b
role: asset-pipeline
deps: [PUL-072, PUL-074]
orca_task: null
unity_sources: []
owns: [art/blender/pot.blend, godot/assets/models/stations/pot/**, godot/entities/stations/kitchen.tscn, docs/evidence/PUL-078/**]
touches_scenes: [godot/entities/stations/kitchen.tscn]
---

## Target
Adaptar este asset a la estética elegida por el responsable (`docs/art/style-refs/referencia-elegida-2026-10-06.png`).

## Change
Cocedores de acero inoxidable con quemador de gas, tuberías/mangueras y vapor (partículas de PUL-069), abiertos para ver lo que cuece; plazas `Anchor_Slot_*` y fuego/vapor por estado intactos.

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
1. Rehacer `art/blender/pot.blend` desde `_template.blend` (materiales v2 enlazados) con un script
   reproducible (`docs/evidence/PUL-078/build_pot.py`, copia como Text en el `.blend`), ejecutado con
   el MCP de Blender por CLI. Misma huella (≈ 0,9 × 0,8 m), mismas alturas de contrato (borde 1,0,
   agua 0,90, `Anchor_Slot_0..1` en x = ∓0,15 / z = 0,86, `Anchor_Steam`, `Anchor_Fire`, `Anchor_Front`).
2. Cocedor cilíndrico de acero (`mat_steel_brushed`) abierto, tapa levantada en bisagra trasera,
   quemador de gas en soporte de patas (`mat_steel_dark`), mando con piloto, bombona
   (`mat_plastic_blue`) con mangueras roja/verde (`mat_rubber_hose_*`) por detrás, pegadas al suelo.
3. Exportar con `tools/blender_export.py --category stations --max-tris 6000`, importar y fijar los
   `.png.import` (pipeline §8).
4. `kitchen.tscn`: sin tocar nodos de contrato, colisión ni `AnchorPoint`; solo el `Fire` si el
   modelo nuevo tapa la llama. Resaltado: probar el contorno sobre las mallas; `OutlineHull` solo si
   rellena la boca.
5. Capturas antes/después (vacío, estados, resaltado) desde la cámara de `level_01` y render del `.blend`.

## Evidence
Rama `jrmougan/pul-078`. Luz: la **actual** de `level_01` (PUL-073 va en paralelo).

**Modelo** (`art/blender/pot.blend` → `godot/assets/models/stations/pot/pot.glb`, 290 KiB):
| Malla | Tris | Materiales |
|---|---|---|
| `pot_body` (cuerpo, borde enrollado, 2 nervios, asas, grifo, bisagra, agua, aros de plaza, burbujas) | 1 608 | `mat_steel_brushed`, `mat_steel_dark`, `mat_steel_brushed_mid`, `mat_plastic_red`, `pot_water` |
| `lid` (tapa abierta 105°, pomo, pletinas) | 332 | `mat_steel_brushed`, `mat_steel_dark`, `mat_rubber` |
| `stove_base` (soporte, quemador de corona r = 0,25, mando, piloto) | 1 112 | `mat_steel_dark`, `mat_steel_brushed_mid`, `mat_steel_brushed`, `mat_rubber`, `mat_emissive_bulb` |
| `gas_bottle` (bombona, collarín, válvula, manguera roja al quemador y verde hacia el muro) | 392 | `mat_plastic_blue`, `mat_steel_brushed`, `mat_rubber_hose_red`, `mat_rubber_hose_green`, `mat_steel_dark` |
| **Total** | **3 444** (≤ 6 000, §4.1) | |

- Texturas: las de la biblioteca (steel_brushed 512² albedo/ORM/normal, plastic 512² albedo/ORM),
  embebidas y extraídas junto al `.glb`, más el **atlas propio `pot_water` de 256²** empaquetado en el
  `.blend` (§3.3): agua **opaca** (la transparencia es solo del tanque, §3.2) `#7C8E92` (L ≈ 0,26),
  AO horneado hacia la pared y ondas anchas de ±4 % (periodo 0,09 m, sin ruido fino). UV de caja a
  1 UV = 2 m (256 px/m); el agua mapea su atlas entero (≈ 365 px/m). `.png.import` con VRAM + mipmaps
  (+ `normal_map` en el normal).
- Contrastes del contenido sobre el agua (§6.1-4): crudo 1,8:1, cocido 1,8:1 (los dos más
  saturación rosa/rojo frente a gris azulado y el aro claro de la plaza), quemado 4,4:1 + humo.
- Contratos intactos: colisión, `AnchorPoint`, `CookBar`, `Highlightable`, audio y posiciones de
  `level_01` sin cambios; `Anchor_Slot_*`/`Anchor_Steam`/`Anchor_Fire` en las mismas coordenadas.
- `kitchen.tscn`: solo el `Fire` (PUL-069). El cuerpo cilíndrico ancho tapaba la llama central
  desde la cámara de 38°; ahora sale en **anillo** (`emission_ring_radius` 0,25 = corona del
  quemador), más corta (velocidad 0,15–0,3) para lamer el fondo, 28 partículas, degradado
  `fire_gas` azul → naranja (§2.2). Reposo/cocción (`amount_ratio`) sin tocar.
- Resaltado: el contorno de `highlight_outline` sobre las mallas funciona con la boca abierta (no
  rellena el agua ni el interior): **no hace falta `OutlineHull`** (`level_camera_after_highlight*`).
- Lo que no se hizo: piloto por estado (opcional, §6.5; el piloto ámbar es fijo y decorativo) y
  bombona/manguera hasta el muro del entorno (la bombona va en la esquina trasera del propio
  cocedor, a ≤ 0,5 m del centro).

**Hallazgo para PUL-073**: con la luz actual el acero metálico (`mat_steel_brushed`, metallic 1) de
las caras verticales refleja el suelo oscuro del cielo procedural y se ve **gris muy oscuro**, no el
`steel_light` de la referencia (pasa igual en la lámina Godot de PUL-074). Con un ambiente/cielo
más claro (≈ `#9AA6A8`, §1.3) se lee como acero claro: `level_camera_after_states_sky*` (variante solo
de captura, `capture_pot.gd ... sky`). La luz final (o una `ReflectionProbe`) debe dar algo claro que
reflejar al acero; el modelo no cambia.

Ficheros en `docs/evidence/PUL-078/`:
- `blender_render_game.png` (cámara ortográfica tipo nivel) y `blender_render_three.png` (3/4), Cycles
  con luz neutra: `render_pot.py`.
- `level_camera_{before,after}_{empty,states,highlight}[_zoom].png` y `level_camera_after_states_sky[_zoom].png`
  (`capture_pot.gd`; «antes» desde un worktree de la base). `states`: Kitchen con pulpo crudo
  cociendo + cachelos cocidos; Kitchen2 con pulpo cocido + quemado.
- `build_pot.py`: geometría y material del agua (reproducible).

Verificación: `tools/verify.sh` verde (720/720 tests, smoke OK; `test_assets_models.gd` incluido);
`tools/check_owns.py jrmougan/pul-078 jrmougan/agentica-migracion-godot-alpha` limpio.
Licencia: modelo y textura propios (D20); la registra el coordinador.
