#!/usr/bin/env bash
# PUL-164: todas las medidas del bot de balance (sin ventana, en paralelo) y las tablas.
# Uso desde la raíz: docs/evidence/PUL-164/run_all.sh   (requiere godot/.godot importado)
# Borra antes las salidas versionadas: si una medida falla, vence el timeout o falta alguna de las
# 14 salidas, el script sale con 1 y no regenera las tablas (nunca se usan resultados antiguos).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
OUT="$ROOT/docs/evidence/PUL-164"
LOGS="${TMPDIR:-/tmp}/pul164-logs"
rm -rf "$LOGS"; mkdir -p "$LOGS"
rm -f "$OUT"/metrics_*.json "$OUT/tables.md" "$OUT/summary.json"

expected=(metrics_recipes_PassSlot04_PassSlot05.json metrics_recipes_PassSlot01_PassSlot02.json)
pids=(); names=()
run() {
  local name; name="$(IFS=_; echo "$*")"
  timeout 1500 godot --headless --audio-driver Dummy --fixed-fps 60 --path "$ROOT/godot" \
    -s res://tests/tools/balance_run.gd -- "$@" > "$LOGS/$name.log" 2>&1 &
  pids+=("$!"); names+=("$name")
}
run recipes PassSlot04 PassSlot05
run recipes PassSlot01 PassSlot02
for mode in solo coop; do for seed in 1 2 3; do
  run round "$mode" "$seed"
  run round "$mode" "$seed" proposal
  expected+=("metrics_round_${mode}_seed${seed}.json" "metrics_round_${mode}_seed${seed}_proposal.json")
done; done

fail=0
for i in "${!pids[@]}"; do
  if wait "${pids[$i]}"; then :; else
    rc=$?
    echo "✗ ${names[$i]}: código $rc (124 = timeout); log: $LOGS/${names[$i]}.log" >&2
    fail=1
  fi
done
if grep -l "SCRIPT ERROR\|espera agotada" "$LOGS"/*.log >&2; then
  echo "✗ errores de script o esperas agotadas en los logs de arriba" >&2
  fail=1
fi
for file in "${expected[@]}"; do
  [[ -s "$OUT/$file" ]] || { echo "✗ falta la salida $file" >&2; fail=1; }
done
grep -h "WARNING: \(objetivo\|la zona\)" "$LOGS"/*.log | sort | uniq -c
if ((fail)); then echo "✗ medidas incompletas: no se generan las tablas" >&2; exit 1; fi
echo "✓ ${#expected[@]} salidas nuevas"
python3 "$OUT/balance_tables.py" > /dev/null || exit 1
echo "tablas: $OUT/tables.md"
