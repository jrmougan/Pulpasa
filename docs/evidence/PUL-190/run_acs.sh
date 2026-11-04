#!/usr/bin/env bash
# Ejecuta AC1-AC5 de PUL-190 contra guard_ownership.py desde Git Bash, con rutas de Windows (`pwd -W`).
# Uso: run_acs.sh <hook.py> <dir_salida>
# Trabaja en un sandbox con copia de docs/backlog: las fichas ilegibles de AC4 no tocan el backlog real.
# Sale con 1 si falla alguna comprobación.
set -uo pipefail
shopt -s lastpipe # `input | run_raw` debe fijar RC en este shell, no en un subshell.
HOOK="$(cygpath -wa "$1")"
OUT="$2"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
export LC_ALL=C # grep compara bytes: «está» solo casa si stderr sale en UTF-8.
# PYTHONUTF8=1 ocultaría el bug: el hook debe funcionar con la codificación por defecto de Windows.
unset PYTHONUTF8 PYTHONIOENCODING

BOX_UNIX="$(mktemp -d)"
trap 'rm -rf "$BOX_UNIX"' EXIT
mkdir -p "$BOX_UNIX/.claude" "$BOX_UNIX/docs"
cp -r "$REPO/docs/backlog" "$BOX_UNIX/docs/backlog"
cd "$BOX_UNIX" || exit 1
BOX="$(pwd -W)"
export CLAUDE_PROJECT_DIR="$BOX"
MARK=".claude/current-task"

fails=0
RC=0
ERR="$(mktemp)"

# Stderr legible y sin rutas absolutas: decodifica como UTF-8 y marca los bytes rotos como \xNN.
show_err() {
  python3 -c '
import re, sys
sys.stdout.reconfigure(encoding="utf-8", newline="\n")
text = open(sys.argv[1], "rb").read().decode("utf-8", "backslashreplace").replace("\0", "\\x00")
for line in text.splitlines():
    print("    " + re.sub(r"[A-Za-z]:[\\/]\S*", "<ruta>", line))
' "$ERR"
}

# Cadena JSON con la ruta de Windows, escapada como la manda Claude Code (barras invertidas).
input_for() {
  local win="$BOX/$1"
  win="${win//\//\\\\}"
  printf '{"tool_name":"Edit","tool_input":{"file_path":"%s"}}' "$win"
}

run_raw() { # entrada por stdin; deja RC y ERR
  python3 "$HOOK" >/dev/null 2>"$ERR"
  RC=$?
}

# check <etiqueta> <rc esperado> <texto esperado en stderr o ""> ; el stderr ya está en ERR y RC fijado.
check() {
  local verdict=PASS
  [[ "$RC" == "$2" ]] || verdict=FAIL
  if [[ -n "$3" ]] && ! grep -qF -- "$3" "$ERR"; then verdict=FAIL; fi
  [[ "$verdict" == PASS ]] || fails=$((fails + 1))
  printf '%s rc=%s (esperado %s) %s\n' "$verdict" "$RC" "$2" "$1"
  show_err
}

edit_case() { # <etiqueta> <ruta relativa> <rc> <texto>
  input_for "$2" | run_raw
  check "$1: $2" "$3" "$4"
}

OWNS_MSG='no está en `owns`'
ASK_MSG='orchestration ask'

python3 -c 'import locale, sys; print("python", sys.version.split()[0], "| locale", locale.getencoding())' \
  >"$OUT/env.txt"

{
  printf 'PUL-184\n' >"$MARK"
  echo "AC1 current-task=PUL-184, destino fuera de owns"
  edit_case "AC1" "Assets/x.txt" 2 "$OWNS_MSG"
  grep -qF "$ASK_MSG" "$ERR" && echo "PASS el mensaje cita orchestration ask" \
    || { echo "FAIL el mensaje no cita orchestration ask"; fails=$((fails + 1)); }
  if grep -qF 'orca ask' "$ERR"; then
    echo "FAIL el mensaje aún cita orca ask"
    fails=$((fails + 1))
  else
    echo "PASS el mensaje ya no cita orca ask"
  fi
} >"$OUT/ac1.txt" 2>&1

{
  echo "AC2 current-task=PUL-184, destinos dentro de owns"
  edit_case "AC2 literal (owns y touches_scenes)" "godot/entities/stations/order_stand.tscn" 0 ""
  edit_case "AC2 glob **" "docs/evidence/PUL-184/captura.png" 0 ""
  edit_case "AC2 glob *" "godot/tests/integration/test_order_tickets.gd.uid" 0 ""
  edit_case "AC2 la propia ficha" "docs/backlog/PUL-184-puestos-entrega-y-numeros-v3.md" 0 ""
} >"$OUT/ac2.txt" 2>&1

{
  echo "AC3 cada ficha: destino ajeno (rc=2 con mensaje de owns), primera ruta de owns (rc=0), propia ficha (rc=0)"
  echo "ficha ajeno propio_owns ficha_self veredicto"
  total=0
  rc1=0
  bad=0
  for card in docs/backlog/PUL-*.md; do
    name="${card##*/}"
    id="$(printf '%s' "$name" | sed -E 's/^(PUL-[0-9]+)-.*/\1/')"
    printf '%s\n' "$id" >"$MARK"
    total=$((total + 1))

    input_for "Assets/x.txt" | run_raw
    foreign=$RC
    grep -qF "$OWNS_MSG" "$ERR" && foreign_msg=1 || foreign_msg=0

    # Primera entrada de owns, leída aparte del hook; comodines y clases ([2-9]) se sustituyen por un nombre concreto.
    first="$(sed -n '2,/^---$/{/^owns: *\[/p}' "$card" | head -1 | sed -E 's/^owns: *\[//; s/\] *$//; s/,.*//' \
      | tr -d "'\"" | sed -E 's/\[(.)[^]]*\]/\1/g; s/\*+/x/g; s/ +$//')"
    if [[ -n "$first" ]]; then
      input_for "$first" | run_raw
      own=$RC
    else
      own=sin_owns
    fi

    input_for "$card" | run_raw
    self=$RC

    verdict=PASS
    [[ "$foreign" == 2 && "$foreign_msg" == 1 && "$self" == 0 ]] || verdict=FAIL
    [[ "$own" == 0 || "$own" == sin_owns ]] || verdict=FAIL
    [[ "$foreign" == 1 || "$own" == 1 || "$self" == 1 ]] && rc1=$((rc1 + 1))
    [[ "$verdict" == PASS ]] || bad=$((bad + 1))
    echo "$id $foreign $own $self $verdict"
  done
  fails=$((fails + bad))
  echo "TOTAL fichas=$total con_rc1=$rc1 fallos=$bad"
} >"$OUT/ac3.txt" 2>&1

{
  echo "AC4 ficha o entrada ilegible: siempre rc=2"
  printf 'PUL-184\n' >"$MARK"
  B=docs/backlog

  printf -- '---\nowns: [Assets/**]\n---\n\n\xff\xfe no es UTF-8\n' >"$B/PUL-901-binaria.md"
  printf 'PUL-901\n' >"$MARK"
  edit_case "ficha con bytes no UTF-8, destino que su owns permitiría" "Assets/x.txt" 2 "Bloqueado"

  mkdir -p "$B/PUL-902-directorio.md"
  printf 'PUL-902\n' >"$MARK"
  edit_case "la ficha es un directorio" "Assets/x.txt" 2 "Bloqueado"

  printf 'sin frontmatter\n' >"$B/PUL-903-sinfm.md"
  printf 'PUL-903\n' >"$MARK"
  edit_case "ficha sin frontmatter" "Assets/x.txt" 2 "Bloqueado"

  printf 'PUL-999\n' >"$MARK"
  edit_case "ficha inexistente" "Assets/x.txt" 2 "Bloqueado"

  printf '\xff\xfePUL-184\n' >"$MARK"
  edit_case "current-task con bytes no UTF-8" "Assets/x.txt" 2 "Bloqueado"

  printf '\xef\xbb\xbfPUL-184\n' >"$MARK"
  edit_case "current-task con BOM (Set-Content de PowerShell 5)" "Assets/x.txt" 2 "Bloqueado"

  printf 'PUL-184\n' >"$MARK"
  printf '{no es json' | run_raw
  check "entrada JSON inválida" 2 "Bloqueado"
  printf '' | run_raw
  check "entrada vacía" 2 "Bloqueado"
  printf '{"tool_input":{"file_path":"Assets/\xf1.txt"}}' | run_raw
  check "entrada JSON con bytes no UTF-8" 2 "Bloqueado"
  printf '[1, 2]' | run_raw
  check "JSON que no es un objeto" 2 "Bloqueado"
  printf '{"tool_input":null}' | run_raw
  check "tool_input null" 2 "Bloqueado"
  printf '{"tool_input":{"file_path":123}}' | run_raw
  check "file_path no es texto" 2 "Bloqueado"
  printf '{"tool_input":{"file_path":"Assets/\\u0000x.txt"}}' | run_raw
  check "file_path con NUL" 2 "Bloqueado"
  printf '{"tool_input":{"file_path":"../fuera.txt"}}' | run_raw
  check "destino fuera del repositorio" 2 "fuera del repositorio"

  echo "Restricción de la ficha: sin current-task no se restringe nada, ni con entrada inválida"
  rm -f "$MARK"
  input_for "Assets/x.txt" | run_raw
  check "sin current-task, destino ajeno" 0 ""
  printf '{no es json' | run_raw
  check "sin current-task, entrada inválida" 0 ""
  : >"$MARK"
  input_for "Assets/x.txt" | run_raw
  check "current-task vacío, destino ajeno" 0 ""
} >"$OUT/ac4.txt" 2>&1

{
  echo "AC5 rutas destino no ASCII: decide owns, sin excepción"
  printf 'PUL-184\n' >"$MARK"
  edit_case "fuera de owns, UTF-8 crudo" "Assets/peñón_ñandú.txt" 2 "$OWNS_MSG"
  grep -qF 'peñón_ñandú' "$ERR" && echo "PASS stderr conserva la ruta en UTF-8" \
    || { echo "FAIL stderr no conserva la ruta en UTF-8"; fails=$((fails + 1)); }
  edit_case "dentro de owns (glob), UTF-8 crudo" "docs/evidence/PUL-184/captura_ñ_€.png" 0 ""

  printf '{"tool_input":{"file_path":"%s/Assets/pe\\u00f1\\u00f3n.txt"}}' "$BOX" | run_raw
  check "fuera de owns, JSON con \\u" 2 "$OWNS_MSG"

  printf -- '---\nid: PUL-904\nowns: [docs/ñandú/peñón.md, godot/ñ/**]\ntouches_scenes: []\n---\n' \
    >docs/backlog/PUL-904-ñandú.md
  printf 'PUL-904\n' >"$MARK"
  edit_case "ficha con owns no ASCII, literal" "docs/ñandú/peñón.md" 0 ""
  edit_case "ficha con owns no ASCII, glob" "godot/ñ/a/b.gd" 0 ""
  edit_case "ficha con owns no ASCII, ruta parecida" "docs/nandu/penon.md" 2 "$OWNS_MSG"

  echo "Consola forzada a cp1252: el resultado no cambia"
  export PYTHONIOENCODING=cp1252
  printf 'PUL-184\n' >"$MARK"
  edit_case "PYTHONIOENCODING=cp1252, fuera de owns" "Assets/peñón.txt" 2 "$OWNS_MSG"
  grep -qF 'peñón' "$ERR" && echo "PASS stderr sigue en UTF-8" \
    || { echo "FAIL stderr no sale en UTF-8"; fails=$((fails + 1)); }
  edit_case "PYTHONIOENCODING=cp1252, dentro de owns" "docs/evidence/PUL-184/ñ.png" 0 ""
  unset PYTHONIOENCODING
} >"$OUT/ac5.txt" 2>&1

rm -f "$ERR"
echo "fallos=$fails" | tee "$OUT/summary.txt"
grep -c '^PASS' "$OUT"/ac[1245].txt | sed 's|.*/||' | tee -a "$OUT/summary.txt"
tail -1 "$OUT/ac3.txt" | tee -a "$OUT/summary.txt"
((fails == 0))
