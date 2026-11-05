---
id: PUL-199
title: Hacer que el hook de ownership falle cerrado y actúe desde subcarpetas
status: review
milestone: M4
role: godot-architect
deps: []
orca_task: null
unity_sources: []
owns: [.claude/settings.json, .claude/hooks/guard_ownership.py, .claude/hooks/run_guard.sh, docs/evidence/PUL-190/run_acs.sh]
touches_scenes: []
---

## Target
Entradas de hooks de `.claude/settings.json` y `guard_ownership.py`.

## Change
La regla 1 tiene dos huecos, medidos en PUL-190 y en la revisión de PUL-192:
- **Fallo abierto antes del `try`:** intérprete ausente (rc=127), hook que no compila (rc=1), `PYTHONIOENCODING` inválida (rc=1) y `PYTHONUTF8=9` (rc=1) dejan pasar la edición. Un envoltorio convierte todo rc distinto de 0 y 2 en 2, y falla cerrado sin intérprete. `except Exception` tampoco cubre `BaseException`.
- **Sesión arrancada en `godot/`:** una sola prueba indica que los hooks no actuaron. Hay que confirmarlo y averiguar la causa; si es `$CLAUDE_PROJECT_DIR` o la resolución de `settings.json`, corregirlo. Si no se puede corregir desde el repo, documentar el límite y qué lo cubre.

Añadido por el coordinador durante la ficha: el `timeout` del hook de Stop pasa de 900 s a 1500 s. PUL-204 calcula que el peor caso de `tools/verify.sh` son 1453 s (import 300, compilación 300, GUT 720, smoke 120, lint 13). `tools/verify.sh` no se toca aquí: PUL-204 sube GUT a 720 s en otra rama.

Añadido por el coordinador tras la revisión: `owns` incluye `docs/evidence/PUL-190/run_acs.sh`, porque su medición de `fail_open.txt` depende del comando del hook.

## Constraints
Funciona en Windows (Git Bash), Linux y macOS. No toca `permissions`. No relaja el bloqueo actual. Si el entorno impide editar los hooks de `settings.json`, status=blocked y explícalo.

## Acceptance
- [x] AC1 Given esos cuatro casos, When se ejecuta el comando real del hook, Then rc=2 y la edición se bloquea → docs/evidence/PUL-199/
- [x] AC2 Given una ruta dentro de owns y otra fuera, When se ejecuta el comando real, Then rc=0 y rc=2 → docs/evidence/PUL-199/
- [x] AC3 Given una sesión `claude -p` real arrancada en la raíz y en `godot/` con `current-task`, When intenta editar fuera de owns, Then se bloquea, o queda documentado por qué no y qué lo cubre → docs/evidence/PUL-199/

## Plan
1. Medir sin cambiar nada: reproducir los fallos abiertos con el comando actual de `settings.json` (arnés de PUL-190) y repetir sesiones `claude -p` reales en un clon temporal, desde la raíz y desde `godot/`, con el hook instrumentado solo en el clon.
2. Averiguar la causa del caso `godot/` antes de cambiar nada: si los hooks se cargan, qué vale `$CLAUDE_PROJECT_DIR` y qué devuelve el comando.
3. Implementar `run_guard.sh` y un comando de `settings.json` que falle cerrado también si falta el envoltorio. Sin tocar `permissions`.
4. Verificar AC1-AC3 con salida real y documentar lo que siga abierto.

## Evidence
Todo en `docs/evidence/PUL-199/`, medido en Windows 11, Git Bash, Claude Code 2.1.318, Python 3.13. Las sesiones usan `--model haiku` y `--no-session-persistence`, en clones temporales fuera del repo.

**Línea base, sin cambiar nada** (`baseline_ac.txt`, comando anterior): PYTHONIOENCODING inválida rc=1, PYTHONUTF8=9 rc=1, sin python rc=127, hook que no compila rc=1. También dejaban pasar: `guard_ownership.py` vacío rc=0, señal rc=137, stub de la Store rc=49. El `except BaseException` ya estaba en el hook: `SystemExit` y `KeyboardInterrupt` dan rc=2 antes y después.

**Causa del arranque en `godot/`** (`sessions/baseline.txt`, `sessions/probe.txt`, `sessions/probe_hooklog.txt`, `sessions/only_project.txt`). Es la resolución de `settings.json`, no `$CLAUDE_PROJECT_DIR` en el comando:
- Reproducible, 5 de 5 en cada caso: raíz bloquea; `godot/` y `godot/core/` crean el fichero. El control sin marcador crea desde ambos.
- Claude Code solo lee `<cwd>/.claude/settings.json` del directorio de arranque, sin subir a los padres. Un hook de registro en el `settings.json` de la raíz no se dispara nunca desde `godot/` (0 de 9 sesiones, 3 de ellas con `CLAUDE_PROJECT_DIR` heredado). Otro en `godot/.claude/settings.json` sí se dispara desde `godot/` (6 de 6), y tampoco sube un nivel: no se dispara desde `godot/core/` (0 de 3).
- `$CLAUDE_PROJECT_DIR` vale siempre el directorio de arranque y Claude Code ignora el heredado (`godot_inherit` y `root_other`, 3 de 3 cada uno).
- Con `--setting-sources project`, desde `godot/` no hay ningún evento PreToolUse (3 de 3) y desde la raíz bloquea (3 de 3). El único evento que se ve desde `godot/` con la configuración por defecto es un hook de usuario o de plugin, ajeno al repo, con rc=0.
- Es comportamiento observado en esta versión, sin leer el código de Claude Code.

**Cambio.** `run_guard.sh` en POSIX sh: sin marcador sale con 0 sin Python; si no, todo rc distinto de 0 y 2 pasa a 2; también bloquea sin intérprete y con el hook ausente o vacío. Toma el repositorio de su propia ubicación. El comando de `settings.json` falla cerrado por sí solo si falta el envoltorio o está vacío, sin depender de ningún fichero. `permissions` no cambia. `guard_ownership.py` solo cambia en su docstring.

**AC1** (`ac1_ac2.txt`): los cuatro casos dan rc=2, también con destino dentro de `owns`. Sesión real desde la raíz, 2 de 2 sin crear el fichero en cada uno: `sessions/real_utf8.txt`, `real_ioenc.txt`, `real_nopy.txt` (sin python de verdad en el PATH), `real_nocompile.txt`. Sin envoltorio: `real_nowrapper.txt`.

**AC2** (`ac1_ac2.txt`): dentro de `owns` rc=0 (literal, otra entrada, ficha, evidence, marcador); fuera rc=2 (también parecida a `owns`, no ASCII y JSON inválido). Igual con `sh -c` (`ac1_ac2_sh.txt`), con dash como `sh` (`ac1_ac2_dash.txt`) y en un directorio con espacios y `ñ` (`ac1_ac2_espacios.txt`). El arnés de PUL-190 da 0 fallos (`pul190_arnes_summary.txt`), y su `fail_open.txt` bloquea cada fila por su causa real, comprobada en la salida (ver «Revisión», B1).

**AC3** (`sessions/after.txt`), con el cambio: raíz, bloquea 5 de 5. `godot/` y `godot/core/`, **no se bloquea**, 5 de 5 crean el fichero. Tras `cd godot` en una sesión arrancada en la raíz, bloquea 3 de 3 (`after_cd.txt`; el `root_cd` de `probe.txt` no cuenta: esa sesión no llegó a llamar a Bash). Control sin marcador, crea 3 de 3 desde cada sitio (`after_control.txt`).

Por qué no se corrige desde `owns`: el `settings.json` de la raíz no llega a leerse en esa sesión, así que nada de lo que contenga puede actuar.

Qué lo cubre, y hasta dónde:
- `tools/check_owns.py` en el merge gate rechaza la rama con rutas fuera de `owns`, se editen como se editen (`check_owns_negativo.txt`, rc=1, sobre esta rama con una base anterior). Tiene tres límites: solo comprueba ramas cuyo nombre contiene `pul-N` (`check_owns.py:17-20`; con otro nombre sale con 0, comprobado con `main`) y sin `--allow-outside-owns` (`merge_gate.sh:10-11`); lee `owns` de la propia rama (`check_owns.py:42`), así que una rama puede ampliar su lista; y no ve lo que no está commiteado.
- Los workers de Orca: que arrancan en la raíz de su worktree es una inferencia. `orca-dispatch` dice que cada ficha tiene su worktree (`--worktree new-child`), pero no habla del directorio de arranque, y no lo he medido.

El hueco real es una sesión arrancada en una subcarpeta: edita sin aviso y, como mucho, se entera en el merge.

**Lo que sigue abierto** (medido):
- Arranque en subcarpeta, como arriba. Un `godot/.claude/settings.json` que apunte al envoltorio de la raíz bloquea desde `godot/` (`sessions/candidate.txt`, 3 de 3), pero no desde `godot/core/` (3 de 3 crean). Está fuera de `owns`, no se ha añadido.
- Subagente con `isolation: worktree` (preexistente, según la revisión): `CLAUDE_PROJECT_DIR` queda en la raíz de la sesión y el `cwd` en el worktree, así que el hook busca el marcador en la raíz y no ve el del worktree. No queda protegido. Reproducido solo el mecanismo con el comando real (rc=0, «Abierto conocido» en `ac1_ac2.txt`); esos valores de entorno son de la revisión, no los he medido en una sesión.
- Timeout del hook: si PreToolUse tarda más que su `timeout`, Claude Code lo cancela y **la edición pasa** (`sessions/hook_timeout.txt`, 3 de 3, con un hook de prueba de 2 s). No se puede cerrar desde el hook.
- Un fichero que sigue siendo código válido y sale con 0 no se distingue del hook: envoltorio o hook sustituidos, o truncados en un punto válido (sección «Abierto conocido» de `ac1_ac2.txt`). Lo cubren el merge gate y la revisión.
- Si Claude Code no puede ejecutar la shell del hook, nada de esto corre. No medido.

**Efecto colateral del cierre:** sin marcador, si falta el envoltorio se bloquea toda edición, también la del producer (`real_nowrapper_nomark.txt`); se recupera con git. Lo mismo sin `sh` en el PATH o con `CLAUDE_PROJECT_DIR` vacío (`ac1_ac2.txt`, N3): el mensaje del comando ahora incluye la ruta buscada, y con la variable vacía se ve `/.claude/hooks/run_guard.sh`; sin `sh`, la shell dice `sh: command not found`. Con `--settings ../.claude/settings.json` desde `godot/` también se bloquea todo, porque el comando busca el envoltorio en el directorio de arranque (`settings_flag.txt`).

**Stop:** `timeout` de 900 a 1500 s, a petición del coordinador (peor caso de `verify.sh` según PUL-204: 1453 s). Comprobado solo el valor del JSON; no se ha ejecutado un Stop de esa duración.

**No verificable:**
- Linux y macOS: no hay máquina aquí y WSL está excluido por el encargo. Corregido tras la revisión: `dash` existe en Git Bash y el envoltorio pasa con él como `sh` (`ac1_ac2_dash.txt`, «sh del PATH: no es bash»). Sigue sin ejecutarse en un dash de Linux ni con el bash 3.2 de macOS.
- Worktree enlazado en sesión real: según la revisión, arrancado en su raíz bloquea 1 de 1; no lo he repetido, porque cada `claude -p` escribe en `~/.claude/` y este encargo lo excluye.
- Confianza: las sesiones corrieron en clones superficiales sin confianza aceptada (`~/.claude.json` no menciona esos clones, comprobado). Los hooks actuaron con `-p`; no está medido qué cambia en una sesión interactiva con el diálogo de confianza.
- Sesión interactiva: todo es `claude -p`.

**Vigencia de `sessions/`:** son anteriores a la revisión. Desde entonces solo cambian el texto del mensaje del comando y el cálculo de `hook_dir` con `$0` sin barra, cubiertos por `ac1_ac2.txt`. No se han repetido las sesiones, por la misma razón.

**Revisión** (todos los hallazgos eran ciertos, ninguno falso; línea base sobre el merge de integración):
- **B1:** reproducido, `docs/evidence/PUL-190/run_acs.sh` daba `fallos=1` y todas las filas bloqueaban por «falta el envoltorio», no por su causa. Además, `fallo_abierto_conocido=0` de la pasada anterior no medía nada, como ya decía esta ficha. Arreglado con los tres cambios: copia de `run_guard.sh`, `export` y filtro del PATH. Añadido a ese arnés un control de causa por fila, que cuenta como fallo: `unknown encoding`, `no hay python3 ni python`, `SyntaxError` y `sin decidir` (`fail_open.txt`).
- **N1:** comprobado en el código y en `check_owns.py main <base>`. Corregido arriba.
- **N2:** reproducido con el envoltorio anterior: `sh run_guard.sh` desde su directorio, con marcador, daba rc=0. Ahora rc=2 fuera de `owns` y rc=0 dentro.
- **N3:** comprobado (`ac1_ac2.txt`). El mensaje se ajusta sin ramas nuevas: imprime la ruta.
- **N4:** comprobado: marcador con espacios da rc=0 con Python y rc=2 sin él. Comentario matizado.
- **N5:** dash comprobado; worktree enlazado citado de la revisión, sin repetir; confianza comprobada en `~/.claude.json` solo por lectura.

**Propuestas para el coordinador, sin implementar:**
1. ¿Añadir `godot/.claude/settings.json` que apunte al envoltorio de la raíz? Bloquea desde `godot/` (`sessions/candidate.txt`, 3 de 3), pero no desde `godot/core/` (3 de 3 crean), y duplica configuración. Reduce el hueco sin cerrarlo.
2. ¿Añadir a la regla 1 de `CLAUDE.md` y `AGENTS.md` «arranca siempre en la raíz»? No impide nada, pero avisa a quien arranca a mano.

**`tools/verify.sh --quick`:** rc=0 (`verify_quick.txt`), sobre el merge con integración.
