---
id: PUL-082
title: Rehacer la estación de condimentos
status: done
milestone: M3b
role: asset-pipeline
deps: [PUL-072, PUL-074]
orca_task: task_fd1017ef4b79
unity_sources: []
owns: [art/blender/seasoning_station.blend, godot/assets/models/stations/seasoning_station/**, godot/entities/stations/seasoning_station.tscn, godot/entities/stations/seasoning_dispenser.tscn, godot/entities/stations/cachelos_bowl.tscn, docs/evidence/PUL-082/**]
touches_scenes: [godot/entities/stations/seasoning_station.tscn, godot/entities/stations/seasoning_dispenser.tscn, godot/entities/stations/cachelos_bowl.tscn]
---

## Target
Adaptar este asset a la estética elegida por el responsable (`docs/art/style-refs/referencia-elegida-2026-10-06.png`).

## Change
Mostrador de acero con botes/latas de pimentón dulce y picante, salero, aceitera, cuenco de cachelos y tabla de corte; geometría jugable de PUL-063/064 sin mover.

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
1. `art/blender/seasoning_station.blend` desde `_template.blend` (materiales v2 enlazados), regenerado con el MCP
   de Blender por CLI (`execute_blender_code_for_cli`; el puerto 9876 lo ocupaba otro Blender y no se tocó) a partir de
   `docs/evidence/PUL-082/build_seasoning_station.py`. Mismas tres raíces y nombres de malla que PUL-052, así las
   escenas (overrides de visibilidad por variante, `OutlineHull` del cuenco) siguen valiendo sin tocarlas.
2. Mostrador de acero (biblia v2 §8): tablero `mat_steel_brushed_top` limpio (Z1), faldón `mat_steel_brushed` con
   etiquetas de color y tornillos (Z2), patas, balda y fondo `mat_steel_brushed_mid`, cajas `mat_cardboard` en la balda,
   bandeja de apoyo `mat_steel_dark` con reborde, tabla de corte `mat_wood_used` y cuchillo en la franja trasera.
3. Recipientes: lata redonda (dulce), lata cuadrada redondeada y más alta (picante), salero de barro con sal gorda,
   aceitera esmaltada; cuenco de cachelos de barro (`mat_clay`). Los colores de §2.5 no están en la biblioteca: van en el
   atlas propio del asset (512², empaquetado en el `.blend`, §3.3).
4. Export con `tools/blender_export.py` (envoltorio `export_seasoning_station.sh`), import con los ajustes de
   `pipeline.md` §8.5, capturas antes/después desde la cámara de `level_01` y render del `.blend`.

## Evidence
- **Fuente**: `art/blender/seasoning_station.blend` (lleva el script como Text). Reproducible: copiar
  `_template.blend` → `seasoning_station.blend` y ejecutar `build_all()` de
  [`build_seasoning_station.py`](../evidence/PUL-082/build_seasoning_station.py); export con
  [`export_seasoning_station.sh`](../evidence/PUL-082/export_seasoning_station.sh) (presupuestos 4 000 / 1 500 / 500).
- **Triángulos** (§4.1, estación ≤ 6 000 el conjunto): `seasoning_station.glb` 1 252 (mostrador 964, bandeja 188,
  tabla 100); `seasoning_dispenser.glb` 1 264 en total, visibles por variante: dulce 224, picante 280, sal 456,
  aceite 304; `cachelos_bowl.glb` 280. **En el nivel: 2 796.**
- **Texturas** (§4.2): solo biblioteca v2 (`steel_brushed`, `steel_brushed_top`, `cardboard`, `wood_used`,
  `wood_dark`, `clay`, más `steel_dark`/`steel_brushed_mid`/`rubber` sin textura propia) a 1 UV = 2 m (256 px/m) y el
  atlas propio `seasoning_station_atlas` 512² (colores de condimento §2.5, etiquetas, fajas de lata, polvo y sal con
  grumos ≥ 8 px, tornillos; etiquetas ≈ 365 px/m). Embebidas en los `.glb`; Godot las extrae junto a ellos (25 PNG,
  ≈ 970 KiB en disco, todos con VRAM + mipmaps y `normal_map` en los `_normal`). `.glb.import` con
  `ensure_tangents=true` (normal maps).
- **Jugabilidad sin cambios**: colisiones, `%PassSide`/`%OperatorSide`, `Tray` (apoyo a y = 1,14), `Dispensers/*`
  (z = +0,45), `CachelosBowl` (x = −1,8, `%Portions` a y = 0,07), anclas `Anchor_*` y posición en `level_01` idénticas;
  las tres `.tscn` no cambian (mismos nombres e índices de nodo en los `.glb`). Atrezo de Z1 (tabla y cuchillo) en
  z ≤ −0,30 (franja trasera ≤ 25 %), ≤ 0,05 m de alto y a ≥ 0,6 m de cualquier ancla; las cajas de la balda, sin colisión.
- **Legibilidad (§2.5, §6.5)**: cada recipiente ≤ 0,24 m y del color de su condimento; dulce/picante se separan por
  silueta (redonda baja / cuadrada alta), tono y faja (papel / negra), y la etiqueta del picante lleva chispas; etiquetas
  de color en el frente del faldón bajo cada recipiente y el cuenco, como la referencia. Sal: color de la biblia
  (`#F7F4EC`, borde `#6E4A2B`), no el turquesa de UI de `salt.tres`.
- **Resaltado (§6.1-7)**: perfiles sin cornisas hacia fuera: el `highlight_outline` crece radial desde el origen y
  pintaba rayas sobre las fajas de la primera versión; corregido, el contorno es fino y limpio en los cuatro
  recipientes; el cuenco sigue con su `OutlineHull` (mismo perfil que la v1).
- **Capturas** (`docs/evidence/PUL-082/`, 1920×1080 desde la cámara de `level_01`, con recorte `_zoom` ×2;
  [`capture_station.gd`](../evidence/PUL-082/capture_station.gd)): `before_level_camera_{plain,box,hl_HotPaprika,
  hl_CachelosBowl}` (v1 de PUL-052) y `after_level_camera_{plain,box,hl_SweetPaprika,hl_HotPaprika,hl_Salt,hl_Oil,
  hl_CachelosBowl}`. Render Cycles del `.blend` (luz neutra; [`render_seasoning_station.py`](../evidence/PUL-082/render_seasoning_station.py)):
  `blender_render_operator.png`, `blender_render_pass.png`, `blender_render_detail.png`.
- **Luz**: capturas con la luz actual del nivel (v1); PUL-073 llega en paralelo. Con ella el acero metálico de la
  biblioteca se ve oscuro y azulado (no hay reflejos del entorno), igual que en la lámina de PUL-074; se revisará al
  entrar la luz v2. Las encimeras vecinas siguen siendo las de madera v1 hasta PUL-084.
- `tools/verify.sh` verde y `check_owns` limpio. Licencia (propia, atlas procedural sin terceros): la registra el
  coordinador.
