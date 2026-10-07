---
id: PUL-087
title: Pasar el QA visual y de rendimiento de la estética v2
status: review
milestone: M3b
role: qa-tester
deps: [PUL-073, PUL-075, PUL-076, PUL-077, PUL-078, PUL-079, PUL-080, PUL-081, PUL-082, PUL-083, PUL-084, PUL-085, PUL-086]
orca_task: null
unity_sources: []
owns: [docs/evidence/PUL-087/**, docs/design/m3b-gate.md, docs/art/style-refs/**]
touches_scenes: []
---

## Target
Cierre de la estética v2 frente a la referencia (`docs/art/style-refs/referencia-elegida-2026-10-06.png`).

## Change
Capturas del mismo plano que `docs/art/style-refs/actual-2026-10-06/` (con `capture_style_refs.gd`) junto a la referencia; partida completa por modo con el MCP; medición de FPS y tiempo de frame a 1080p; lista de desajustes por asset; guía de revisión para el responsable (`m3b-gate.md`).

Notas de PUL-073: la energía del sol (1,34) la fija `test_level_01`; `scene-tree.md` no recoge aún los nodos `Bulbs` y `Vignette` de `environment.tscn` (pedir enmienda al arquitecto); costes de rendimiento estimados a medir aquí. Si el ambiente queda lejos de la referencia, proponer ajuste de `render_config.tres`.

Nota de PUL-085: los materiales embebidos de los .glb suman 83 recursos de material y 98 superficies en el entorno; comprobar frente al límite de §4.3 de la biblia v2 y proponer atlas/merge si afecta al rendimiento.

Nota de PUL-084: el pipeline extrae ~115 PNG con texturas de biblioteca duplicadas por .glb (~40 MB de VRAM); proponer deduplicación (materiales externos compartidos) si afecta.

Notas: el panel «Turno» del HUD (PUL-086, ×1,5 a 1080p) tapa parte del lateral izquierdo y de la estantería de bandejas (PUL-081); una bandeja llena de pulpo + cachelos ronda 2 430 tris (PUL-077). Revisar también que nada quede del arte v1 (p. ej. restos de `romeria`, placeholders) y la coherencia de color de la sal (PUL-086).

## Constraints
- Referencia visual: `docs/art/style-refs/referencia-elegida-2026-10-06.png`; reglas en `docs/art/art-bible.md` v2 (PUL-072) y materiales de PUL-074.
- Modela con el MCP de Blender (por CLI; no uses el puerto 9876 si hay un Blender del responsable).
  Godot para capturas siempre con `--audio-driver Dummy`.
- No cambies la jugabilidad: colisiones, anclas, nodos de contrato (`scene-tree.md`), posiciones en
  `level_01` y los tests de selección/entrega deben seguir en verde. Resaltado con contorno fino
  (`OutlineHull` si el modelo es abierto, nota de PUL-049).
- Conserva la legibilidad (biblia §3): siluetas, crudo/cocido/quemado, pegatinas, colores por puesto.
- Capturas desde la cámara de `level_01` (antes/después, con resaltado) y render del `.blend` en
  `docs/evidence/<id>/`. La licencia propia la registra el coordinador.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [x] AC1 Comparativa referencia / antes / después
- [x] AC2 60 fps a 1080p o lista de lo que lo impide
- [x] AC3 Partidas sin errores en consola
- [x] Captura antes/después desde la cámara del nivel y render del `.blend`
- [x] `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. `tools/verify.sh` de partida. Capturas `despues/` con `capture_style_refs.gd` (mismo plano que
   `actual-2026-10-06/`) y láminas referencia / antes / progreso / después por nivel y por zona;
   luminancia de PUL-073 y estadísticas globales de color frente a la referencia.
2. Script de medición (`measure_perf.gd`): partida real vía `GameState.start_level`, input del
   InputMap, sin vsync, 60 s por modo con y sin tilt-shift a 1920×1080; fps, frame, GPU, draw
   calls, primitivas, VRAM, materiales y luces. Coste por efecto apagándolos solo en la ejecución.
3. Partidas completas Individual y Local 2P con el MCP (menú → ronda de 300 s → game over →
   salir/reintentar/pausa) y consola.
4. Revisión por asset (restos v1, sal, HUD, bandejas, materiales/texturas duplicados), render del
   `.blend` del entorno por CLI, lista de desajustes y guía `docs/design/m3b-gate.md`.

## Evidence
Todo en `docs/evidence/PUL-087/README.md`. Resumen:
- AC1: `ac1_comparativa_nivel.png`, `ac1_comparativa_hud.png`, `ac1_zona_*.png`, `despues/`;
  luminancia jugable dentro de rango; desajustes D1–D9 (uno A: rótulo de comanda de los kioscos
  sin placa, PUL-083).
- AC2: **pasa**. 1080p en pantalla real: 426 fps (GPU 1,28 ms, p99 1,29) en Individual, 423 en 2P;
  con tilt-shift 382–385 fps (GPU 1,52). 690–729 draw calls, 5 omni sin sombra, VRAM 477 MB.
  Fuera de límite pero sin coste de fps: 239 recursos de material para 60 nombres y 341 PNG
  duplicados (D5, D6). Bajo Xvfb la medida no vale (12 fps por la presentación).
- AC3: **pasa**. Individual y Local 2P de 300 s hasta el game over (más salir, reintentar y pausa)
  con 0 errores del juego en consola (`partidas/`).
- Render del `.blend`: `render_environment_v2.png` (Blender 5.2.2 por CLI, sin el puerto 9876).
- Audio: capturas y medición con `--audio-driver Dummy`; el MCP no lo admite y se silenció con
  `AudioServer.set_bus_mute` al arrancar.
- `tools/verify.sh` verde (735/735 tests); `tools/check_owns.py` limpio.
