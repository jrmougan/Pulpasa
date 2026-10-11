#!/usr/bin/env bash
# Genera todas las capturas y medidas de PUL-132 (una ejecución de Godot por resolución).
# Uso: bash docs/evidence/PUL-132/run_all.sh   (desde la raíz del repositorio; abre ventanas)
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT"
OUT="$ROOT/docs/evidence/PUL-132"
run() { # resolución, etiqueta, argumentos de usuario extra
  godot --path godot --resolution "$1" --position 0,0 -s ../docs/evidence/PUL-132/capture_boot.gd \
    -- "${@:3}" --out="$OUT" --tag="$2" 2>&1 | grep -E "MEDIDAS|ERROR" 
}
run 1280x720 1280x720-desktop
run 1920x1080 1920x1080-desktop
run 2340x1080 2340x1080-touch --touch --safe
run 1920x1080 1920x1080-touch --touch
run 800x370 800x370-desktop
run 800x370 800x370-touch --touch
