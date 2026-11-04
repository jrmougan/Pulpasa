#!/usr/bin/env bash
# Comprueba el hook de Stop en un repo Git temporal con un verify.sh falso que cuenta sus llamadas.
# Uso, desde Git Bash o Linux: run_stop_hook.sh <verify_on_stop.sh>
# No toca el repo real y no lanza la suite. Sale con 1 si algún caso falla.
set -uo pipefail
HOOK="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
BOX="$(mktemp -d)"
trap 'rm -rf "$BOX"' EXIT
cd "$BOX" || exit 1
git init -q .
git config user.email pul204@example.invalid
git config user.name PUL-204
git config core.autocrlf false
mkdir -p .claude godot docs tools
printf 'a\n' >AGENTS.md
printf 'a\n' >CLAUDE.md
printf 'a\n' >godot/a.gd
printf 'a\n' >docs/a.md
cat >tools/verify.sh <<'EOF'
#!/usr/bin/env bash
echo x >>"$CALLS"
echo "verify falso rc=$STUB_RC"
exit "$STUB_RC"
EOF
chmod +x tools/verify.sh
git add -A
git commit -qm base
BASE="$(git rev-parse HEAD)"
export CLAUDE_PROJECT_DIR="$BOX"
export CALLS="$BOX/.git/verify_calls"
fails=0

reset_box() {
  git reset -q --hard "$BASE"
  git clean -fdq godot docs AGENTS.md CLAUDE.md
  rm -f .claude/.stop-retries "$CALLS"
  printf 'PUL-204\n' >.claude/current-task
}

# case_run <etiqueta> <rc esperado> <llamadas a verify esperadas> [STUB_RC]; el estado ya está preparado.
case_run() {
  local rc calls verdict=PASS
  STUB_RC="${4:-1}" bash "$HOOK" >/dev/null 2>&1
  rc=$?
  calls=0
  [[ -f "$CALLS" ]] && calls=$(wc -l <"$CALLS")
  calls=$((calls + 0))
  [[ "$rc" == "$2" && "$calls" == "$3" ]] || verdict=FAIL
  [[ "$verdict" == PASS ]] || fails=$((fails + 1))
  printf '%s rc=%s (esperado %s) verify=%s (esperado %s) %s\n' "$verdict" "$rc" "$2" "$calls" "$3" "$1"
}

reset_box
rm -f .claude/current-task
printf 'b\n' >>AGENTS.md
case_run "sin current-task, AGENTS.md cambiado" 0 0

reset_box
rm -f .claude/current-task
printf 'b\n' >>godot/a.gd
case_run "sin current-task, godot/ cambiado" 0 0

reset_box
case_run "current-task, sin cambios" 0 0

reset_box
printf 'b\n' >>docs/a.md
case_run "current-task, solo docs/ cambiado" 0 0

reset_box
printf 'b\n' >>godot/a.gd
case_run "current-task, godot/ cambiado, verify falla" 2 1

reset_box
printf 'b\n' >godot/nuevo.gd
case_run "current-task, godot/ con fichero nuevo, verify falla" 2 1

reset_box
printf 'b\n' >>AGENTS.md
case_run "current-task, AGENTS.md cambiado, verify falla" 2 1

reset_box
printf 'b\n' >>CLAUDE.md
case_run "current-task, CLAUDE.md cambiado, verify falla" 2 1

reset_box
rm -f CLAUDE.md
case_run "current-task, CLAUDE.md borrado, verify falla" 2 1

reset_box
printf 'b\n' >>AGENTS.md
git add AGENTS.md
case_run "current-task, AGENTS.md en el índice, verify falla" 2 1

reset_box
printf 'b\n' >>AGENTS.md
case_run "current-task, AGENTS.md cambiado, verify pasa" 0 1 0

reset_box
git rm -q --cached CLAUDE.md
git commit -qm 'sin CLAUDE.md'
case_run "current-task, CLAUDE.md sin versionar, verify falla" 2 1
git reset -q --hard "$BASE"

reset_box
printf 'b\n' >>AGENTS.md
rm -f "$CALLS"
case_run "tres fallos seguidos, intento 1" 2 1
case_run "tres fallos seguidos, intento 2" 2 2
case_run "tres fallos seguidos, intento 3: deja parar y escala" 0 3

echo "fallos=$fails"
((fails == 0))
