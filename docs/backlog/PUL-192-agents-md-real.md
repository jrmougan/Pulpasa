---
id: PUL-192
title: Convertir AGENTS.md en el fichero real de contexto y CLAUDE.md en su import
status: blocked
milestone: M4
role: godot-architect
deps: []
orca_task: null
unity_sources: []
owns: [AGENTS.md, CLAUDE.md, .claude/skills/orca-dispatch/SKILL.md]
touches_scenes: []
---

## Target
`AGENTS.md`, `CLAUDE.md` y `.claude/skills/orca-dispatch/SKILL.md`.

## Change
`AGENTS.md` es un symlink en git (modo 120000). Con `core.symlinks=false` en Windows se materializa como un texto de
9 bytes que dice «CLAUDE.md», y Codex, que hace las revisiones, puede no recibir las reglas.

- `AGENTS.md` pasa a ser un fichero normal con el contenido actual de `CLAUDE.md`, más una línea que diga que los
  hooks de `.claude/` solo corren en Claude Code: fuera de él, la barrera es `tools/merge_gate.sh`.
- `CLAUDE.md` queda solo con `@AGENTS.md`.
- Retirar de orca-dispatch el aviso de que `AGENTS.md` no contiene el contexto en Windows y la petición de leer
  `CLAUDE.md` en los specs de agentes no Claude y de revisión.

## Constraints
No se pierde ni se relaja ninguna regla no negociable. El contenido no crece salvo esa línea.

## Acceptance
- [ ] AC1 Given la rama, When `git ls-files -s AGENTS.md`, Then modo 100644 y en Windows el fichero tiene las reglas completas → salida en docs/evidence/PUL-192/
- [ ] AC2 Given una sesión nueva de Claude Code, When se pregunta por la regla 1, Then la cita desde el contexto cargado → nota en docs/evidence/PUL-192/
- [ ] AC3 Given un worker Codex en Windows, When se le pide citar la regla 1 sin indicarle el fichero, Then la cita; si no se puede lanzar, «no verificable» con motivo → nota en docs/evidence/PUL-192/

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker: salida de verify.sh, capturas, notas.)
