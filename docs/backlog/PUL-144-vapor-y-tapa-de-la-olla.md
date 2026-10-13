---
id: PUL-144
title: Hacer visible el vapor de la olla y apoyar su tapa abierta
status: draft
milestone: M4
role: asset-pipeline
deps: [PUL-146]
orca_task: null
unity_sources: []
owns: [godot/entities/stations/kitchen.tscn, godot/assets/models/stations/pot/**, art/blender/pot.blend, godot/tests/integration/test_pot_visuals.gd*, docs/evidence/PUL-144/**, docs/backlog/PUL-144-vapor-y-tapa-de-la-olla.md]
touches_scenes: [godot/entities/stations/kitchen.tscn]
---

## Target
Desajustes D2 y D3 del QA de la estética v2 (`docs/evidence/PUL-087/README.md`), vivos en PUL-139:
- D2: el vapor apenas se ve; `Steam` (`GPUParticles3D` bajo `Model` en `kitchen.tscn`) sigue con
  `amount = 8`. La referencia muestra dos columnas de vapor claras «aquí se cuece».
- D3: la tapa abierta se lee como un disco gris flotando sobre la olla
  (`docs/evidence/PUL-087/zoom_ollas_pizarras.png`; sigue igual en `docs/evidence/PUL-139/pop/full_deliver_ok_0.png`).

## Change
1. Vapor más legible (más partículas o más grandes, alfa suave) **solo con la olla cociendo**, como lo
   gobierna hoy `cooking_station.gd`.
2. Tapa apoyada de forma creíble (menos inclinada, contra el muro o con bisagra visible) en
   `art/blender/pot.blend`, reexportada con `tools/blender_export.py` aplicando la convención de
   materiales y texturas compartidos de PUL-146.

## Constraints
- No cambiar el árbol contractual de `kitchen.tscn` (`docs/arch/scene-tree.md`): mismos nodos con
  nombre único, `Steam` sigue siendo el nodo de vapor. No tocar `cooking_station.gd`.
- Presupuesto de la biblia (`docs/art/art-bible.md` §4): tris de la olla dentro de su límite; GPU del
  nivel sin empeorar más de 0,1 ms en pantalla real (método de `docs/evidence/PUL-087/measure_perf.gd`).
- Legible a la cámara de juego de escritorio y de móvil.

## Acceptance
- [ ] AC1 Given la olla cociendo Then `Steam.emitting` es verdadero y con la olla vacía o cocido
  es falso (sin regresión) → `test_pot_visuals.gd`.
- [ ] AC2 Captura a 1920×1080 de las dos ollas cociendo, junto a la de PUL-087, con el vapor
  distinguible a simple vista → `docs/evidence/PUL-144/ac2-vapor.png`.
- [ ] AC3 Captura del mismo plano con la tapa apoyada (sin hueco visible entre la tapa y su apoyo) →
  `docs/evidence/PUL-144/ac3-tapa.png`; tris de `pot.glb` anotados.
- [ ] AC4 GPU medio del nivel ≤ el de PUL-087 + 0,1 ms (Individual, sin tilt-shift, pantalla real);
  `tools/verify.sh` en verde; `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker: salida de verify.sh, capturas, notas.)
