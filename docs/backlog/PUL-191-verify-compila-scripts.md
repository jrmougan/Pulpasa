---
id: PUL-191
title: Detectar en verify.sh scripts que no compilan aunque ningún test los cargue
status: ready
milestone: M4
role: godot-architect
deps: []
orca_task: null
unity_sources: []
owns: [tools/verify.sh, tools/check_scripts.gd*, .claude/skills/godot-verify/SKILL.md]
touches_scenes: []
---

## Target
`tools/verify.sh`, script nuevo `tools/check_scripts.gd` y la skill `godot-verify`.

## Change
Ni el import ni el smoke detectan errores de tipo: con `var _x_err: String = 1` en `core/action_hint.gd`, ambos dieron
rc=0 y 0 errores. Además, `--quick` no parsea, aunque la cabecera de `verify.sh` lo diga.

Añadir tras el import, también en `--quick`, un paso con un script `SceneTree` que haga `load()` y `can_instantiate()`
de todos los `.gd` salvo `addons/`, `.godot/` y `.mcp/`, liste los que fallan y salga con código distinto de 0. En una
prueba previa en Windows revisó 245 scripts en 4 s y señaló el script con el error. Actualizar godot-verify y la cabecera de `verify.sh`.

## Constraints
No relajar `untyped_declaration`. Un script `-s` se compila antes de los autoloads: el arranque no debe referenciar
nada del proyecto. Si el paso da falsos positivos por ello, la ficha se para y se pregunta.

## Acceptance
- [ ] AC1 Given el proyecto limpio, When `tools/verify.sh --quick`, Then rc=0 con el paso en verde → salida en docs/evidence/PUL-191/
- [ ] AC2 Given `var _x_err: String = 1` en un script de `core/` sin commitear, When `tools/verify.sh --quick`, Then rc≠0 y cita ese script → salida en docs/evidence/PUL-191/
- [ ] AC3 Given el proyecto limpio, When `tools/verify.sh` completo, Then rc=0 → salida en docs/evidence/PUL-191/
- [ ] AC4 Given Linux, When se repiten AC1 y AC2, Then mismo resultado; macOS se indica como «no verificable» si no hay máquina → docs/evidence/PUL-191/

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker: salida de verify.sh, capturas, notas.)
