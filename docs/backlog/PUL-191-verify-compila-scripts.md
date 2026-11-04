---
id: PUL-191
title: Detectar en verify.sh scripts que no compilan aunque ningún test los cargue
status: review
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
- [x] AC1 Given el proyecto limpio, When `tools/verify.sh --quick`, Then rc=0 con el paso en verde → salida en docs/evidence/PUL-191/
- [x] AC2 Given `var _x_err: String = 1` en un script de `core/` sin commitear, When `tools/verify.sh --quick`, Then rc≠0 y cita ese script → salida en docs/evidence/PUL-191/
- [x] AC3 Given el proyecto limpio, When `tools/verify.sh` completo, Then rc=0 → salida en docs/evidence/PUL-191/
- [x] AC4 Given Linux, When se repiten AC1 y AC2, Then mismo resultado; macOS se indica como «no verificable» si no hay máquina → docs/evidence/PUL-191/

## Plan
1. `tools/check_scripts.gd`: script `SceneTree` que recorre `res://` sin `addons/`, `.godot/` ni `.mcp/`, hace `load()` y
   `can_instantiate()` de cada `.gd`, lista los que fallan y sale con 1. Solo usa tipos del motor. Un recorrido vacío falla.
2. `tools/verify.sh`: paso nuevo tras el import, también en `--quick`, que exige rc=0 y la línea final de OK. Cabecera al día.
3. Skill `godot-verify`: documentar el paso.
4. Evidencia de AC1 a AC4 en `docs/evidence/PUL-191/`. Linux en un contenedor Docker, sin montar el worktree.

## Evidence
- AC1: `tools/verify.sh --quick` en Windows, rc=0, `check_scripts: OK (245 scripts)` → `docs/evidence/PUL-191/ac1_windows.txt`.
- AC2: con `var _x_err: String = 1` en `core/action_hint.gd`, sin commitear y ya revertido, rc=1 y cita `res://core/action_hint.gd`.
  El error va en orden de declaraciones: formato y lint pasan y solo falla el paso nuevo → `docs/evidence/PUL-191/ac2_windows.txt`.
- AC3: `tools/verify.sh` completo en Windows, rc=0, 1378 tests en verde y smoke OK → `docs/evidence/PUL-191/ac3_windows.txt`.
- AC4: AC1 y AC2 repetidos en Linux (contenedor Debian 13, Godot 4.7.2 oficial), mismo resultado →
  `docs/evidence/PUL-191/ac4_ac1_linux.txt`, `docs/evidence/PUL-191/ac4_ac2_linux.txt`, `docs/evidence/PUL-191/ac4_entorno.txt`.
  macOS: **no verificable**, no hay máquina macOS disponible.

Notas:
- Sin falsos positivos por los autoloads: los 245 scripts compilan, también con `.godot/` recién importado en Linux.
- El motor no marca siempre los dependientes: con el error de AC2, `action_prompt.gd` e `interaction_detector.gd` dan
  `SCRIPT ERROR` pero no salen en la lista de `check_scripts`. Por eso `verify.sh` falla también con cualquier `SCRIPT ERROR`.
- Prueba adicional, sin archivo de evidencia: un error de sintaxis en un autoload y otro de tipo en una suite a la vez dieron rc=1
  y los dos scripts en la lista, junto con los que dependen del autoload.
- Al salir, el paso imprime en bruto `ERROR` de fugas (RID, recursos). Son ruido y `verify.sh` no los cuenta ni los muestra.
