#!/usr/bin/env bash
# PostToolUse (Edit|Write|MultiEdit): formatea y lintea el .gd editado.
# exit 2 devuelve stderr al agente para que lo corrija.
set -uo pipefail
f=$(jq -r '.tool_input.file_path // empty')
[[ "$f" == *.gd ]] || exit 0
[[ "$f" == */addons/* || "$f" == */.mcp/* ]] && exit 0
[[ -f "$f" ]] || exit 0
gdformat "$f" >/dev/null 2>&1 || true
if ! out=$(gdlint "$f" 2>&1); then
  echo "gdlint ha fallado en $f. Corrígelo antes de seguir:" >&2
  echo "$out" >&2
  exit 2
fi
exit 0
