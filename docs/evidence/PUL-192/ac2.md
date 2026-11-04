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

El worktree cuelga de un checkout del repo, y Claude Code también carga los `CLAUDE.md` de los directorios padre. La
regla 1 sola no distinguiría de dónde sale. La línea de los hooks solo existe en el `AGENTS.md` de esta rama (0
coincidencias en el `CLAUDE.md` del checkout padre), así que citarla prueba que `@AGENTS.md` se resolvió.

Límite: es una sesión `-p`, no una interactiva.
