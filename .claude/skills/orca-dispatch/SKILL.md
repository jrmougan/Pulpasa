---
name: orca-dispatch
description: Receta del producer para lanzar una ficha de docs/backlog como worker supervisado de Orca en su propio worktree, esperar el resultado, revisarlo y mergearlo. Úsala al coordinar oleadas.
---
# Lanzar fichas con Orca

Usa siempre `orca-ide` (en Linux `orca` es el lector de pantalla). Antes de la primera oleada
de la sesión, lee la guía completa: `orca-ide skills get orchestration`.

## Una oleada

```bash
orca-ide status --json
orca-ide orchestration run-create --objective "Pulpasa <hito>: oleada <n>" --json
```

Por cada ficha `ready` sin solapes de `owns`/`touches_scenes`:

```bash
orca-ide orchestration worker-start \
  --spec "Tarea PUL-0xx: implementa la ficha docs/backlog/PUL-0xx-<slug>.md (copiada abajo).

$(cat docs/backlog/PUL-0xx-*.md)

ROL: actúa según .claude/agents/<role>.md. Escribe PUL-0xx en .claude/current-task antes de editar.
VERIFICACIÓN: tools/verify.sh debe pasar. Evidencia en docs/evidence/PUL-0xx/.
CIERRE: commit en tu rama con mensaje 'PUL-0xx: <título>' y worker_done con --files-modified." \
  --task-title "PUL-0xx <título>" \
  --worktree new-child --name pul-0xx --base-branch <rama-integración> \
  --agent claude --model <sonnet|opus según rol> --json
```

El spec no puede empezar por `---` (Orca lo toma por un flag): por eso va la línea «Tarea …» delante.
No escribas `orca_task` en la ficha mientras el worker la tiene: chocaría al mergear. Anótalo al cerrarla.

## Esperar y procesar

```bash
orca-ide orchestration check --wait --types "worker_done,escalation,question" --timeout-ms 900000 --json
orca-ide orchestration reply --id <message_id> --body "<respuesta>" --json
```

Por cada `worker_done` con `--outcome succeeded`:
1. Revisión: `worker-start --spec "Revisa la rama pul-0xx contra docs/backlog/PUL-0xx… (rol reviewer)" --worktree branch:<rama> --agent codex --json`.
2. Si `CHANGES`: nueva Dispatch al mismo terminal del worker con los hallazgos.
3. Si `APPROVE`: `tools/merge_gate.sh <rama>`; ficha → `done`; `worker-release --dispatch <id>`.

Después de cada lote: `check --ack <delivery_id>` y seguir esperando hasta que todas las
Dispatch se hayan cerrado. Antes de terminar, `worker-list --terminal-state reclaimable --json`
tiene que salir vacío.

## Gates humanos

Para alcance, ADRs, game feel y fin de hito:
`orca-ide skills get orchestration --reference references/messaging-and-gates.md` y usa `gate-create`.
