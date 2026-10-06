---
id: PUL-089
title: Ajustar el cielo y los reflejos para que el acero se lea claro
status: ready
milestone: M3b
role: asset-pipeline
deps: [PUL-073]
orca_task: null
unity_sources: []
owns: [godot/data/config/render_config.tres, godot/resources/render_config.gd, godot/tests/unit/test_render_config.gd, docs/evidence/PUL-089/**]
touches_scenes: []
---

## Target
Hallazgo de PUL-078 (`docs/evidence/PUL-078/level_camera_after_states*_zoom.png`): con la luz v2 el
acero metálico (ollas, y lo serán encimeras, estación y tanque) sale gris muy oscuro en las caras
verticales porque refleja el suelo oscuro del cielo procedural; con un cielo más claro se lee como
acero claro, como en la referencia (`docs/art/style-refs/referencia-elegida-2026-10-06.png`).

## Change
Ajustar en `render_config.tres` el cielo/fuente de reflejos y la luz ambiental (p. ej. suelo del
cielo procedural más claro y cálido, `reflected_light_source`, energía de ambiente/reflejos) para que
los materiales `mat_steel_*` de PUL-074 se lean como en la lámina de Blender, sin quemar el resto ni
romper la comprobación de luminancia de PUL-073 (AC2: pegatinas, números, aros). No toques
`environment.tscn` (lo tiene PUL-085).

## Constraints
- Godot siempre con `--audio-driver Dummy`. Datos en `.tres`.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [ ] AC1 Las ollas de PUL-078 se leen como acero claro desde la cámara del nivel (captura antes/después)
- [ ] AC2 Comprobación de luminancia de PUL-073 (`docs/evidence/PUL-073/check_luminance.py`) sin fallos
- [ ] AC3 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
