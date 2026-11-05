#!/usr/bin/env bash
# Comprueba que run_stop_hook.sh y run_acs.sh no tocan nada si mktemp falla.
# Uso: run_mktemp_guard.sh <dir_vacío_fuera_de_cualquier_repo> <run_stop_hook.sh> <run_acs.sh> <esperado: guarda|sin_guarda>
# Cada caso corre con un mktemp falso en un repo desechable de ese directorio. mkdir y cp falsos registran
# y no ejecutan cualquier destino absoluto fuera de él, para que tampoco un script sin guarda escriba en `/`.
# Cada caso corre con el `cd` de este bash y con uno que, como en otras versiones de bash, devuelve 0 con `cd ""`.
# Con `guarda` sale con 1 si algún caso no da rc=2 sin cambios. Con `sin_guarda` solo informa.
set -uo pipefail
WORK="${1:?falta el directorio}"
STOP_SCRIPT="${2:?falta run_stop_hook.sh}"
ACS_SCRIPT="${3:?falta run_acs.sh}"
MODE="${4:?falta guarda o sin_guarda}"
[[ -d "$WORK" && -z "$(ls -A "$WORK")" ]] || { echo "run_mktemp_guard: hace falta un directorio vacío" >&2; exit 2; }
WORK="$(cd "$WORK" && pwd)" || exit 2
[[ -n "$WORK" && "$WORK" != / ]] || exit 2
if git -C "$WORK" rev-parse --git-dir >/dev/null 2>&1; then
  echo "run_mktemp_guard: el directorio está dentro de un repo" >&2
  exit 2
fi
STOP_SCRIPT="$(cd "$(dirname "$STOP_SCRIPT")" && pwd)/$(basename "$STOP_SCRIPT")"
ACS_SCRIPT="$(cd "$(dirname "$ACS_SCRIPT")" && pwd)/$(basename "$ACS_SCRIPT")"

BIN="$WORK/bin"
/usr/bin/env mkdir -p "$BIN" "$WORK/tmp" || exit 2
export WORK
export TMPDIR="$WORK/tmp"
export REAL_MKTEMP REAL_MKDIR REAL_CP
REAL_MKTEMP="$(command -v mktemp)"
REAL_MKDIR="$(command -v mkdir)"
REAL_CP="$(command -v cp)"

cat >"$BIN/mktemp" <<'EOF'
#!/usr/bin/env bash
case "$MKTEMP_MODE" in
  falla) exit 1 ;;
  vacio) exit 0 ;;
  inexistente) echo "$WORK/no-existe"; exit 0 ;;
  fichero_falla) [[ "${1:-}" == -d ]] && exec "$REAL_MKTEMP" "$@"; exit 1 ;;
  fichero_vacio) [[ "${1:-}" == -d ]] && exec "$REAL_MKTEMP" "$@"; exit 0 ;;
esac
EOF
cat >"$BIN/mkdir" <<'EOF'
#!/usr/bin/env bash
args=()
for arg in "$@"; do
  if [[ "$arg" == /* && "$arg" != "$WORK"/* ]]; then
    echo "mkdir $arg" >>"$OUTSIDE_LOG"
  else
    args+=("$arg")
  fi
done
exec "$REAL_MKDIR" "${args[@]}"
EOF
cat >"$BIN/cp" <<'EOF'
#!/usr/bin/env bash
target="${*: -1}"
if [[ "$target" == /* && "$target" != "$WORK"/* ]]; then
  echo "cp -> $target" >>"$OUTSIDE_LOG"
  exit 0
fi
exec "$REAL_CP" "$@"
EOF

snapshot() { # huella de un repo desechable: ficheros, contenido, HEAD y configuración
  (
    cd "$1" || exit 2
    find . -path ./.git -prune -o -print | LC_ALL=C sort
    find . -path ./.git -prune -o -type f -exec cksum {} + | LC_ALL=C sort
    git rev-parse HEAD
    cksum .git/config
  )
}

new_repo() {
  local repo="$1"
  "$REAL_MKDIR" -p "$repo/.claude/hooks" "$repo/docs/backlog" "$repo/docs/evidence/PUL-190" "$repo/docs/evidence/PUL-204" || return 2
  printf 'real\n' >"$repo/README.md"
  printf 'exit 2\n' >"$repo/.claude/hooks/hook_falso.sh"
  printf 'import sys\nsys.exit(2)\n' >"$repo/.claude/hooks/guard_ownership.py"
  "$REAL_CP" "$STOP_SCRIPT" "$repo/docs/evidence/PUL-204/run_stop_hook.sh" || return 2
  "$REAL_CP" "$ACS_SCRIPT" "$repo/docs/evidence/PUL-190/run_acs.sh" || return 2
  (
    cd "$repo" || exit 2
    git init -q . && git config user.email desechable@example.invalid && git config user.name desechable &&
      git config core.autocrlf false && git add -A && git commit -qm base
  )
}

fails=0
count=0
run_case() { # <script> <modo de mktemp> <real|vacio_0>
  local repo rc before after changed outside commits
  count=$((count + 1))
  repo="$WORK/repo_$count"
  new_repo "$repo" || { echo "run_mktemp_guard: no puedo crear el repo desechable" >&2; exit 2; }
  "$REAL_MKDIR" -p "$WORK/out_$count"
  export OUTSIDE_LOG="$WORK/fuera_$count.log"
  : >"$OUTSIDE_LOG"
  before="$(snapshot "$repo")"
  (
    cd "$repo" || exit 3
    export PATH="$BIN:$PATH" MKTEMP_MODE="$2"
    if [[ "$3" == vacio_0 ]]; then
      cd() { if [[ $# == 1 && -z "$1" ]]; then return 0; fi; builtin cd "$@"; }
      export -f cd
    fi
    if [[ "$1" == stop ]]; then
      bash docs/evidence/PUL-204/run_stop_hook.sh .claude/hooks/hook_falso.sh
    else
      bash docs/evidence/PUL-190/run_acs.sh .claude/hooks/guard_ownership.py "$WORK/out_$count"
    fi
  ) >"$WORK/salida_$count.log" 2>&1
  rc=$?
  after="$(snapshot "$repo")"
  changed=no
  [[ "$before" == "$after" ]] || changed=sí
  commits="$(git -C "$repo" rev-list --all --count)"
  outside="$(wc -l <"$OUTSIDE_LOG")"
  outside=$((outside + 0))
  local verdict=PASS
  [[ "$rc" == 2 && "$changed" == no && "$outside" == 0 && "$commits" == 1 ]] || verdict=FAIL
  [[ "$verdict" == PASS ]] || fails=$((fails + 1))
  printf '%s %s mktemp=%s cd=%s rc=%s repo_cambiado=%s commits=%s escrituras_fuera=%s\n' \
    "$verdict" "$1" "$2" "$3" "$rc" "$changed" "$commits" "$outside"
  sed 's/^/    fuera: /' "$OUTSIDE_LOG"
}

for cd_mode in real vacio_0; do
  for mode in falla vacio inexistente; do run_case stop "$mode" "$cd_mode"; done
  for mode in falla vacio inexistente fichero_falla fichero_vacio; do run_case acs "$mode" "$cd_mode"; done
done
echo "fallos=$fails"
[[ "$MODE" != guarda ]] || ((fails == 0))
