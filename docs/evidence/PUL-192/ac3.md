# AC3: Codex en Windows

Ejecutado en el worktree de la rama (`core.symlinks=false`) con codex-cli 0.166.0. Sandbox de solo lectura y sin
ninguna llamada a comandos en la salida `--json`: solo `agent_message`. El prompt no nombra ningún fichero.

```
codex exec --ephemeral --sandbox read-only --json "<prompt>"
```

Prompt:

> Responde solo con lo que ya tengas en tu contexto cargado. No ejecutes comandos ni leas ficheros. 1. Cita literalmente
> la regla 1 de las reglas no negociables de este proyecto. 2. Cita literalmente la línea que indica dónde corren los
> hooks y cuál es la barrera fuera de ellos. Si no tienes alguno de los dos textos en el contexto, escribe NO_DISPONIBLE
> en su lugar.

## Control: antes del cambio (`AGENTS.md` de 9 bytes)

> 1. NO_DISPONIBLE
> 2. NO_DISPONIBLE

Reproduce el fallo que describe la ficha: Codex no recibía las reglas.

## Después del cambio

> 1. Una ficha por worker. Escribe su id en `.claude/current-task` antes de editar: un hook solo
>    permite tocar `owns` y `touches_scenes` de esa ficha. Bórralo al terminar. El merge gate
>    (`tools/check_owns.py`) rechaza la rama si cambia cualquier otra ruta, también desde Bash: si
>    necesitas tocar algo más, pregunta al coordinador.
>
> 2. Los hooks de `.claude/` solo corren en Claude Code: fuera de él, la barrera es `tools/merge_gate.sh`.

## Repetición tras la revisión

Mismo comando y mismo prompt, sin llamadas a comandos en la salida `--json`:

| Arranque | Regla 1 | Línea de los hooks |
|---|---|---|
| Clon de la base (`AGENTS.md` de 9 bytes), raíz | NO_DISPONIBLE | NO_DISPONIBLE |
| Worktree de la rama, raíz | sí | sí |
| Worktree de la rama, `godot/` | sí | sí |

Arrancar desde un subdirectorio no afecta a Codex, a diferencia de Claude Code (`ac2.md`).

## Repetición en la segunda revisión

Mismo comando y mismo prompt, sin llamadas a comandos en la salida `--json`. En el worktree de la rama, desde la raíz y
desde `godot/`, Codex cita la regla 1 y la línea de los hooks.

## Límite

Se lanzó con `codex exec` en un worktree, no como worker supervisado por Orca (`worker-start --agent codex`): esta tarea
no crea runs de Orca. El arranque por Orca no se ha comprobado.
