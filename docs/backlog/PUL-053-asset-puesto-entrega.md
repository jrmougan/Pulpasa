---
id: PUL-053
title: Modelar el puesto de entrega
status: done
milestone: M3
role: asset-pipeline
agent: claude + MCP de Blender (PUL-043)
deps: [PUL-042, PUL-043, PUL-039]
orca_task: task_c032c2088210
unity_sources: []
owns: [art/blender/order_stand.blend, godot/assets/models/stations/order_stand/**, godot/entities/stations/order_stand.tscn, godot/entities/stations/order_stand_model.gd, godot/entities/stations/order_stand_model.gd.uid, godot/tests/unit/test_order_stand_model.gd, godot/tests/unit/test_order_stand_model.gd.uid, docs/evidence/PUL-053/**]
touches_scenes: [godot/entities/stations/order_stand.tscn]
---

## Target
D20: arte propio en Blender con un agente con MCP de Blender (pipeline de PUL-043), siguiendo la
biblia de arte (`docs/art/art-bible.md`, PUL-042).

## Change
1. Mostrador/ventanilla de feria con número de puesto visible y sitio para el `#id` de la comanda.
2. Fuente en `art/blender/order_stand.blend`; export `.glb` en `godot/assets/models/stations/order_stand/` con
   `tools/blender_export.py`.
3. Sustituir el placeholder en su escena (`Model`), sin cambiar colisiones ni nodos de contrato
   (`scene-tree.md` §3) salvo que se pida. Si PUL-039 sigue abierta, espera a su merge (comparte `order_stand.tscn`).
4. Registrar la licencia (propia) en `docs/assets/licenses.md` → pedirlo al coordinador (fuera de `owns`).

## Ajustes de la biblia de arte (PUL-042)
Ajuste de la biblia (§4): 4 variantes de color de toldillo (puestos 1–4); el número es un `Label3D` del motor.

Nota de PUL-049: si el modelo tiene mallas abiertas o huecas (cubas, cestos, baldas), el contorno inverted-hull del resaltado lo rellena entero. Solución usada: nodo `OutlineHull` con cajas cerradas ocultas y `Highlightable.root` apuntando a él; comprueba la captura resaltada.

## Constraints
- Presupuesto de polígonos, escala, frente −Z y paleta de la biblia de arte.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [x] AC1 Escala y frente correctos frente a `scale_check.tscn` → `test_assets_models.gd`
- [x] AC2 Legible desde la cámara del nivel: captura en `docs/evidence/PUL-053/`
- [x] AC3 `.blend` y `.glb` versionados; escena sin errores de import
- [x] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. Plantilla → `art/blender/order_stand.blend` (MCP de Blender): mostrador de madera de 1,8 × 1,0 × 0,44 en la escena
   (`level_01` escala las instancias 0,78 × 0,975, fijado por `test_level_01.gd`: en el nivel mide 1,4 × 1,0 como pide
   §2.1), placa crema en el frente para el número de puesto, cuatro postes y toldillo inclinado hacia la cámara con
   faldón festoneado. Cuatro objetos `awning_1..4` (rayas crema + `canvas_stripe`/`bunting_blue`/`bunting_yellow`/
   `bunting_green`) y un cartel crema en el centro del toldillo como fondo del `#id`.
2. Export `--category stations --max-tris 1500`; `Model` instancia el `.glb` a escala 1 con el script de vista
   `order_stand_model.gd` (como `box_model.gd`): muestra `awning_<n>` según `slot_id` y escribe el número en el
   `Label3D` `StandNumber` sobre la placa. Test `test_order_stand_model.gd`.
3. Resaltado: material por defecto (sin contorno propio) sobre un `OutlineHull` de cajas cerradas ocultas (PUL-049).
   Se conservan colisiones, `%DeliveryZone`, `%OrderLabel` (recolocado sobre el cartel), audios, grupos y script.
4. Capturas desde la cámara de `level_01` (4 puestos, uno resaltado, personaje entregando) y render del `.blend`.

## Evidence
- `art/blender/order_stand.blend` (plantilla + `build_order_stand.py`, ejecutado con `execute_blender_code_for_cli` del MCP:
  el Blender del puerto 9876 era de otra sesión y no se tocó), `godot/assets/models/stations/order_stand/order_stand.glb`
  (+`.import`): 1 120 triángulos en total (≤ 1 500), de los que se ven 520 (mostrador 264 + cartel 24 + un toldillo 232).
- **Medidas**: en la escena, mostrador de 1,84 × 1,0 × 0,5 y toldillo hasta 1,83 m. `level_01` escala cada instancia
  0,78 × 0,975 × 0,975 (lo fija `test_ac2_stand_scale_matches_unity`, fuera de `owns`), así que en el nivel mide
  **1,43 de ancho × 0,975 de alto de mostrador** (art-bible §2.1: 1,4 × 1,0). `Model` va a escala 1 y la colisión
  (1,9 × 1,0 × 0,4) no cambia. El `order_stand.fbx` antiguo lo sigue usando `scale_check.tscn` (fuera de `owns`).
- **Variantes**: `awning_1..4` (rayas crema + `canvas_stripe`/`bunting_blue`/`bunting_yellow`/`bunting_green`, faldón
  festoneado). Script de vista `order_stand_model.gd` (`OrderStandModel`, en `Model`, como `box_model.gd`): enseña
  `awning_<posmod(slot_id−1, 4)+1>` y escribe el número en el `Label3D` nuevo `StandNumber` (oscuro, sobre la placa crema
  del frente del mostrador, `Anchor_Number`). Test: `tests/unit/test_order_stand_model.gd`.
- **`#id`**: sigue en `%OrderLabel` (billboard, sin depth test, mismo texto); se recoloca sobre el cartel crema del
  toldillo (`Anchor_Sign`) y pasa a texto oscuro con contorno crema, `pixel_size` 0,0045 para que quepa en el cartel.
- **Resaltado**: sin el material de contorno propio de PUL-039; `Highlightable` con el material por defecto y
  `root` en `OutlineHull` (cajas cerradas metidas dentro del mostrador y del toldillo, nota de PUL-049).
- Se conservan `%DeliveryZone`, colisiones, `%OkAudio`/`%ErrorAudio`, grupo `interactable` y `order_stand.gd`.
- Capturas en `docs/evidence/PUL-053/`: `level_camera_plain[_zoom].png` (los 4 puestos con número y `#id`; el 4 sin
  comanda, «–»; los `#id` se rellenan en la captura si la ronda aún no generó comandas) y
  `level_camera_highlight[_zoom].png` (puesto 2 resaltado, Player1 detrás con una caja); `blender_render.png`;
  scripts `build_order_stand.py`, `capture_stands.gd`.
- Limitación: el toldillo tapa el cuerpo de un cocinero pegado detrás del puesto (se le ve la cabeza), igual que el
  placeholder de 2 m.
- `tools/verify.sh` OK (645 tests). Licencia (propia): la registra el coordinador en `docs/assets/licenses.md`.
