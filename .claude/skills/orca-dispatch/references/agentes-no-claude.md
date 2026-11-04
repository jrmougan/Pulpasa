# Agentes no Claude como worker

Probado por última vez: 2026-10-04 (Orca anterior); revalida con `--help`.

- **antigravity** (Gemini, `agy`): `worker-start ... --agent antigravity --model <id>` funciona supervisado.
  **No reutilices su terminal** para la ronda de cambios (`worker-start --terminal` falla en `agent_readiness`
  y la entrada se pierde): libera el worker y lanza uno nuevo sobre la misma rama con
  `--task <task de la ronda> --retry-of <dispatch fallido> --worktree branch:<rama> --agent antigravity --model <id>`.
  Modelos: `agy models` (p. ej. `gemini-3.1-pro-high` para fichas difíciles, `gemini-3.8-flash-high` para medias).
- Con `gemini-3.1-pro-*`, el «Signing in…» del arranque supera la espera de Orca y `worker-start` falla en
  `agent_readiness` (aunque `ok:true` al lanzar): comprueba el `stage` y, si falla, usa la vía de kimi
  (terminal propio con `agy --dangerously-skip-permissions --model <id>` + `task-create` + `terminal wait` + `dispatch --inject` + Enter).
- **kimi** (`kimi`, K3): Orca no lo reconoce como agente, `worker-start --terminal` falla en `agent_readiness`.
  Receta (vía no supervisada, low-level-topology):
  1. `orca-ide worktree create --name pul-0xx --base-branch <rama-integración> --setup skip --json`
  2. `orca-ide terminal create --worktree path:<ruta> --title "PUL-0xx kimi" --command "kimi --auto" --json`
  3. La primera vez kimi pregunta «Trust this folder?» (MCP del proyecto): `terminal send --enter`.
  4. `orchestration task-create --run <run> --spec "..."`, `terminal wait --terminal <h> --for tui-idle --timeout-ms 60000 --json` y `orchestration dispatch --task <id> --to <terminal> --inject`.
  5. Si el texto queda en el prompt sin enviarse, `terminal send --terminal <h> --enter`.
  El carril queda «unsupervised»: `worker-stop/release` no cierran el proceso; ciérralo con `orca-ide terminal close` al terminar.
- Ni antigravity ni kimi ejecutan los hooks de `.claude/`: la propiedad y la verificación las garantiza
  `tools/merge_gate.sh` (check_owns + verify). Pide en el spec que ejecuten ambos antes de cerrar.
