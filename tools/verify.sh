#!/usr/bin/env bash
# Verificación única del proyecto Godot. La usan hooks, agentes y el merge gate.
# Uso: tools/verify.sh [--quick]   (--quick: solo lint + parseo, sin tests ni smoke)
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_DIR="$ROOT/godot"
GODOT="${GODOT_PATH:-godot}"
QUICK=0; [[ "${1:-}" == "--quick" ]] && QUICK=1
fail=0
step() { printf '\n== %s\n' "$1"; }

cd "$GODOT_DIR"
mapfile -t GD_FILES < <(find . -name '*.gd' -not -path './addons/*' -not -path './.godot/*' -not -path './.mcp/*' | sort)

step "gdformat --check"
if ((${#GD_FILES[@]})); then gdformat --check "${GD_FILES[@]}" || fail=1; fi

step "gdlint"
if ((${#GD_FILES[@]})); then gdlint "${GD_FILES[@]}" || fail=1; fi

step "import"
out=$(timeout 300 "$GODOT" --headless --import 2>&1); rc=$?
if ((rc != 0)) || grep -qE '^(SCRIPT )?ERROR' <<<"$out"; then grep -E 'ERROR' <<<"$out" | head -30; fail=1; fi

if ((QUICK == 0)); then
  step "tests (GUT)"
  mkdir -p .gut_reports
  timeout 600 "$GODOT" --headless -s addons/gut/gut_cmdln.gd 2>&1 | tee .gut_reports/last.log | tail -25
  rc=${PIPESTATUS[0]}
  if ((rc != 0)) || ! grep -q 'All tests passed' .gut_reports/last.log; then fail=1; fi
  # GUT ignora en silencio los scripts que no compilan ("Ignoring script ... does not extend GutTest"):
  # eso esconde suites enteras con verify en verde. Cualquier script ignorado o error de parseo falla.
  if grep -qE "Ignoring script|Parse Error|SCRIPT ERROR" .gut_reports/last.log; then
    echo "✗ GUT ignoró scripts o hubo errores de parseo:" >&2
    grep -E "Ignoring script|Parse Error|SCRIPT ERROR" .gut_reports/last.log | head -10 >&2
    fail=1
  fi

  step "smoke run (escena principal, 120 frames)"
  out=$(timeout 120 "$GODOT" --headless --quit-after 120 2>&1); rc=$?
  if ((rc != 0)) || grep -qE '(SCRIPT ERROR|^ERROR)' <<<"$out"; then echo "$out" | tail -30; fail=1; else echo "OK"; fi
fi

if ((fail)); then printf '\n✗ verify FAILED\n'; exit 1; fi
printf '\n✓ verify OK\n'
