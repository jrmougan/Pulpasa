#!/usr/bin/env bash
# Exporta el proyecto a build/<plataforma>/ (ignorado por git).
# Uso: tools/export.sh [linux|windows|web|all]   (por defecto: all)
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT_PATH:-godot}"
TARGET="${1:-all}"
fail=0

export_one() { # <plataforma> <preset> <fichero de salida>
  local out="$ROOT/build/$1/$3" log
  rm -rf "$ROOT/build/$1"; mkdir -p "$ROOT/build/$1"
  printf '== export %s\n' "$1"
  log=$(cd "$ROOT/godot" && timeout 600 "$GODOT" --headless --export-release "$2" "$out" 2>&1); local rc=$?
  if ((rc != 0)) || grep -qE '^(SCRIPT )?ERROR' <<<"$log" || [[ ! -s "$out" ]]; then
    grep -E 'ERROR' <<<"$log" | head -20; echo "FALLO: $1"; fail=1
  else
    du -sh "$ROOT/build/$1" | sed 's/^/tamaño: /'
  fi
}

(cd "$ROOT/godot" && timeout 300 "$GODOT" --headless --import >/dev/null 2>&1)
case "$TARGET" in
  linux|windows|web|all) ;;
  *) echo "Uso: tools/export.sh [linux|windows|web|all]"; exit 2 ;;
esac
[[ "$TARGET" == linux   || "$TARGET" == all ]] && export_one linux "Linux x86_64" pulpasa.x86_64
[[ "$TARGET" == windows || "$TARGET" == all ]] && export_one windows "Windows x86_64" pulpasa.exe
[[ "$TARGET" == web     || "$TARGET" == all ]] && export_one web "Web" index.html
exit $fail
