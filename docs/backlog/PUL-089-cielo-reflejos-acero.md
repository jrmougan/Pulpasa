---
id: PUL-089
title: Ajustar el cielo y los reflejos para que el acero se lea claro
status: done
milestone: M3b
role: asset-pipeline
deps: [PUL-073]
orca_task: task_0bcfc9b82a99
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
- [x] AC1 Las ollas de PUL-078 se leen como acero claro desde la cámara del nivel (captura antes/después)
- [x] AC2 Comprobación de luminancia de PUL-073 (`docs/evidence/PUL-073/check_luminance.py`) sin fallos
- [x] AC3 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
Aclarar en `render_config.tres` el cielo procedural (suelo y horizonte pasan de verde oliva oscuro a gris claro cálido, que es lo que refleja el acero en las caras verticales). Sin tocar ambiente ni `environment.tscn`. Medir con `check_luminance.py` y añadir test.

## Evidence
- Cambio: `ProceduralSkyMaterial` en `render_config.tres`: top (0.6,0.66,0.68), horizon (0.84,0.85,0.83), ground_bottom (0.6,0.64,0.64), ground_horizon (0.79,0.81,0.8). `reflected_light_source` ya era Sky; ambiente sin cambios.
- AC1: `docs/evidence/PUL-089/antes/` vs `despues/` (`level_camera_*_states_zoom.png`, script `docs/evidence/PUL-078/capture_pot.gd`): las ollas pasan de gris verdoso oscuro a acero claro.
- AC2: `docs/evidence/PUL-089/ac2_luminancia.txt`: sin FALLA (ninguna zona <0,08 ni >0,95 de mediana).
- AC3: test nuevo `test_sky_reflects_light_for_steel`; `tools/verify.sh` y `check_owns` verdes.
