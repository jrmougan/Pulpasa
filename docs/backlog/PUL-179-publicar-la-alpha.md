---
id: PUL-179
title: Publicar la alpha (versión, notas y subida)
status: draft
milestone: M4
role: producer
deps: [PUL-176, PUL-177, PUL-178]
orca_task: null
unity_sources: []
owns: [godot/project.godot, docs/release/**, docs/evidence/PUL-179/**, docs/backlog/PUL-179-publicar-la-alpha.md]
touches_scenes: []
---

## Target
Puerta «Publicar alpha» aprobada con `m4-gate.md` (PUL-178). Builds de PUL-170 verificados en PUL-176.

## Change
1. Subir `config/version` a la versión de la alpha (p. ej. `0.4.0-alpha`; la fija el responsable) en el
   commit de release y etiquetarlo.
2. `docs/release/alpha.md`: notas de la versión (qué hay, controles, problemas conocidos de PUL-176/177,
   cómo enviar feedback) y requisitos mínimos.
3. Publicar los `.zip` donde y para quien decida el responsable (pregunta P4). Acción hacia fuera:
   **solo con confirmación explícita del responsable** en el momento de subir.

## Constraints
- `project.godot` solo para `config/version` (ficha sola en su oleada).
- Nada se publica sin el gate «Publicar alpha» aprobado y la confirmación de P4.

## Acceptance
- [ ] AC1 Versión de la alpha en `project.godot`, en los nombres de los `.zip` y en el menú (PUL-172).
- [ ] AC2 `docs/release/alpha.md` con notas, controles, problemas conocidos y canal de feedback.
- [ ] AC3 Enlace de la publicación y suma de comprobación de cada `.zip` en `docs/evidence/PUL-179/`.
- [ ] AC4 `tools/verify.sh` en verde; `check_owns` limpio.

## Plan
(Lo escribe el producer.)

## Evidence
(Lo rellena el producer.)
