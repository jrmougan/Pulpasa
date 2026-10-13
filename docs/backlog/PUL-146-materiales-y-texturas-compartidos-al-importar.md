---
id: PUL-146
title: Compartir materiales y texturas entre los .glb y retirar la fuente v1
status: draft
milestone: M4
role: asset-pipeline
deps: []
orca_task: null
unity_sources: []
owns: [tools/blender_export.py, docs/art/pipeline.md, art/blender/romeria.blend, godot/assets/models/characters/**, godot/assets/models/environment/**, godot/assets/models/food/**, godot/assets/models/furniture/**, godot/assets/models/items/**, godot/assets/models/_pipeline/**, godot/assets/models/stations/box_shelf/**, godot/assets/models/stations/cachelos_storage/**, godot/assets/models/stations/octopus_storage/**, godot/assets/models/stations/order_stand/**, godot/assets/models/stations/seasoning_station/**, godot/assets/models/stations/trash_bin/**, godot/assets/textures/shared/**, godot/tests/unit/test_assets_shared.gd*, docs/evidence/PUL-146/**, docs/backlog/PUL-146-materiales-y-texturas-compartidos-al-importar.md]
touches_scenes: []
---

## Target
Desajustes D5, D6 y D9 (resto) del QA de la estética v2 (`docs/evidence/PUL-087/README.md`), vivos
en PUL-139:
- D5: cada `.glb` embebe su copia de `mat_steel_*`, `mat_rubber`, etc.: 60 materiales por nombre pero
  239 recursos en pantalla. Ninguno de los 40 `*.glb.import` de `godot/assets/models/` usa materiales
  externos.
- D6: 367 PNG en `godot/assets/models/**`, solo 64 distintos (md5).
- D9b: `art/blender/romeria.blend` (fuente del entorno v1) sigue en el repo; ninguna escena usa ya sus
  modelos (`environment.tscn` carga `romeria_v2/*.glb`).

## Change
1. Convención de import: los materiales de la biblioteca v2 (`godot/assets/materials/v2/*.tres`) se
   enlazan como externos al importar cada `.glb` (sin editar esos `.tres`), y las texturas repetidas
   se sirven desde `godot/assets/textures/shared/`; documentarlo en `docs/art/pipeline.md` y, si hace
   falta, en `tools/blender_export.py`.
2. Aplicarla a todos los modelos de `owns` (la olla, `stations/pot/`, la aplica PUL-144).
3. Borrar `art/blender/romeria.blend` tras confirmar que nada lo referencia.

## Constraints
- **Pregunta para el responsable**: ¿los 256 MB de memoria de texturas del nivel (`docs/art/art-bible.md`
  §4.2) cuentan solo los assets o el total de vídeo (412 MB hoy, 314 de ellos de render)? Decide si el
  AC3 mide assets o total; la ficha queda en `draft` hasta la respuesta.
- Mismo aspecto: ningún cambio visible. No tocar `mat_steel_brushed_top.tres` ni `render_config.tres`
  (PUL-145), ni `stations/pot/` (PUL-144), ni ningún `.tscn`. No inventar `uid://`: reimportar con Godot.
- **Script de captura**: `docs/art/style-refs/capture_style_refs.gd` está desfasado (usa
  `data/boxes/large.tres`/`medium.tres` y `hot_paprika`/`salt`/`oil`, retirados por D25, líneas 7–12, y
  llama a `toggle_seasoning`, línea 103, que la `Box` actual no tiene: la API es `apply_seasoning`). No se
  edita: el worker lo copia en `docs/evidence/PUL-146/capture_style_refs.gd`, lo adapta a la caja única
  (`data/boxes/box.tres`) y a los aliños actuales (`data/seasonings/sweet_dressing.tres`,
  `hot_dressing.tres`, `cachelos.tres`, con `apply_seasoning`) y usa **exactamente esa copia y ese
  estado de partida** para el antes y el después. Las dos ejecuciones deben salir con **cero errores**
  de script o de carga (salida anotada en Evidence).
- Si un `.tscn` necesita cambios para enlazar materiales, parar y pedir ampliación al coordinador.

## Acceptance
- [ ] AC1 Recursos de material distintos en pantalla en `level_01` ≤ 70 (hoy 235–239), contados como
  en PUL-087 → `docs/evidence/PUL-146/ac1_materiales.txt`.
- [ ] AC2 PNG en `godot/assets/models/**` sin duplicados por md5 fuera de `stations/pot/` (hoy 367 para
  64 distintos) → `test_assets_shared.gd` o script en `docs/evidence/PUL-146/`.
- [ ] AC3 Memoria de texturas de los assets del nivel ≤ 30 MB (hoy ~97 MB), método de
  `docs/evidence/PUL-087/perf/base_mem.gd` → `docs/evidence/PUL-146/ac3_memoria.txt`.
- [ ] AC4 Sin cambio visible, por revisión humana: capturas antes y después del reimport tomadas
  sobre el mismo commit base de la rama (antes = ese commit sin el cambio; después = con el cambio), con
  la misma copia adaptada `docs/evidence/PUL-146/capture_style_refs.gd` (ver Constraints), la misma cámara, resolución y estado
  de partida, en lámina lado a lado por plano → `docs/evidence/PUL-146/ac4-antes-despues.png`. No se
  usa umbral de píxeles (skill `godot-verify`) ni las capturas de PUL-087, anteriores a
  PUL-101/113/114/125/131. `art/blender/romeria.blend` borrado.
- [ ] AC5 `tools/verify.sh` en verde (incluye `test_assets_models.gd`); `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker: salida de verify.sh, capturas, notas.)
