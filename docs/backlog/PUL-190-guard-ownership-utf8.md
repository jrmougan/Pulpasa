---
id: PUL-190
title: Hacer que guard_ownership lea UTF-8 y bloquee ante cualquier fallo
status: ready
milestone: M4
role: godot-architect
deps: []
orca_task: null
unity_sources: []
owns: [.claude/hooks/guard_ownership.py]
touches_scenes: []
---

## Target
`.claude/hooks/guard_ownership.py`.

## Change
En Windows, `read_text()` usa cp1252 y falla con `UnicodeDecodeError` al leer fichas UTF-8 con ciertos caracteres
(13 hoy, entre ellas PUL-175 y PUL-184). El hook sale con código 1, que Claude Code trata como no bloqueante: **la
edición fuera de `owns` se permite**. Reproducido el 2026-11-04 con `current-task` = PUL-184 y destino `Assets/x.txt`.

- Leer con `encoding="utf-8"` las fichas y `current-task`, y la entrada JSON como UTF-8 con independencia de la consola.
- Cualquier excepción inesperada bloquea (exit 2) con un mensaje claro.
- Mensajes de stderr en UTF-8: hoy salen con caracteres rotos.
- El mensaje de bloqueo cita un comando que no existe (`orca ask`): cambiarlo por `orchestration ask` (binario según CLAUDE.md).

## Constraints
Sin `current-task`, el hook sigue sin restringir nada. No cambia el formato de `owns`. Unificar el parser con
`tools/check_owns.py` queda fuera de esta ficha.

## Acceptance
- [ ] AC1 Given `current-task` = PUL-184, When se edita `Assets/x.txt`, Then rc=2 con el mensaje de `owns` → salida en docs/evidence/PUL-190/
- [ ] AC2 Given `current-task` = PUL-184, When se edita una ruta de su `owns`, Then rc=0 → salida en docs/evidence/PUL-190/
- [ ] AC3 Given todas las fichas de docs/backlog, When se ejecuta el hook con cada una en Windows, Then ninguna da rc=1 → salida en docs/evidence/PUL-190/
- [ ] AC4 Given una ficha ilegible o una entrada JSON inválida, When se ejecuta el hook, Then rc=2 → salida en docs/evidence/PUL-190/
- [ ] AC5 Given una ruta destino no ASCII, When se ejecuta el hook, Then decide por `owns` sin excepción → salida en docs/evidence/PUL-190/

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker: salida de verify.sh, capturas, notas.)
