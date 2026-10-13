---
id: PUL-145
title: Ajustar el ambiente y el brillo del acero delantero a la referencia
status: draft
milestone: M4
role: asset-pipeline
deps: []
orca_task: null
unity_sources: []
owns: [godot/data/config/render_config.tres, godot/assets/materials/v2/mat_steel_brushed_top.tres, godot/entities/environment/environment.tscn, godot/tests/unit/test_render_config.gd, docs/evidence/PUL-145/**, docs/backlog/PUL-145-ambiente-y-acero-delantero.md]
touches_scenes: [godot/entities/environment/environment.tscn]
---

## Target
Desajustes D4 y D7 del QA de la estética v2 (`docs/evidence/PUL-087/README.md`), vivos en PUL-139:
- D4: más claro y amarillo que la referencia (luma media 0,51 frente a 0,42; contraste 0,147 frente a
  0,165; tono 41° frente a 31°, `docs/evidence/PUL-087/ac1_color_global.txt`). Hoy
  `render_config.tres` tiene `ambient_light_energy = 0.5` y `adjustment_contrast = 1.1`.
- D7: el acero de la fila delantera y de la columna derecha sale casi blanco con manchas de las
  bombillas; en la referencia es gris azulado mate. `mat_steel_brushed_top.tres` no ha cambiado desde
  PUL-074 ni las luces de `environment.tscn` desde PUL-085.

## Change
1. Aplicar la propuesta de PUL-087 (o la que decida el responsable): `ambient_light_energy` 0,5 → 0,4,
   `adjustment_contrast` 1,1 → 1,15, sin tocar la saturación.
2. Bajar el brillo del acero delantero (`specular`/`roughness` de `mat_steel_brushed_top` o energía
   especular de las omni de `Bulbs`). **Orden**: hoy los `.glb` embeben su copia de
   `mat_steel_brushed_top` y no enlazan el `.tres` (D5), así que editar el `.tres` no cambia el nivel.
   Si se elige esa vía, PUL-145 va **después de PUL-146** (que enlaza los materiales v2 como externos)
   y pasa a `deps: [PUL-146]`; la vía de las omni de `Bulbs` no depende de PUL-146.
3. Volver a medir color global y luminancia con los scripts de PUL-087 y PUL-073.

## Constraints
- **Pregunta para el responsable (gate)**: es una decisión de dirección de arte. ¿Se aplica la
  propuesta de PUL-087 (valores de arriba)? ¿Se oscurece también el suelo de arena (PUL-085), que es de
  donde viene lo amarillo? La ficha queda en `draft` hasta la respuesta.
- Ninguna zona jugable fuera de 0,08–0,95 de luminancia por mediana (§6.1-6,
  `docs/evidence/PUL-073/check_luminance.py`). Saturación sin bajar de 0,31.
- Si se ajusta `mat_steel_brushed_top.tres`, comprobar antes que algún `.glb` del nivel lo enlaza
  (tras PUL-146); si no, el cambio no tiene efecto y la ficha se para.
- No cambiar el árbol de `environment.tscn` (`Bulbs`, `Vignette`, `scene-tree.md` §8). Datos en `.tres`.

## Acceptance
- [ ] AC1 Captura nueva y reproducible del plano 00 de `docs/art/style-refs/capture_style_refs.gd`
  (1920×1080, comando y commit anotados en Evidence), antes y después del ajuste sobre el mismo commit:
  la de después con luma media entre 0,40 y 0,46 y contraste ≥ 0,16 →
  `docs/evidence/PUL-145/ac1_color_global.txt` (script `color_stats.py` de PUL-087). `despues/00` de
  PUL-087 (luma 0,51, anterior a M3c–M3e) queda solo como referencia, no como medida.
- [ ] AC2 Luminancia por zona jugable dentro de 0,08–0,95 → `docs/evidence/PUL-145/ac2_luminancia.txt`.
- [ ] AC3 Acero delantero: luma media del recorte de la encimera Z1 ≤ 0,75, medida sobre las
  capturas nuevas de AC1 (antes y después), y comparativa para revisión humana →
  `docs/evidence/PUL-145/ac3-acero.png`.
- [ ] AC4 `test_render_config.gd` fija los valores nuevos; `tools/verify.sh` en verde; `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker: salida de verify.sh, capturas, notas.)
