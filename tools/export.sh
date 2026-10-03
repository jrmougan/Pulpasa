#!/usr/bin/env bash
# Exporta el proyecto a build/<plataforma>/ (ignorado por git).
# Uso: tools/export.sh [linux|windows|web|all]   (por defecto: all)
# Aborta con código distinto de cero si falla la importación o cualquier exportación.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT_PATH:-godot}"
TARGET="${1:-all}"
fail=0

case "$TARGET" in
  linux|windows|web|all) ;;
  *) echo "Uso: tools/export.sh [linux|windows|web|all]" >&2; exit 2 ;;
esac

export_one() { # <plataforma> <preset> <fichero de salida>
  local out="$ROOT/build/$1/$3" log rc=0
  rm -rf "$ROOT/build/$1"
  mkdir -p "$ROOT/build/$1"
  printf '== export %s\n' "$1"
  log=$(cd "$ROOT/godot" && timeout 600 "$GODOT" --headless --export-release "$2" "$out" 2>&1) || rc=$?
  if ((rc != 0)) || grep -qE '^(SCRIPT )?ERROR' <<<"$log" || [[ ! -s "$out" ]]; then
    echo "FALLO: export $1 (código $rc, salida $out)" >&2
    grep -E 'ERROR' <<<"$log" | head -20 >&2 || true
    fail=1
    return 0
  fi
  du -sh "$ROOT/build/$1" | sed 's/^/tamaño: /'
}

echo "== import"
rc=0
log=$(cd "$ROOT/godot" && timeout 300 "$GODOT" --headless --import 2>&1) || rc=$?
if ((rc != 0)); then
  echo "FALLO: la importación terminó con código $rc; no se exporta." >&2
  tail -20 <<<"$log" >&2
  exit "$rc"
fi

if [[ "$TARGET" == linux || "$TARGET" == all ]]; then export_one linux "Linux x86_64" pulpasa.x86_64; fi
if [[ "$TARGET" == windows || "$TARGET" == all ]]; then export_one windows "Windows x86_64" pulpasa.exe; fi
if [[ "$TARGET" == web || "$TARGET" == all ]]; then export_one web "Web" index.html; fi
exit "$fail"
