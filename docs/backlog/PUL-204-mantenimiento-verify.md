---
id: PUL-204
title: Ajustar timeouts, diagnóstico y documentación de verify
status: ready
milestone: M4
role: godot-architect
deps: []
orca_task: null
unity_sources: []
owns: [tools/verify.sh, .claude/hooks/verify_on_stop.sh, .claude/skills/godot-verify/SKILL.md, AGENTS.md, CLAUDE.md, tools/card_frontmatter.py, docs/evidence/PUL-190/run_acs.sh]
touches_scenes: []
---

## Target
`verify.sh`, hook de Stop, `godot-verify`, y dos flecos de PUL-190 y PUL-193.

## Change
- **R9:** `timeout 600` de GUT con una suite de ~488 s deja poco margen. Subirlo sin superar el `timeout` de 900 s del hook de Stop en `settings.json`; si no cabe, dilo.
- **Filtro de errores de `verify.sh`:** solo muestra la ubicación si la línea lleva `GDScript::reload` (se pierde la de `@static_initializer`), y `head -60` puede recortar la lista y su resumen.
- **Hook de Stop:** solo mira `godot/`; incluir `AGENTS.md` y `CLAUDE.md`.
- **Documentación:** `godot-verify` y la línea «Verificación completa» de `AGENTS.md` y `CLAUDE.md` no mencionan compilación ni sincronía; sin hacer crecer el texto más de lo necesario.
- **`card_frontmatter.py:27`:** cambiar el U+FEFF literal por el escape de Python.
- **`run_acs.sh`:** copiar `tools/card_frontmatter.py` al sandbox para que el control «hook intacto» vuelva a probar `owns` y no `ModuleNotFoundError`, y exigir al final los `ac*.txt` esperados.

## Constraints
No cambia qué se verifica. `AGENTS.md` y `CLAUDE.md` siguen idénticos.

## Acceptance
- [ ] AC1 Given un error en un `static var` y otro en un script distinto, When `verify.sh --quick`, Then rc≠0, y se ven la ubicación y el resumen → docs/evidence/PUL-204/
- [ ] AC2 Given `verify.sh` completo, When corre la suite, Then verde dentro del nuevo timeout → docs/evidence/PUL-204/
- [ ] AC3 Given `run_acs.sh`, When se ejecuta con el hook actual, Then el control bloquea por `owns` y con salida faltante falla → docs/evidence/PUL-204/

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker: salida de verify.sh, capturas, notas.)
