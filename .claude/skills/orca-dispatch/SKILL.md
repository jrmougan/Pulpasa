---
name: orca-dispatch
description: Receta del producer para lanzar una ficha de docs/backlog como worker supervisado de Orca en su propio worktree, esperar el resultado, revisarlo y mergearlo. Úsala al coordinar oleadas.
---
# Lanzar fichas con Orca

Los comandos de esta receta usan `orca-ide`, el nombre en Linux, donde `orca` es el lector de
pantalla. En Windows `orca-ide` no existe: sustitúyelo por `orca` en todos ellos. Antes de la
primera oleada de la sesión, lee la guía completa: `orca-ide skills get orchestration`.

## Una oleada

```bash
orca-ide status --json
orca-ide orchestration run-create --objective "Pulpasa <hito>: oleada <n>" --json
```

Por cada ficha `ready` sin solapes de `owns`/`touches_scenes` (en Windows, desde Git Bash):

```bash
{
  echo "Tarea PUL-0xx: implementa la ficha docs/backlog/PUL-0xx-<slug>.md (copiada abajo)."
  echo
  cat docs/backlog/PUL-0xx-*.md
  echo
  echo "ROL: actúa según .claude/agents/<role>.md. Escribe PUL-0xx en .claude/current-task antes de editar."
  echo "VERIFICACIÓN: tools/verify.sh debe pasar. Evidencia en docs/evidence/PUL-0xx/."
  echo "CIERRE: commit en tu rama con mensaje 'PUL-0xx: <título>' y worker_done con --files-modified."
} | orca-ide orchestration worker-start --spec-file - \
  --task-title "PUL-0xx <título>" \
  --worktree new-child --name pul-0xx --base-branch <rama-integración> \
  --agent claude --model <sonnet|opus según rol> --json
```

El spec no puede empezar por `---` (Orca lo toma por un flag): por eso va la línea «Tarea …» delante.
No escribas `orca_task` en la ficha mientras el worker la tiene: chocaría al mergear. Anótalo al cerrarla.

## Esperar y procesar

Tras lanzar la oleada, termina el turno: Orca te despierta. Ejecuta el `check` que trae el aviso y
procesa el lote entero (mezcla tipos). `question` → `orca-ide orchestration reply --id <message_id> --body "..." --json`.
`escalation` con `stopReason` → `send`, parar y reintentar, o avisar. Sin contexto:
`inbox --terminal run:<run_id> --limit 50`.

Por cada `worker_done` con `--outcome succeeded`:
1. Revisión: `worker-start --spec "Revisa la rama <rama> contra docs/backlog/PUL-0xx-*.md. Base: <rama-integración>. Rol: .claude/agents/reviewer.md. Responde APPROVE o CHANGES en worker_done." --worktree branch:<rama> --agent codex --json`.
2. Si `CHANGES`: `orca-ide orchestration send --to dispatch:<id del worker> --subject "Cambios PUL-0xx" --body "<hallazgos>"`; responde con otro `worker_done`.
3. Si `APPROVE`, con árbol limpio y de una en una: `tools/merge_gate.sh <rama>` (nombre exacto del recibo o de `worker-show`; debe contener `pul-<n>`, o check_owns no comprueba nada). Después ficha en `done`, tabla de `docs/backlog/README.md`, `orca_task`, commit `docs: close PUL-0xx` y `worker-release --dispatch <id>`.

Antes de cerrar la oleada, `worker-list --terminal-state reclaimable --json` debe salir vacío.

## Gates humanos

Para alcance, ADRs, game feel y fin de hito:
`orca-ide orchestration gate-create --task <task_id> --question "<decisión>" --options '["a","b"]' --json`;
la Task queda bloqueada hasta `gate-resolve --id <gate_id> --resolution "<texto>"`.

## Agentes no Claude

Antigravity y kimi: lee `references/agentes-no-claude.md` antes de lanzarlos. No consta que carguen `AGENTS.md`
por sí solos (solo está probado en Codex): pide en su spec que lo lean antes de empezar. Ni estos ni Codex como
worker ejecutan los hooks de `.claude/`: pide en el spec
ejecutar `tools/check_owns.py <rama> <base>` y `tools/verify.sh` antes de `worker_done`. Un worktree por ficha (`--worktree new-child`). Revisa sus
capturas contra cada AC: un estado que no se distingue en la imagen no prueba el AC.
