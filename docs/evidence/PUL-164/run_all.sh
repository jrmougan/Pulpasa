#!/usr/bin/env bash
# PUL-164: todas las medidas del bot de balance (sin ventana; 2-6 min en paralelo) y las tablas.
# Uso desde la raíz: docs/evidence/PUL-164/run_all.sh   (requiere godot/.godot importado)
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
OUT="$ROOT/docs/evidence/PUL-164"
LOGS="${TMPDIR:-/tmp}/pul164-logs"; mkdir -p "$LOGS"
run() { timeout 1500 godot --headless --audio-driver Dummy --fixed-fps 60 --path "$ROOT/godot" \
  -s res://tests/tools/balance_run.gd -- "$@" > "$LOGS/$(IFS=_; echo "$*").log" 2>&1; }
run recipes PassSlot04 PassSlot05 &
run recipes PassSlot01 PassSlot02 &
for mode in solo coop; do for seed in 1 2 3; do
  run round "$mode" "$seed" &
  run round "$mode" "$seed" proposal &
done; done
wait
grep -h "WARNING: \(objetivo\|la zona\)\|SCRIPT ERROR\|espera agotada" "$LOGS"/*.log | sort | uniq -c
python3 "$OUT/balance_tables.py" > /dev/null && echo "tablas: $OUT/tables.md"
