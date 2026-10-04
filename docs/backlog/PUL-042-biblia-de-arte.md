---
id: PUL-042
title: Escribir la biblia de arte y la lista de assets
status: ready
milestone: M2
role: game-designer
deps: []
orca_task: null
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
- [ ] AC1 Biblia con estilo, paleta, reglas técnicas y de legibilidad
- [ ] AC2 Lámina de referencia/moodboard (imágenes propias o descripciones; sin imágenes de terceros sin licencia, D16)
- [ ] AC3 Lista de assets revisada frente a PUL-044..PUL-055

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
