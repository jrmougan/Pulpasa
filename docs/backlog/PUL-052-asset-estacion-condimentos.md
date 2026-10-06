---
id: PUL-052
title: Modelar la estación de condimentos
status: review
milestone: M3
role: asset-pipeline
agent: claude + MCP de Blender (PUL-043)
deps: [PUL-042, PUL-043, PUL-040, PUL-058]
orca_task: task_f17865c98aa1
unity_sources: []
owns: [art/blender/seasoning_station.blend, godot/assets/models/stations/seasoning_station/**, docs/evidence/PUL-052/**, godot/entities/stations/seasoning_station.tscn, godot/entities/stations/seasoning_dispenser.tscn, godot/entities/stations/cachelos_bowl.tscn]
touches_scenes: [godot/entities/stations/seasoning_station.tscn, godot/entities/stations/seasoning_dispenser.tscn, godot/entities/stations/cachelos_bowl.tscn]
---

## Target
D20: arte propio en Blender con un agente con MCP de Blender (pipeline de PUL-043), siguiendo la
biblia de arte (`docs/art/art-bible.md`, PUL-042).

## Change
1. Mesa de condimentos de D18 con pimentón dulce, pimentón picante, sal gorda, aceitera y cachelos, según el diseño de PUL-040 (lados por jugador si los hay).
2. Fuente en `art/blender/seasoning_station.blend`; export `.glb` en `godot/assets/models/stations/seasoning_station/` con
   `tools/blender_export.py`.
3. Sustituir el placeholder en su escena (`Model`), sin cambiar colisiones ni nodos de contrato
   (`scene-tree.md` §3) salvo que se pida. Depende del diseño de PUL-040; la escena de la estación la crea su ficha de gameplay.
4. Registrar la licencia (propia) en `docs/assets/licenses.md` → pedirlo al coordinador (fuera de `owns`).

## Ajustes de la biblia de arte (PUL-042)
Ajuste de la biblia (§4) y PUL-040 aprobada: recipientes **fijos** (no se manipulan); aceitera como pieza propia; anclas `Anchor_Tray` y por dispensador; dos lados (pase y condimentar) según la feature. Respeta los nodos de la escena de PUL-058.

Nota de PUL-049: si el modelo tiene mallas abiertas o huecas (cubas, cestos, baldas), el contorno inverted-hull del resaltado lo rellena entero. Solución usada: nodo `OutlineHull` con cajas cerradas ocultas y `Highlightable.root` apuntando a él; comprueba la captura resaltada.

## Constraints
- Presupuesto de polígonos, escala, frente −Z y paleta de la biblia de arte.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [x] AC1 Escala y frente correctos frente a `scale_check.tscn` → `test_assets_models.gd`
- [x] AC2 Legible desde la cámara del nivel: captura en `docs/evidence/PUL-052/`
- [x] AC3 `.blend` y `.glb` versionados; escena sin errores de import
- [x] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. Plantilla → `art/blender/seasoning_station.blend` (MCP de Blender, `execute_blender_code_for_cli`: el puerto
   9876 estaba ocupado por otro Blender y no se tocó). Tres raíces en tres colecciones, adaptadas a la geometría
   jugable de PUL-063/064 sin moverla: mostrador de pase 4,0 × 1,1 con la bandeja; los cuatro recipientes fijos
   como variantes de una pieza; el cuenco de cachelos.
2. Export con `tools/blender_export.py` a tres `.glb` hermanos en `assets/models/stations/seasoning_station/`
   (`--max-tris 1500` cada uno), con un envoltorio que renombra en memoria colección y `Anchor_Front`.
3. Escenas: `Model` instancia su `.glb` a escala 1; colisiones, marcadores, slot, dispensadores y cuenco intactos.
   Cada dispensador del mostrador enseña su variante por override de visibilidad (sin scripts nuevos).
   Cuenco abierto: `OutlineHull` con un cilindro cerrado transparente (nota de PUL-049).
4. Capturas desde la cámara de `level_01` y render del `.blend`.

## Evidence
- **Fuente**: `art/blender/seasoning_station.blend` (plantilla + `docs/evidence/PUL-052/build_seasoning_station.py`).
  Export reproducible: `docs/evidence/PUL-052/export_seasoning_station.sh`.
- **`.glb`** (`godot/assets/models/stations/seasoning_station/`, con `.import`):
  - `seasoning_station.glb` (360 tris): mostrador 3,92 × 1,02 × 1,0 de cuerpo, tablero `wood_light` 4,04 × 1,12 con la
    cara superior a y = 1,10 (donde apoyan los dispensadores), zócalo y listones `wood_dark`. Bandeja `tray`
    0,7 × 0,55 en x = +0,3, z = −0,25 con la cara de apoyo a y = 1,14 (el `Anchor` del slot) y borde oscuro.
    Lado de pase (−Z, frente, hacia la cocina): banda `canvas_stripe`. Lado de condimentar (+Z, hacia los puestos
    y la cámara): placa crema con el color de cada recipiente debajo de él (dulce, picante, sal, aceite, cachelos).
    Anclas: `Anchor_Tray`, `Anchor_Dispenser_<Nombre>` ×4, `Anchor_Bowl`, `Anchor_PassSide`, `Anchor_OperatorSide`.
  - `seasoning_dispenser.glb` (924 tris en total, ≤ 240 por variante visible): recipientes fijos ≤ 0,23 m de alto
    (art-bible §3.5), colores de la paleta §2.6/§3.4: `paprika_sweet` (lata `paprika_sweet` con faja crema y
    pimentón asomando), `paprika_hot` (lata `paprika_hot` con faja `iron_black`: más oscura y con otra faja, no
    solo otro tono), `salt` (cuenco de madera con sal gorda en granos) y `oil` (aceitera propia: cuerpo `oil`,
    cuello y pico `steel_grey`, asa `iron_black`).
  - `cachelos_bowl.glb` (224 tris): cuenco hondo de madera Ø 0,5 (fuera `wood_light`, borde `wood_dark`, dentro
    `wood_mid` para que destaquen los cachelos), fondo interior a y = 0,07 (`Anchor_Portions`).
- **Escenas** (`Model` a escala 1; colisiones, `%PassSide`/`%OperatorSide`, `Tray`, `Dispensers/*`, `CachelosBowl`,
  `%ErrorAudio`, `%Icon`, `%Portions` y `%Highlightable` se conservan; posiciones de PUL-063/064 sin cambios):
  - `seasoning_station.tscn`: `Model` = `seasoning_station.glb`; fuera el placeholder (`Counter`, `Top`, `TrayMesh`).
    Cada dispensador enseña su variante por override (`[editable path="Dispensers/<Nombre>"]`).
  - `seasoning_dispenser.tscn`: `Model` = `seasoning_dispenser.glb` (por defecto, `paprika_sweet`); sin `%Body`, así
    que `seasoning_dispenser.gd` ya no tiñe el bote con `SeasoningData.color` (lo admite: `get_node_or_null`). El
    color sale de la paleta; ojo, `salt.tres` tiene `color` turquesa (UI) y el bote es `salt` blanco de la biblia.
    Resaltado con el material por defecto sobre las mallas (sólidos cerrados).
  - `cachelos_bowl.tscn`: `Model` = `cachelos_bowl.glb`; `%Portions` baja a y = 0,07 (fondo del cuenco).
    `Highlightable.root` → `Model/OutlineHull` (cilindro cerrado con material transparente: el contorno no
    rellena el hueco del cuenco, nota de PUL-049).
- **Capturas** (`docs/evidence/PUL-052/`, cámara de `level_01`, 1920×1080, con recorte `_zoom` ×2;
  `capture_station.gd`): `level_camera_plain` (vacía), `level_camera_box` (caja con picante, sal, aceite y cachelos
  en la bandeja con su fila de pegatinas; Player1 en el lado de pase y Player2 en el de condimentar),
  `level_camera_hl_{SweetPaprika,HotPaprika,Salt,Oil,CachelosBowl}` (cada uno resaltado: contorno fino, el
  cuenco sin rellenar). Render del `.blend`: `blender_render_operator_side.png` y `blender_render_pass_side.png`.
- Limitación: un personaje justo delante de un recipiente lo tapa desde esta cámara (como cualquier estación); el
  icono flotante (`%Icon`) sigue visible.
- `tools/verify.sh` OK (645 tests; `test_m2b_station_selection.gd`, `test_seasoning_station.gd` y
  `test_station_level.gd` sin cambios). Licencia (propia): la registra el coordinador en `docs/assets/licenses.md`.
