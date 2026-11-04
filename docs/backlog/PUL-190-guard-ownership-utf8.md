---
id: PUL-190
title: Hacer que guard_ownership lea UTF-8 y bloquee ante cualquier fallo
status: review
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
- [x] AC1 Given `current-task` = PUL-184, When se edita `Assets/x.txt`, Then rc=2 con el mensaje de `owns` → salida en docs/evidence/PUL-190/
- [x] AC2 Given `current-task` = PUL-184, When se edita una ruta de su `owns`, Then rc=0 → salida en docs/evidence/PUL-190/
- [x] AC3 Given todas las fichas de docs/backlog, When se ejecuta el hook con cada una en Windows, Then ninguna da rc=1 → salida en docs/evidence/PUL-190/
- [x] AC4 Given una ficha ilegible o una entrada JSON inválida, When se ejecuta el hook, Then rc=2 → salida en docs/evidence/PUL-190/
- [x] AC5 Given una ruta destino no ASCII, When se ejecuta el hook, Then decide por `owns` sin excepción → salida en docs/evidence/PUL-190/

## Plan
1. Línea base: un arnés `docs/evidence/PUL-190/run_acs.sh` (Git Bash, rutas `pwd -W`, sandbox con copia de
   `docs/backlog` y `.claude/current-task` propio, para no ensuciar el backlog real con fichas ilegibles) se ejecuta
   primero contra el hook antiguo: debe reproducir el rc=1.
2. Hook: pasar el cuerpo a `main()`; `sys.stderr.reconfigure` a UTF-8, `encoding="utf-8"` en fichas y `current-task`,
   JSON desde `sys.stdin.buffer` decodificado como UTF-8. `except Exception` alrededor de `main()` → exit 2 con mensaje.
   Marcador ausente o vacío se comprueba antes de leer la entrada: sigue sin restringir. Mensaje: `orchestration ask`.
3. Volver a pasar el arnés contra el hook nuevo, guardar la salida por AC y `tools/verify.sh --quick`.

## Evidence
Arnés: `docs/evidence/PUL-190/run_acs.sh <hook.py> <dir_salida>`, desde Git Bash en Windows 11, con rutas `pwd -W`,
Python 3.13.18, locale cp1252 (`env.txt`) y `PYTHONUTF8`/`PYTHONIOENCODING` sin definir. Usa un sandbox con copia de
`docs/backlog`, para que las fichas ilegibles de AC4 no toquen el backlog real. Resumen en `summary.txt`. La línea base
es el hook de `cac6ac1`, pasado por el mismo arnés.

| AC | Hook nuevo | Hook antiguo (`baseline/`) | Salida |
|---|---|---|---|
| AC1 | rc=2 con el mensaje de `owns` y `orchestration ask` | rc=1 (`UnicodeDecodeError`) | `ac1.txt` |
| AC2 | rc=0 en 4 rutas (literal, `**`, `*`, propia ficha) | rc=1 en las 4 | `ac2.txt` |
| AC3 | 188 fichas: 0 con rc=1; ajena rc=2, primera de `owns` rc=0, propia ficha rc=0 | 13 fichas con rc=1, las que cita la ficha | `ac3.txt` |
| AC4 | 35 de 35: rc=2 en los 26 casos de bloqueo y rc=0 en los 9 de control (BOM, `owns` con stderr cerrado, sin `current-task` o vacío) | 25 fallos: 10 con rc=0 donde debía bloquear, 11 con rc=1 y 4 con BOM | `ac4.txt` |
| AC5 | Decide por `owns` en 6 casos, con UTF-8 crudo y `\u`; 2 más con `PYTHONIOENCODING=cp1252` | rc=1 en la ficha PUL-184 | `ac5.txt` |

- **Entrada sin `file_path` de texto**: `{}`, `tool_input` vacío, otro campo (`path`) y `file_path` a `null`, `""`, `0`,
  `false`, `[]`, `{}` o `123` dan rc=2 con «entrada sin file_path válido». Antes, todos menos `123` daban rc=0.
- **Stderr cerrado** (`2>&-`): sin `current-task` o con él vacío, rc=0; con ficha activa, decide por `owns`.
- **BOM**: `current-task` o ficha con BOM ya no bloquean; decide `owns` (rc=0 dentro, rc=2 fuera).
- `file_path` con NUL da rc=2 por `owns` en Windows, no por excepción.
- `tools/verify.sh --quick`: `✓ verify OK` (`verify_quick.txt`).
- Hook sobre el worktree real, con `current-task` = PUL-190: `Assets/x.txt` da rc=2 y `.claude/hooks/guard_ownership.py` rc=0.
- **Linux** (WSL2 Ubuntu, Python 3.14.4, rutas POSIX, `linux/`): mismo resultado en todos los AC, `fallos=0`.

### Fallo abierto conocido
Medido con el comando real de `.claude/settings.json`, ficha activa y destino ajeno (`fail_open.txt`, igual en Windows y
Linux). Solo el 2 bloquea, así que en estos tres casos **la edición fuera de `owns` pasa**. Ocurren antes de que Python
ejecute el `try`, por lo que este hook no puede evitarlos.

| Caso | rc |
|---|---|
| Control: hook intacto | 2 |
| `PYTHONIOENCODING` inválida (`Fatal Python error`) | 1 |
| Intérprete ausente (simulado con un comando inexistente, sin quitar Python) | 127 |
| Hook que no compila | 1 |

El arreglo va en `.claude/settings.json`, fuera de `owns`: un envoltorio que convierta cualquier rc distinto de 0 y 2 en
2 y que falle cerrado si falta el intérprete. Requiere otra ficha.

### No verificado
- macOS: no hay máquina disponible.
