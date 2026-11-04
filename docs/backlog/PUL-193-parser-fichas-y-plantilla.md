---
id: PUL-193
title: Compartir el parser de fichas entre hook y merge gate y limpiar la plantilla
status: done
milestone: M4
role: godot-architect
deps: [PUL-190]
orca_task: null
unity_sources: []
owns: [.claude/hooks/guard_ownership.py, tools/check_owns.py, tools/card_frontmatter.py, docs/backlog/_TEMPLATE.md, docs/backlog/README.md]
touches_scenes: []
---

## Target
`guard_ownership.py`, `check_owns.py`, módulo nuevo `tools/card_frontmatter.py`, `_TEMPLATE.md` y la cabecera de `docs/backlog/README.md`.

## Change
- Hoy hay dos parsers: el hook entiende listas inline y en bloque, y `check_owns.py` solo inline. Una ficha con `owns` en bloque pasa el hook y la rechaza el merge gate. Ambos pasan a usar un único parser.
- `owns: []   # comentario` no casa con la regex: la lista queda vacía, el hook bloquea todo y `check_owns` rechaza la rama. El parser tolera el comentario y lo que viene tras él no cuenta como glob.
- `_TEMPLATE.md`: sin comentarios tras `owns` y `touches_scenes`; `unity_sources` opcional, ya no «de especificación» (D17); estados con `superseded`; hito remitiendo a `docs/design/roadmap.md`.
- `docs/backlog/README.md` (líneas de cabecera): quitar «tal cual», «Ownership» y `worker-start --spec`, que contradicen orca-dispatch. La tabla de fichas no se toca.

## Constraints
El hook mantiene lo de PUL-190: lee UTF-8 y bloquea ante fallo, también si no puede importar el módulo. Debe funcionar desde cualquier directorio de trabajo. Las 180+ fichas existentes dan el mismo resultado que hoy. `check_owns` sigue saliendo con 0 en ramas sin `pul-<n>`.

## Acceptance
- [x] AC1 Given una ficha con `owns` inline, en bloque y con comentario final, When hook y `check_owns` la leen, Then obtienen la misma lista → salida en docs/evidence/PUL-193/
- [x] AC2 Given todas las fichas de docs/backlog, When se comparan los `owns` del parser nuevo con los del anterior, Then no hay diferencias → salida en docs/evidence/PUL-193/
- [x] AC3 Given una copia de `_TEMPLATE.md` con `owns` relleno, When se ejecuta el hook sobre una ruta incluida, Then rc=0 → salida en docs/evidence/PUL-193/
- [x] AC4 Given el módulo ausente, When se ejecuta el hook con `current-task`, Then rc=2 → salida en docs/evidence/PUL-193/

## Plan
1. Línea base: `docs/evidence/PUL-193/run_acs.py` (se lanza desde Git Bash con rutas `pwd -W`) trabaja en sandboxes con repo
   Git propio y compara con el hook y `check_owns.py` de `ec25ecc`, leídos con `git show`.
2. `tools/card_frontmatter.py`: `frontmatter_list(text, key)` por líneas. Admite lista inline, en bloque (con y sin sangría),
   comentario final (`#` tras espacio y fuera de comillas), BOM y CRLF. Lo no reconocido da `[]`: bloquea.
3. Hook: importa el módulo dentro de `main()`, tras comprobar `current-task` (sin ficha activa no restringe nada ni necesita
   el módulo), con la ruta sacada de `__file__`. Fallo al importar: exit 2. Sin `CLAUDE_PROJECT_DIR`, la raíz sale de `__file__`.
4. `check_owns.py`: importa tras la salida con 0 de ramas sin `pul-<n>` y ejecuta git desde la raíz del repo. Al rechazar, lista
   las rutas permitidas, para poder comparar la lista con la del hook.
5. Hook y `check_owns` con `sys.dont_write_bytecode`: `.gitignore` no cubre `__pycache__`, y un `tools/__pycache__` ensuciaría
   el árbol que `merge_gate.sh` exige limpio y podría colarse en el commit del worker (`.gitignore` no está en `owns`).
6. `_TEMPLATE.md` y cabecera de `README.md`; la tabla de fichas no se toca.
7. Pasar el arnés, repetir el de PUL-190 contra el hook nuevo y `tools/verify.sh --quick`.

## Evidence
Arnés: `docs/evidence/PUL-193/run_acs.py`, lanzado desde Git Bash en Windows 11 con ruta de Windows, Python 3.13.18,
locale cp1252 (`env.txt`), sin `PYTHONUTF8` ni `PYTHONIOENCODING`. Sandboxes con repo Git propio. Línea base: hook y
`check_owns.py` de `ec25ecc`, leídos con `git show`. Resultado: `fallos: 0` (`summary.txt`).

| AC | Resultado | Salida |
|---|---|---|
| AC1 | 9 formas de ficha (inline, bloque, comentario final, bloque con comentarios, sin sangría, vacía con comentario, comillas y `#` en un glob, BOM, CRLF): hook y `check_owns` imprimen la misma lista esperada; los dos aceptan las rutas incluidas y rechazan la ajena. Línea base: `check_owns` rechaza las ramas válidas de 7 de las 9 formas y el hook lee mal 4 | `ac1.txt` |
| AC2 | 191 ficheros (`docs/backlog/*.md` y la plantilla de `ec25ecc`): 0 diferencias con los dos parsers anteriores en `owns` y `touches_scenes`. Hook completo, nuevo y antiguo, en 188 fichas: 0 con rc distinto | `ac2.txt` |
| AC3 | Copia de la plantilla con `owns` relleno: rc=0 en ruta literal y glob, rc=2 en la ajena. Una copia de la plantilla anterior, con comentario, también da rc=0. Plantilla y cabecera de README comprobadas; tabla idéntica a `ec25ecc` | `ac3.txt` |
| AC4 | Módulo ausente con `current-task`: rc=2 con mensaje, también con otro `card_frontmatter.py` en el directorio de trabajo. Módulo roto, sin la función, que lanza o con `sys.exit(0)`: rc=2. Sin `current-task`: rc=0 | `ac4.txt` |

Constraints:
- Cualquier directorio de trabajo: hook y `check_owns` probados desde carpeta ajena y subcarpeta, y el hook también sin
  `CLAUDE_PROJECT_DIR` (`ac1.txt`). `check_owns` sale con 0 en ramas sin `pul-<n>`, con módulo y sin él (`ac1.txt`).
- PUL-190: su arnés contra el hook nuevo da `fallos=0` en 188 fichas (`regresion_pul190_summary.txt`). Su contador
  `fallo_abierto_conocido=3` es lo que el hook no puede arreglar según ese arnés: no cuenta como fallo.
- Sin `__pycache__` en el árbol tras ejecutar las herramientas. Control: quitando la bandera del hook aparece
  `tools/__pycache__` (`ac1.txt`). `.gitignore` no cubre `__pycache__` y no está en `owns`.
- `tools/verify.sh --quick`: `verify OK` (`verify_quick.txt`). `check_owns.py` real sobre esta rama: `check_owns_real.txt`.

Notas:
- En AC2, 185 de 188 fichas dan rc=0 en su primera ruta. Las otras 3 (PUL-139, 140 y 141) tienen globs con `[...]` y el arnés
  genera una ruta de prueba que no casa; hook nuevo y antiguo coinciden también ahí. El parser conserva esos corchetes.
- `check_owns` lista ahora las rutas permitidas al rechazar: AC1 compara esa lista con la del hook.
- El hook pasa a capturar `BaseException`: un `sys.exit(0)` en el módulo importado dejaría pasar la edición.
- No verificable aquí: Linux y macOS (solo se ha ejecutado en Windows) y `tools/verify.sh` completo (la ficha pide `--quick`,
  y no cambia GDScript). `merge_gate.sh` tampoco se ha ejecutado: lo lanza solo el producer.
