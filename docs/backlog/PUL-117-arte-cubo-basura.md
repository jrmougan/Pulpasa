---
id: PUL-117
title: Arte del cubo de basura (dirección A, D22)
status: in_progress
milestone: M3d
role: asset-pipeline
deps: [PUL-112]
orca_task: null
unity_sources: []
owns: [art/blender/trash_bin.blend, godot/assets/models/stations/trash_bin/**, godot/assets/models/trash_bin/**, godot/entities/stations/trash_bin.tscn, docs/evidence/PUL-117/**, docs/backlog/PUL-117-arte-cubo-basura.md]
touches_scenes: [godot/entities/stations/trash_bin.tscn]
---

## Target
Sustituir el modelo provisional del cubo (PUL-112) por uno propio con la estética de D22 (diorama de romería, franquicia PulpaSA) y la señalética de pase de D23, con la tapa que reacciona al tirar (≥ 0,3 s, `cubo-basura.md` T4).

## Acceptance
- [x] AC1 Modelo importado con colisión igual a la provisional
- [x] AC2 Se lee como cubo de basura a 1080p desde la cámara (captura)
- [x] AC3 `tools/verify.sh` en verde

## Plan
1. `art/blender/trash_bin.blend` desde `_template.blend` (script batch de Blender, materiales v2 enlazados): cubo troncocónico azul (`mat_plastic_blue`) con aros y asas de acero, borde de acero, pictograma de papelera marino sobre placa de papel en el frente, bolsa negra asomando y tapa basculante roja (`Lid`, objeto aparte con el origen en la bisagra, entreabierta 8 grados) para animarla despues. Se distingue de la olla (acero, sin color, con hornillo) por color y tapa.
2. Export con `blender_export.py --category stations` a `godot/assets/models/stations/trash_bin/`; se fijan en los `.png.import` los ajustes de pipeline.md §8.5.
3. `trash_bin.tscn`: el `.glb` sustituye a los dos `CylinderMesh` bajo `Model`, girado 180 grados (el frente del `.glb` es -Z y la camara mira desde +Z); colision, `Highlightable` y `Feedback` intactos.
4. Capturas en `docs/evidence/PUL-117/` y `tools/verify.sh`.

## Evidence
- Triangulos: 776 (7 objetos; presupuesto de estacion 6 000, objetivo 3 500). Texturas: las de la biblioteca v2 (steel_brushed, plastic, cloth), 512 px, sin atlas propio.
- Dimensiones: radio maximo 0,325 m (tapa) y 0,66-0,70 m de alto sin la tapa inclinada; base en y = 0. La colision (cilindro r 0,3 / h 0,8) no se toca.
- [`level_01_cubos.png`](../evidence/PUL-117/level_01_cubos.png): `level_01` a 1280x720 con el cubo de la cocina y el del servicio (AC2).
- [`level_01_cubo_resaltado.png`](../evidence/PUL-117/level_01_cubo_resaltado.png): cubo del servicio resaltado.
- [`cubo_cerca_resaltado.png`](../evidence/PUL-117/cubo_cerca_resaltado.png): primer plano, uno resaltado y otro normal (pictograma visible).
- El resaltado funciona: `Highlightable` pone el contorno en `material_overlay` de todas las mallas del `.glb` (cuerpo, herrajes, bolsa, tapa, placa).
- `tools/verify.sh` en verde (AC3); `check_owns.py` limpio.
