#!/usr/bin/env bash
# Uso: run_loop.sh N salida.log  (desde la raíz del repo)
cd "$(dirname "$0")/../../../godot" || exit 1
mkdir -p .gut_reports
pass=0; fail=0
for i in $(seq 1 "$1"); do
  out=$(godot --headless -s addons/gut/gut_cmdln.gd -gselect=test_level_01_r16.gd -gjunit_xml_file= 2>&1)
  if grep -q 'All tests passed' <<<"$out"; then pass=$((pass+1)); echo "run $i PASS" >> "$2"
  else fail=$((fail+1)); echo "run $i FAIL" >> "$2"; grep -E "Failed|expected|Expected|\[Failed\]|FAILED" <<<"$out" | head -8 >> "$2"; fi
done
echo "pass=$pass fail=$fail" >> "$2"
