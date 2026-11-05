#!/usr/bin/env bash
# Sesiones `claude -p` reales contra un clon temporal: intentan crear con Write un fichero fuera de owns.
# Uso: sessions.sh <clon> <dir_salida> <repeticiones> <etiqueta> [caso...]
# Casos: root godot sub godot_inherit root_other root_cd root_nomark godot_nomark
#   root/godot/sub: arranca en la raíz, en godot/ o en godot/core/, con current-task.
#   godot_inherit: arranca en godot/ con CLAUDE_PROJECT_DIR heredado apuntando a la raíz.
#   root_other: arranca en la raíz con CLAUDE_PROJECT_DIR heredado apuntando a otro directorio.
#   root_cd: arranca en la raíz y hace `cd godot` con Bash antes de escribir.
#   *_nomark: control sin current-task.
# SESSION_ARGS (palabras) y SESSION_ENV (VAR=valor...) se añaden a cada sesión; SESSION_PATH sustituye su PATH.
# No persiste sesiones (--no-session-persistence) y no toca el repo. El diagnóstico lee stream-json.
set -uo pipefail
CLONE="$1"
OUT="$2"
N="$3"
LABEL="$4"
shift 4
CASES=("$@")
[[ ${#CASES[@]} -gt 0 ]] || CASES=(root godot)
mkdir -p "$OUT"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIN_CLONE="$(cd "$CLONE" && pwd -W)"
SUMMARY="$OUT/$LABEL.txt"
: >"$SUMMARY"

clean_env=(env -u CLAUDECODE -u CLAUDE_CODE_CHILD_SESSION -u CLAUDE_CODE_SESSION_ID -u CLAUDE_PID
  -u CLAUDE_EFFORT -u CLAUDE_CODE_MESSAGING_SOCKET -u CLAUDE_CODE_MESSAGING_TOKEN
  -u CLAUDE_CODE_SESSION_ATTENDED -u CLAUDE_CODE_ENTRYPOINT -u CLAUDE_CODE_PLUGIN_DIRS
  -u CLAUDE_CODE_EXECPATH -u CLAUDE_CODE_FORCE_TERMINAL_IMAGES -u CLAUDE_PROJECT_DIR)

for case in "${CASES[@]}"; do
  sub=""
  extra=()
  mark=1
  case "$case" in
    root) ;;
    godot) sub=godot ;;
    sub) sub=godot/core ;;
    godot_inherit)
      sub=godot
      extra=(CLAUDE_PROJECT_DIR="$WIN_CLONE")
      ;;
    root_other) extra=(CLAUDE_PROJECT_DIR="$WIN_CLONE/docs") ;;
    root_cd) ;;
    root_nomark) mark=0 ;;
    godot_nomark)
      sub=godot
      mark=0
      ;;
    *)
      echo "caso desconocido: $case" >&2
      exit 2
      ;;
  esac
  if ((mark)); then printf 'PUL-199\n' >"$CLONE/.claude/current-task"; else rm -f "$CLONE/.claude/current-task"; fi
  for i in $(seq 1 "$N"); do
    rel="zz_probe_${LABEL}_${case}_$i.txt"
    # Dentro de godot/core: es el directorio de trabajo de todos los casos o un descendiente suyo, así
    # que el permiso de edición lo concede acceptEdits y solo el hook puede bloquear.
    target="godot/core/$rel"
    raw="$OUT/raw_${LABEL}_${case}_$i.jsonl"
    prompt="Usa la herramienta Write una sola vez para crear el fichero $WIN_CLONE/$target con el contenido x. No uses Bash ni ninguna otra herramienta. Si Write falla o se bloquea, no reintentes: responde solo con el texto del error."
    args=()
    if [[ "$case" == root_cd ]]; then
      prompt="Son dos pasos obligatorios y en este orden. Paso 1: llama a la herramienta Bash con el comando exacto: cd godot. Paso 2: llama a la herramienta Write una sola vez para crear el fichero $WIN_CLONE/$target con el contenido x. Si Write falla o se bloquea, no reintentes: responde solo con el texto del error."
      args=(--allowedTools "Bash(cd:*)")
    fi
    run_env=("${extra[@]}")
    [[ -n "${SESSION_PATH:-}" ]] && run_env+=(PATH="$SESSION_PATH")
    # shellcheck disable=SC2086 # SESSION_ARGS y SESSION_ENV son listas de palabras a propósito.
    (cd "$CLONE/$sub" && "${clean_env[@]}" "${run_env[@]}" ${SESSION_ENV:-} claude -p "$prompt" --model haiku \
      --permission-mode acceptEdits --no-session-persistence --max-budget-usd 0.25 \
      "${args[@]}" ${SESSION_ARGS:-} \
      --output-format stream-json --verbose --include-hook-events </dev/null >"$raw" 2>"$raw.err")
    rc=$?
    if [[ -e "$CLONE/$target" ]]; then
      created=CREADO
      rm -f "$CLONE/$target"
    else
      created=NO_CREADO
    fi
    python3 "$HERE/parse_session.py" "$raw" "$case" "$i" "$created" "$rc" "$WIN_CLONE" | tee -a "$SUMMARY"
  done
done
rm -f "$CLONE/.claude/current-task"
