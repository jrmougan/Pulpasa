#!/usr/bin/env bash
# Genera todas las capturas y medidas de PUL-152 (una ejecución de Godot por resolución).
# Copia de docs/evidence/PUL-132/run_all.sh con las resoluciones de PUL-152 AC1 y el caso 09 (AC4).
# Uso: bash docs/evidence/PUL-152/run_all.sh   (desde cualquier sitio; abre ventanas)
set -euo pipefail
# --disable-vsync: con la ventana sin foco u ocultada (Wayland) el V-Sync deja el juego a 1 FPS.
# --audio-driver Dummy: sin sonido por los altavoces (skill godot-verify).
# Cada ejecución aborta el script si Godot sale con código ≠ 0, si no imprime su línea MEDIDAS o si
# su salida trae algún ERROR (también los de recursos en uso al salir); el log queda en $LOGS.
# GODOT=<ruta> cambia el binario (p. ej. uno simulado para probar el runner).
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT"
OUT="$ROOT/docs/evidence/PUL-152"
LOGS="$(mktemp -d)"
GODOT="${GODOT:-godot}"
N=0
godot_run() { # etiqueta del log, argumentos de Godot
  local log="$LOGS/$1.log"
  local status=0
  "$GODOT" --path godot --disable-vsync --audio-driver Dummy "${@:2}" >"$log" 2>&1 || status=$?
  if [ "$status" -ne 0 ]; then
    echo "FALLO $1: Godot salió con $status (log: $log)" >&2
    exit "$status"
  fi
  if grep -E "ERROR" "$log" >&2; then
    echo "FALLO $1: la salida trae ERROR (log: $log)" >&2
    exit 1
  fi
  if ! grep -E "^MEDIDAS" "$log"; then
    echo "FALLO $1: sin línea MEDIDAS (log: $log)" >&2
    exit 1
  fi
}
run() { # resolución, etiqueta, argumentos de usuario extra
  godot_run "$2" --resolution "$1" --position 0,0 -s ../docs/evidence/PUL-152/capture_boot.gd \
    -- "${@:3}" --out="$OUT" --tag="$2"
}
caso09() { # resolución, argumentos de usuario extra (un --tag posterior manda)
  N=$((N + 1))
  godot_run "caso09-$1-$N" --resolution "$1" --position 0,0 \
    -s ../docs/evidence/PUL-152/capture_caso09_boot.gd \
    -- --touch --out="$OUT" --tag="$1" "${@:2}"
}
run 1280x720 1280x720-desktop
run 1920x1080 1920x1080-desktop
run 2340x1080 2340x1080-touch --touch --safe
run 1920x1080 1920x1080-touch --touch
rm -f "$OUT"/1920x1080-touch-*.jpg # repositorio ligero: a 1920x1080 táctil solo el JSON
run 800x370 800x370-touch --touch
caso09 2340x1080
caso09 1920x1080 --no-jpg
caso09 800x370
# Comparación con PUL-136/138 (H-05): la pasada «nula» con la safe area del sistema, solo JSON.
# Depende de la máquina: solo reproduce PUL-136/138 con un panel superior de 32 px (GNOME).
caso09 2340x1080 --no-jpg --host-safe --tag=2340x1080-host
caso09 800x370 --no-jpg --host-safe --tag=800x370-host
