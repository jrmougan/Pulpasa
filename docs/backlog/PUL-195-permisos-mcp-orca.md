---
id: PUL-195
title: Ajustar los permisos de settings.json a las recetas actuales
status: done
milestone: M4
role: godot-architect
deps: []
orca_task: null
unity_sources: []
owns: [.claude/settings.json]
touches_scenes: []
---

## Target
`.claude/settings.json`, lista `permissions.allow`.

## Change
La lista no cubre las recetas de `godot-verify` y `orca-dispatch`, y permite una tool que falla.

- Añadir `mcp__godot__run_project`, `mcp__godot__simulate_input`, `mcp__godot__get_ui_elements`, `Bash(orca status:*)`, `Bash(orca skills get:*)`, `Bash(orca-ide status:*)` y `Bash(orca-ide skills get:*)`.
- Quitar `mcp__godot__get_scene_tree` mientras godot-mcp-runtime#73 no esté publicado.

## Constraints
Solo estos cambios. `tools/merge_gate.sh` y `mcp__godot__run_script` no se añaden: los decide el responsable. Hooks y `enabledMcpjsonServers` no se tocan.

## Acceptance
- [x] AC1 Given `settings.json`, When se valida como JSON, Then es válido y contiene exactamente esos cambios → diff en docs/evidence/PUL-195/

## Plan
Aplicar `## Change` tal cual en `permissions.allow`.

## Evidence
- Aprobado por el responsable en la sesión del 2026-11-04: lista entera, incluidos `mcp__godot__run_project` y `Bash(orca ...)` en el fichero compartido con Linux.
- AC1: `docs/evidence/PUL-195/ac1.diff` (7 entradas añadidas, `get_scene_tree` quitada) y `ac1.txt` (JSON válido, 18 entradas).
- `tools/verify.sh --quick`: OK.
- No verificado: que `godot-mcp-runtime#73` siga sin publicar (lo dicen la ficha y ADR-001), y el efecto de los permisos en una sesión real, porque se leen al arrancar.
