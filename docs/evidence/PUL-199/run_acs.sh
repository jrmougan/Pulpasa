#!/usr/bin/env bash
# AC1 y AC2 de PUL-199 con el comando real del hook, leído del settings.json del árbol que se mide.
# Uso: run_acs.sh <árbol> <fichero_salida> [shell] [dir_temporal]
#   <árbol>: raíz de un checkout (el clon anterior al cambio da la línea base; el worktree, el resultado).
# Trabaja en un sandbox con copia de .claude/hooks, settings.json, card_frontmatter.py y la ficha, para poder
# romper hooks sin tocar el árbol. La plantilla de mktemp respeta TMPDIR: apúntalo fuera del repo y de $HOME.
# [shell] ejecuta el comando (bash por defecto); [dir_temporal] aloja el sandbox. Solo el rc=2 bloquea en Claude Code. Sale con 1 si un caso con expectativa no se cumple.
set -uo pipefail
SRC="$(cd "$1" && pwd)"
OUT="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
export LC_ALL=C
unset PYTHONUTF8 PYTHONIOENCODING

HOOK_SHELL="${3:-bash}"
[[ -n "${4:-}" ]] && export TMPDIR="$4"
BOX_UNIX="$(mktemp -d)"
trap 'rm -rf "$BOX_UNIX"' EXIT
fresh_box() {
  rm -rf "${BOX_UNIX:?}/.claude" "$BOX_UNIX/tools" "$BOX_UNIX/docs"
  mkdir -p "$BOX_UNIX/.claude" "$BOX_UNIX/tools" "$BOX_UNIX/docs/backlog"
  cp -r "$SRC/.claude/hooks" "$BOX_UNIX/.claude/hooks"
  cp "$SRC/.claude/settings.json" "$BOX_UNIX/.claude/settings.json"
  cp "$SRC/tools/card_frontmatter.py" "$BOX_UNIX/tools/"
  cp "$SRC"/docs/backlog/PUL-199-*.md "$BOX_UNIX/docs/backlog/"
  printf 'PUL-199\n' >"$BOX_UNIX/.claude/current-task"
}
fresh_box
cd "$BOX_UNIX" || exit 1
BOX="$(pwd -W 2>/dev/null || pwd)"
export CLAUDE_PROJECT_DIR="$BOX"

CMD="$(python3 -c '
import json, sys
hooks = json.load(open(sys.argv[1], encoding="utf-8"))["hooks"]["PreToolUse"]
print(next(h for h in hooks if h["matcher"] == "Edit|Write|MultiEdit")["hooks"][0]["command"])
' "$(cygpath -wa "$SRC/.claude/settings.json" 2>/dev/null || echo "$SRC/.claude/settings.json")" | tr -d '\r')"

# Sin intérprete de verdad: PATH reducido a lo que trae el sistema, y fuera todo directorio con python.
NOPY_PATH=""
IFS=: read -ra path_dirs <<<"$PATH"
for d in "${path_dirs[@]}"; do
  [[ -z "$d" || -e "$d/python3" || -e "$d/python3.exe" || -e "$d/python" || -e "$d/python.exe" ]] && continue
  NOPY_PATH="${NOPY_PATH:+$NOPY_PATH:}$d"
done
FAKE="$BOX_UNIX/fakebin"
ERR="$BOX_UNIX/stderr.txt"
fails=0
open=0

input_for() {
  local win="$BOX/$1"
  [[ "$BOX" == *:* ]] && win="${win//\//\\\\}"
  printf '{"tool_name":"Edit","tool_input":{"file_path":"%s"}}' "$win"
}

show_err() {
  sed -E 's/[A-Za-z]:[\\/][^ ":]*/<ruta>/g; s#/tmp/[^ ":]*#<ruta>#g; s/^/    /' "$ERR" | tr -d '\r' | cut -c1-200 | head -"${1:-3}"
}

# run_case <esperado|-> <etiqueta> <destino> [VAR=valor...]; el resto del entorno es el del arnés.
run_case() {
  local want="$1" label="$2" target="$3"
  shift 3
  input_for "$target" | env "$@" "$HOOK_SHELL" -c "$CMD" >/dev/null 2>"$ERR"
  local rc=${PIPESTATUS[1]}
  local verdict=PASS
  [[ "$rc" == 2 ]] || open=$((open + (want == 2 ? 1 : 0)))
  if [[ "$rc" != "$want" ]]; then
    verdict=FAIL
    fails=$((fails + 1))
  fi
  printf '%s rc=%s (esperado %s) %s -> %s\n' "$verdict" "$rc" "$want" "$label" "$target"
  show_err
}

FOREIGN=Assets/x.txt
OWNED=.claude/hooks/guard_ownership.py

{
  echo "comando: $CMD"
  echo "PATH sin python: $(env PATH="$NOPY_PATH" bash -c 'command -v python3 python || echo ninguno')"
  echo
  echo "== Control"
  run_case 2 "hook intacto, fuera de owns" "$FOREIGN"

  echo
  echo "== AC1: los cuatro casos de la ficha, fuera de owns"
  run_case 2 "AC1 PYTHONIOENCODING inválida" "$FOREIGN" PYTHONIOENCODING=no-existe
  run_case 2 "AC1 PYTHONUTF8=9" "$FOREIGN" PYTHONUTF8=9
  run_case 2 "AC1 intérprete ausente (sin python en PATH)" "$FOREIGN" PATH="$NOPY_PATH"
  printf 'def (:\n' >.claude/hooks/guard_ownership.py
  run_case 2 "AC1 hook que no compila" "$FOREIGN"
  fresh_box

  echo
  echo "== AC1: también dentro de owns, si Python no llega a decidir no hay permiso"
  run_case 2 "PYTHONIOENCODING inválida" "$OWNED" PYTHONIOENCODING=no-existe
  run_case 2 "PYTHONUTF8=9" "$OWNED" PYTHONUTF8=9
  run_case 2 "sin python en PATH" "$OWNED" PATH="$NOPY_PATH"
  printf 'def (:\n' >.claude/hooks/guard_ownership.py
  run_case 2 "hook que no compila" "$OWNED"
  fresh_box

  echo
  echo "== Más allá de la ficha: falta o se rompe alguna pieza, fuera de owns"
  rm .claude/hooks/guard_ownership.py
  run_case 2 "falta guard_ownership.py" "$FOREIGN"
  fresh_box
  : >.claude/hooks/guard_ownership.py
  run_case 2 "guard_ownership.py vacío" "$FOREIGN"
  fresh_box
  printf 'raise SystemExit(0)\n' >tools/card_frontmatter.py
  run_case 2 "BaseException en el import: SystemExit(0)" "$FOREIGN"
  fresh_box
  printf 'raise KeyboardInterrupt\n' >tools/card_frontmatter.py
  run_case 2 "BaseException en el import: KeyboardInterrupt" "$FOREIGN"
  fresh_box
  mkdir -p "$FAKE"
  printf '#!/bin/sh\nkill -9 $$\n' >"$FAKE/python3"
  run_case 2 "el intérprete muere por una señal" "$FOREIGN" PATH="$FAKE:$PATH"
  printf '#!/bin/sh\nexit 49\n' >"$FAKE/python3"
  run_case 2 "stub de la Microsoft Store (rc=49 por 9009)" "$FOREIGN" PATH="$FAKE:$PATH"
  rm -rf "$FAKE"
  rm -f .claude/hooks/run_guard.sh
  run_case 2 "falta run_guard.sh" "$FOREIGN"
  fresh_box
  [[ -e .claude/hooks/run_guard.sh ]] && : >.claude/hooks/run_guard.sh
  run_case 2 "run_guard.sh vacío" "$FOREIGN"
  fresh_box
  [[ -e .claude/hooks/run_guard.sh ]] && printf 'if then (\n' >.claude/hooks/run_guard.sh
  run_case 2 "run_guard.sh con error de sintaxis" "$FOREIGN"
  fresh_box
  rm -rf .claude/hooks
  run_case 2 "falta .claude/hooks entero" "$FOREIGN"
  fresh_box
  run_case 2 "CLAUDE_PROJECT_DIR sin definir" "$FOREIGN" -u CLAUDE_PROJECT_DIR
  run_case 2 "CLAUDE_PROJECT_DIR vacío" "$FOREIGN" CLAUDE_PROJECT_DIR=
  rm .claude/current-task
  mkdir .claude/current-task
  run_case 2 "current-task es un directorio" "$FOREIGN"
  run_case 2 "current-task es un directorio, sin python" "$FOREIGN" PATH="$NOPY_PATH"
  fresh_box

  echo
  echo "== Abierto conocido: un fichero que sigue siendo código válido y sale con 0 no se distingue del hook"
  if [[ -e .claude/hooks/run_guard.sh ]]; then
    printf 'exit 0\n' >.claude/hooks/run_guard.sh
    run_case 0 "ABIERTO run_guard.sh sustituido por exit 0" "$FOREIGN"
    fresh_box
    head -n 8 "$SRC/.claude/hooks/run_guard.sh" >.claude/hooks/run_guard.sh
    run_case 0 "ABIERTO run_guard.sh truncado tras los comentarios" "$FOREIGN"
    fresh_box
  fi
  printf 'import sys\nsys.exit(0)\n' >.claude/hooks/guard_ownership.py
  run_case 0 "ABIERTO guard_ownership.py sustituido por uno que sale con 0" "$FOREIGN"
  fresh_box
  head -n 3 "$SRC/.claude/hooks/guard_ownership.py" >.claude/hooks/guard_ownership.py
  printf '"""\n' >>.claude/hooks/guard_ownership.py
  run_case 0 "ABIERTO guard_ownership.py truncado a un docstring" "$FOREIGN"
  fresh_box

  echo
  echo "== AC2: dentro y fuera de owns, hook intacto"
  run_case 0 "literal de owns" "$OWNED"
  run_case 0 "otra entrada de owns" .claude/settings.json
  run_case 0 "la propia ficha" docs/backlog/PUL-199-hooks-regla-1.md
  run_case 0 "docs/evidence/<id>/" docs/evidence/PUL-199/x.txt
  run_case 0 "current-task" .claude/current-task
  run_case 2 "fuera de owns" godot/core/x.gd
  run_case 2 "fuera de owns, otra ficha" docs/backlog/PUL-001.md
  run_case 2 "parecida a owns" .claude/hooks/guard_ownership.py.bak
  run_case 2 "fuera de owns, no ASCII" "Assets/peñón.txt"
  # La entrada inválida no pasa por input_for.
  printf '{no es json' | "$HOOK_SHELL" -c "$CMD" >/dev/null 2>"$ERR"
  rc=${PIPESTATUS[1]}
  [[ "$rc" == 2 ]] && v=PASS || {
    v=FAIL
    fails=$((fails + 1))
  }
  printf '%s rc=%s (esperado 2) entrada JSON inválida\n' "$v" "$rc"
  show_err

  echo
  echo "== Sin current-task no se restringe nada (regla previa, PUL-190), ni aunque falte una pieza"
  rm .claude/current-task
  run_case 0 "sin marcador, fuera de owns" "$FOREIGN"
  run_case 0 "sin marcador, sin python" "$FOREIGN" PATH="$NOPY_PATH"
  run_case 0 "sin marcador, PYTHONUTF8=9" "$FOREIGN" PYTHONUTF8=9
  : >.claude/current-task
  run_case 0 "marcador vacío" "$FOREIGN"
  run_case 0 "marcador vacío, sin python" "$FOREIGN" PATH="$NOPY_PATH"
  fresh_box
  rm .claude/current-task
  rm -f .claude/hooks/run_guard.sh
  run_case 2 "sin marcador pero falta run_guard.sh (no se distingue: bloquea)" "$FOREIGN"
  fresh_box

  echo
  echo "RESUMEN fallos=$fails abiertos_con_rc_distinto_de_2=$open"
} >"$OUT" 2>&1

cat "$OUT" | grep -E '^(FAIL|RESUMEN)'
((fails == 0))
