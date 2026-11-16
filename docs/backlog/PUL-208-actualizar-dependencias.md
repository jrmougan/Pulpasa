---
id: PUL-208
title: Actualizar el toolchain de mise y godot-mcp-runtime a 4.0.1
status: review
milestone: M4
role: godot-architect
deps: []
orca_task: null
unity_sources: []
owns: [mise.toml, .mcp.json, docs/art/pipeline.md, docs/design/decisions.md]
touches_scenes: []
---

## Target
`mise.toml`, `.mcp.json` (MCP `godot` y `blender`), `docs/art/pipeline.md` §2 y T5 de `docs/design/decisions.md`.
Rama `jrmougan/deps-update` (PR #4).

## Change
- mise: node 24 → 26 (LTS), python 3.13 → 3.14, uv 0.12 → 0.13, `min_version` 2026.10.1 → 2026.11.8. jq 1.8 y gdtoolkit 4.5.0 sin cambios.
- `.mcp.json`: `godot-mcp-runtime@3.8.1` → `@4.0.1` (major) y `--python 3.13` → `3.14` en la entrada `blender`; `pipeline.md` §2 igual.
- T5 de `decisions.md` pasa a `godot-mcp-runtime@4.0.1`.
- Cambios incompatibles de 4.0: `attach_project`/`detach_project` pasan a `run_project({attach: true})`/`stop_project`
  (solo salen en evidencias históricas); se retira el gate de escaneo de GDScript (`GODOT_MCP_STRICT`,
  `GODOT_MCP_DISABLE_SECURITY`, no se usan); respuestas en JSON estructurado.

## Constraints
- T5 está en `decisions.md`: el cambio de versión es gate humano y solo se propone con una sesión MCP real.
- ADR-001 Enmienda 1 (línea 136, `godot-mcp-runtime@3.8.1`) es contrato: no se toca aquí; solo se informa si queda desfasada.
- Sin cambios en `godot/`. Godot 4.7.2 no lo gestiona mise.

## Acceptance
- [x] AC1 Given el binario oficial de Godot 4.7.2, When se comprueba con `SHA512-SUMS.txt` de la release, Then coincide → docs/evidence/PUL-208/ac1-godot-instalado.txt
- [x] AC2 Given `.mcp.json`, When se arranca `godot-mcp-runtime@4.0.1` por stdio y se llaman `run_project({attach: true})`, `take_screenshot` y `simulate_input` sobre level_01 (y en modo `background`, con `get_debug_output`), Then ninguna devuelve error, las capturas no están en blanco y no hay `ERROR` del juego → docs/evidence/PUL-208/ac2-*
- [x] AC3 Given la entrada `blender` de `.mcp.json`, When se arranca con uv 0.13 y `--python 3.14`, Then responde a `initialize` y `tools/list` → docs/evidence/PUL-208/ac3-blender-mcp-py314.txt
- [x] AC4 Given la rama, When `tools/verify.sh` con Godot 4.7.2, Then verde → docs/evidence/PUL-208/ac4-verify.txt
- [x] AC5 Given ADR-001:136, When se prueba una operación headless (`get_scene_tree`) con 4.0.1, Then se informa si la nota sigue vigente → docs/evidence/PUL-208/ac5-headless-get-scene-tree.txt

## Plan
1. Instalar Godot 4.7.2 en espacio de usuario (no lo gestiona mise) y comprobar su SHA512.
2. Sesión MCP real con un cliente mínimo del SDK (scripts `mcp_session_*.mjs` en la evidencia), Godot bajo `xvfb-run`.
3. Arrancar `blender-mcp` con la entrada de `.mcp.json`.
4. `tools/verify.sh` y `tools/merge_gate.sh` sobre `main`.

## Evidence
- AC1: SHA512 coincide; `godot --version` → `4.7.2.stable.official.ed1daf0bf`.
- AC2: attach (`sessionMode: attached`) + `take_screenshot` (`likelyBlank: false`) + `simulate_input` (`p1_move_right`,
  `p1_move_up`, `Escape` abre `PauseMenu`) + `stop_project`, todo `isError=false`; log de Godot sin `ERROR`. En
  `background: true`, `get_debug_output` solo da el `WARNING` de xic de X11 (ruido conocido). Capturas en JPG.
  El árbol de trabajo queda limpio tras la sesión (el puente se retira de `project.godot`).
- AC3: `blender-mcp` 1.30.0 (v1.0.3) arranca con Python 3.14.7 y lista 26 herramientas. No verificable contra Blender:
  no está instalado en esta máquina.
- AC4: `tools/verify.sh` OK: 245 scripts, GUT 1380/1380 (30407 asserts), smoke OK.
- AC5: con 4.0.1, `get_scene_tree` headless de level_01 funciona. El contexto de ADR-001 Enmienda 1 (fallo de 3.8.1
  por `untyped_declaration`, godot-mcp-runtime#73) queda desfasado; la ADR no se cambia (contrato, gate humano).
  También lo repiten `.claude/skills/gdscript-conventions/SKILL.md:31` y la retirada del permiso de `get_scene_tree` (PUL-195).
- Gate humano de T5: las pruebas de AC2 lo respaldan; lo cierra el responsable al mergear la PR #4.
