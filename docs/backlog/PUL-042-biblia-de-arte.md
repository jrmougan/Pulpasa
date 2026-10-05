---
id: PUL-042
title: Escribir la biblia de arte y la lista de assets
status: done
milestone: M2
role: game-designer
deps: []
orca_task: task_dad4b30f62dd
unity_sources: []
owns: [docs/art/**]
touches_scenes: []
---

## Target
D20: arte propio hecho en Blender por un agente con MCP. Antes de modelar hace falta una biblia
de arte común para que las piezas casen entre sí.

## Change
`docs/art/art-bible.md`:
1. Estilo (low-poly estilizado o el que se proponga), referencias (romería gallega, pulpería,
   caldeiro de cobre, platos de madera), paleta en hex, tratamiento de materiales (color plano,
   texturas pequeñas o atlas).
2. Reglas técnicas: unidades (1 u = 1 m, escala frente a `scale_check.tscn`), presupuesto de
   polígonos por tipo, orientación (frente −Z en Godot), origen, nombres, export glTF 2.0 (`.glb`),
   ruta `.blend` → `art/blender/<asset>.blend` y `.glb` → `godot/assets/models/<categoría>/<asset>/`.
3. Legibilidad desde la cámara ortográfica: siluetas, contraste del pulpo crudo/cocido y de los
   cachelos crudo/cocido, distintivos de la caja (D18).
4. Revisión de la lista de assets de las fichas PUL-044..PUL-055 (añadir o quitar lo que falte).

## Constraints
- Solo documentación. Coherente con D14 (3D ortográfico) y D18.

## Acceptance
- [x] AC1 Biblia con estilo, paleta, reglas técnicas y de legibilidad
- [x] AC2 Lámina de referencia/moodboard (imágenes propias o descripciones; sin imágenes de terceros sin licencia, D16)
- [x] AC3 Lista de assets revisada frente a PUL-044..PUL-055

## Plan
1. Leer fichas PUL-043..PUL-055, `decisions.md` (D14, D16, D18, D20), `scale_check.tscn`, cámara y placeholders para fijar medidas reales.
2. Escribir `docs/art/art-bible.md`: estilo, referencias descritas, paleta hex, reglas técnicas, legibilidad y revisión de la lista de assets.
3. Lámina propia `docs/art/moodboard.svg` (sin imágenes de terceros) y captura en evidencia.
4. Comprobar contrastes de luminancia citados, `tools/verify.sh` y `check_owns`.

## Evidence
- `docs/art/art-bible.md`: §1 estilo/referencias, §2 reglas técnicas y paleta, §3 legibilidad (pulpo, cachelos, cajas/distintivos D18), §4 revisión de PUL-044..055, §5 checklist por asset.
- `docs/art/moodboard.svg` (obra propia) y su render `docs/evidence/PUL-042/moodboard.png`.
- Contrastes calculados (WCAG): pulpo crudo/cocido 3,1:1; patata cruda/cocida 3,3:1.
- Revisión de assets: 7 fichas con ajuste (044, 046, 047, 052, 053, 054, 055), sin fichas que quitar; faltan pegatinas (a PUL-047), botes manipulables (tras PUL-040) y VFX (ficha posterior).
- Pendiente de coordinador: la ficha PUL-054 menciona módulos que dependen de PUL-041; las fichas de asset aún no referencian las rutas/tris de la biblia, solo `art-bible.md` en general.
