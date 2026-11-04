# AC2: sesión nueva de Claude Code

Ejecutado en el worktree de la rama, en Windows, con Claude Code 2.1.318. Sesión no interactiva, sin herramientas
integradas (`--tools ""`, sin Read ni Bash) y sin ninguna llamada a herramienta en la salida `stream-json`.

```
claude -p "<prompt>" --tools "" --no-session-persistence --output-format stream-json --verbose
```

Prompt:

> Responde solo con lo que ya tengas en tu contexto cargado. No uses herramientas. 1. Cita literalmente la regla 1 de
> las reglas no negociables de este proyecto. 2. Cita literalmente la línea que indica dónde corren los hooks y cuál es
> la barrera fuera de ellos. Si no tienes alguno de los dos textos en el contexto, escribe NO_DISPONIBLE en su lugar.

Respuesta (`result: success`):

> **1. Regla 1:**
>
> 1. Una ficha por worker. Escribe su id en `.claude/current-task` antes de editar: un hook solo
>    permite tocar `owns` y `touches_scenes` de esa ficha. Bórralo al terminar. El merge gate
>    (`tools/check_owns.py`) rechaza la rama si cambia cualquier otra ruta, también desde Bash: si
>    necesitas tocar algo más, pregunta al coordinador.
>
> **2. Línea sobre los hooks:**
>
> Los hooks de `.claude/` solo corren en Claude Code: fuera de él, la barrera es `tools/merge_gate.sh`.

## Por qué se pide también la línea de los hooks

Solo existe en el `AGENTS.md` de esta rama, así que citarla prueba que `@AGENTS.md` se resolvió. La regla 1 sola no
distingue: en la base está en el propio `CLAUDE.md`.

La versión anterior de esta nota decía que el worktree heredaba el `CLAUDE.md` del checkout padre. Es falso en este
caso, aunque la conclusión de AC2 no cambia. Sesiones nuevas con el mismo comando, preguntando por cada texto:

| Arranque | `Z:/Pulpasa/CLAUDE.md` («en migración de Unity 6») | `padre/CLAUDE.md` (`MARCA_PADRE_7319`) | Regla 1 |
|---|---|---|---|
| Worktree, raíz | no | n/a | sí, desde `AGENTS.md` |
| Worktree, `godot/` | no | n/a | no |
| Clon dentro de un directorio con `CLAUDE.md` propio, raíz | n/a | sí | sí, desde `AGENTS.md` |
| El mismo clon, `godot/` | n/a | sí | no |

Claude Code sí carga el `CLAUDE.md` de un directorio padre normal, pero aquí no cargó el del checkout del que cuelga el
worktree. No he buscado la causa.

## Límite abierto: arrancar desde un subdirectorio

Desde un subdirectorio, `CLAUDE.md` se carga, pero `@AGENTS.md` no se expande: la sesión se queda sin reglas y sin
ningún error. Es una regresión respecto a la base. Decisión pendiente del coordinador.

Prompt de AC2, `--tools ""`, Claude Code 2.1.318, en Windows:

| Arranque | Regla 1 | Línea de los hooks |
|---|---|---|
| Worktree de la rama, raíz | sí | sí |
| Worktree de la rama, `godot/` | NO_DISPONIBLE | NO_DISPONIBLE |
| Clon limpio de la rama, raíz | sí | sí |
| Clon limpio de la rama, `godot/` (dos sesiones) | NO_DISPONIBLE | NO_DISPONIBLE |
| Clon limpio de la rama, `godot/`, con `--add-dir ..` | NO_DISPONIBLE | NO_DISPONIBLE |
| Clon de la base (`cac6ac1`), `godot/` | sí | NO_DISPONIBLE (la línea no existe en la base) |

Opción A de la revisión, probada solo en un clon temporal y sin aplicar a la rama: `CLAUDE.md` con una segunda línea,
«Si no ves las reglas arriba, lee AGENTS.md en este directorio». Una sesión por caso, desde `godot/`, pidiendo citar la
regla 1:

| `CLAUDE.md` | Herramientas | Resultado |
|---|---|---|
| Con la segunda línea | ninguna | ve la línea, NO_DISPONIBLE |
| Con la segunda línea | `Read` | intenta leer `AGENTS.md`, permiso denegado, no cita la regla |
| Solo `@AGENTS.md` | `Read` | intenta leer `AGENTS.md`, permiso denegado, no cita la regla |

En estas pruebas, la segunda línea no cambia el resultado: sin ella, la sesión ya intenta leer `AGENTS.md`, y `-p` le
deniega el permiso porque el fichero queda fuera del directorio de trabajo.

Sin comprobar: una sesión interactiva desde `godot/`, tanto si pide aprobar el import como si pide permiso para `Read`.
Los flujos documentados de Orca arrancan en la raíz del worktree; esta prueba no los lanza.
