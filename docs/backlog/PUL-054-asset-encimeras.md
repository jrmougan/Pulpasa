---
id: PUL-054
title: Modelar las encimeras modulares
status: ready
milestone: M3
role: asset-pipeline
agent: claude + MCP de Blender (PUL-043)
deps: [PUL-042, PUL-043, PUL-041]
orca_task: null
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
- [ ] AC1 Escala y frente correctos frente a `scale_check.tscn` → `test_assets_models.gd`
- [ ] AC2 Legible desde la cámara del nivel: captura en `docs/evidence/PUL-054/`
- [ ] AC3 `.blend` y `.glb` versionados; escena sin errores de import
- [ ] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
