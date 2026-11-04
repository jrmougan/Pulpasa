#!/usr/bin/env bash
# Stop: en modo worker (existe .claude/current-task) y con cambios en godot/, AGENTS.md o
# CLAUDE.md, no deja terminar si tools/verify.sh falla. Máximo 3 bloqueos seguidos por tarea
# para no entrar en bucle; al tercero deja parar y el agente debe escalar.
# Como en guard_ownership.py, un current-task vacío, o solo con espacios o BOM, es «sin ficha».
set -uo pipefail
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
MARK="$ROOT/.claude/current-task"
[[ -f "$MARK" ]] || exit 0
if task=$(LC_ALL=C tr -d '[:space:]\357\273\277' 2>/dev/null <"$MARK") && [[ -z "$task" ]]; then exit 0; fi
cd "$ROOT"
WATCHED=(godot/ AGENTS.md CLAUDE.md)
if git diff --quiet HEAD -- "${WATCHED[@]}" 2>/dev/null && [[ -z "$(git ls-files --others --exclude-standard -- "${WATCHED[@]}")" ]]; then
  exit 0
fi
COUNT_FILE="$ROOT/.claude/.stop-retries"
n=$(cat "$COUNT_FILE" 2>/dev/null || echo 0)
[[ "$n" =~ ^[0-9]+$ ]] || n=0
if out=$("$ROOT/tools/verify.sh" 2>&1); then
  rm -f "$COUNT_FILE"
  exit 0
fi
n=$((10#$n + 1))
# Sin contador no hay límite de bloqueos: mejor dejar parar y avisar que bloquear para siempre.
if ! { echo "$n" >"$COUNT_FILE"; } 2>/dev/null; then
  echo "verify.sh falla y no puedo escribir .claude/.stop-retries. Escala al coordinador con el error; no marques la tarea como hecha." >&2
  echo "$out" | tail -40 >&2
  exit 0
fi
if ((n >= 3)); then
  rm -f "$COUNT_FILE"
  echo "verify.sh sigue fallando tras 3 intentos. Escala al coordinador con el error; no marques la tarea como hecha." >&2
  exit 0
fi
echo "tools/verify.sh falla (intento $n/3). Arréglalo antes de terminar:" >&2
echo "$out" | tail -40 >&2
exit 2
