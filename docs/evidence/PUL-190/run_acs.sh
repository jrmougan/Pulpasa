#!/usr/bin/env bash
# Ejecuta AC1-AC5 de PUL-190 contra guard_ownership.py. En Git Bash usa rutas de Windows (`pwd -W`);
# en Linux, rutas POSIX. fail_open.txt mide lo que el hook no puede arreglar: no cuenta como fallo.
# Uso: run_acs.sh <hook.py> <dir_salida>
# Trabaja en un sandbox con copia de docs/backlog: las fichas ilegibles de AC4 no tocan el backlog real.
# Sale con 1 si falla alguna comprobación.
set -uo pipefail
shopt -s lastpipe # `input | run_raw` debe fijar RC en este shell, no en un subshell.
HOOK="$(cygpath -wa "$1" 2>/dev/null || realpath "$1")"
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
BOX="$(pwd -W 2>/dev/null || pwd)"
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
    print("    " + re.sub(r"([A-Za-z]:[\\/]|/tmp/|/mnt/)\S*", "<ruta>", line))
' "$ERR"
}

# Cadena JSON con la ruta del sistema; en Windows, escapada como la manda Claude Code (barras invertidas).
input_for() {
  local win="$BOX/$1"
  [[ "$BOX" == *:* ]] && win="${win//\//\\\\}"
  printf '{"tool_name":"Edit","tool_input":{"file_path":"%s"}}' "$win"
}

run_raw() { # entrada por stdin; deja RC y ERR
  python3 "$HOOK" >/dev/null 2>"$ERR"
  RC=$?
}

run_closed() { # como run_raw, con stderr cerrado: Python deja sys.stderr en None
  python3 "$HOOK" >/dev/null 2>&-
  RC=$?
  : >"$ERR"
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
PATH_MSG='entrada sin file_path válido'
OWN_PATH='godot/entities/stations/order_stand.tscn' # literal en `owns` de PUL-184
ASK_MSG='orchestration ask'

python3 -c 'import locale, platform, sys; print(platform.system(), "| python", sys.version.split()[0], "| locale", locale.getencoding())' \
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

  echo "Entrada sin file_path de texto: Edit, Write y MultiEdit siempre lo llevan"
  for json in '{}' '{"tool_input":{}}' '{"tool_input":{"path":"Assets/x.txt"}}' \
    '{"tool_input":{"file_path":null}}' '{"tool_input":{"file_path":""}}' '{"tool_input":{"file_path":0}}' \
    '{"tool_input":{"file_path":false}}' '{"tool_input":{"file_path":[]}}' '{"tool_input":{"file_path":{}}}' \
    '{"tool_input":{"file_path":123}}'; do
    printf '%s' "$json" | run_raw
    check "$json" 2 "$PATH_MSG"
  done

  printf '{"tool_input":{"file_path":"Assets/\\u0000x.txt"}}' | run_raw
  check "file_path con NUL" 2 "Bloqueado"
  printf '{"tool_input":{"file_path":"../fuera.txt"}}' | run_raw
  check "destino fuera del repositorio" 2 "fuera del repositorio"

  echo "Un BOM no hace ilegible el texto: decide owns (Set-Content de PowerShell 5 lo escribe)"
  printf '\xef\xbb\xbfPUL-184\n' >"$MARK"
  edit_case "current-task con BOM, ruta de owns" "$OWN_PATH" 0 ""
  edit_case "current-task con BOM, destino ajeno" "Assets/x.txt" 2 "$OWNS_MSG"
  printf '\xef\xbb\xbf---\nowns: [Assets/**]\n---\n' >"$B/PUL-905-bom.md"
  printf 'PUL-905\n' >"$MARK"
  edit_case "ficha con BOM, ruta de owns" "Assets/x.txt" 0 ""
  edit_case "ficha con BOM, destino ajeno" "godot/x.gd" 2 "$OWNS_MSG"

  echo "Stderr cerrado: no cambia ninguna decisión"
  printf 'PUL-184\n' >"$MARK"
  input_for "Assets/x.txt" | run_closed
  check "stderr cerrado, destino ajeno" 2 ""
  input_for "$OWN_PATH" | run_closed
  check "stderr cerrado, ruta de owns" 0 ""
  printf '{no es json' | run_closed
  check "stderr cerrado, entrada inválida" 2 ""

  echo "Restricción de la ficha: sin current-task no se restringe nada, ni con entrada inválida"
  rm -f "$MARK"
  input_for "Assets/x.txt" | run_raw
  check "sin current-task, destino ajeno" 0 ""
  printf '{no es json' | run_raw
  check "sin current-task, entrada inválida" 0 ""
  : >"$MARK"
  input_for "Assets/x.txt" | run_raw
  check "current-task vacío, destino ajeno" 0 ""
  input_for "Assets/x.txt" | run_closed
  check "current-task vacío, stderr cerrado" 0 ""
  rm -f "$MARK"
  input_for "Assets/x.txt" | run_closed
  check "sin current-task, stderr cerrado, destino ajeno" 0 ""
  printf '{no es json' | run_closed
  check "sin current-task, stderr cerrado, entrada inválida" 0 ""
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

# Lo que queda fuera del alcance del hook, con el comando real de .claude/settings.json. Solo el 2 bloquea.
hook_command() {
  python3 -c '
import json, sys
hooks = json.load(open(sys.argv[1], encoding="utf-8"))["hooks"]["PreToolUse"]
print(next(h for h in hooks if h["matcher"] == "Edit|Write|MultiEdit")["hooks"][0]["command"])
' "$(cygpath -wa "$REPO/.claude/settings.json" 2>/dev/null || echo "$REPO/.claude/settings.json")"
}

measure() { # <etiqueta> <comando>; la edición va a una ruta ajena, así que el rc correcto es 2
  input_for "Assets/x.txt" | bash -c "$2" >/dev/null 2>"$ERR"
  RC=$?
  if [[ "$RC" == 2 ]]; then
    printf 'BLOQUEA rc=%s %s\n' "$RC" "$1"
  else
    printf 'FALLO ABIERTO rc=%s %s\n' "$RC" "$1"
  fi
  show_err
}

{
  echo "Comando de settings.json, marcador activo y destino ajeno: cualquier rc distinto de 2 deja pasar la edición"
  printf 'PUL-184\n' >"$MARK"
  CMD="$(hook_command | tr -d '\r')"
  echo "comando: $CMD"
  mkdir -p .claude/hooks
  cp "$HOOK" .claude/hooks/guard_ownership.py
  measure "control: hook intacto" "$CMD"
  measure "PYTHONIOENCODING inválida (Fatal Python error, antes del try)" "PYTHONIOENCODING=no-existe $CMD"
  measure "intérprete ausente (simulado con un comando inexistente, sin quitar Python)" "${CMD/python3/python3-no-existe}"
  printf 'def (:\n' >.claude/hooks/guard_ownership.py
  measure "hook que no compila" "$CMD"
} >"$OUT/fail_open.txt" 2>&1

rm -f "$ERR"
echo "fallos=$fails" | tee "$OUT/summary.txt"
grep -c '^PASS' "$OUT"/ac[1245].txt | sed 's|.*/||' | tee -a "$OUT/summary.txt"
tail -1 "$OUT/ac3.txt" | tee -a "$OUT/summary.txt"
echo "fallo_abierto_conocido=$(grep -c '^FALLO ABIERTO' "$OUT/fail_open.txt")" | tee -a "$OUT/summary.txt"
((fails == 0))
