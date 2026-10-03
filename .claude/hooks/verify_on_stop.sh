#!/usr/bin/env bash
# Stop: en modo worker (existe .claude/current-task) y con cambios en godot/,
# no deja terminar si tools/verify.sh falla. Máximo 3 bloqueos seguidos por tarea
# para no entrar en bucle; al tercero deja parar y el agente debe escalar.
set -uo pipefail
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
MARK="$ROOT/.claude/current-task"
[[ -f "$MARK" ]] || exit 0
cd "$ROOT"
if git diff --quiet HEAD -- godot/ 2>/dev/null && [[ -z "$(git ls-files --others --exclude-standard godot/)" ]]; then
  exit 0
fi
COUNT_FILE="$ROOT/.claude/.stop-retries"
n=$(cat "$COUNT_FILE" 2>/dev/null || echo 0)
if out=$("$ROOT/tools/verify.sh" 2>&1); then
  rm -f "$COUNT_FILE"
  exit 0
fi
n=$((n + 1)); echo "$n" > "$COUNT_FILE"
if ((n >= 3)); then
  rm -f "$COUNT_FILE"
  echo "verify.sh sigue fallando tras 3 intentos. Escala al coordinador con el error; no marques la tarea como hecha." >&2
  exit 0
fi
echo "tools/verify.sh falla (intento $n/3). Arréglalo antes de terminar:" >&2
echo "$out" | tail -40 >&2
exit 2
