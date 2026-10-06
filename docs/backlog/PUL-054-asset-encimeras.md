---
id: PUL-054
title: Modelar las encimeras modulares
status: done
milestone: M3
role: asset-pipeline
agent: claude + MCP de Blender (PUL-043)
deps: [PUL-042, PUL-043, PUL-041]
orca_task: task_d66fdf5940e1
unity_sources: []
owns: [art/blender/counters.blend, godot/assets/models/furniture/counters/**, godot/entities/environment/kitchen_layout.tscn, godot/assets/models/furniture/**, docs/evidence/PUL-054/**]
touches_scenes: [godot/entities/environment/kitchen_layout.tscn]
---

## Target
D20: arte propio en Blender con un agente con MCP de Blender (pipeline de PUL-043), siguiendo la
biblia de arte (`docs/art/art-bible.md`, PUL-042).

## Change
1. Kit modular de mesas/encimeras de pulpería (recta, esquina, extremo) en cuadrícula de 1 m para montar la planta elegida en PUL-041.
2. Fuente en `art/blender/counters.blend`; export `.glb` en `godot/assets/models/furniture/counters/` con
   `tools/blender_export.py`.
3. Sustituir el placeholder en su escena (`Model`), sin cambiar colisiones ni nodos de contrato
   (`scene-tree.md` §3) salvo que se pida. Depende de la planta elegida (PUL-041).
4. Registrar la licencia (propia) en `docs/assets/licenses.md` → pedirlo al coordinador (fuera de `owns`).

## Ajustes de la biblia de arte (PUL-042)
Ajuste de la biblia (§4) y planta B elegida: kit de 1 m repetible más módulos de 2 y 3 m, módulo de pasaplatos (mesa a dos caras) y tablero a 1,0 m de altura. Cantidad y disposición según `docs/design/level-layouts.md` (planta B).

Nota de PUL-049: si el modelo tiene mallas abiertas o huecas (cubas, cestos, baldas), el contorno inverted-hull del resaltado lo rellena entero. Solución usada: nodo `OutlineHull` con cajas cerradas ocultas y `Highlightable.root` apuntando a él; comprueba la captura resaltada.

Nota de PUL-051: la estantería de cajas (1,8 m de ancho) queda en parte dentro de la pared oscura de la planta B; las paredes y encimeras nuevas deben dejarla libre y visible.

## Constraints
- Presupuesto de polígonos, escala, frente −Z y paleta de la biblia de arte.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [x] AC1 Escala y frente correctos frente a `scale_check.tscn` → `test_assets_models.gd`
- [x] AC2 Legible desde la cámara del nivel: captura en `docs/evidence/PUL-054/`
- [x] AC3 `.blend` y `.glb` versionados; escena sin errores de import
- [x] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. Plantilla → `art/blender/counters.blend` (MCP de Blender, `execute_blender_code_for_cli`; no se tocó el
   puerto 9876). Kit en cuadrícula de 1 m, una raíz por colección: encimera perimetral (1, 2, 3 m, media,
   esquina, extremo), pasaplatos a dos caras (1, 2, 3 m, extremo) y barrera baja del público.
2. Export con `tools/blender_export.py` (`--max-tris 300`) a `.glb` hermanos en
   `assets/models/furniture/counters/`, con el envoltorio de PUL-052 que renombra en memoria colección y `Anchor_Front`.
3. `kitchen_layout.tscn`: fuera las mallas placeholder; cada `StaticBody3D` lleva un `Model` con los módulos.
   Colisiones, capa `world`, posiciones y huellas sin cambios. Única excepción (nota de PUL-051): `WallLeftFront`
   pasa a barrera baja (misma huella, 0,6 m de alto) para no tapar la estantería de cajas.
4. Capturas desde la cámara de `level_01`, `scale_check` y render del `.blend`.

## Evidence
- **Fuente**: `art/blender/counters.blend` (plantilla + `docs/evidence/PUL-054/build_counters.py`). Export
  reproducible: `docs/evidence/PUL-054/export_counters.sh`.
- **`.glb`** (`godot/assets/models/furniture/counters/`, con `.import`), todos ≤ 170 tris (presupuesto 300),
  origen en el centro de la base, frente −Z, paleta `wood_light`/`wood_mid`/`wood_dark` (+ `canvas_stripe`,
  `canvas_cream`), mismo lenguaje que el mostrador de PUL-052 (zócalo, listones y moldura oscuros):
  - Encimera (tablero a y = 1,00, fondo 1 m = la celda; vuelo al frente dentro de la huella):
    `counter_1m` (60), `counter_2m` (70), `counter_3m` (80), `counter_half` (0,5 m, 60), `counter_corner`
    (listones en el frente y los dos costados, 120) y `counter_end` (costados oscuros en los dos extremos: sirve de
    remate por cualquier lado, 80). Un listón en cada extremo del módulo marca la junta de 1 m.
  - Pasaplatos (mesa a dos caras, tablero a y = 1,10, vuelo a los dos lados): `pass_1m` (110), `pass_2m` (140),
    `pass_3m` (170), `pass_end` (130). Banda `canvas_stripe` en el lado de la cocina, continua con la del mostrador
    de condimentos, y una tabla `wood_mid` embutida (3 mm) en el centro de cada metro: el sitio de cada `Slot`.
  - `rail_1m` (70): barrera baja del público, 0,6 m, faldón `canvas_cream` con banda roja y postes oscuros.
- **Escena** `kitchen_layout.tscn`: los nodos `Mesh` placeholder (y `ph_wood`/`ph_dark`) se sustituyen por `Model`
  con los módulos: barra 2+2 m (cocina) y 3+1+extremo (servicio), con cada metro centrado en su `PassSlot`;
  encimeras del fondo esquina+media, 1, 1 y 3+2+2+esquina; paredes laterales 3+1+extremo y 3+3+2+1+extremo
  (encimeras de cara a la sala); barandilla del público con `rail_1m` estirado en X a su ancho. Colisiones, capa
  `world`, posiciones y huellas sin cambios. **Excepción** (nota de PUL-051): `WallLeftFront` es barrera baja
  (3 × `rail_1m`) y su colisión baja de 1,0 a 0,6 m con la misma huella, para que la estantería de cajas se vea
  entera. La estación de condimentos no se duplica (ocupa su hueco de 4 m en la barra).
- **Desviaciones de la biblia**: fondo 1,0 m (no 0,8) para que la malla llene la huella de colisión de la celda;
  pasaplatos a 1,10 (no 1,0) porque es la altura fija del `Anchor` de los `Slot` (test_level_01) y del mostrador de PUL-052.
- **Capturas** (`docs/evidence/PUL-054/`, `capture_counters.gd`, 1920×1080 desde la cámara de `level_01`):
  `level_camera_plain` (nivel completo) con recortes ×2 `_bar_left`, `_bar_right`, `_corner_shelf` (estantería
  libre y visible) y `_corner_right`; `level_camera_boxes` (cajas de los tres tamaños en cuatro huecos del pase) y
  sus recortes; `scale_check.png` (kit junto al cubo de 1 m y el personaje); render del `.blend`: `blender_render.png`.
- `tools/verify.sh` OK (645 tests; `test_assets_models.gd` valida los 11 `.glb`; `test_level_01`,
  `test_m2b_flow`, `test_delivery_e2e`, `test_station_level` en verde). `check_owns` limpio.
  Licencia (propia): la registra el coordinador en `docs/assets/licenses.md`.
